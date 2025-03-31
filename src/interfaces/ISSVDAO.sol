// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface ISSVDAO {
    event FeeTimelockPeriodUpdated(uint32 feeTimelockPeriod);
    event FeeExpireTimeUpdated(uint32 feeExpireTime);
    event WithdrawalTimelockPeriodUpdated(uint32 withdrawalTimelockPeriod); // Note: might be a mistake, see below
    event WithdrawalExpireTimeUpdated(uint32 withdrawalExpireTime);
    event ObligationTimelockPeriodUpdated(uint32 obligationTimelockPeriod);
    event ObligationExpireTimeUpdated(uint32 obligationExpireTime);
    event MaxPercentageUpdated(uint32 maxPercentage);
    event EthAddressUpdated(address ethAddress);
    event StrategyMaxSharesUpdated(uint256 maxShares);
    event StrategyMaxFeeIncrementUpdated(uint32 maxFeeIncrement);

    function updateFeeTimelockPeriod(uint32 value) external;
    function updateFeeExpireTime(uint32 value) external;
    function updateWithdrawalTimelockPeriod(uint32 value) external;
    function updateWithdrawalExpireTime(uint32 value) external;
    function updateObligationTimelockPeriod(uint32 value) external;
    function updateObligationExpireTime(uint32 value) external;
    function updateMaxPercentage(uint32 value) external;
    function updateEthAddress(address value) external;
    function updateMaxShares(uint256 value) external;
    function updateMaxFeeIncrement(uint32 value) external;
}
