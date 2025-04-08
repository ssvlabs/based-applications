// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface ISlashingManager {
    event SlashingFundWithdrawn(address token, uint256 amount);
    event StrategyFrozen(uint32 indexed strategyId, address indexed bApp, bytes data);
    event StrategySlashed(uint32 indexed strategyId, address indexed bApp, address token, uint256 amount, bytes data);

    function slash(uint32 strategyId, address bApp, address token, uint256 amount, bytes calldata data) external;
    function withdrawETHSlashingFund(uint256 amount) external;
    function withdrawSlashingFund(address token, uint256 amount) external;
}
