// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.29;

import { IProtocolManager } from "@ssv/src/core/interfaces/IProtocolManager.sol";
import { ProtocolStorageLib } from "@ssv/src/core/libraries/ProtocolStorageLib.sol";
import { ISSVBasedApps } from "@ssv/src/core/interfaces/ISSVBasedApps.sol";

contract ProtocolManager is IProtocolManager {
    uint32 private constant SLASHING_DISABLED = 1 << 0;
    uint32 private constant WITHDRAWALS_DISABLED = 1 << 1;

    function updateFeeTimelockPeriod(uint32 feeTimelockPeriod) external {
        if (feeTimelockPeriod < 1 days)
            revert ISSVBasedApps.InvalidFeeTimelockPeriod();
        ProtocolStorageLib.load().feeTimelockPeriod = feeTimelockPeriod;
        emit FeeTimelockPeriodUpdated(feeTimelockPeriod);
    }

    function updateFeeExpireTime(uint32 feeExpireTime) external {
        if (feeExpireTime < 1 hours)
            revert ISSVBasedApps.InvalidFeeExpireTime();
        ProtocolStorageLib.load().feeExpireTime = feeExpireTime;
        emit FeeExpireTimeUpdated(feeExpireTime);
    }

    function updateWithdrawalTimelockPeriod(
        uint32 withdrawalTimelockPeriod
    ) external {
        if (withdrawalTimelockPeriod < 1 days)
            revert ISSVBasedApps.InvalidWithdrawalTimelockPeriod();
        ProtocolStorageLib
            .load()
            .withdrawalTimelockPeriod = withdrawalTimelockPeriod;
        emit WithdrawalTimelockPeriodUpdated(withdrawalTimelockPeriod);
    }

    function updateWithdrawalExpireTime(uint32 withdrawalExpireTime) external {
        if (withdrawalExpireTime < 1 hours)
            revert ISSVBasedApps.InvalidWithdrawalExpireTime();
        ProtocolStorageLib.load().withdrawalExpireTime = withdrawalExpireTime;
        emit WithdrawalExpireTimeUpdated(withdrawalExpireTime);
    }

    function updateObligationTimelockPeriod(
        uint32 obligationTimelockPeriod
    ) external {
        if (obligationTimelockPeriod < 1 days)
            revert ISSVBasedApps.InvalidObligationTimelockPeriod();
        ProtocolStorageLib
            .load()
            .obligationTimelockPeriod = obligationTimelockPeriod;
        emit ObligationTimelockPeriodUpdated(obligationTimelockPeriod);
    }

    function updateObligationExpireTime(uint32 obligationExpireTime) external {
        if (obligationExpireTime < 1 hours)
            revert ISSVBasedApps.InvalidObligationExpireTime();
        ProtocolStorageLib.load().obligationExpireTime = obligationExpireTime;
        emit ObligationExpireTimeUpdated(obligationExpireTime);
    }

    function updateTokenUpdateTimelockPeriod(
        uint32 tokenUpdateTimelockPeriod
    ) external {
        if (tokenUpdateTimelockPeriod < 1 days)
            revert ISSVBasedApps.InvalidTokenUpdateTimelockPeriod();
        ProtocolStorageLib
            .load()
            .tokenUpdateTimelockPeriod = tokenUpdateTimelockPeriod;
        emit TokenUpdateTimelockPeriodUpdated(tokenUpdateTimelockPeriod);
    }

    function updateMaxShares(uint256 maxShares) external {
        if (maxShares < 1e38) revert ISSVBasedApps.InvalidMaxShares();
        ProtocolStorageLib.load().maxShares = maxShares;
        emit StrategyMaxSharesUpdated(maxShares);
    }

    function updateMaxFeeIncrement(uint32 maxFeeIncrement) external {
        if (maxFeeIncrement < 50)
            // 0.5% increment
            revert ISSVBasedApps.InvalidMaxFeeIncrement();
        ProtocolStorageLib.load().maxFeeIncrement = maxFeeIncrement;
        emit StrategyMaxFeeIncrementUpdated(maxFeeIncrement);
    }

    function updateDisabledFeatures(uint32 disabledFeatures) external {
        ProtocolStorageLib.load().disabledFeatures = disabledFeatures;
        emit DisabledFeaturesUpdated(disabledFeatures);
    }
}
