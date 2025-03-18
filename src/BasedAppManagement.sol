// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {IStorage} from "@ssv/src/interfaces/IStorage.sol";
import {IBasedApp} from "@ssv/src/interfaces/IBasedApp.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";

contract BasedAppManagement is IBasedAppManager {
    uint32 public constant TOKEN_UPDATE_TIMELOCK_PERIOD = 7 days;
    uint32 public constant TOKEN_UPDATE_EXPIRE_TIME = 1 days;
    uint32 public constant TOKEN_REMOVAL_TIMELOCK_PERIOD = 7 days;
    uint32 public constant TOKEN_REMOVAL_EXPIRE_TIME = 1 days;
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
    /**
     * @notice Tracks the token update requests
     * @dev The bApp is identified with its address
     */
    mapping(address bApp => IStorage.TokenUpdateRequest) public bAppTokenUpdateRequests;
    /**
     * @notice Tracks the token removal requests
     * @dev The bApp is identified with its address
     */
    mapping(address bApp => IStorage.TokenRemovalRequest) public bAppTokenRemovalRequests;

    /// @notice Allow the function to be called only by a registered bApp
    modifier onlyRegisteredBApp() {
        if (!registeredBApps[msg.sender]) revert IStorage.BAppNotRegistered();
        _;
    }

    /// @notice Get the token update request for a bApp
    /// @param bApp The address of the bApp
    /// @return tokens The list of tokens
    /// @return sharedRiskLevels The shared risk levels of the tokens
    /// @return requestTime The time of the request
    function getTokenUpdateRequest(address bApp)
        public
        view
        returns (address[] memory tokens, uint32[] memory sharedRiskLevels, uint32 requestTime)
    {
        IStorage.TokenUpdateRequest storage request = bAppTokenUpdateRequests[bApp];
        tokens = request.tokens;
        sharedRiskLevels = request.sharedRiskLevels;
        requestTime = request.requestTime;
    }

    /// @notice Get the token removal request for a bApp
    /// @param bApp The address of the bApp
    /// @return tokens The list of tokens
    /// @return requestTime The time of the request
    function getTokenRemovalRequest(address bApp) public view returns (address[] memory tokens, uint32 requestTime) {
        IStorage.TokenRemovalRequest storage request = bAppTokenRemovalRequests[bApp];
        tokens = request.tokens;
        requestTime = request.requestTime;
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

        registeredBApps[msg.sender] = true;

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

    /// @notice Function to propose the update of tokens for a bApp
    /// @param tokens The list of tokens to update
    /// @param sharedRiskLevels The shared risk levels of the tokens
    function proposeBAppTokensUpdate(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external onlyRegisteredBApp {
        if (tokens.length == 0) revert IStorage.EmptyTokenList();
        _validateArraysLength(tokens, sharedRiskLevels);

        address token;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            _validateTokenInput(token);
            IStorage.SharedRiskLevel storage tokenData = bAppTokens[msg.sender][token];
            if (!tokenData.isSet) revert IStorage.TokenNoTSupportedByBApp(token);
            if (tokenData.value == sharedRiskLevels[i]) {
                revert IStorage.SharedRiskLevelAlreadySet();
            }
        }

        IStorage.TokenUpdateRequest storage request = bAppTokenUpdateRequests[msg.sender];
        request.tokens = tokens;
        request.sharedRiskLevels = sharedRiskLevels;
        request.requestTime = uint32(block.timestamp);
        emit BAppTokensUpdateProposed(msg.sender, tokens, sharedRiskLevels);
    }

    /// @notice Function to finalize the update of tokens for a bApp
    function finalizeBAppTokensUpdate() external onlyRegisteredBApp {
        IStorage.TokenUpdateRequest storage request = bAppTokenUpdateRequests[msg.sender];

        uint256 requestTime = request.requestTime;
        if (requestTime == 0) revert IStorage.NoPendingTokenUpdate();

        _checkTimelocks(requestTime, TOKEN_UPDATE_TIMELOCK_PERIOD, TOKEN_UPDATE_EXPIRE_TIME);

        address[] memory tokens = request.tokens;
        uint32[] memory sharedRiskLevels = request.sharedRiskLevels;

        for (uint256 i = 0; i < tokens.length; i++) {
            _setTokenRiskLevel(msg.sender, tokens[i], sharedRiskLevels[i]);
        }

        delete request.tokens;
        delete request.sharedRiskLevels;
        delete request.requestTime;

        emit BAppTokensUpdated(msg.sender, tokens, sharedRiskLevels);
    }

    /// @notice Function to propose the removal of tokens from a bApp
    /// @param tokens The list of tokens to remove
    function proposeBAppTokensRemoval(address[] calldata tokens) external onlyRegisteredBApp {
        if (tokens.length == 0) revert IStorage.EmptyTokenList();

        address token;
        for (uint256 i = 0; i < tokens.length; i++) {
            token = tokens[i];
            _validateTokenInput(token);
            if (!bAppTokens[msg.sender][token].isSet) revert IStorage.TokenNoTSupportedByBApp(token);
        }

        IStorage.TokenRemovalRequest storage request = bAppTokenRemovalRequests[msg.sender];
        request.tokens = tokens;
        request.requestTime = uint32(block.timestamp);

        emit BAppTokensRemovalProposed(msg.sender, tokens);
    }

    /// @notice Function to finalize the removal of tokens from a bApp
    function finalizeBAppTokensRemoval() external onlyRegisteredBApp {
        IStorage.TokenRemovalRequest storage request = bAppTokenRemovalRequests[msg.sender];

        uint256 requestTime = request.requestTime;
        if (requestTime == 0) revert IStorage.NoPendingTokenRemoval();

        _checkTimelocks(requestTime, TOKEN_REMOVAL_TIMELOCK_PERIOD, TOKEN_REMOVAL_EXPIRE_TIME);

        address[] memory tokens = request.tokens;
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; i++) {
            _removeToken(msg.sender, tokens[i]);
        }

        delete request.tokens;
        delete request.requestTime;

        emit BAppTokensRemoved(msg.sender, tokens);
    }

    // **********************
    // ** Section: Slashing **
    // **********************

    function slash(uint32[] calldata strategies) external onlyRegisteredBApp {
        // require(bApp)
        //todo pick the strategy
        // remove the relative amount, for now it will be a burn.
    }

    /// @notice Function to add tokens to a bApp
    /// @param bApp The address of the bApp
    /// @param tokens The list of tokens to add
    /// @param sharedRiskLevels The shared risk levels of the tokens
    function _addNewTokens(address bApp, address[] calldata tokens, uint32[] calldata sharedRiskLevels) internal {
        _validateArraysLength(tokens, sharedRiskLevels);
        uint256 length = tokens.length;
        address token;
        for (uint256 i = 0; i < length; i++) {
            token = tokens[i];
            _validateTokenInput(token);
            if (bAppTokens[bApp][token].isSet) revert IStorage.TokenAlreadyAddedToBApp(token);
            _setTokenRiskLevel(bApp, token, sharedRiskLevels[i]);
        }
    }

    /// @notice Check the timelocks
    /// @param requestTime The time of the request
    /// @param timelockPeriod The timelock period
    /// @param expireTime The expire time
    function _checkTimelocks(uint256 requestTime, uint256 timelockPeriod, uint256 expireTime) internal view {
        uint256 currentTime = uint32(block.timestamp);
        uint256 unlockTime = requestTime + timelockPeriod;
        if (currentTime < unlockTime) revert IStorage.TimelockNotElapsed();
        if (currentTime > unlockTime + expireTime) {
            revert IStorage.RequestTimeExpired();
        }
    }

    /// @notice Internal function to set the shared risk level for a token
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    /// @param sharedRiskLevel The shared risk level
    function _setTokenRiskLevel(address bApp, address token, uint32 sharedRiskLevel) internal {
        IStorage.SharedRiskLevel storage tokenData = bAppTokens[bApp][token];

        tokenData.value = sharedRiskLevel;
        tokenData.isSet = true;
    }

    /// @notice Internal function to set the shared risk level for a token
    /// @param bApp The address of the bApp
    /// @param token The address of the token
    function _removeToken(address bApp, address token) internal {
        delete bAppTokens[bApp][token];
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

    /// @notice Function to check if an address uses the correct bApp interface
    /// @param bApp The address of the bApp
    /// @return isBApp True if the address uses the correct bApp interface
    function _isBApp(address bApp) public view returns (bool isBApp) {
        return ERC165Checker.supportsInterface(bApp, type(IBasedApp).interfaceId);
    }
}
