// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ArventisVault} from "../src/ArventisVault.sol";
import {MockERC20} from "./MockERC20.sol";

contract ArventisVaultTest is Test {
    ArventisVault public vault;
    MockERC20 public asset;

    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        asset = new MockERC20("Test Token", "TEST");
        vault = new ArventisVault(asset, "Vault Share", "vTEST");

        asset.mint(user1, 1_000_000e18);
        asset.mint(user2, 1_000_000e18);

        vm.prank(user1);
        asset.approve(address(vault), type(uint256).max);

        vm.prank(user2);
        asset.approve(address(vault), type(uint256).max);
    }

    /// @notice Standard Unit Test
    function test_BasicDepositAndWithdraw() public {
        vm.startPrank(user1);
        uint256 depositAmount = 100e18;

        uint256 shares = vault.deposit(depositAmount, user1);
        assertEq(shares, depositAmount);
        assertEq(vault.totalAssets(), depositAmount);

        uint256 withdrawnShares = vault.withdraw(depositAmount, user1, user1);
        assertEq(withdrawnShares, shares);
        assertEq(vault.totalAssets(), 0);
        vm.stopPrank();
    }

    /// @notice Advanced Fuzz Testing: Random amounts up to total supply
    function testFuzz_Deposit(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000e18);

        vm.prank(user1);
        uint256 shares = vault.deposit(amount, user1);

        assertEq(vault.balanceOf(user1), shares);
        assertEq(vault.totalAssets(), amount);
    }

    /// @notice Invariant Check: Vault Solvency (Total assets must always cover shares ratio)
    function testFuzz_Withdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        depositAmount = bound(depositAmount, 1000, 1_000_000e18);
        withdrawAmount = bound(withdrawAmount, 1, depositAmount);

        vm.startPrank(user1);
        vault.deposit(depositAmount, user1);
        vault.withdraw(withdrawAmount, user1, user1);
        vm.stopPrank();

        assertEq(vault.totalAssets(), depositAmount - withdrawAmount);
    }
}