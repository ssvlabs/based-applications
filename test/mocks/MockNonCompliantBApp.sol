// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IBasedAppManager {
    function registerBApp(
        address sender,
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external;
}

contract NonCompliantBApp {
    event OptInToBApp(uint32 indexed strategyId, address[] tokens, uint32[] obligationPercentages, bytes data);

    uint32 public counter;
    address public immutable BASED_APP_MANAGER;

    constructor(address _basedAppManager) {
        BASED_APP_MANAGER = _basedAppManager;
        counter = 0;
    }

    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI)
        external
        virtual
    {
        IBasedAppManager(BASED_APP_MANAGER).registerBApp(msg.sender, tokens, sharedRiskLevels, metadataURI);
    }

    function optInToBApp(
        uint32 strategyId,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external returns (bool success) {
        counter++;
        emit OptInToBApp(strategyId, tokens, obligationPercentages, data);
        if (counter % 2 == 0) return false;
        else return true;
    }
}
