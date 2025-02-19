// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedApp} from "../interfaces/IBasedApp.sol";
import {IBasedAppManager} from "../interfaces/IBasedAppManager.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract BasedAppCore is IBasedApp, OwnableUpgradeable {
    /// @notice Address of the SSV Based App Manager contract
    address public immutable BASED_APP_MANAGER;

    error UnauthorizedCaller();

    /// @dev Allows only the SSV Based App Manager to call the function
    modifier onlyManager() {
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

    /// @notice Allows a BApp to opt-in to a strategy
    function optInToBApp(uint32 strategyId, bytes calldata data) external virtual onlyManager returns (bool success) {
        return true;
    }
}
