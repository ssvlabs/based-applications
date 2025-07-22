// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { IERC20, BasedAppMock } from "@ssv/test/helpers/Setup.t.sol";
import { StrategyManagerTest } from "@ssv/test/modules/StrategyManager.t.sol";
import {
    IStrategyManager
} from "@ssv/src/core/interfaces/IStrategyManager.sol";
import {
    IBasedAppManager
} from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { UtilsTest } from "@ssv/test/helpers/Utils.t.sol";
import { ValidationLib } from "@ssv/src/core/libraries/ValidationLib.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";
import { IRebase } from "@ssv/test/mocks/MockERC20.sol";

contract RebasingTokensTest is StrategyManagerTest {
    function testBalanceAfterRebase() public {
        uint256 depositAmount = 10000;
        uint256 rebaseAmount = 10000;
        testCreateStrategyAndSingleDeposit(depositAmount);
        (address strategyAddress, , ) = proxiedManager.strategies(STRATEGY1);
        IRebase(address(erc20mock)).rebase(strategyAddress, 10000);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            depositAmount,
            depositAmount + rebaseAmount
        );
        checkAccountShares(STRATEGY1, USER1, address(erc20mock), depositAmount);
    }

    function testWithdrawalAfterRebasingEvent() public {
        (
            uint256 withdrawalAmount,
            IERC20 token,
            uint256 currentBalance
        ) = testProposeWithdrawalFromStrategy();
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        uint256 oldUserBalance = token.balanceOf(USER1);

        (address strategyAddress, , ) = proxiedManager.strategies(STRATEGY1);
        // 120.000
        // withdraw 1000, withdraw 1000 shares
        // rebase to 220000, 1000 shares now are worth 1833 tokens
        uint256 oldStrategyBalance = token.balanceOf(strategyAddress);

        IRebase(address(token)).rebase(strategyAddress, 100000);
        uint256 newStrategyBalance = token.balanceOf(strategyAddress);
        uint256 newWithdrawalAmount = (newStrategyBalance * withdrawalAmount) /
            oldStrategyBalance;

        vm.prank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyWithdrawal(
            STRATEGY1,
            USER1,
            address(token),
            newWithdrawalAmount,
            false
        );
        proxiedManager.finalizeWithdrawal(STRATEGY1, token);
        uint256 newShareBalance = currentBalance - withdrawalAmount;
        uint256 newBalance = newStrategyBalance - newWithdrawalAmount;
        uint256 newUserBalance = token.balanceOf(USER1);

        assertNotEq(newUserBalance, oldUserBalance);

        assertEq(newUserBalance, oldUserBalance + newWithdrawalAmount);

        checkAccountShares(STRATEGY1, USER1, address(token), newShareBalance);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(token),
            newShareBalance,
            newBalance
        );
        checkProposedWithdrawal(STRATEGY1, USER1, address(token), 0, 0);
    }
}
