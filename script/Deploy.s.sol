// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ArventisVault} from "../src/ArventisVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DeployScript for ArventisVault
/// @notice Production-grade deployment script with dynamic environment config
contract DeployScript is Script {
    function run() external returns (ArventisVault vault) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address underlyingAsset = vm.envAddress("UNDERLYING_ASSET");

        require(underlyingAsset != address(0), "DeployScript: Invalid asset address");

        vm.startBroadcast(deployerPrivateKey);

        vault = new ArventisVault(IERC20(underlyingAsset), "Arventis Vault Token", "aVAULT");

        vm.stopBroadcast();

        console2.log("--------------------------------------------------");
        console2.log("ArventisVault Deployed Successfully");
        console2.log("Vault Address   :", address(vault));
        console2.log("Underlying Asset:", underlyingAsset);
        console2.log("Deployer        :", vm.addr(deployerPrivateKey));
        console2.log("--------------------------------------------------");
    }
}
