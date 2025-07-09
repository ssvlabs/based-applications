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

    function testWithdrawalAfterRebase() public {}
}
