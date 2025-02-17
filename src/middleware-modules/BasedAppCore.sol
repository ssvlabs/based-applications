// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedApp} from "../interfaces/IBasedApp.sol";
import {IBasedAppManager} from "../interfaces/IBasedAppManager.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract BasedAppCore is IBasedApp, OwnableUpgradeable {
    address public immutable BASED_APP_MANAGER;

    error UnauthorizedCaller();

    modifier onlyManager() {
        if (msg.sender != address(BASED_APP_MANAGER)) {
            revert UnauthorizedCaller();
        }
        _;
    }

    constructor(address _basedAppManager, address owner) {
        BASED_APP_MANAGER = _basedAppManager;
        _transferOwnership(owner);
        _disableInitializers();
    }

    function updateBAppMetadataURI(string calldata metadataURI) external virtual onlyOwner {
        IBasedAppManager(BASED_APP_MANAGER).updateBAppMetadataURI(address(this), metadataURI);
    }

    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external virtual onlyOwner {
        IBasedAppManager(BASED_APP_MANAGER).addTokensToBApp(address(this), tokens, sharedRiskLevels);
    }

    function updateBAppTokens(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external virtual onlyOwner {
        IBasedAppManager(BASED_APP_MANAGER).updateBAppTokens(address(this), tokens, sharedRiskLevels);
    }

    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI)
        external
        virtual
        onlyOwner
    {
        IBasedAppManager(BASED_APP_MANAGER).registerBApp(msg.sender, tokens, sharedRiskLevels, metadataURI);
    }

    function optInToBApp(uint32 strategyId, bytes calldata data) external virtual onlyManager {}
}
