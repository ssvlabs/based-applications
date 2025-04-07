// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.29;

import {ISSVDAO} from "@ssv/src/interfaces/ISSVDAO.sol";
import {SSVBasedAppsStorageProtocol} from "@ssv/src/libraries/SSVBasedAppsStorageProtocol.sol";

contract SSVDAO is ISSVDAO {
    function updateFeeTimelockPeriod(uint32 feeTimelockPeriod) external {
        SSVBasedAppsStorageProtocol.load().feeTimelockPeriod = feeTimelockPeriod;
        emit FeeTimelockPeriodUpdated(feeTimelockPeriod);
    }

    function updateFeeExpireTime(uint32 feeExpireTime) external {
        SSVBasedAppsStorageProtocol.load().feeExpireTime = feeExpireTime;
        emit FeeExpireTimeUpdated(feeExpireTime);
    }

    function updateWithdrawalTimelockPeriod(uint32 withdrawalTimelockPeriod) external {
        SSVBasedAppsStorageProtocol.load().withdrawalTimelockPeriod = withdrawalTimelockPeriod;
        emit WithdrawalTimelockPeriodUpdated(withdrawalTimelockPeriod);
    }

    function updateWithdrawalExpireTime(uint32 withdrawalExpireTime) external {
        SSVBasedAppsStorageProtocol.load().withdrawalExpireTime = withdrawalExpireTime;
        emit WithdrawalExpireTimeUpdated(withdrawalExpireTime);
    }

    function updateObligationTimelockPeriod(uint32 obligationTimelockPeriod) external {
        SSVBasedAppsStorageProtocol.load().obligationTimelockPeriod = obligationTimelockPeriod;
        emit ObligationTimelockPeriodUpdated(obligationTimelockPeriod);
    }

    function updateObligationExpireTime(uint32 obligationExpireTime) external {
        SSVBasedAppsStorageProtocol.load().obligationExpireTime = obligationExpireTime;
        emit ObligationExpireTimeUpdated(obligationExpireTime);
    }

    function updateMaxPercentage(uint32 maxPercentage) external {
        SSVBasedAppsStorageProtocol.load().maxPercentage = maxPercentage;
        emit MaxPercentageUpdated(maxPercentage);
    }

    function updateEthAddress(address ethAddress) external {
        SSVBasedAppsStorageProtocol.load().ethAddress = ethAddress;
        emit EthAddressUpdated(ethAddress);
    }

    function updateMaxShares(uint256 maxShares) external {
        SSVBasedAppsStorageProtocol.load().maxShares = maxShares;
        emit StrategyMaxSharesUpdated(maxShares);
    }

    function updateMaxFeeIncrement(uint32 maxFeeIncrement) external {
        SSVBasedAppsStorageProtocol.load().maxFeeIncrement = maxFeeIncrement;
        emit StrategyMaxFeeIncrementUpdated(maxFeeIncrement);
    }

    function updateFreezingTimelockPeriod(uint32 freezeTimelockPeriod) external {
        SSVBasedAppsStorageProtocol.load().freezeTimelockPeriod = freezeTimelockPeriod;
        emit FreezingTimelockPeriodUpdated(freezeTimelockPeriod);
    }
}
