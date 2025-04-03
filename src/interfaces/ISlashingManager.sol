// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface ISlashingManager {
    event SlashingFundWithdrawn(address token, uint256 amount);
    event StrategySlashed(uint32 indexed strategyId, address indexed bApp, address token, uint256 amount, bytes data);

    // function getSlashableBalance(uint32 strategyId, address bApp, address token) internal view returns (uint256 slashableBalance);
    function slash(uint32 strategyId, address bApp, address token, uint256 amount, bytes calldata data) external;
    function withdrawETHSlashingFund(uint256 amount) external;
    function withdrawSlashingFund(address token, uint256 amount) external;
}
