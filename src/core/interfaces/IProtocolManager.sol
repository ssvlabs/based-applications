// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface IProtocolManager {
    event FeeExpireTimeUpdated(uint32 feeExpireTime);
    event FeeTimelockPeriodUpdated(uint32 feeTimelockPeriod);
    event ObligationExpireTimeUpdated(uint32 obligationExpireTime);
    event ObligationTimelockPeriodUpdated(uint32 obligationTimelockPeriod);
    event TokenUpdateTimelockPeriodUpdated(uint32 tokenUpdateTimelockPeriod);
    event StrategyMaxFeeIncrementUpdated(uint32 maxFeeIncrement);
    event StrategyMaxSharesUpdated(uint256 maxShares);
    event WithdrawalExpireTimeUpdated(uint32 withdrawalExpireTime);
    event WithdrawalTimelockPeriodUpdated(uint32 withdrawalTimelockPeriod);
    event DisabledFeaturesUpdated(uint32 disabledFeatures);

    function updateFeeExpireTime(uint32 value) external;
    function updateFeeTimelockPeriod(uint32 value) external;
    function updateMaxFeeIncrement(uint32 value) external;
    function updateMaxShares(uint256 value) external;
    function updateObligationExpireTime(uint32 value) external;
    function updateObligationTimelockPeriod(uint32 value) external;
    function updateTokenUpdateTimelockPeriod(uint32 value) external;
    function updateWithdrawalExpireTime(uint32 value) external;
    function updateWithdrawalTimelockPeriod(uint32 value) external;
}
