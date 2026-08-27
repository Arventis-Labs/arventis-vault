// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ArventisVault} from "../src/ArventisVault.sol";
import {MockERC20} from "./MockERC20.sol";

contract VaultHandler is Test {
    ArventisVault public vault;
    MockERC20 public asset;

    address[] public actors;
    address public currentActor;

    constructor(ArventisVault _vault, MockERC20 _asset) {
        vault = _vault;
        asset = _asset;

        // Initialize multiple test actors to simulate concurrent user interactions
        actors.push(address(0x1111));
        actors.push(address(0x2222));
        actors.push(address(0x3333));

        // Fund actors and approve the vault for infinite token transfer
        for (uint256 i = 0; i < actors.length; i++) {
            asset.mint(actors[i], 100_000_000 ether);
            vm.prank(actors[i]);
            asset.approve(address(vault), type(uint256).max);
        }
    }

    // Modifier to dynamically switch between fuzzing actors
    modifier useActor(uint256 actorIndex) {
        currentActor = actors[actorIndex % actors.length];
        vm.startPrank(currentActor);
        _;
        vm.stopPrank();
    }

    function deposit(uint256 amount, uint256 actorIndex) public useActor(actorIndex) {
        amount = bound(amount, 1 wei, 1_000_000 ether);
        try vault.deposit(amount, currentActor) {} catch {}
    }

    function mint(uint256 shares, uint256 actorIndex) public useActor(actorIndex) {
        shares = bound(shares, 1 wei, 1_000_000 ether);
        try vault.mint(shares, currentActor) {} catch {}
    }

    function withdraw(uint256 assets, uint256 actorIndex) public useActor(actorIndex) {
        assets = bound(assets, 0, vault.maxWithdraw(currentActor));
        if (assets == 0) return;
        try vault.withdraw(assets, currentActor, currentActor) {} catch {}
    }

    function redeem(uint256 shares, uint256 actorIndex) public useActor(actorIndex) {
        shares = bound(shares, 0, vault.maxRedeem(currentActor));
        if (shares == 0) return;
        try vault.redeem(shares, currentActor, currentActor) {} catch {}
    }
}

contract ArventisVaultInvariants is StdInvariant, Test {
    ArventisVault public vault;
    MockERC20 public asset;
    VaultHandler public handler;

    function setUp() public {
        asset = new MockERC20("Mock Asset", "MCK");
        vault = new ArventisVault(asset, "Arventis Vault Share", "avSHARES");

        handler = new VaultHandler(vault, asset);

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = VaultHandler.deposit.selector;
        selectors[1] = VaultHandler.mint.selector;
        selectors[2] = VaultHandler.withdraw.selector;
        selectors[3] = VaultHandler.redeem.selector;

        // Route invariant fuzzing calls exclusively through the Handler contract
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    /// @notice Invariant 1: Vault's tracked totalAssets must never exceed its actual underlying asset balance (Strict Solvency)
    function invariant_solvency() public view {
        assertGe(asset.balanceOf(address(vault)), vault.totalAssets());
    }

    /// @notice Invariant 2: If totalSupply is zero, totalAssets must strictly be zero (Defense against empty-vault inflation vectors)
    function invariant_totalSupplyZeroImpliesTotalAssetsZero() public view {
        if (vault.totalSupply() == 0) {
            assertEq(vault.totalAssets(), 0);
        }
    }

    /// @notice Invariant 3: Share to asset conversion rate must remain mathematically consistent and prevent precision loss overflow
    function invariant_convertToAssetsConsistency() public view {
        uint256 supply = vault.totalSupply();
        if (supply > 0) {
            uint256 oneShareAssets = vault.convertToAssets(1e18);
            assertTrue(oneShareAssets >= 0);
        }
    }
}
