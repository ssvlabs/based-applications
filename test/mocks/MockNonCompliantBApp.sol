// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface ICustomBasedAppManager {
    function registerBApp(
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external;
    function slash(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 percentage,
        bytes calldata data
    ) external;
}

contract NonCompliantBApp {
    event OptInToBApp(
        uint32 indexed strategyId,
        address[] tokens,
        uint32[] obligationPercentages,
        bytes data
    );

    uint32 public counter;
    address public immutable BASED_APP_MANAGER;

    constructor(address _basedAppManager) {
        BASED_APP_MANAGER = _basedAppManager;
        counter = 0;
    }

    function registerBApp(
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external {
        ICustomBasedAppManager(BASED_APP_MANAGER).registerBApp(
            tokens,
            sharedRiskLevels,
            metadataURI
        );
    }

    function slash(
        uint32 strategyId,
        address token,
        uint32 percentage
    ) external {
        ICustomBasedAppManager(BASED_APP_MANAGER).slash(
            strategyId,
            address(this),
            token,
            percentage,
            ""
        );
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

    receive() external payable {
        // Accept plain Ether transfers
    }
}
