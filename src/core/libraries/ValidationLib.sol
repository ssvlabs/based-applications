// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.29;

uint32 constant MAX_PERCENTAGE = 1e4; // 100% in basis points
address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

library ValidationLib {
    error InvalidPercentage();
    error LengthsNotMatching();
    error ZeroAddressNotAllowed();

    function validatePercentage(uint32 percentage) internal pure {
        if (percentage > MAX_PERCENTAGE) {
            revert InvalidPercentage();
        }
    }

    function validatePercentageAndNonZero(uint32 percentage) internal pure {
        if (percentage == 0 || percentage > MAX_PERCENTAGE) {
            revert InvalidPercentage();
        }
    }

    function validateArrayLengths(
        address[] calldata tokens,
        uint32[] memory values
    ) internal pure {
        if (tokens.length != values.length) {
            revert LengthsNotMatching();
        }
    }

    function validateNonZeroAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert ZeroAddressNotAllowed();
        }
    }
}
