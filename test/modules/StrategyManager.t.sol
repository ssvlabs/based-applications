// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { IERC20, BasedAppMock } from "@ssv/test/helpers/Setup.t.sol";
import { BasedAppsManagerTest } from "@ssv/test/modules/BasedAppsManager.t.sol";
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
import { CoreStorageLib } from "@ssv/src/core/libraries/CoreStorageLib.sol";

contract StrategyManagerTest is UtilsTest, BasedAppsManagerTest {
    function updateObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) internal {
        proxiedManager.proposeUpdateObligation(
            strategyId,
            bApp,
            token,
            obligationPercentage
        );
        vm.warp(block.timestamp + proxiedManager.obligationTimelockPeriod());
        proxiedManager.finalizeUpdateObligation(strategyId, bApp, token);
    }

    function testCreateStrategies() public {
        vm.startPrank(USER1);

        erc20mock.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.approve(
            address(proxiedManager),
            INITIAL_USER1_BALANCE_ERC20
        );

        vm.expectEmit(true, false, true, true);
        emit IStrategyManager.StrategyCreated(
            STRATEGY1,
            address(0),
            USER1,
            STRATEGY1_INITIAL_FEE,
            ""
        );
        uint32 strategyId1 = proxiedManager.createStrategy(
            STRATEGY1_INITIAL_FEE,
            ""
        );
        uint32[] memory strategies = proxiedManager.ownedStrategies(USER1);
        assertEq(
            strategies.length,
            1,
            "Should have created 1 strategy for USER1"
        );
        assertEq(
            strategies[0],
            strategyId1,
            "Should have the correct ID for Strategy 1"
        );
        proxiedManager.createStrategy(STRATEGY2_INITIAL_FEE, "");
        proxiedManager.createStrategy(STRATEGY3_INITIAL_FEE, "");
        strategies = proxiedManager.ownedStrategies(USER1);
        assertEq(strategies.length, 3, "Should have created the strategy");
        assertEq(
            strategies[0],
            strategyId1,
            "Should have the correct ID for Strategy 1"
        );
        assertEq(
            strategies[1],
            STRATEGY2,
            "Should have the correct ID for Strategy 2"
        );
        assertEq(
            strategies[2],
            STRATEGY3,
            "Should have the correct ID for Strategy 3"
        );
        assertEq(
            strategyId1,
            STRATEGY1,
            "Should have the correct ID for Strategy 1"
        );
        (, address owner, uint32 delegationFeeOnRewards) = proxiedManager
            .strategies(strategyId1);
        assertEq(owner, USER1, "Should have the correct strategy owner");
        assertEq(
            delegationFeeOnRewards,
            STRATEGY1_INITIAL_FEE,
            "Should have the correct strategy fee"
        );
        vm.stopPrank();

        vm.startPrank(USER2);

        uint32 strategyId4 = proxiedManager.createStrategy(
            STRATEGY4_INITIAL_FEE,
            ""
        );
        strategies = proxiedManager.ownedStrategies(USER2);
        assertEq(
            strategies.length,
            1,
            "Should have created one strategy for USER2"
        );
        assertEq(
            strategies[0],
            strategyId4,
            "Should have the correct ID for Strategy 4"
        );
        assertEq(
            strategyId4,
            STRATEGY4,
            "Should have the correct ID for Strategy 3"
        );
        (, owner, delegationFeeOnRewards) = proxiedManager.strategies(
            strategyId4
        );
        assertEq(owner, USER2, "Should have the correct strategy owner");
        assertEq(
            delegationFeeOnRewards,
            STRATEGY4_INITIAL_FEE,
            "Should have the correct strategy fee"
        );

        checkAccountShares(STRATEGY1, USER1, address(erc20mock), 0);
        checkAccountShares(STRATEGY2, USER1, address(erc20mock), 0);
        checkAccountShares(STRATEGY3, USER1, address(erc20mock), 0);
        checkAccountShares(STRATEGY4, USER2, address(erc20mock), 0);

        checkTotalSharesAndTotalBalance(STRATEGY1, address(erc20mock), 0, 0);
        checkTotalSharesAndTotalBalance(STRATEGY2, address(erc20mock), 0, 0);
        checkTotalSharesAndTotalBalance(STRATEGY3, address(erc20mock), 0, 0);
        checkTotalSharesAndTotalBalance(STRATEGY4, address(erc20mock), 0, 0);

        vm.stopPrank();
    }

    function testCreateStrategyWithZeroFee() public {
        vm.startPrank(USER1);
        vm.expectEmit(true, false, true, true);
        emit IStrategyManager.StrategyCreated(
            STRATEGY1,
            address(0), // Placeholder, cause the address is not possible to predict
            USER1,
            0,
            ""
        );
        uint32 strategyId1 = proxiedManager.createStrategy(0, "");
        (, , uint32 delegationFeeOnRewards) = proxiedManager.strategies(
            strategyId1
        );
        assertEq(
            delegationFeeOnRewards,
            0,
            "Should have the correct strategy fee"
        );
        vm.stopPrank();
    }

    function testRevertCreateStrategyWithTooHighFee() public {
        vm.startPrank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidStrategyFee.selector)
        );
        proxiedManager.createStrategy(10_001, "");
        vm.stopPrank();
    }

    function testCreateStrategyAndSingleDepositA(
        uint256 amount,
        uint256 user2Amount,
        uint256 attackerAmount
    ) public {
        vm.assume(
            amount > 0 &&
                amount < INITIAL_USER1_BALANCE_ERC20 &&
                user2Amount > 0 &&
                user2Amount < INITIAL_USER2_BALANCE_ERC20 &&
                attackerAmount > 0 &&
                attackerAmount < INITIAL_ATTACKER_BALANCE_ERC20
        );
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        testCreateStrategies();
        vm.prank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyDeposit(
            STRATEGY1,
            USER1,
            address(erc20mock),
            amount
        );
        proxiedManager.depositERC20(STRATEGY1, erc20mock, amount);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            amount,
            amount
        );
        checkAccountShares(STRATEGY1, USER1, address(erc20mock), amount);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, user2Amount);
        uint256 newTotal = amount + user2Amount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            newTotal,
            newTotal
        );
        checkAccountShares(STRATEGY1, USER2, address(erc20mock), user2Amount);
        vm.prank(ATTACKER);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, attackerAmount);
        newTotal = amount + user2Amount + attackerAmount;
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            newTotal,
            newTotal
        );
        checkAccountShares(
            STRATEGY1,
            ATTACKER,
            address(erc20mock),
            attackerAmount
        );
        vm.stopPrank();
    }

    function testCreateStrategyAndSingleDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        testCreateStrategies();
        vm.startPrank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyDeposit(
            STRATEGY1,
            USER1,
            address(erc20mock),
            amount
        );
        proxiedManager.depositERC20(STRATEGY1, erc20mock, amount);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            amount,
            amount
        );
        checkAccountShares(STRATEGY1, USER1, address(erc20mock), amount);
        vm.stopPrank();
    }

    function testRevertInvalidDepositWithZeroAmount() public {
        testCreateStrategyAndSingleDeposit(1);
        vm.startPrank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector)
        );
        proxiedManager.depositERC20(STRATEGY1, erc20mock, 0);
        vm.stopPrank();
    }

    function testCreateStrategyAndMultipleDeposits(
        uint256 deposit1S1,
        uint256 deposit2S1,
        uint256 deposit1S2
    ) public {
        vm.assume(deposit1S1 > 0 && deposit1S1 < INITIAL_USER1_BALANCE_ERC20);
        vm.assume(deposit2S1 > 0 && deposit2S1 <= INITIAL_USER1_BALANCE_ERC20);
        vm.assume(
            deposit1S2 > 0 &&
                deposit1S2 < INITIAL_USER1_BALANCE_ERC20 &&
                deposit1S2 <= INITIAL_USER1_BALANCE_ERC20 - deposit1S1
        );
        testCreateStrategies();
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, deposit1S1);
        checkAccountShares(STRATEGY1, USER1, address(erc20mock), deposit1S1);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            deposit1S1,
            deposit1S1
        );
        proxiedManager.depositERC20(STRATEGY2, erc20mock, deposit1S2);
        checkAccountShares(STRATEGY2, USER1, address(erc20mock), deposit1S2);
        checkTotalSharesAndTotalBalance(
            STRATEGY2,
            address(erc20mock),
            deposit1S2,
            deposit1S2
        );
        proxiedManager.depositERC20(STRATEGY1, erc20mock, deposit2S1);
        checkAccountShares(
            STRATEGY1,
            USER1,
            address(erc20mock),
            deposit1S1 + deposit2S1
        );
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            deposit1S1 + deposit2S1,
            deposit1S1 + deposit2S1
        );
        vm.stopPrank();
    }

    function testRevertDepositAmountHigherThanMaxShares() public {
        testCreateStrategies();
        uint256 depositAmount = proxiedManager.maxShares() + 1;
        vm.prank(USER3);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.ExceedingMaxShares.selector)
        );
        proxiedManager.depositERC20(STRATEGY1, erc20mock, depositAmount);
    }

    function testRevertDepositETHAmountHigherThanMaxShares() public {
        testCreateStrategies();
        uint256 depositAmount = proxiedManager.maxShares() + 1;
        vm.prank(USER3);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.ExceedingMaxShares.selector)
        );
        proxiedManager.depositETH{ value: depositAmount }(STRATEGY1);
    }

    function testCreateStrategyAndSingleDeposit() public {
        uint256 depositAmount = 100_000;
        testCreateStrategies();
        vm.startPrank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyDeposit(
            STRATEGY1,
            USER1,
            address(erc20mock),
            depositAmount
        );
        proxiedManager.depositERC20(STRATEGY1, erc20mock, depositAmount);
        checkAccountShares(STRATEGY1, USER1, address(erc20mock), depositAmount);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock),
            depositAmount,
            depositAmount
        );
        vm.stopPrank();
    }

    function testRevertInvalidProposeWithdrawalWithZeroAmount() public {
        testCreateStrategyAndSingleDeposit();
        vm.startPrank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector)
        );
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 0);
        vm.stopPrank();
    }

    function testRevertInvalidProposeWithdrawalETHWithZeroAmount() public {
        testCreateStrategyETHAndDepositETH();
        vm.startPrank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector)
        );
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 0);
        vm.stopPrank();
    }

    function testRevertInvalidProposeWithdrawalWithInsufficientBalance()
        public
    {
        testCreateStrategyAndSingleDeposit();
        vm.startPrank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InsufficientBalance.selector
            )
        );
        proxiedManager.proposeWithdrawal(
            STRATEGY1,
            address(erc20mock),
            2000 * 10 ** 18
        );
        vm.stopPrank();
    }

    function testRevertInvalidProposeWithdrawalETHWithInsufficientBalance()
        public
    {
        testCreateStrategyETHAndDepositETH();
        vm.startPrank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InsufficientBalance.selector
            )
        );
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 2 ether);
        vm.stopPrank();
    }

    function testStrategyOptInToBApp(uint32 percentage) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testCreateStrategies();
        testRegisterBApp();
        vm.startPrank(USER1);
        (, address owner, ) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Should have the correct strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit();
            emit IStrategyManager.BAppOptedInByStrategy(
                STRATEGY1,
                address(bApps[i]),
                abi.encodePacked("0x00"),
                tokensInput,
                obligationPercentagesInput
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
            checkStrategyInfo(
                USER1,
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                percentage,
                proxiedManager,
                true
            );
        }
        uint32 counter = bApp1.counter();
        assertEq(counter, 1, "Should have set the counter as 1");
        vm.stopPrank();
    }

    function testStrategyOptInToBAppWithEmitEvent(uint32 percentage) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testCreateStrategies();
        testRegisterBApp();
        vm.startPrank(USER1);
        (, address owner, ) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Should have set the correct strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        bytes memory data = abi.encodePacked("0x00");
        vm.expectEmit();
        emit BasedAppMock.OptInToBApp(
            STRATEGY1,
            tokensInput,
            obligationPercentagesInput,
            data
        );
        vm.expectEmit();
        emit IStrategyManager.BAppOptedInByStrategy(
            STRATEGY1,
            address(bApp1),
            abi.encodePacked("0x00"),
            tokensInput,
            obligationPercentagesInput
        );
        proxiedManager.optInToBApp(
            STRATEGY1,
            address(bApp1),
            tokensInput,
            obligationPercentagesInput,
            data
        );
        checkStrategyInfo(
            USER1,
            STRATEGY1,
            address(bApp1),
            address(erc20mock),
            percentage,
            proxiedManager,
            true
        );
        uint32 counter = bApp1.counter();
        assertEq(counter, 1, "Should have set the counter as 1");
        vm.stopPrank();
    }

    function testStrategyOptInToBAppEOA(uint32 percentage) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testCreateStrategies();
        testRegisterBAppWithEOA();
        vm.startPrank(USER1);
        (, address owner, ) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Should have set the correct strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        vm.expectEmit();
        emit IStrategyManager.BAppOptedInByStrategy(
            STRATEGY1,
            USER1,
            abi.encodePacked("0x00"),
            tokensInput,
            obligationPercentagesInput
        );
        proxiedManager.optInToBApp(
            STRATEGY1,
            USER1,
            tokensInput,
            obligationPercentagesInput,
            abi.encodePacked("0x00")
        );
        checkStrategyInfo(
            USER1,
            STRATEGY1,
            USER1,
            address(erc20mock),
            percentage,
            proxiedManager,
            true
        );
        vm.stopPrank();
    }

    function testStrategyOptInToBAppEOAWithETH(uint32 percentage) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testCreateStrategies();
        testRegisterBAppWithEOAWithEth();
        vm.startPrank(USER1);
        (, address owner, ) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Should have set the correct strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = ETH_ADDRESS;
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        vm.expectEmit();
        emit IStrategyManager.BAppOptedInByStrategy(
            STRATEGY1,
            USER1,
            abi.encodePacked("0x00"),
            tokensInput,
            obligationPercentagesInput
        );
        proxiedManager.optInToBApp(
            STRATEGY1,
            USER1,
            tokensInput,
            obligationPercentagesInput,
            abi.encodePacked("0x00")
        );
        checkStrategyInfo(
            USER1,
            STRATEGY1,
            USER1,
            ETH_ADDRESS,
            percentage,
            proxiedManager,
            true
        );
        vm.stopPrank();
    }

    function testStrategyOptInToBAppNonCompliant(uint32 percentage) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testCreateStrategies();
        testRegisterBAppFromNonBAppContract();
        vm.startPrank(USER1);
        (, address owner, ) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Should have set the correct strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        vm.expectEmit();
        emit IStrategyManager.BAppOptedInByStrategy(
            STRATEGY1,
            address(nonCompliantBApp),
            abi.encodePacked("0x00"),
            tokensInput,
            obligationPercentagesInput
        );
        proxiedManager.optInToBApp(
            STRATEGY1,
            address(nonCompliantBApp),
            tokensInput,
            obligationPercentagesInput,
            abi.encodePacked("0x00")
        );
        checkStrategyInfo(
            USER1,
            STRATEGY1,
            address(nonCompliantBApp),
            address(erc20mock),
            percentage,
            proxiedManager,
            true
        );
        vm.stopPrank();
    }

    function testStrategyRevertsSecondOptIn(uint32 percentage) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testStrategyOptInToBApp(percentage);
        vm.startPrank(USER2);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.BAppOptInFailed.selector)
        );
        proxiedManager.optInToBApp(
            STRATEGY4,
            address(bApp1),
            tokensInput,
            obligationPercentagesInput,
            abi.encodePacked("0x00")
        );
        checkStrategyInfo(
            USER2,
            0,
            address(bApp1),
            address(erc20mock),
            0,
            proxiedManager,
            false
        );
        uint32 counter = bApp1.counter();
        assertEq(
            counter,
            1,
            "Should have the counter set as 1 and not incremented"
        );
        vm.stopPrank();
    }

    function testOptInToBAppWithNoTokensWithNoTokens() public {
        testCreateStrategies();
        testRegisterBAppWithNoTokens();
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit();
            emit IStrategyManager.BAppOptedInByStrategy(
                STRATEGY1,
                address(bApps[i]),
                abi.encodePacked("0x00"),
                new address[](0),
                new uint32[](0)
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                new address[](0),
                new uint32[](0),
                abi.encodePacked("0x00")
            );
            checkBAppInfo(
                new ICore.TokenConfig[](0),
                address(bApps[i]),
                proxiedManager
            );
            checkStrategyInfo(
                USER1,
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                0,
                proxiedManager,
                false
            );
        }
        vm.stopPrank();
    }

    function testStrategyWithTwoTokensOptInToBAppWithFiveTokens(
        uint32 percentage
    ) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testCreateStrategies();
        testRegisterBAppWithFiveTokens();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](2);
        obligationPercentagesInput[0] = percentage;
        obligationPercentagesInput[1] = percentage;
        vm.expectEmit();
        emit IStrategyManager.BAppOptedInByStrategy(
            STRATEGY1,
            address(bApp1),
            abi.encodePacked("0x00"),
            tokensInput,
            obligationPercentagesInput
        );
        proxiedManager.optInToBApp(
            1,
            address(bApp1),
            tokensInput,
            obligationPercentagesInput,
            abi.encodePacked("0x00")
        );
        checkStrategyInfo(
            USER1,
            STRATEGY1,
            address(bApp1),
            address(erc20mock),
            percentage,
            proxiedManager,
            true
        );
        checkStrategyInfo(
            USER1,
            STRATEGY1,
            address(bApp1),
            address(erc20mock2),
            percentage,
            proxiedManager,
            true
        );
        vm.stopPrank();
    }

    function testRevertOptInToBAppWithNoTokensWithAToken(
        uint32 percentage
    ) public {
        testCreateStrategies();
        testRegisterBAppWithNoTokens();
        vm.startPrank(USER1);
        (
            address[] memory tokensInput,
            uint32[] memory obligationPercentagesInput
        ) = createSingleTokenAndSingleObligationPercentage(
                address(erc20mock),
                percentage
            );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.TokenNotSupportedByBApp.selector,
                    address(erc20mock)
                )
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testStrategyOptInToBAppWithMultipleTokens(
        uint32 percentage
    ) public {
        testCreateStrategies();
        testRegisterBAppWith2Tokens();
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        vm.startPrank(USER1);

        (
            address[] memory tokensInput,
            uint32[] memory obligationPercentagesInput
        ) = createSingleTokenAndSingleObligationPercentage(
                address(erc20mock),
                percentage
            );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit();
            emit IStrategyManager.BAppOptedInByStrategy(
                STRATEGY1,
                address(bApps[i]),
                abi.encodePacked("0x00"),
                tokensInput,
                obligationPercentagesInput
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
            checkStrategyInfo(
                USER1,
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                percentage,
                proxiedManager,
                true
            );
        }
        vm.stopPrank();
    }

    function testRevertStrategyOptInToBAppWithMultipleTokensFailsPercentageOverMax()
        public
    {
        testCreateStrategies();
        testRegisterBAppWith2Tokens();
        (
            address[] memory tokensInput,
            uint32[] memory obligationPercentagesInput
        ) = createSingleTokenAndSingleObligationPercentage(
                address(erc20mock),
                proxiedManager.maxPercentage() + 1
            );
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(ValidationLib.InvalidPercentage.selector)
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testStrategyOptInToBAppWithMultipleTokensWithPercentageZero()
        public
    {
        testCreateStrategies();
        testRegisterBAppWith2Tokens();
        vm.startPrank(USER1);
        uint32 percentage = 0;
        (
            address[] memory tokensInput,
            uint32[] memory obligationPercentagesInput
        ) = createSingleTokenAndSingleObligationPercentage(
                address(erc20mock),
                percentage
            );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit();
            emit IStrategyManager.BAppOptedInByStrategy(
                STRATEGY1,
                address(bApps[i]),
                abi.encodePacked("0x00"),
                tokensInput,
                obligationPercentagesInput
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
            checkStrategyInfo(
                USER1,
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                percentage,
                proxiedManager,
                true
            );
        }
        vm.stopPrank();
    }

    function testStrategyOptInToBAppWithETH() public {
        testCreateStrategies();
        testRegisterBAppWithETH();
        vm.startPrank(USER1);
        uint32 percentage = proxiedManager.maxPercentage();
        (
            address[] memory tokensInput,
            uint32[] memory obligationPercentagesInput
        ) = createSingleTokenAndSingleObligationPercentage(
                ETH_ADDRESS,
                percentage
            );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit();
            emit IStrategyManager.BAppOptedInByStrategy(
                STRATEGY1,
                address(bApps[i]),
                abi.encodePacked("0x00"),
                tokensInput,
                obligationPercentagesInput
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
            checkStrategyInfo(
                USER1,
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                percentage,
                proxiedManager,
                true
            );
        }
        vm.stopPrank();
    }

    function testRevertStrategyOptInWithNonOwner() public {
        testCreateStrategies();
        testRegisterBApp();
        uint32 percentage = 9000;
        (
            address[] memory tokensInput,
            uint32[] memory obligationPercentagesInput
        ) = createSingleTokenAndSingleObligationPercentage(
                address(erc20mock),
                percentage
            );
        vm.startPrank(ATTACKER);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.InvalidStrategyOwner.selector,
                    address(ATTACKER),
                    address(USER1)
                )
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testRevertStrategyOptInToBAppNonMatchingTokensAndObligations()
        public
    {
        testCreateStrategies();
        testRegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = proxiedManager.maxPercentage(); // 100%
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    ValidationLib.LengthsNotMatching.selector
                )
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testRevertStrategyOptInToBAppNotAllowNonMatchingStrategyTokensWithBAppTokens()
        public
    {
        testCreateStrategies();
        testRegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](2);
        obligationPercentagesInput[0] = 6000; // 60%
        obligationPercentagesInput[1] = 5000; // 50%
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.TokenNotSupportedByBApp.selector,
                    address(erc20mock2)
                )
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testRevertStrategyAlreadyOptedIn(uint32 percentage) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testStrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        (, address owner, ) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage; // 90%
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.BAppAlreadyOptedIn.selector
                )
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testRevertStrategyOptingInToNonExistingBApp(
        uint32 percentage
    ) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testCreateStrategies();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](0);
        uint32[] memory obligationPercentagesInput = new uint32[](0);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IBasedAppManager.BAppNotRegistered.selector,
                    address(erc20mock2)
                )
            );
            proxiedManager.optInToBApp(
                STRATEGY1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testStrategyOwnerDepositERC20WithNoObligation(
        uint256 amount
    ) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        testStrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        checkAccountShares(STRATEGY1, USER1, address(erc20mock2), 0);
        checkTotalSharesAndTotalBalance(STRATEGY1, address(erc20mock2), 0, 0);
        vm.expectEmit();
        emit IStrategyManager.StrategyDeposit(
            STRATEGY1,
            USER1,
            address(erc20mock2),
            amount
        );
        proxiedManager.depositERC20(STRATEGY1, erc20mock2, amount);
        checkAccountShares(STRATEGY1, USER1, address(erc20mock2), amount);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(erc20mock2),
            amount,
            amount
        );
        vm.stopPrank();
    }

    function testStrategyOwnerDepositETHWithNoObligation() public {
        uint32 percentage = 9000;
        uint256 amount = 1_000_000 ether;
        testStrategyOptInToBApp(percentage);
        vm.startPrank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyDeposit(
            STRATEGY1,
            USER1,
            ETH_ADDRESS,
            amount
        );
        proxiedManager.depositETH{ value: amount }(STRATEGY1);
        checkAccountShares(STRATEGY1, USER1, ETH_ADDRESS, amount);
        checkTotalSharesAndTotalBalance(STRATEGY1, ETH_ADDRESS, amount, amount);
        vm.stopPrank();
    }

    function testRevertStrategyOwnerDepositETHWithNoObligationRevertWithZeroAmount()
        public
    {
        testStrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector)
        );
        proxiedManager.depositETH{ value: 0 ether }(STRATEGY1);
        vm.stopPrank();
    }

    function testRevertObligationNotMatchTokensBApp() public {
        testStrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.TokenNotSupportedByBApp.selector,
                    address(erc20mock2)
                )
            );
            proxiedManager.createObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock2),
                100
            );
        }
        vm.stopPrank();
    }

    function testCreateStrategyETHAndDepositETH() public {
        testStrategyOptInToBAppWithETH();
        vm.startPrank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyDeposit(
            STRATEGY1,
            USER1,
            ETH_ADDRESS,
            1 ether
        );
        proxiedManager.depositETH{ value: 1 ether }(STRATEGY1);
        checkAccountShares(STRATEGY1, USER1, ETH_ADDRESS, 1 ether);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            ETH_ADDRESS,
            1 ether,
            1 ether
        );

        vm.stopPrank();
    }

    function testRevertObligationHigherThanMaxPercentage() public {
        testStrategyOptInToBApp(9000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(ValidationLib.InvalidPercentage.selector)
            );
            proxiedManager.createObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                10_001
            );
        }
    }

    function testRevertCreateObligationToNonExistingBApp() public {
        testStrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.BAppNotOptedIn.selector)
        );
        proxiedManager.createObligation(
            STRATEGY1,
            NON_EXISTENT_BAPP,
            address(erc20mock),
            100
        );
    }

    function testRevertCreateObligationToNonExistingStrategy() public {
        uint32 nonExistentStrategy = 333;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.InvalidStrategyOwner.selector,
                    address(USER1),
                    0x00
                )
            );
            proxiedManager.createObligation(
                nonExistentStrategy,
                address(bApps[i]),
                address(erc20mock),
                100
            );
        }
    }

    function testRevertCreateObligationToNotOwnedStrategy() public {
        testCreateStrategies();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(ATTACKER);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.InvalidStrategyOwner.selector,
                    address(ATTACKER),
                    address(USER1)
                )
            );
            proxiedManager.createObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                100
            );
        }
    }

    function testRevertCreateObligationFailsBecauseAlreadySet() public {
        testStrategyOptInToBAppWithMultipleTokens(9000);
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.ObligationAlreadySet.selector
                )
            );
            proxiedManager.createObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                100
            );
        }
        vm.stopPrank();
    }

    function testCreateNewObligationSuccessful() public {
        testStrategyOptInToBAppWithMultipleTokens(9000);
        vm.startPrank(USER1);
        uint32 percentage = 9500;
        address token = address(erc20mock2);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit();
            emit IStrategyManager.ObligationCreated(
                STRATEGY1,
                address(bApps[i]),
                token,
                percentage
            );
            proxiedManager.createObligation(
                STRATEGY1,
                address(bApps[i]),
                token,
                percentage
            );
            checkObligationInfo(
                STRATEGY1,
                address(bApps[i]),
                token,
                percentage,
                true,
                proxiedManager
            );
        }
        vm.stopPrank();
    }

    function testRevertCreateObligationFailCauseAlreadySet() public {
        testCreateNewObligationSuccessful();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.ObligationAlreadySet.selector
                )
            );
            proxiedManager.createObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock2),
                10_000
            );
        }
    }

    function testRevertStrategyFeeUpdateFailsWithNonOwner(uint32 fee) public {
        testStrategyOptInToBApp(9000);
        vm.assume(fee > 0 && fee <= proxiedManager.maxPercentage());
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InvalidStrategyOwner.selector,
                address(ATTACKER),
                USER1
            )
        );
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
    }

    function testRevertStrategyFeeUpdateFailsWithNoProposal() public {
        testStrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.NoPendingFeeUpdate.selector)
        );
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
    }

    function testRevertStrategyFeeUpdateFailsWithOverLimitFee(
        uint32 fee
    ) public {
        testStrategyOptInToBApp(9000);
        vm.assume(fee > proxiedManager.maxPercentage());
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(ValidationLib.InvalidPercentage.selector)
        );
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
    }

    function testRevertStrategyFeeUpdateFailsWithOverLimitIncrement(
        uint32 proposedFee
    ) public {
        testStrategyOptInToBApp(9000);
        (, , uint32 fee) = proxiedManager.strategies(STRATEGY1);
        vm.assume(
            proposedFee < proxiedManager.maxPercentage() &&
                proposedFee > fee + proxiedManager.maxFeeIncrement()
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InvalidPercentageIncrement.selector
            )
        );
        proxiedManager.proposeFeeUpdate(STRATEGY1, proposedFee);
    }

    function testRevertStrategyFeeUpdateFailsWithSameFeeValue() public {
        testStrategyOptInToBApp(9000);
        (, , uint32 fee) = proxiedManager.strategies(STRATEGY1);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.FeeAlreadySet.selector)
        );
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
    }

    function testStrategyProposeFeeUpdate()
        public
        returns (uint32 proposedFee)
    {
        testStrategyOptInToBApp(9000);
        proposedFee = 505;
        vm.prank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyFeeUpdateProposed(
            STRATEGY1,
            USER1,
            proposedFee
        );
        proxiedManager.proposeFeeUpdate(STRATEGY1, proposedFee);
        checkProposedFee(
            STRATEGY1,
            USER1,
            STRATEGY1_INITIAL_FEE,
            proposedFee,
            1
        );
        return proposedFee;
    }

    function testStrategyFeeUpdate(uint256 timeBeforeLimit) public {
        vm.assume(timeBeforeLimit < proxiedManager.feeExpireTime());
        uint32 proposedFee = testStrategyProposeFeeUpdate();
        vm.warp(
            block.timestamp +
                proxiedManager.feeTimelockPeriod() +
                timeBeforeLimit
        );
        vm.prank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyFeeUpdated(
            STRATEGY1,
            USER1,
            proposedFee,
            false
        );
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        checkProposedFee(STRATEGY1, USER1, proposedFee, 0, 0);
    }

    function testRevertStrategyFeeUpdateTooLate(uint256 timeAfterLimit) public {
        timeAfterLimit = bound(
            timeAfterLimit,
            proxiedManager.feeExpireTime() + 1,
            100 * 365 days
        );
        testStrategyProposeFeeUpdate();
        vm.warp(
            block.timestamp +
                proxiedManager.feeTimelockPeriod() +
                timeAfterLimit
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.RequestTimeExpired.selector)
        );
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
    }

    function testRevertStrategyFeeUpdateTooEarly() public {
        testStrategyProposeFeeUpdate();
        vm.warp(
            block.timestamp + proxiedManager.feeTimelockPeriod() - 1 seconds
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.TimelockNotElapsed.selector)
        );
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
    }

    function testStrategyFastFeeUpdate() public {
        testStrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyFeeUpdated(STRATEGY1, USER1, 1, true);
        proxiedManager.reduceFee(STRATEGY1, 1);
        checkFee(STRATEGY1, USER1, 1);
    }

    function testRevertStrategyFastFeeUpdateInvalidPercentage() public {
        testStrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InvalidPercentageIncrement.selector
            )
        );
        proxiedManager.reduceFee(STRATEGY1, 100);
    }

    function testRevertProposeUpdateObligationWithNonOwner() public {
        testStrategyOptInToBApp(9000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(ATTACKER);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.InvalidStrategyOwner.selector,
                    address(ATTACKER),
                    USER1
                )
            );
            proxiedManager.proposeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                1000
            );
        }
    }

    function testRevertProposeUpdateObligationWithTooHighPercentage(
        uint32 obligationPercentage
    ) public {
        testStrategyOptInToBApp(9000);
        vm.assume(obligationPercentage > 10_000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(ValidationLib.InvalidPercentage.selector)
            );
            proxiedManager.proposeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                obligationPercentage
            );
        }
    }

    function testRevertFinalizeFeeUpdateWithWrongOwner() public {
        testStrategyProposeFeeUpdate();
        vm.warp(block.timestamp + proxiedManager.feeTimelockPeriod());
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InvalidStrategyOwner.selector,
                address(ATTACKER),
                USER1
            )
        );
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
    }

    function testProposeStrategyObligationPercentage(
        uint32 initialObligationPercentage,
        uint32 proposedObligationPercentage
    ) public {
        vm.assume(
            initialObligationPercentage > 0 &&
                initialObligationPercentage <= proxiedManager.maxPercentage() &&
                proposedObligationPercentage >= 0 &&
                proposedObligationPercentage <=
                proxiedManager.maxPercentage() &&
                proposedObligationPercentage != initialObligationPercentage
        );

        testStrategyOptInToBApp(initialObligationPercentage);

        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit();
            emit IStrategyManager.ObligationUpdateProposed(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                proposedObligationPercentage
            );
            proxiedManager.proposeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                proposedObligationPercentage
            );
            checkProposedObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                initialObligationPercentage,
                proposedObligationPercentage,
                1,
                true
            );
        }
    }

    function testUpdateStrategyObligationFinalizeOnInitialLimit() public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        testProposeStrategyObligationPercentage(
            initialObligationPercentage,
            proposedObligationPercentage
        );
        vm.warp(block.timestamp + proxiedManager.obligationTimelockPeriod());
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit();
            emit IStrategyManager.ObligationUpdated(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                proposedObligationPercentage
            );
            proxiedManager.finalizeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock)
            );
            checkProposedObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                proposedObligationPercentage,
                0,
                0,
                true
            );
        }
    }

    function testUpdateStrategyObligationFinalizeOnLatestLimit() public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        testProposeStrategyObligationPercentage(
            initialObligationPercentage,
            proposedObligationPercentage
        );
        vm.warp(
            block.timestamp +
                proxiedManager.obligationTimelockPeriod() +
                proxiedManager.obligationExpireTime()
        );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit();
            emit IStrategyManager.ObligationUpdated(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                proposedObligationPercentage
            );
            proxiedManager.finalizeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock)
            );
            checkProposedObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                proposedObligationPercentage,
                0,
                0,
                true
            );
        }
    }

    function testUpdateStrategyObligationFinalizeWithZeroValue() public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 0;
        testProposeStrategyObligationPercentage(
            initialObligationPercentage,
            proposedObligationPercentage
        );

        vm.startPrank(USER1);

        vm.warp(
            block.timestamp +
                proxiedManager.obligationTimelockPeriod() +
                proxiedManager.obligationExpireTime()
        );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit();
            emit IStrategyManager.ObligationUpdated(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                proposedObligationPercentage
            );
            proxiedManager.finalizeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock)
            );
            checkProposedObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                proposedObligationPercentage,
                0,
                0,
                true
            );
        }
        vm.stopPrank();
    }

    function testRevertUpdateStrategyObligationFinalizeTooLate(
        uint256 timeAfterLimit
    ) public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        testProposeStrategyObligationPercentage(
            initialObligationPercentage,
            proposedObligationPercentage
        );
        timeAfterLimit = bound(
            timeAfterLimit,
            proxiedManager.obligationExpireTime() + 1,
            100 * 365 days
        );
        vm.warp(
            block.timestamp +
                proxiedManager.obligationTimelockPeriod() +
                timeAfterLimit
        );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.RequestTimeExpired.selector
                )
            );
            proxiedManager.finalizeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock)
            );
        }
    }

    function testRevertUpdateStrategyObligationFinalizeTooEarly(
        uint256 timeToLimit
    ) public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        testProposeStrategyObligationPercentage(
            initialObligationPercentage,
            proposedObligationPercentage
        );
        vm.assume(
            timeToLimit > 0 &&
                timeToLimit < proxiedManager.obligationTimelockPeriod()
        );
        vm.warp(
            block.timestamp +
                proxiedManager.obligationTimelockPeriod() -
                timeToLimit
        );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.TimelockNotElapsed.selector
                )
            );
            proxiedManager.finalizeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock)
            );
        }
    }

    function testRevertUpdateStrategyObligationWithNonOwner() public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        testProposeStrategyObligationPercentage(
            initialObligationPercentage,
            proposedObligationPercentage
        );
        vm.warp(block.timestamp + proxiedManager.obligationTimelockPeriod());
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(ATTACKER);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.InvalidStrategyOwner.selector,
                    address(ATTACKER),
                    USER1
                )
            );
            proxiedManager.finalizeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock)
            );
        }
    }

    function testRevertFinalizeUpdateObligationFailWithNoPendingRequest()
        public
    {
        uint32 initialObligationPercentage = 9000;
        testStrategyOptInToBApp(initialObligationPercentage);
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.NoPendingObligationUpdate.selector
                )
            );
            proxiedManager.finalizeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock)
            );
        }
        vm.stopPrank();
    }

    function testProposeWithdrawalFromStrategy()
        public
        returns (uint256 withdrawalAmount, IERC20 token, uint256 currentBalance)
    {
        testCreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        withdrawalAmount = 1000;
        token = erc20mock;
        currentBalance = 120_000;
        vm.expectEmit();
        emit IStrategyManager.StrategyWithdrawalProposed(
            STRATEGY1,
            USER1,
            address(token),
            withdrawalAmount
        );
        vm.prank(USER1);
        proxiedManager.proposeWithdrawal(
            STRATEGY1,
            address(token),
            withdrawalAmount
        );
        checkAccountShares(STRATEGY1, USER1, address(token), currentBalance);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(token),
            currentBalance,
            currentBalance
        );
        checkProposedWithdrawal(
            STRATEGY1,
            USER1,
            address(token),
            block.timestamp,
            withdrawalAmount
        );
    }

    function testFinalizeWithdrawFromStrategy() public {
        (
            uint256 withdrawalAmount,
            IERC20 token,
            uint256 currentBalance
        ) = testProposeWithdrawalFromStrategy();
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        vm.expectEmit();
        emit IStrategyManager.StrategyWithdrawal(
            STRATEGY1,
            USER1,
            address(token),
            withdrawalAmount,
            false
        );
        uint256 oldUserBalance = token.balanceOf(USER1);
        vm.prank(USER1);
        proxiedManager.finalizeWithdrawal(STRATEGY1, token);
        uint256 newBalance = currentBalance - withdrawalAmount;
        uint256 newUserBalance = token.balanceOf(USER1);

        assertNotEq(newUserBalance, oldUserBalance);
        assertEq(newUserBalance, oldUserBalance + withdrawalAmount);

        checkAccountShares(STRATEGY1, USER1, address(token), newBalance);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            address(token),
            newBalance,
            newBalance
        );
        checkProposedWithdrawal(STRATEGY1, USER1, address(token), 0, 0);
    }

    function testRevertAsyncWithdrawFromStrategyOnlyFinalize() public {
        testCreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.NoPendingWithdrawal.selector
            )
        );
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
    }

    function testProposeWithdrawalETHFromStrategy(
        uint256 withdrawalAmount
    ) public returns (uint256 currentBalance) {
        testCreateStrategyETHAndDepositETH();
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        currentBalance = 1 ether;
        vm.expectEmit();
        emit IStrategyManager.StrategyWithdrawalProposed(
            STRATEGY1,
            USER1,
            ETH_ADDRESS,
            withdrawalAmount
        );
        vm.prank(USER1);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, withdrawalAmount);
        checkAccountShares(STRATEGY1, USER1, ETH_ADDRESS, currentBalance);
        checkProposedWithdrawal(
            STRATEGY1,
            USER1,
            ETH_ADDRESS,
            block.timestamp,
            withdrawalAmount
        );
    }

    function testAsyncWithdrawETHFromStrategy(uint256 withdrawalAmount) public {
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        uint256 currentBalance = testProposeWithdrawalETHFromStrategy(
            withdrawalAmount
        );
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        vm.expectEmit();
        emit IStrategyManager.StrategyWithdrawal(
            STRATEGY1,
            USER1,
            ETH_ADDRESS,
            withdrawalAmount,
            false
        );
        vm.prank(USER1);
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        uint256 newBalance = currentBalance - withdrawalAmount;
        checkAccountShares(STRATEGY1, USER1, ETH_ADDRESS, newBalance);
        checkTotalSharesAndTotalBalance(
            STRATEGY1,
            ETH_ADDRESS,
            newBalance,
            newBalance
        );
        checkProposedWithdrawal(STRATEGY1, USER1, ETH_ADDRESS, 0, 0);
    }

    function testRevertAsyncWithdrawETHFromStrategyOnlyFinalize() public {
        testCreateStrategyETHAndDepositETH();
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.NoPendingWithdrawal.selector
            )
        );
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
    }

    function testRevertAsyncWithdrawETHFromStrategyWithMadeUpToken() public {
        testCreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        vm.prank(USER1);
        vm.expectRevert(); // It will fail cause the address has no balanceOf()
        proxiedManager.proposeWithdrawal(STRATEGY1, address(1), 1000);
    }

    function testRevertAsyncFailedWithdrawETHFromStrategyTooEarly(
        uint256 withdrawalAmount
    ) public {
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        testProposeWithdrawalETHFromStrategy(withdrawalAmount);
        vm.warp(
            block.timestamp +
                proxiedManager.withdrawalTimelockPeriod() -
                1 seconds
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.TimelockNotElapsed.selector)
        );
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
    }

    function testRevertAsyncFailedWithdrawETHFromStrategyTooLate(
        uint256 withdrawalAmount
    ) public {
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        testProposeWithdrawalETHFromStrategy(withdrawalAmount);
        vm.warp(
            block.timestamp +
                proxiedManager.withdrawalTimelockPeriod() +
                proxiedManager.withdrawalExpireTime() +
                1 seconds
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.RequestTimeExpired.selector)
        );
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
    }

    function testRevertAsyncFailedWithdrawFromStrategyETHInsteadOfERC20(
        uint256 withdrawalAmount
    ) public {
        testCreateStrategyETHAndDepositETH();
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.InvalidToken.selector)
        );
        proxiedManager.proposeWithdrawal(
            STRATEGY1,
            ETH_ADDRESS,
            withdrawalAmount
        );
    }

    function testRevertAsyncFailedWithdrawFromStrategyTooEarly() public {
        testProposeWithdrawalFromStrategy();
        vm.warp(
            block.timestamp +
                proxiedManager.withdrawalTimelockPeriod() -
                1 seconds
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.TimelockNotElapsed.selector)
        );
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
    }

    function testRevertAsyncFailedWithdrawFromStrategyTooLate() public {
        testProposeWithdrawalFromStrategy();
        vm.warp(
            block.timestamp +
                proxiedManager.withdrawalTimelockPeriod() +
                proxiedManager.withdrawalExpireTime() +
                1 seconds
        );
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.RequestTimeExpired.selector)
        );
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
    }

    function testCreateObligationETH(uint32 percentage) public {
        vm.assume(
            percentage > 0 && percentage <= proxiedManager.maxPercentage()
        );
        testCreateStrategies();
        testRegisterBAppWithETHAndErc20();
        vm.startPrank(USER1);
        (
            address[] memory tokensInput,
            uint32[] memory obligationPercentagesInput
        ) = createSingleTokenAndSingleObligationPercentage(
                address(erc20mock),
                percentage
            );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit();
            emit IStrategyManager.BAppOptedInByStrategy(
                STRATEGY1,
                address(bApps[i]),
                abi.encodePacked("0x00"),
                tokensInput,
                obligationPercentagesInput
            );
            proxiedManager.optInToBApp(
                1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
            checkObligationInfo(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                percentage,
                true,
                proxiedManager
            );

            vm.expectEmit();
            emit IStrategyManager.ObligationCreated(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                proxiedManager.maxPercentage()
            );
            proxiedManager.createObligation(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                proxiedManager.maxPercentage()
            );
            checkObligationInfo(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                proxiedManager.maxPercentage(),
                true,
                proxiedManager
            );
        }
        vm.stopPrank();
    }

    function testCreateObligationETHWithZeroPercentage() public {
        testCreateStrategies();
        testRegisterBAppWithETHAndErc20();
        vm.startPrank(USER1);
        (
            address[] memory tokensInput,
            uint32[] memory obligationPercentagesInput
        ) = createSingleTokenAndSingleObligationPercentage(
                address(erc20mock),
                0
            );

        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit();
            emit IStrategyManager.BAppOptedInByStrategy(
                STRATEGY1,
                address(bApps[i]),
                abi.encodePacked("0x00"),
                tokensInput,
                obligationPercentagesInput
            );
            proxiedManager.optInToBApp(
                1,
                address(bApps[i]),
                tokensInput,
                obligationPercentagesInput,
                abi.encodePacked("0x00")
            );
            checkObligationInfo(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock),
                0,
                true,
                proxiedManager
            );
            vm.expectEmit();
            emit IStrategyManager.ObligationCreated(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                0
            );
            proxiedManager.createObligation(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                0
            );
            checkObligationInfo(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                0,
                true,
                proxiedManager
            );
        }
        vm.stopPrank();
    }

    function testUpdateObligationFromZeroToHigher() public {
        testCreateObligationETHWithZeroPercentage();
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            proxiedManager.proposeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                5000
            );
            vm.warp(
                block.timestamp + proxiedManager.obligationTimelockPeriod()
            );
            proxiedManager.finalizeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS
            );
            checkObligationInfo(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                5000,
                true,
                proxiedManager
            );
        }
        vm.stopPrank();
    }

    function testRevertProposeUpdateObligationWithBAppNotOptedIN() public {
        testCreateStrategies();
        testRegisterBApp();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(IStrategyManager.BAppNotOptedIn.selector)
            );
            proxiedManager.proposeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                5000
            );
        }
    }

    function testRevertProposeUpdateObligationWithSamePercentage() public {
        testCreateObligationETH(10_000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);

            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.ObligationAlreadySet.selector
                )
            );
            proxiedManager.proposeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                ETH_ADDRESS,
                10_000
            );
        }
    }

    function testRevertProposeUpdateObligationNotCreated() public {
        testCreateObligationETH(10_000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);

            vm.expectRevert(
                abi.encodeWithSelector(
                    IStrategyManager.ObligationHasNotBeenCreated.selector
                )
            );
            proxiedManager.proposeUpdateObligation(
                STRATEGY1,
                address(bApps[i]),
                address(erc20mock2),
                8000
            );
        }
    }

    function testUpdateStrategyMetadata() public {
        testCreateStrategies();
        string memory metadataURI = "https://metadata.com";
        vm.startPrank(USER1);
        vm.expectEmit();
        emit IStrategyManager.StrategyMetadataURIUpdated(
            STRATEGY1,
            metadataURI
        );
        proxiedManager.updateStrategyMetadataURI(STRATEGY1, metadataURI);
        vm.stopPrank();
    }

    function testRevertUpdateStrategyMetadataWithWrongOwner() public {
        testCreateStrategies();
        string memory metadataURI = "https://metadata-attacker.com";
        vm.startPrank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InvalidStrategyOwner.selector,
                address(ATTACKER),
                address(USER1)
            )
        );
        proxiedManager.updateStrategyMetadataURI(STRATEGY1, metadataURI);
        vm.stopPrank();
    }

    function testRevertProposeWithdrawInsufficientLiquidity() public {
        testCreateObligationETHWithZeroPercentage(); // Registers BApp and does the opt in
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InsufficientLiquidity.selector
            )
        );
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 10_000);
    }

    function testRevertProposeWithdrawInsufficientLiquidityETH() public {
        testCreateObligationETHWithZeroPercentage(); // Registers BApp and does the opt in
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InsufficientLiquidity.selector
            )
        );
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 1 ether);
    }

    function testFinalizeWithdrawalAfterSlashingEventSucceeds() public {
        testStrategyOptInToBApp(10_000);
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, 10_000);
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 10_000);
        proxiedManager.slash(
            createSlashContext(
                STRATEGY1,
                address(bApp1),
                address(erc20mock),
                5000
            ),
            abi.encode("0x00")
        );
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        vm.stopPrank();
    }

    function testRevertFinalizeWithdrawalAfterSlashingEventFailsCauseBalanceIsZero()
        public
    {
        testStrategyOptInToBApp(10_000);
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, 10_000);
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 10_000);
        proxiedManager.slash(
            createSlashContext(
                STRATEGY1,
                address(bApp1),
                address(erc20mock),
                10_000
            ),
            abi.encode("0x00")
        );
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InvalidAccountGeneration.selector
            )
        );
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        vm.stopPrank();
    }

    function testFinalizeWithdrawalETHAfterSlashingEventSucceeds() public {
        testStrategyOptInToBAppWithETH();
        vm.startPrank(USER1);
        proxiedManager.depositETH{ value: 1 ether }(STRATEGY1);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 1 ether);
        uint32 slashPercentage = 5000;
        proxiedManager.slash(
            createSlashContext(
                STRATEGY1,
                address(bApp1),
                ETH_ADDRESS,
                slashPercentage
            ),
            abi.encode("0x00")
        );
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        vm.stopPrank();
    }

    function testRevertFinalizeWithdrawalETHAfterSlashingEventFailsCauseBalanceIsZero()
        public
    {
        testStrategyOptInToBAppWithETH();
        vm.startPrank(USER1);
        proxiedManager.depositETH{ value: 1 ether }(STRATEGY1);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 1 ether);
        uint32 slashPercentage = 10_000;
        proxiedManager.slash(
            createSlashContext(
                STRATEGY1,
                address(bApp1),
                ETH_ADDRESS,
                slashPercentage
            ),
            abi.encode("0x00")
        );
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.InvalidAccountGeneration.selector
            )
        );
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        vm.stopPrank();
    }

    function testProposeUpdateAndProposeAnotherChangeToUpdate() public {
        uint256 withdrawalAmount = 1 ether;
        testStrategyOptInToBAppWithETH();
        vm.startPrank(USER1);
        proxiedManager.depositETH{ value: 1 ether }(STRATEGY1);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, withdrawalAmount);
        checkProposedWithdrawal(
            STRATEGY1,
            USER1,
            proxiedManager.ethAddress(),
            block.timestamp,
            withdrawalAmount
        );
        uint256 newTimestamp = block.timestamp +
            proxiedManager.withdrawalTimelockPeriod() -
            100 seconds;
        vm.warp(newTimestamp);
        uint256 newWithdrawalAmount = 0.5 ether;
        proxiedManager.proposeWithdrawalETH(STRATEGY1, newWithdrawalAmount);
        checkProposedWithdrawal(
            STRATEGY1,
            USER1,
            proxiedManager.ethAddress(),
            newTimestamp,
            newWithdrawalAmount
        );
    }

    function testSlashWhenEnabled(uint32 slashPercentage) public {
        uint32 pct = proxiedManager.maxPercentage();
        // register & opt‐in
        testStrategyOptInToBApp(pct);
        // deposit 1 token
        vm.startPrank(USER1);
        erc20mock.approve(address(proxiedManager), 1);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, 1);
        vm.stopPrank();
        // slash from bApp1
        vm.prank(address(bApp1));
        proxiedManager.slash(
            createSlashContext(
                STRATEGY1,
                address(bApp1),
                address(erc20mock),
                10_000
            ),
            ""
        );
        // after slash, strategy balance should be zero
        uint256 bal = proxiedManager.strategyTotalBalance(
            STRATEGY1,
            address(erc20mock)
        );
        assertEq(bal, 0, "Strategy balance should have decreased by 1");
    }

    function testSlashRevertsWhenDisabled() public {
        // disable slashing
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(1 << 0);
        // now any slash call must revert
        vm.prank(address(bApp1));
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyManager.SlashingDisabled.selector)
        );
        proxiedManager.slash(
            createSlashContext(
                STRATEGY1,
                address(bApp1),
                address(erc20mock),
                10_000
            ),
            ""
        );
    }

    function testSlashSucceedsAfterReenable() public {
        // re‐enable slashing
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(0);
        // prepare valid slash (opt-in + deposit)
        uint32 pct = proxiedManager.maxPercentage();
        testStrategyOptInToBApp(pct);
        vm.startPrank(USER1);
        erc20mock.approve(address(proxiedManager), 1);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, 1);
        vm.stopPrank();
        // should no longer revert
        vm.prank(address(bApp1));
        proxiedManager.slash(
            createSlashContext(
                STRATEGY1,
                address(bApp1),
                address(erc20mock),
                10_000
            ),
            ""
        );
        // confirm balance dropped
        uint256 bal = proxiedManager.strategyTotalBalance(
            STRATEGY1,
            address(erc20mock)
        );
        assertEq(bal, 0, "Slash should succeed once re-enabled");
    }

    function testProposeAndFinalizeWithdrawalWhenEnabled() public {
        // set up a deposit
        testCreateStrategyAndSingleDeposit(100);
        // propose withdrawal
        vm.prank(USER1);
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 50);
        // fast-forward timelock
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        // finalize and check balances
        vm.prank(USER1);
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        uint256 remaining = proxiedManager.strategyAccountShares(
            STRATEGY1,
            USER1,
            address(erc20mock)
        );
        assertEq(
            remaining,
            50,
            "User should have 50 tokens left in the strategy"
        );
    }

    function testProposeWithdrawalRevertsWhenDisabled() public {
        // disable withdrawals (bit 1)
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(1 << 1);

        // attempt to propose an ERC20 withdrawal
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.WithdrawalsDisabled.selector
            )
        );
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 1);
    }

    function testFinalizeWithdrawalRevertsWhenDisabled() public {
        // first get a pending withdrawal
        testProposeWithdrawalFromStrategy();

        // disable withdrawals
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(1 << 1);

        // now finalize should revert
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.WithdrawalsDisabled.selector
            )
        );
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
    }

    function testProposeWithdrawalETHRevertsWhenDisabled() public {
        // deposit some ETH first
        testCreateStrategyETHAndDepositETH();

        // disable withdrawals
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(1 << 1);

        // attempt to propose an ETH withdrawal
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.WithdrawalsDisabled.selector
            )
        );
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 1 ether);
    }

    function testFinalizeWithdrawalETHRevertsWhenDisabled() public {
        // get a pending ETH withdrawal
        testProposeWithdrawalETHFromStrategy(0.5 ether);

        // disable withdrawals
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(1 << 1);

        // warp past timelock
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        // now finalize should revert
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IStrategyManager.WithdrawalsDisabled.selector
            )
        );
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
    }
}
