// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.29;

import { IProtocolManager } from "@ssv/src/core/interfaces/IProtocolManager.sol";
import { ProtocolStorageLib } from "@ssv/src/core/libraries/ProtocolStorageLib.sol";

contract ProtocolManager is IProtocolManager {
    function updateFeeTimelockPeriod(uint32 feeTimelockPeriod) external {
        ProtocolStorageLib.load().feeTimelockPeriod = feeTimelockPeriod;
        emit FeeTimelockPeriodUpdated(feeTimelockPeriod);
    }

    function updateFeeExpireTime(uint32 feeExpireTime) external {
        ProtocolStorageLib.load().feeExpireTime = feeExpireTime;
        emit FeeExpireTimeUpdated(feeExpireTime);
    }

    function updateWithdrawalTimelockPeriod(
        uint32 withdrawalTimelockPeriod
    ) external {
        ProtocolStorageLib
            .load()
            .withdrawalTimelockPeriod = withdrawalTimelockPeriod;
        emit WithdrawalTimelockPeriodUpdated(withdrawalTimelockPeriod);
    }

    function updateWithdrawalExpireTime(uint32 withdrawalExpireTime) external {
        ProtocolStorageLib.load().withdrawalExpireTime = withdrawalExpireTime;
        emit WithdrawalExpireTimeUpdated(withdrawalExpireTime);
    }

    function updateObligationTimelockPeriod(
        uint32 obligationTimelockPeriod
    ) external {
        ProtocolStorageLib
            .load()
            .obligationTimelockPeriod = obligationTimelockPeriod;
        emit ObligationTimelockPeriodUpdated(obligationTimelockPeriod);
    }

    function updateObligationExpireTime(uint32 obligationExpireTime) external {
        ProtocolStorageLib.load().obligationExpireTime = obligationExpireTime;
        emit ObligationExpireTimeUpdated(obligationExpireTime);
    }

    function updateMaxShares(uint256 maxShares) external {
        ProtocolStorageLib.load().maxShares = maxShares;
        emit StrategyMaxSharesUpdated(maxShares);
    }

    function updateMaxFeeIncrement(uint32 maxFeeIncrement) external {
        ProtocolStorageLib.load().maxFeeIncrement = maxFeeIncrement;
        emit StrategyMaxFeeIncrementUpdated(maxFeeIncrement);
    }
}
