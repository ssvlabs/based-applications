// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IStorage} from "@ssv/src/interfaces/IStorage.sol";

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IBasedApp} from "@ssv/src/interfaces/IBasedApp.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";

contract BasedAppManagement is IBasedAppManager {
    /**
     * @notice Tracks the owners of the bApps
     * @dev The bApp is identified with its address
     */
    mapping(address bApp => bool isRegistered) public registeredBApps;
    /**
     * @notice Tracks the tokens supported by the bApps
     * @dev The bApp is identified with its address
     */
    mapping(address bApp => mapping(address token => IStorage.SharedRiskLevel)) public bAppTokens;

    /// @notice Allow the function to be called only by a registered bApp
    modifier onlyRegisteredBApp() {
        if (!registeredBApps[msg.sender]) revert IStorage.BAppNotRegistered();
        _;
    }

    // ********************
    // ** Section: bApps **
    // ********************

    /// @notice Registers a bApp.
    /// @param tokens The list of tokens the bApp accepts; can be empty.
    /// @param sharedRiskLevels The shared risk level of the bApp.
    /// @param metadataURI The metadata URI of the bApp, which is a link (e.g., http://example.com)
    /// to a JSON file containing metadata such as the name, description, logo, etc.
    /// @dev Allows creating a bApp even with an empty token list.
    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external {
        if (registeredBApps[msg.sender]) revert IStorage.BAppAlreadyRegistered();
        else registeredBApps[msg.sender] = true;

        if (_isContract(msg.sender) && !_isBApp(msg.sender)) {
            revert IStorage.BAppDoesNotSupportInterface();
        }

        _addNewTokens(msg.sender, tokens, sharedRiskLevels);

        emit BAppRegistered(msg.sender, tokens, sharedRiskLevels, metadataURI);
    }

    /// @notice Function to update the metadata URI of the Based Application
    /// @param metadataURI The new metadata URI
    function updateBAppMetadataURI(string calldata metadataURI) external onlyRegisteredBApp {
        emit BAppMetadataURIUpdated(msg.sender, metadataURI);
    }

    // this function could be put somewhere else
    /// @notice Function to add tokens to an existing bApp
    /// @param tokens The list of tokens to add
    /// @param sharedRiskLevels The shared risk levels of the tokens
    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external onlyRegisteredBApp {
        if (tokens.length == 0) revert IStorage.EmptyTokenList();
        _addNewTokens(msg.sender, tokens, sharedRiskLevels);
        emit BAppTokensCreated(msg.sender, tokens, sharedRiskLevels);
    }

    /// @notice Function to update the shared risk levels of the tokens for a bApp
    /// @param tokens The list of tokens to update
    /// @param sharedRiskLevels The shared risk levels of the tokens
    function updateBAppTokens(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external onlyRegisteredBApp {
        if (tokens.length == 0) revert IStorage.EmptyTokenList();
        _validateArraysLength(tokens, sharedRiskLevels);
        for (uint8 i = 0; i < tokens.length; i++) {
            _validateTokenInput(tokens[i]);
            if (!bAppTokens[msg.sender][tokens[i]].isSet) revert IStorage.TokenNoTSupportedByBApp(tokens[i]);
            if (bAppTokens[msg.sender][tokens[i]].value == sharedRiskLevels[i]) {
                revert IStorage.SharedRiskLevelAlreadySet();
            }
            _setTokenRiskLevel(msg.sender, tokens[i], sharedRiskLevels[i]);
        }
        emit BAppTokensUpdated(msg.sender, tokens, sharedRiskLevels);
    }

    /// @notice Function to add tokens to a bApp
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to add
    /// @param sharedRiskLevels The shared risk levels of the tokens
    function _addNewTokens(address bApp, address[] calldata tokens, uint32[] calldata sharedRiskLevels) internal {
        _validateArraysLength(tokens, sharedRiskLevels);
        for (uint8 i = 0; i < tokens.length; i++) {
            _validateTokenInput(tokens[i]);
            if (bAppTokens[bApp][tokens[i]].isSet) revert IStorage.TokenAlreadyAddedToBApp(tokens[i]);
            _setTokenRiskLevel(bApp, tokens[i], sharedRiskLevels[i]);
        }
    }

    /// @notice Check the timelocks
    /// @param requestTime The time of the request
    /// @param timelockPeriod The timelock period
    /// @param expireTime The expire time
    function _checkTimelocks(uint256 requestTime, uint256 timelockPeriod, uint256 expireTime) internal view {
        if (uint32(block.timestamp) < requestTime + timelockPeriod) revert IStorage.TimelockNotElapsed();
        if (uint32(block.timestamp) > requestTime + timelockPeriod + expireTime) {
            revert IStorage.RequestTimeExpired();
        }
    }

    /// @notice Internal function to set the shared risk level for a token
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param sharedRiskLevel The shared risk level
    function _setTokenRiskLevel(address bApp, address token, uint32 sharedRiskLevel) internal {
        bAppTokens[bApp][token].value = sharedRiskLevel;
        bAppTokens[bApp][token].isSet = true;
    }

    /// @notice Validate the length of two arrays
    /// @param tokens The list of tokens
    /// @param uint32Array The list of uint32 values
    function _validateArraysLength(address[] calldata tokens, uint32[] calldata uint32Array) internal pure {
        if (tokens.length != uint32Array.length) revert IStorage.LengthsNotMatching();
    }

    /// @notice Internal function to validate the token and shared risk level
    /// @param token The token address to be validated
    function _validateTokenInput(address token) internal pure {
        if (token == address(0)) revert IStorage.ZeroAddressNotAllowed();
    }

    /// @notice Function to check if an address is a contract
    /// @param account The address to check
    /// @return isContract True if the address is a contract
    function _isContract(address account) internal view returns (bool isContract) {
        uint32 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @notice Function to check if an address uses the correct bApp interface
    /// @param bApp The address of the bApp
    /// @return isBApp True if the address uses the correct bApp interface
    function _isBApp(address bApp) public view returns (bool isBApp) {
        return ERC165Checker.supportsInterface(bApp, type(IBasedApp).interfaceId);
    }
}
