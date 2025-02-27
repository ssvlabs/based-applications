// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IBasedApp} from "@ssv/src/interfaces/IBasedApp.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";
import {BasedAppCore} from "@ssv/src/middleware/modules/core/BasedAppCore.sol";

abstract contract AccessRolesBasedApp is AccessControlUpgradeable, BasedAppCore {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, msg.sender)) {
            revert UnauthorizedCaller();
        }
        _;
    }

    modifier onlyOwner() {
        if (!hasRole(OWNER_ROLE, msg.sender)) {
            revert UnauthorizedCaller();
        }
        _;
    }

    /// @notice constructor for the BasedAppCore contract, initializes the contract with the SSVBasedApps address and the owner and disables the initializers.
    /// @param _basedAppManager address of the SSVBasedApps contract
    constructor(address _basedAppManager) {
        BASED_APP_MANAGER = _basedAppManager;
        _disableInitializers();
    }

    function initialize(address owner) external initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OWNER_ROLE, owner);
    }

    function grantManagerRole(address manager) external onlyRole(OWNER_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    function revokeManagerRole(address manager) external onlyRole(OWNER_ROLE) {
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
    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI)
        external
        override
        onlyRole(MANAGER_ROLE)
    {
        IBasedAppManager(BASED_APP_MANAGER).registerBApp(tokens, sharedRiskLevels, metadataURI);
    }

    /// @notice Adds tokens to a BApp
    /// @param tokens array of token addresses
    /// @param sharedRiskLevels array of shared risk levels
    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external override onlyRole(MANAGER_ROLE) {
        IBasedAppManager(BASED_APP_MANAGER).addTokensToBApp(tokens, sharedRiskLevels);
    }

    /// @notice Updates the tokens of a BApp
    /// @param tokens array of token addresses
    /// @param sharedRiskLevels array of shared risk levels
    function updateBAppTokens(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external override onlyRole(MANAGER_ROLE) {
        IBasedAppManager(BASED_APP_MANAGER).updateBAppTokens(tokens, sharedRiskLevels);
    }

    /// @notice Updates the metadata URI of a BApp
    /// @param metadataURI new metadata URI
    function updateBAppMetadataURI(string calldata metadataURI) external override onlyRole(MANAGER_ROLE) {
        IBasedAppManager(BASED_APP_MANAGER).updateBAppMetadataURI(metadataURI);
    }

    /// @notice Allows a Strategy to Opt-in to a BApp, it can be called only by the SSV Based App Manager
    function optInToBApp(
        uint32, /*strategyId*/
        address[] calldata, /*tokens*/
        uint32[] calldata, /*obligationPercentages*/
        bytes calldata /*data*/
    ) external view override onlySSVBasedAppManager returns (bool success) {
        return true;
    }

    /// @notice Checks if the contract supports the interface
    /// @param interfaceId interface id
    /// @return true if the contract supports the interface
    function supportsInterface(bytes4 interfaceId) public pure override(AccessControlUpgradeable, BasedAppCore) returns (bool) {
        return interfaceId == type(IBasedApp).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
