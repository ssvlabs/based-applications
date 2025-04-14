// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.29;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {CoreStorageLib, SSVCoreModules} from "@ssv/src/core/libraries/CoreStorageLib.sol";
import {ISSVBasedApps} from "@ssv/src/core/interfaces/ISSVBasedApps.sol";
import {IBasedApp} from "@ssv/src/middleware/interfaces/IBasedApp.sol";

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

    function validateArrayLengths(address[] calldata tokens, uint32[] memory values) internal pure {
        if (tokens.length != values.length) {
            revert LengthsNotMatching();
        }
    }

    function validateNonZeroAddress(address addr) internal pure {
        if (addr == address(0)) {
            revert ZeroAddressNotAllowed();
        }
    }
    //todo check get version place

    event ModuleUpgraded(SSVCoreModules indexed moduleId, address moduleAddress);

    function getVersion() internal pure returns (string memory) {
        return "v0.0.0";
    }

    /// @notice Function to check if an address uses the correct bApp interface
    /// @param bApp The address of the bApp
    /// @return True if the address uses the correct bApp interface
    function isBApp(address bApp) public view returns (bool) {
        return ERC165Checker.supportsInterface(bApp, type(IBasedApp).interfaceId);
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        if (account == address(0)) {
            return false;
        }
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function setModuleContract(SSVCoreModules moduleId, address moduleAddress) internal {
        if (!isContract(moduleAddress)) revert ISSVBasedApps.TargetModuleDoesNotExist(uint8(moduleId));

        CoreStorageLib.load().ssvContracts[moduleId] = moduleAddress;
        emit ModuleUpgraded(moduleId, moduleAddress);
    }
}
