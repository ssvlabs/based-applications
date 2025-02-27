// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IBasedApp} from "@ssv/src/interfaces/IBasedApp.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";
import {BasedAppCore} from "@ssv/src/middleware/modules/core/BasedAppCore.sol";

abstract contract OwnableUpgradeableBasedApp is OwnableUpgradeable, BasedAppCore {
    /// @notice constructor for the BasedAppCore contract, initializes the contract with the SSVBasedApps address and the owner and disables the initializers.
    /// @param _basedAppManager address of the SSVBasedApps contract
    /// @param owner address of the owner of the bApp
    constructor(address _basedAppManager, address owner) BasedAppCore(_basedAppManager) {
        _transferOwnership(owner);
        _disableInitializers();
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
        onlyOwner
    {
        IBasedAppManager(BASED_APP_MANAGER).registerBApp(tokens, sharedRiskLevels, metadataURI);
    }

    /// @notice Adds tokens to a BApp
    /// @param tokens array of token addresses
    /// @param sharedRiskLevels array of shared risk levels
    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external override onlyOwner {
        IBasedAppManager(BASED_APP_MANAGER).addTokensToBApp(tokens, sharedRiskLevels);
    }

    /// @notice Updates the tokens of a BApp
    /// @param tokens array of token addresses
    /// @param sharedRiskLevels array of shared risk levels
    function updateBAppTokens(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external override onlyOwner {
        IBasedAppManager(BASED_APP_MANAGER).updateBAppTokens(tokens, sharedRiskLevels);
    }

    /// @notice Updates the metadata URI of a BApp
    /// @param metadataURI new metadata URI
    function updateBAppMetadataURI(string calldata metadataURI) external override onlyOwner {
        IBasedAppManager(BASED_APP_MANAGER).updateBAppMetadataURI(metadataURI);
    }

    /// @notice Checks if the contract supports the interface
    /// @param interfaceId interface id
    /// @return true if the contract supports the interface
    function supportsInterface(bytes4 interfaceId) public pure override(BasedAppCore) returns (bool) {
        return interfaceId == type(IBasedApp).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}
