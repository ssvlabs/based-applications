// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { BasedAppCore } from "@ssv/src/middleware/modules/core/BasedAppCore.sol";

import { IBasedAppManager } from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";

abstract contract OwnableBasedApp is Ownable, BasedAppCore {
    constructor(
        address _basedAppManager,
        address _initOwner
    ) BasedAppCore(_basedAppManager) Ownable(_initOwner) {}

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
    ) external override onlyOwner {
        IBasedAppManager(SSV_BASED_APPS_NETWORK).registerBApp(
            tokenConfigs,
            metadataURI
        );
    }

    /// @notice Updates the metadata URI of a BApp
    /// @param metadataURI new metadata URI
    function updateBAppMetadataURI(
        string calldata metadataURI
    ) external override onlyOwner {
        IBasedAppManager(SSV_BASED_APPS_NETWORK).updateBAppMetadataURI(
            metadataURI
        );
    }
}
