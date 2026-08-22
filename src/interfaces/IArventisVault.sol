// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IArventisVault - Standard ERC-4626 Vault Interface with Dynamic Yield & Slashing
interface IArventisVault {
    // Custom Errors for Gas Efficiency
    error DepositZero();
    error WithdrawZero();
    error ExceedsMaxDeposit();
    error ExceedsMaxWithdraw();
    error Unauthorized();
    error ReentrancyGuard();

    // Events
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );
    event YieldHarvested(uint256 amount, uint256 timestamp);

    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
}
