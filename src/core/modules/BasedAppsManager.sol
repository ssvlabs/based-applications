// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { ICore } from "@ssv/src/core/interfaces/ICore.sol";
import {
    IBasedAppManager
} from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { CoreStorageLib } from "@ssv/src/core/libraries/CoreStorageLib.sol";
import {
    ProtocolStorageLib
} from "@ssv/src/core/libraries/ProtocolStorageLib.sol";
import { ValidationLib } from "@ssv/src/core/libraries/ValidationLib.sol";

contract BasedAppsManager is IBasedAppManager {
    /// @notice Allow the function to be called only by a registered bApp
    function _onlyRegisteredBApp(CoreStorageLib.Data storage s) private view {
        if (!s.registeredBApps[msg.sender]) {
            revert IBasedAppManager.BAppNotRegistered();
        }
    }

    /// @notice Registers a bApp.
    /// @param tokenConfigs The list of tokens configs the bApp accepts; can be empty.
    /// @param metadataURI The metadata URI of the bApp, which is a link (e.g., http://example.com)
    /// to a JSON file containing metadata such as the name, description, logo, etc.
    /// @dev Allows creating a bApp even with an empty token list.
    function registerBApp(
        ICore.TokenConfig[] calldata tokenConfigs,
        string calldata metadataURI
    ) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        if (s.registeredBApps[msg.sender]) {
            revert IBasedAppManager.BAppAlreadyRegistered();
        }

        s.registeredBApps[msg.sender] = true;

        _addNewTokens(msg.sender, tokenConfigs);

        emit BAppRegistered(msg.sender, tokenConfigs, metadataURI);
    }

    /// @notice Function to update the metadata URI of the Based Application
    /// @param metadataURI The new metadata URI
    function updateBAppMetadataURI(string calldata metadataURI) external {
        _onlyRegisteredBApp(CoreStorageLib.load());
        emit BAppMetadataURIUpdated(msg.sender, metadataURI);
    }

    function updateBAppsTokens(
        ICore.TokenConfig[] calldata tokenConfigs
    ) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        _onlyRegisteredBApp(s);

        uint32 requestTime = uint32(block.timestamp);

        address token;
        ICore.SharedRiskLevel storage tokenData;
        ProtocolStorageLib.Data storage sp = ProtocolStorageLib.load();

        for (uint256 i = 0; i < tokenConfigs.length; ) {
            token = tokenConfigs[i].token;
            tokenData = s.bAppTokens[msg.sender][token];
            // Update current value if the previous effect time has passed
            if (requestTime > tokenData.effectTime) {
                tokenData.currentValue = tokenData.pendingValue;
            }
            tokenData.pendingValue = tokenConfigs[i].sharedRiskLevel;
            tokenData.effectTime = requestTime + sp.tokenUpdateTimelockPeriod;
            tokenData.isSet = true;
            unchecked {
                i++;
            }
        }

        emit BAppTokensUpdated(msg.sender, tokenConfigs);
    }

    /// @notice Function to add tokens to a bApp
    /// @param bApp The address of the bApp
    /// @param tokenConfigs The list of tokens to add
    function _addNewTokens(
        address bApp,
        ICore.TokenConfig[] calldata tokenConfigs
    ) internal {
        uint256 length = tokenConfigs.length;
        address token;
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        for (uint256 i = 0; i < length; ) {
            token = tokenConfigs[i].token;
            ValidationLib.validateNonZeroAddress(token);
            if (s.bAppTokens[bApp][token].isSet) {
                revert IBasedAppManager.TokenAlreadyAddedToBApp(token);
            }
            ICore.SharedRiskLevel storage tokenData = s.bAppTokens[bApp][token];
            tokenData.currentValue = tokenConfigs[i].sharedRiskLevel;
            tokenData.isSet = true;
            unchecked {
                i++;
            }
        }
    }
}
