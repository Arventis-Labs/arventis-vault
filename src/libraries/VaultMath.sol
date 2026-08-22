// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title VaultMath - High-Performance Gas Optimized Math for Arventis Vaults
/// @notice Implements low-level Yul arithmetic for ERC-4626 ratio calculations
library VaultMath {
    /// @dev Multiplies two numbers and divides by a third with full precision handling in Yul
    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to require(denominator != 0)
            if iszero(denominator) {
                // Revert with generic panic or custom error selector
                mstore(0x00, 0x12) // Custom error flag or standard panic
                revert(0x00, 0x20)
            }

            // Calculate x * y
            let prod0 := mul(x, y)

            // Check overflow: if x != 0 and prod0 / x != y
            if and(gt(x, 0), iszero(eq(div(prod0, x), y))) {
                revert(0x00, 0x00)
            }

            // Perform floor division
            result := div(prod0, denominator)
        }
    }

    /// @dev Calculates shares rounding UP to prevent inflation attacks / rounding exploits
    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        assembly {
            if iszero(denominator) {
                revert(0x00, 0x00)
            }

            let prod0 := mul(x, y)

            if and(gt(x, 0), iszero(eq(div(prod0, x), y))) {
                revert(0x00, 0x00)
            }

            // Ceil division logic: (x * y + denominator - 1) / denominator
            result := div(add(prod0, sub(denominator, 1)), denominator)
        }
    }
}