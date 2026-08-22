// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VaultMath} from "./libraries/VaultMath.sol";
import {IArventisVault} from "./interfaces/IArventisVault.sol";

/// @title ArventisVault - Production-Grade ERC-4626 Yield Vault
/// @notice Optimized vault implementation built for high-security asset management
contract ArventisVault is ERC20, ReentrancyGuard, IArventisVault {
    using SafeERC20 for IERC20;
    using VaultMath for uint256;

    IERC20 private immutable _asset;

    constructor(IERC20 underlyingAsset, string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        if (address(underlyingAsset) == address(0)) revert Unauthorized();
        _asset = underlyingAsset;
    }

    /// @notice Address of the underlying asset
    function asset() public view override returns (address) {
        return address(_asset);
    }

    /// @notice Total underlying assets managed by the vault
    function totalAssets() public view override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /// @notice Converts asset amount to share amount using Yul low-level math
    function convertToShares(uint256 assets) public view override returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 totalVaultAssets = totalAssets();

        if (totalShares == 0 || totalVaultAssets == 0) {
            return assets;
        }
        return assets.mulDivDown(totalShares, totalVaultAssets);
    }

    /// @notice Converts share amount to asset amount using Yul low-level math
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 totalVaultAssets = totalAssets();

        if (totalShares == 0 || totalVaultAssets == 0) {
            return shares;
        }
        return shares.mulDivDown(totalVaultAssets, totalShares);
    }

    /// @notice Deposit underlying assets to receive vault shares
    function deposit(uint256 assets, address receiver) external override nonReentrant returns (uint256 shares) {
        if (assets == 0) revert DepositZero();
        if (receiver == address(0)) revert Unauthorized();

        shares = convertToShares(assets);
        if (shares == 0) revert DepositZero();

        _asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice Withdraw assets from vault by burning shares
    function withdraw(uint256 assets, address receiver, address owner)
        external
        override
        nonReentrant
        returns (uint256 shares)
    {
        if (assets == 0) revert WithdrawZero();
        if (receiver == address(0) || owner == address(0)) revert Unauthorized();

        shares = convertToShares(assets);
        if (shares == 0) revert WithdrawZero();

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                if (allowed < shares) revert Unauthorized();
                _approve(owner, msg.sender, allowed - shares);
            }
        }

        _burn(owner, shares);
        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}
