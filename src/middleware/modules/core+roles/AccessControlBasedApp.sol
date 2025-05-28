// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {
    AccessControl
} from "@openzeppelin/contracts/access/AccessControl.sol";

import { IBasedApp } from "@ssv/src/middleware/interfaces/IBasedApp.sol";
import {
    BasedAppCore
} from "@ssv/src/middleware/modules/core/BasedAppCore.sol";

import {
    IBasedAppManager
} from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";

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
    /// @param tokenConfigs array of token addresses and shared risk levels
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
        ICore.TokenConfig[] calldata tokenConfigs,
        string calldata metadataURI
    ) external override onlyRole(MANAGER_ROLE) {
        IBasedAppManager(SSV_BASED_APPS_NETWORK).registerBApp(
            tokenConfigs,
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
}
