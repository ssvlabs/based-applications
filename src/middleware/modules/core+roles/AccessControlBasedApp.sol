// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { IBasedApp } from "@ssv/src/middleware/interfaces/IBasedApp.sol";
import { BasedAppCore } from "@ssv/src/middleware/modules/core/BasedAppCore.sol";

import { IBasedAppManager } from "@ssv/src/core/interfaces/IBasedAppManager.sol";

abstract contract AccessControlBasedApp is BasedAppCore, AccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    constructor(
        address _basedAppManager,
        address owner
    ) AccessControl() BasedAppCore(_basedAppManager) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        SSV_BASED_APPS_NETWORK = _basedAppManager;
    }

    function grantManagerRole(
        address manager
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    function revokeManagerRole(
        address manager
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    /// @notice Registers a BApp calling the SSV SSVBasedApps
    /// @param tokens array of token addresses
    /// @param sharedRiskLevels array of shared risk levels
    /// @param metadataURI URI of the metadata
    /// @dev metadata should point to a json that respect template:
    ///    {
    ///        "name": "SSV Based App",
    ///        "website": "https://www.ssvlabs.io/",
    ///        "description": "SSV Based App Core",
    ///        "logo": "https://link-to-your-logo.png",
    ///        "social": "https://x.com/ssv_network"
    ///    }
    function registerBApp(
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external override onlyRole(MANAGER_ROLE) {
        IBasedAppManager(SSV_BASED_APPS_NETWORK).registerBApp(
            tokens,
            sharedRiskLevels,
            metadataURI
        );
    }

    /// @notice Updates the metadata URI of a BApp
    /// @param metadataURI new metadata URI
    function updateBAppMetadataURI(
        string calldata metadataURI
    ) external override onlyRole(MANAGER_ROLE) {
        IBasedAppManager(SSV_BASED_APPS_NETWORK).updateBAppMetadataURI(
            metadataURI
        );
    }

    /// @notice Checks if the contract supports the interface
    /// @param interfaceId interface id
    /// @return isSupported if the contract supports the interface
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        pure
        override(AccessControl, BasedAppCore)
        returns (bool isSupported)
    {
        return
            interfaceId == type(IBasedApp).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
