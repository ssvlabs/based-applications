// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { ICore } from "@ssv/src/core/interfaces/ICore.sol";

interface IBasedAppManager {
    event BAppMetadataURIUpdated(address indexed bApp, string metadataURI);
    event BAppRegistered(
        address indexed bApp,
        address[] tokens,
        uint32[] sharedRiskLevel,
        string metadataURI
    );
    event BAppTokensUpdated(
        address indexed bApp,
        ICore.TokenConfig[] tokenConfigs
    );

    function registerBApp(
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external;
    function updateBAppMetadataURI(string calldata metadataURI) external;
    function updateBAppsTokens(
        ICore.TokenConfig[] calldata tokenConfigs
    ) external;

    error BAppAlreadyRegistered();
    error BAppDoesNotSupportInterface();
    error BAppNotRegistered();
    error TokenAlreadyAddedToBApp(address token);
    error ZeroAddressNotAllowed();
}
