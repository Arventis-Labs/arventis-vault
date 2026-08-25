// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IArventisVault} from "./interfaces/IArventisVault.sol";
import {VaultMath} from "./libraries/VaultMath.sol";

contract ArventisVault is ERC20, ReentrancyGuard, IArventisVault {
    using SafeERC20 for IERC20;
    using VaultMath for uint256;

    // Custom Errors (Unauthorized is inherited from IArventisVault)
    error ZeroAmount();
    error ZeroAddress();
    error ZeroShares();

    IERC20 private immutable _asset;

    constructor(
        IERC20 underlyingAsset,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        if (address(underlyingAsset) == address(0)) revert Unauthorized();
        _asset = underlyingAsset;
    }

    function asset() public view override returns (address) {
        return address(_asset);
    }

    function totalAssets() public view override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    function convertToShares(uint256 assets) public view override returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 totalVaultAssets = totalAssets();

        if (totalShares == 0 || totalVaultAssets == 0) {
            return assets;
        }
        return assets.mulDivDown(totalShares, totalVaultAssets);
    }

    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 totalVaultAssets = totalAssets();

        if (totalShares == 0 || totalVaultAssets == 0) {
            return shares;
        }
        return shares.mulDivDown(totalVaultAssets, totalShares);
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf(owner);
    }

    function deposit(uint256 assets, address receiver) public nonReentrant returns (uint256 shares) {
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        shares = convertToShares(assets);
        if (shares == 0) revert ZeroShares();

        _asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public nonReentrant returns (uint256 assets) {
        if (shares == 0) revert ZeroShares();
        if (receiver == address(0)) revert ZeroAddress();

        uint256 totalShares = totalSupply();
        uint256 totalVaultAssets = totalAssets();

        assets = (totalShares == 0 || totalVaultAssets == 0) 
            ? shares 
            : shares.mulDivUp(totalVaultAssets, totalShares);

        _asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public nonReentrant returns (uint256 shares) {
        if (assets == 0) revert ZeroAmount();
        if (receiver == address(0)) revert ZeroAddress();

        shares = convertToShares(assets);
        if (shares == 0) revert ZeroShares();

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                _spendAllowance(owner, msg.sender, shares);
            }
        }

        _burn(owner, shares);
        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public nonReentrant returns (uint256 assets) {
        if (shares == 0) revert ZeroShares();
        if (receiver == address(0)) revert ZeroAddress();

        assets = convertToAssets(shares);
        if (assets == 0) revert ZeroAmount();

        if (msg.sender != owner) {
            uint256 allowed = allowance(owner, msg.sender);
            if (allowed != type(uint256).max) {
                _spendAllowance(owner, msg.sender, shares);
            }
        }

        _burn(owner, shares);
        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }
}