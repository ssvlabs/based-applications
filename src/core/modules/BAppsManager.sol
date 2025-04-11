// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {ICore} from "@ssv/src/interfaces/ICore.sol";
import {IBAppsManager} from "@ssv/src/interfaces/IBAppsManager.sol";
import {CoreStorageLib} from "@ssv/src/libraries/CoreStorageLib.sol";
import {ValidationsLib, MAX_PERCENTAGE} from "@ssv/src/libraries/ValidationsLib.sol";

contract BAppsManager is IBAppsManager {
    /// @notice Registers a bApp.
    /// @param tokens The list of tokens the bApp accepts; can be empty.
    /// @param sharedRiskLevels The shared risk level of the bApp.
    /// @param metadataURI The metadata URI of the bApp, which is a link (e.g., http://example.com)
    /// to a JSON file containing metadata such as the name, description, logo, etc.
    /// @dev Allows creating a bApp even with an empty token list.
    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();

        if (s.registeredBApps[msg.sender]) revert BAppAlreadyRegistered();

        s.registeredBApps[msg.sender] = true;

        _addNewTokens(msg.sender, tokens, sharedRiskLevels);

        emit BAppRegistered(msg.sender, tokens, sharedRiskLevels, metadataURI);
    }

    /// @notice Function to update the metadata URI of the Based Application
    /// @param metadataURI The new metadata URI
    function updateBAppMetadataURI(string calldata metadataURI) external {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        if (!s.registeredBApps[msg.sender]) revert BAppNotRegistered();

        emit BAppMetadataURIUpdated(msg.sender, metadataURI);
    }

    /// @notice Function to add tokens to a bApp
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to add
    /// @param sharedRiskLevels The shared risk levels of the tokens
    function _addNewTokens(address bApp, address[] calldata tokens, uint32[] calldata sharedRiskLevels) internal {
        ValidationsLib.validateArrayLengths(tokens, sharedRiskLevels);

        uint256 length = tokens.length;
        address token;
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        for (uint256 i = 0; i < length;) {
            token = tokens[i];
            ValidationsLib.validateNonZeroAddress(token);
            if (s.bAppTokens[bApp][token].isSet) revert TokenAlreadyAddedToBApp(token);
            _setTokenRiskLevel(bApp, token, sharedRiskLevels[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Internal function to set the shared risk level for a token
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param sharedRiskLevel The shared risk level
    function _setTokenRiskLevel(address bApp, address token, uint32 sharedRiskLevel) internal {
        CoreStorageLib.Data storage s = CoreStorageLib.load();
        ICore.SharedRiskLevel storage tokenData = s.bAppTokens[bApp][token];

        tokenData.value = sharedRiskLevel;
        tokenData.isSet = true;
    }
}
