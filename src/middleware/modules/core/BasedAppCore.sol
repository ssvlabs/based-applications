// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedApp} from "@ssv/src/interfaces/IBasedApp.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

abstract contract BasedAppCore is IBasedApp, OwnableUpgradeable, IERC165 {
    /// @notice Address of the SSV Based App Manager contract
    address public immutable BASED_APP_MANAGER;

    error UnauthorizedCaller();

    /// @dev Allows only the SSV Based App Manager to call the function
    modifier onlySSVBasedAppManager() {
        if (msg.sender != address(BASED_APP_MANAGER)) {
            revert UnauthorizedCaller();
        }
        _;
    }

    /// @notice constructor for the BasedAppCore contract, initializes the contract with the BasedAppManager address and the owner and disables the initializers.
    /// @param _basedAppManager address of the BasedAppManager contract
    /// @param owner address of the owner of the contract
    constructor(address _basedAppManager, address owner) {
        BASED_APP_MANAGER = _basedAppManager;
        _transferOwnership(owner);
        _disableInitializers();
    }

    /// @notice Registers a BApp calling the SSV BasedAppManager
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
    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI)
        external
        virtual
        onlyOwner
    {
        IBasedAppManager(BASED_APP_MANAGER).registerBApp(msg.sender, tokens, sharedRiskLevels, metadataURI);
    }

    /// @notice Allows a Strategy to Opt-in to a BApp, it can be called only by the SSV Based App Manager
    /// @param strategyId id of the strategy
    /// @param data data to be passed to the BApp
    function optInToBApp(
        uint32 strategyId,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external virtual onlySSVBasedAppManager returns (bool success) {
        /// --- PRE-CONDITIONS (HOOK) ---
        _preOptIn(strategyId, tokens, obligationPercentages, data);
        /// --- CORE LOGIC (TO BE IMPLEMENTED) ---
        success = true;
        /// --- POST-CONDITIONS (HOOK) ---
        _postOptIn(strategyId, tokens, obligationPercentages, data, success);
        return success;
    }

    /// @notice Checks if the contract supports the interface
    /// @param interfaceId interface id
    /// @return true if the contract supports the interface
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(IBasedApp).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @notice Hook function for pre-processing before opting into a BApp.
    /// @dev Can be overridden by child contracts to add custom pre-processing.
    /// @param strategyId The ID of the strategy.
    /// @param tokens Array of token addresses.
    /// @param obligationPercentages Corresponding percentage obligations.
    /// @param data Additional data payload.
    function _preOptIn(uint32 strategyId, address[] calldata tokens, uint32[] calldata obligationPercentages, bytes calldata data)
        internal
        virtual
    {}

    /// @notice Hook function for post-processing after opting into a BApp.
    /// @dev Can be overridden by child contracts to add custom post-processing.
    /// @param strategyId The ID of the strategy.
    /// @param tokens Array of token addresses.
    /// @param obligationPercentages Corresponding percentage obligations.
    /// @param data Additional data payload.
    /// @param success Boolean indicating success status.
    function _postOptIn(
        uint32 strategyId,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data,
        bool success
    ) internal virtual {}
}
