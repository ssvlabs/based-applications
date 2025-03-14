// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {
    BasedAppManagerSetupTest,
    IStorage,
    IBasedAppManager,
    IERC20,
    BasedAppMock,
    ISSVBasedApps
} from "@ssv/test/BAppManager.setup.t.sol";
import {BasedAppsTest} from "@ssv/test/BApps.general.t.sol";
import {TestUtils} from "@ssv/test/Utils.t.sol";

contract BasedAppManagerStrategyTest is BasedAppManagerSetupTest, BasedAppsTest {
    function checkStrategyTokenBalance(uint32 strategyId, address owner, address token, uint256 expectedBalance) internal view {
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(strategyId, owner, token);
        assertEq(strategyTokenBalance, expectedBalance, "Should match the expected strategy token balance");
    }

    function checkProposedFee(
        uint32 strategyId,
        address expectedOwner,
        uint32 expectedInitialFee,
        uint32 expectedProposedFee,
        uint256 expectedUpdateTime
    ) internal view {
        (address owner, uint32 fee) = proxiedManager.strategies(strategyId);
        (uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.feeUpdateRequests(strategyId);
        assertEq(owner, expectedOwner, "Should match the expected strategy owner");
        assertEq(fee, expectedInitialFee, "Should match the expected current strategy fee");
        assertEq(feeProposed, expectedProposedFee, "Should match the expected strategy fee proposed");
        assertEq(feeUpdateTime, expectedUpdateTime, "Should match the expected fee update time");
    }

    function checkFee(uint32 strategyId, address expectedOwner, uint32 expectedFee) internal view {
        (address owner, uint32 fee) = proxiedManager.strategies(strategyId);
        assertEq(owner, expectedOwner, "Should match the expected strategy owner");
        assertEq(fee, expectedFee, "Should match the expected fee percentage");
    }

    function checkProposedObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 expectedCurrentPercentage,
        uint32 expectedProposedPercentage,
        uint256 expectedRequestTime,
        bool expectedIsSet
    ) internal view {
        (uint32 proposedPercentage, uint256 requestTime) = proxiedManager.obligationRequests(strategyId, bApp, token);
        (uint32 oldPercentage, bool isSet) = proxiedManager.obligations(strategyId, bApp, token);
        assertEq(isSet, expectedIsSet, "Should match the expected isSet value");
        assertEq(oldPercentage, expectedCurrentPercentage, "Should match the expected current obligation percentage");
        assertEq(proposedPercentage, expectedProposedPercentage, "Should match the expected proposed obligation percentage");
        assertEq(requestTime, expectedRequestTime, "Should match the expected obligation request time");
    }

    function checkProposedWithdrawal(
        uint32 strategyId,
        address owner,
        address token,
        uint256 expectedRequestTime,
        uint256 expectedAmount
    ) internal view {
        (uint256 amount, uint256 requestTime) = proxiedManager.withdrawalRequests(strategyId, owner, token);
        assertEq(requestTime, expectedRequestTime, "Should match the expected request time");
        assertEq(amount, expectedAmount, "Should match the expected request amount");
    }

    function test_CreateStrategies() public {
        vm.startPrank(USER1);

        erc20mock.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);

        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyCreated(STRATEGY1, USER1, STRATEGY1_INITIAL_FEE, "");
        uint32 strategyId1 = proxiedManager.createStrategy(STRATEGY1_INITIAL_FEE, "");
        proxiedManager.createStrategy(STRATEGY2_INITIAL_FEE, "");
        proxiedManager.createStrategy(STRATEGY3_INITIAL_FEE, "");

        assertEq(strategyId1, STRATEGY1, "Strategy 1 was saved correctly");
        (address owner, uint32 delegationFeeOnRewards) = proxiedManager.strategies(strategyId1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(delegationFeeOnRewards, STRATEGY1_INITIAL_FEE, "Strategy fee");
        vm.stopPrank();

        vm.startPrank(USER2);

        uint32 strategyId4 = proxiedManager.createStrategy(STRATEGY4_INITIAL_FEE, "");
        assertEq(strategyId4, STRATEGY4, "Strategy 4 was saved correctly");
        (owner, delegationFeeOnRewards) = proxiedManager.strategies(strategyId4);
        assertEq(owner, USER2, "Strategy 4 owner");
        assertEq(delegationFeeOnRewards, STRATEGY4_INITIAL_FEE, "Strategy fee");

        checkStrategyTokenBalance(STRATEGY1, USER1, address(erc20mock), 0);
        checkStrategyTokenBalance(STRATEGY2, USER1, address(erc20mock), 0);
        checkStrategyTokenBalance(STRATEGY3, USER1, address(erc20mock), 0);
        checkStrategyTokenBalance(STRATEGY4, USER2, address(erc20mock), 0);

        vm.stopPrank();
    }

    function test_CreateStrategyWithZeroFee() public {
        vm.startPrank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyCreated(STRATEGY1, USER1, 0, "");
        uint32 strategyId1 = proxiedManager.createStrategy(0, "");
        (, uint32 delegationFeeOnRewards) = proxiedManager.strategies(strategyId1);
        assertEq(delegationFeeOnRewards, 0, "Strategy fee");
        vm.stopPrank();
    }

    function testRevert_CreateStrategyWithTooHighFee() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyFee.selector));
        proxiedManager.createStrategy(10_001, "");
        vm.stopPrank();
    }

    function test_CreateStrategyAndSingleDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        test_CreateStrategies();
        vm.startPrank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyDeposit(STRATEGY1, USER1, address(erc20mock), amount);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, amount);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            amount,
            "User strategy balance should be the amount specified"
        );
        vm.stopPrank();
    }

    function testRevert_InvalidDepositWithZeroAmount() public {
        test_CreateStrategyAndSingleDeposit(1);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidAmount.selector));
        proxiedManager.depositERC20(STRATEGY1, erc20mock, 0);
        vm.stopPrank();
    }

    function test_CreateStrategyAndMultipleDeposits(uint256 deposit1S1, uint256 deposit2S1, uint256 deposit1S2) public {
        vm.assume(deposit1S1 > 0 && deposit1S1 < INITIAL_USER1_BALANCE_ERC20);
        vm.assume(deposit2S1 > 0 && deposit2S1 <= INITIAL_USER1_BALANCE_ERC20);
        vm.assume(
            deposit1S2 > 0 && deposit1S2 < INITIAL_USER1_BALANCE_ERC20 && deposit1S2 <= INITIAL_USER1_BALANCE_ERC20 - deposit1S1
        );
        test_CreateStrategies();
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, deposit1S1);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            deposit1S1,
            "Strategy1 balance should be the first deposit"
        );
        proxiedManager.depositERC20(STRATEGY2, erc20mock, deposit1S2);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY2, USER1, address(erc20mock)),
            deposit1S2,
            "Strategy2 balance should be the first deposit"
        );
        proxiedManager.depositERC20(STRATEGY1, erc20mock, deposit2S1);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            deposit1S1 + deposit2S1,
            "Strategy1 balance should be the sum of first and second deposit"
        );
        vm.stopPrank();
    }

    function test_CreateStrategyAndSingleDepositAndSingleWithdrawal() public {
        uint256 depositAmount = 100_000;
        uint256 withdrawalAmount = 50_000;
        test_CreateStrategies();
        vm.startPrank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyDeposit(STRATEGY1, USER1, address(erc20mock), depositAmount);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, depositAmount);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            100_000,
            "User strategy balance should be 100_000"
        );
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyWithdrawal(STRATEGY1, USER1, address(erc20mock), withdrawalAmount, true);
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, withdrawalAmount);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            50_000,
            "User strategy balance should be 50_000"
        );
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalNoAmount() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InsufficientBalance.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 50_000);
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalEth() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        proxiedManager.depositETH{value: 1 ether}(STRATEGY1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidToken.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, IERC20(ETH_ADDRESS), 50_000);
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalEthWithNonOwnerAddress() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(ATTACKER);
        proxiedManager.depositETH{value: 1 ether}(STRATEGY1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidToken.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, IERC20(ETH_ADDRESS), 50_000);
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalWithZeroAmount() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidAmount.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 0);
        vm.stopPrank();
    }

    function testRevert_InvalidProposeWithdrawalWithZeroAmount() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidAmount.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 0);
        vm.stopPrank();
    }

    function testRevert_InvalidProposeWithdrawalETHWithZeroAmount() public {
        test_CreateStrategyETHAndDepositETH();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidAmount.selector));
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 0);
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalWithInsufficientBalance() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InsufficientBalance.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 2000 * 10 ** 18);
        vm.stopPrank();
    }

    function testRevert_InvalidProposeWithdrawalWithInsufficientBalance() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InsufficientBalance.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 2000 * 10 ** 18);
        vm.stopPrank();
    }

    function testRevert_InvalidProposeWithdrawalETHWithInsufficientBalance() public {
        test_CreateStrategyETHAndDepositETH();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InsufficientBalance.selector));
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 2 ether);
        vm.stopPrank();
    }

    function test_CreateStrategyAndSingleDepositAndMultipleFastWithdrawals() public {
        test_CreateStrategies();
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, 100_000);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            100_000,
            "User strategy balance should be 100_000"
        );
        // There was no opt-in so the fast withdraw is allowed
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyWithdrawal(STRATEGY1, USER1, address(erc20mock), 50_000, true);
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 50_000);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyWithdrawal(STRATEGY1, USER1, address(erc20mock), 10_000, true);
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 10_000);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            40_000,
            "User strategy balance should be 50_000"
        );
        vm.stopPrank();
    }

    function test_StrategyOptInToBApp(uint32 percentage) public {
        vm.assume(percentage > 0 && percentage <= proxiedManager.MAX_PERCENTAGE());
        test_CreateStrategies();
        test_RegisterBApp();
        vm.startPrank(USER1);
        (address owner,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.BAppOptedInByStrategy(
                STRATEGY1, address(bApps[i]), abi.encodePacked("0x00"), tokensInput, obligationPercentagesInput
            );
            emit BasedAppMock.OptInToBApp(STRATEGY1, tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
            checkStrategyInfo(
                USER1, STRATEGY1, address(bApps[i]), address(erc20mock), percentage, proxiedManager, uint32(i) + 1, true
            );
        }
        uint32 counter = bApp1.counter();
        assertEq(counter, 1, "Counter should be 1");
        vm.stopPrank();
    }

    function test_StrategyRevertsSecondOptIn(uint32 percentage) public {
        vm.assume(percentage > 0 && percentage <= proxiedManager.MAX_PERCENTAGE());
        test_StrategyOptInToBApp(percentage);
        vm.startPrank(USER2);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppOptInFailed.selector));
        proxiedManager.optInToBApp(STRATEGY4, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        checkStrategyInfo(USER2, 0, address(bApp1), address(erc20mock), 0, proxiedManager, 0, false);
        uint32 counter = bApp1.counter();
        assertEq(counter, 1, "Counter should be 1 and not incremented");
        vm.stopPrank();
    }

    function test_optInToBAppWithNoTokensWithNoTokens() public {
        test_CreateStrategies();
        test_RegisterBAppWithNoTokens();
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.BAppOptedInByStrategy(
                STRATEGY1, address(bApps[i]), abi.encodePacked("0x00"), new address[](0), new uint32[](0)
            );
            proxiedManager.optInToBApp(STRATEGY1, address(bApps[i]), new address[](0), new uint32[](0), abi.encodePacked("0x00"));
            checkBAppInfo(new address[](0), new uint32[](0), address(bApps[i]), proxiedManager);
            checkStrategyInfo(USER1, STRATEGY1, address(bApps[i]), address(erc20mock), 0, proxiedManager, 0, false);
        }
        vm.stopPrank();
    }

    function test_StrategyWithTwoTokensOptInToBAppWithFiveTokens(uint32 percentage) public {
        vm.assume(percentage > 0 && percentage <= proxiedManager.MAX_PERCENTAGE());
        test_CreateStrategies();
        test_RegisterBAppWithFiveTokens();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](2);
        obligationPercentagesInput[0] = percentage;
        obligationPercentagesInput[1] = percentage;
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.BAppOptedInByStrategy(
            STRATEGY1, address(bApp1), abi.encodePacked("0x00"), tokensInput, obligationPercentagesInput
        );
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        checkStrategyInfo(USER1, STRATEGY1, address(bApp1), address(erc20mock), percentage, proxiedManager, 1, true);
        checkStrategyInfo(USER1, STRATEGY1, address(bApp1), address(erc20mock2), percentage, proxiedManager, 1, true);
        vm.stopPrank();
    }

    function testRevert_optInToBAppWithNoTokensWithAToken(uint32 percentage) public {
        test_CreateStrategies();
        test_RegisterBAppWithNoTokens();
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), percentage);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.TokenNoTSupportedByBApp.selector, address(erc20mock)));
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalWithUsedToken(uint32 amount) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        test_StrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, amount);
    }

    function test_StrategyOptInToBAppWithMultipleTokens(uint32 percentage) public {
        test_CreateStrategies();
        test_RegisterBAppWith2Tokens();
        vm.assume(percentage > 0 && percentage <= proxiedManager.MAX_PERCENTAGE());
        vm.startPrank(USER1);

        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), percentage);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.BAppOptedInByStrategy(
                STRATEGY1, address(bApps[i]), abi.encodePacked("0x00"), tokensInput, obligationPercentagesInput
            );
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
            checkStrategyInfo(
                USER1, STRATEGY1, address(bApps[i]), address(erc20mock), percentage, proxiedManager, uint32(i) + 1, true
            );
        }
        vm.stopPrank();
    }

    function testRevert_StrategyOptInToBAppWithMultipleTokensFailsPercentageOverMax() public {
        test_CreateStrategies();
        test_RegisterBAppWith2Tokens();
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), proxiedManager.MAX_PERCENTAGE() + 1);
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function test_StrategyOptInToBAppWithMultipleTokensWithPercentageZero() public {
        test_CreateStrategies();
        test_RegisterBAppWith2Tokens();
        vm.startPrank(USER1);
        uint32 percentage = 0;
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), percentage);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.BAppOptedInByStrategy(
                STRATEGY1, address(bApps[i]), abi.encodePacked("0x00"), tokensInput, obligationPercentagesInput
            );
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
            checkStrategyInfo(USER1, STRATEGY1, address(bApps[i]), address(erc20mock), percentage, proxiedManager, 0, true);
        }
        vm.stopPrank();
    }

    function test_StrategyOptInToBAppWithETH() public {
        test_CreateStrategies();
        test_RegisterBAppWithETH();
        vm.startPrank(USER1);
        uint32 percentage = proxiedManager.MAX_PERCENTAGE();
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(ETH_ADDRESS, percentage);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.BAppOptedInByStrategy(
                STRATEGY1, address(bApps[i]), abi.encodePacked("0x00"), tokensInput, obligationPercentagesInput
            );
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
            checkStrategyInfo(USER1, STRATEGY1, address(bApps[i]), ETH_ADDRESS, percentage, proxiedManager, uint32(i) + 1, true);
        }
        vm.stopPrank();
    }

    function testRevert_StrategyOptInWithNonOwner() public {
        test_CreateStrategies();
        test_RegisterBApp();
        uint32 percentage = 9000;
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), percentage);
        vm.startPrank(ATTACKER);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyOwner.selector, address(ATTACKER), address(USER1)));
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testRevert_StrategyOptInToBAppNonMatchingTokensAndObligations() public {
        test_CreateStrategies();
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = proxiedManager.MAX_PERCENTAGE(); // 100%
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.LengthsNotMatching.selector));
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testRevert_StrategyOptInToBAppNotAllowNonMatchingStrategyTokensWithBAppTokens() public {
        test_CreateStrategies();
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](2);
        obligationPercentagesInput[0] = 6000; // 60%
        obligationPercentagesInput[1] = 5000; // 50%
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function testRevert_StrategyAlreadyOptedIn(uint32 percentage) public {
        vm.assume(percentage > 0 && percentage <= proxiedManager.MAX_PERCENTAGE());
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        (address owner,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage; // 90%
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppAlreadyOptedIn.selector));
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
        }
        vm.stopPrank();
    }

    function test_StrategyOwnerDepositERC20WithNoObligation(uint256 amount) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyDeposit(STRATEGY1, USER1, address(erc20mock2), amount);
        proxiedManager.depositERC20(STRATEGY1, erc20mock2, amount);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, amount, "User strategy balance not matching");
        vm.stopPrank();
    }

    function test_StrategyOwnerDepositETHWithNoObligation() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyDeposit(STRATEGY1, USER1, ETH_ADDRESS, 1 ether);
        proxiedManager.depositETH{value: 1 ether}(STRATEGY1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(STRATEGY1, USER1, ETH_ADDRESS);
        assertEq(strategyTokenBalance, 1 ether, "User strategy balance not matching");
        vm.stopPrank();
    }

    function testRevert_StrategyOwnerDepositETHWithNoObligationRevertWithZeroAmount() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidAmount.selector));
        proxiedManager.depositETH{value: 0 ether}(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_ObligationNotMatchTokensBApp() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
            proxiedManager.createObligation(STRATEGY1, address(bApps[i]), address(erc20mock2), 100);
        }
        vm.stopPrank();
    }

    function test_CreateStrategyETHAndDepositETH() public {
        test_StrategyOptInToBAppWithETH();
        vm.startPrank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyDeposit(STRATEGY1, USER1, ETH_ADDRESS, 1 ether);
        proxiedManager.depositETH{value: 1 ether}(STRATEGY1);
        uint256 strategyETHBalance = proxiedManager.strategyTokenBalances(STRATEGY1, USER1, ETH_ADDRESS);
        assertEq(strategyETHBalance, 1 ether, "User strategy balance not matching");
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalETHWithUsedToken() public {
        test_CreateStrategyETHAndDepositETH();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawETH(STRATEGY1, 0.5 ether);
    }

    function testRevert_InvalidFastWithdrawalETHWithInvalidAmount() public {
        test_StrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InsufficientBalance.selector));
        proxiedManager.fastWithdrawETH(STRATEGY1, 100 ether);
    }

    function testRevert_ObligationHigherThanMaxPercentage() public {
        test_StrategyOptInToBApp(9000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
            proxiedManager.createObligation(STRATEGY1, address(bApps[i]), address(erc20mock), 10_001);
        }
    }

    function testRevert_CreateObligationToNonExistingBApp() public {
        test_StrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotOptedIn.selector));
        proxiedManager.createObligation(STRATEGY1, NON_EXISTENT_BAPP, address(erc20mock), 100);
    }

    function testRevert_CreateObligationToNonExistingStrategy() public {
        uint32 nonExistentStrategy = 333;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyOwner.selector, address(USER1), 0x00));
            proxiedManager.createObligation(nonExistentStrategy, address(bApps[i]), address(erc20mock), 100);
        }
    }

    function testRevert_CreateObligationToNotOwnedStrategy() public {
        test_CreateStrategies();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(ATTACKER);
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyOwner.selector, address(ATTACKER), address(USER1)));
            proxiedManager.createObligation(STRATEGY1, address(bApps[i]), address(erc20mock), 100);
        }
    }

    function testRevert_CreateObligationFailsBecauseAlreadySet() public {
        test_StrategyOptInToBAppWithMultipleTokens(9000);
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.ObligationAlreadySet.selector));
            proxiedManager.createObligation(STRATEGY1, address(bApps[i]), address(erc20mock), 100);
        }
        vm.stopPrank();
    }

    function test_CreateNewObligationSuccessful() public {
        test_StrategyOptInToBAppWithMultipleTokens(9000);
        vm.startPrank(USER1);
        uint32 percentage = 9500;
        address token = address(erc20mock2);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.ObligationCreated(STRATEGY1, address(bApps[i]), token, percentage);
            proxiedManager.createObligation(STRATEGY1, address(bApps[i]), token, percentage);
            checkObligationInfo(STRATEGY1, address(bApps[i]), token, percentage, uint32(i) + 1, true, proxiedManager);
        }
        vm.stopPrank();
    }

    function testRevert_CreateObligationFailCauseAlreadySet() public {
        test_CreateNewObligationSuccessful();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.ObligationAlreadySet.selector));
            proxiedManager.createObligation(STRATEGY1, address(bApps[i]), address(erc20mock2), 10_000);
        }
    }

    function test_FastWithdrawErc20FromStrategy() public {
        uint256 initialBalance = 200;
        uint256 withdrawalAmount = 50;
        test_StrategyOwnerDepositERC20WithNoObligation(200);
        checkStrategyTokenBalance(STRATEGY1, USER1, address(erc20mock2), initialBalance);
        vm.startPrank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyWithdrawal(STRATEGY1, USER1, address(erc20mock2), withdrawalAmount, true);
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock2, withdrawalAmount);
        checkStrategyTokenBalance(STRATEGY1, USER1, address(erc20mock2), initialBalance - withdrawalAmount);
        vm.stopPrank();
    }

    function test_WithdrawETHFromStrategy() public {
        test_StrategyOwnerDepositETHWithNoObligation();
        uint256 initialBalance = 1 ether;
        uint256 withdrawalAmount = 0.4 ether;
        vm.startPrank(USER1);
        checkStrategyTokenBalance(STRATEGY1, USER1, ETH_ADDRESS, initialBalance);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyWithdrawal(STRATEGY1, USER1, ETH_ADDRESS, withdrawalAmount, true);
        proxiedManager.fastWithdrawETH(STRATEGY1, withdrawalAmount);
        checkStrategyTokenBalance(STRATEGY1, USER1, ETH_ADDRESS, initialBalance - withdrawalAmount);
        vm.stopPrank();
    }

    function testRevert_WithdrawETHFromStrategyRevertWithZeroAmount() public {
        test_StrategyOwnerDepositETHWithNoObligation();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidAmount.selector));
        proxiedManager.fastWithdrawETH(STRATEGY1, 0 ether);
    }

    function test_FastUpdateObligation() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint32 percentage = 10_000;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.ObligationUpdated(STRATEGY1, address(bApps[i]), address(erc20mock), percentage, true);
            proxiedManager.fastUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock), percentage);
            checkObligationInfo(
                STRATEGY1, address(bApps[i]), address(erc20mock), percentage, uint32(bApps.length), true, proxiedManager
            );
        }
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationBAppNotOptedIn() public {
        test_CreateStrategies();
        test_RegisterBApp();
        uint32 percentage = 10_000;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotOptedIn.selector));
            proxiedManager.fastUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock), percentage);
        }
    }

    function testRevert_FastUpdateObligationFailWithNonOwner() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(ATTACKER);
        uint32 percentage = 10_000;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
            proxiedManager.fastUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock), percentage);
        }
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithWrongHighPercentages(uint32 obligationPercentage) public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.assume(obligationPercentage > 10_000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
            proxiedManager.fastUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock), obligationPercentage);
        }
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithZeroPercentages(uint32 obligationPercentage) public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.assume(obligationPercentage > 0 && obligationPercentage <= 9000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
            proxiedManager.fastUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock), obligationPercentage);
        }
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithPercentageLowerThanCurrent() public {
        test_StrategyOptInToBApp(9000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
            proxiedManager.fastUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock), 0);
        }
    }

    function testRevert_StrategyFeeUpdateFailsWithNonOwner(uint32 fee) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(fee > 0 && fee <= proxiedManager.MAX_PERCENTAGE());
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
    }

    function testRevert_StrategyFeeUpdateFailsWithNoProposal() public {
        test_StrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingFeeUpdate.selector));
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
    }

    function testRevert_StrategyFeeUpdateFailsWithOverLimitFee(uint32 fee) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(fee > proxiedManager.MAX_PERCENTAGE());
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
    }

    function testRevert_StrategyFeeUpdateFailsWithOverLimitIncrement(uint32 proposedFee) public {
        test_StrategyOptInToBApp(9000);
        (, uint32 fee) = proxiedManager.strategies(STRATEGY1);
        vm.assume(proposedFee < proxiedManager.MAX_PERCENTAGE() && proposedFee > fee + proxiedManager.maxFeeIncrement());
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentageIncrement.selector));
        proxiedManager.proposeFeeUpdate(STRATEGY1, proposedFee);
    }

    function testRevert_StrategyFeeUpdateFailsWithSameFeeValue() public {
        test_StrategyOptInToBApp(9000);
        (, uint32 fee) = proxiedManager.strategies(STRATEGY1);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.FeeAlreadySet.selector));
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
    }

    function test_StrategyProposeFeeUpdate() public returns (uint32 proposedFee) {
        test_StrategyOptInToBApp(9000);
        proposedFee = 20;
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyFeeUpdateProposed(STRATEGY1, USER1, proposedFee);
        proxiedManager.proposeFeeUpdate(STRATEGY1, proposedFee);
        checkProposedFee(STRATEGY1, USER1, STRATEGY1_INITIAL_FEE, proposedFee, 1);
        return proposedFee;
    }

    function test_StrategyFeeUpdate(uint256 timeBeforeLimit) public {
        vm.assume(timeBeforeLimit < proxiedManager.FEE_EXPIRE_TIME());
        uint32 proposedFee = test_StrategyProposeFeeUpdate();
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD() + timeBeforeLimit);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyFeeUpdated(STRATEGY1, USER1, proposedFee);
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        checkProposedFee(STRATEGY1, USER1, proposedFee, 0, 0);
    }

    function testRevert_StrategyFeeUpdateTooLate(uint256 timeAfterLimit) public {
        vm.assume(timeAfterLimit > proxiedManager.FEE_EXPIRE_TIME() && timeAfterLimit < 100 * 365 days);
        test_StrategyProposeFeeUpdate();
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD() + timeAfterLimit);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.RequestTimeExpired.selector));
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
    }

    function testRevert_StrategyFeeUpdateTooEarly() public {
        test_StrategyProposeFeeUpdate();
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD() - 1 seconds);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
    }

    function test_StrategyFastFeeUpdate() public {
        test_StrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyFeeUpdated(STRATEGY1, USER1, 1);
        proxiedManager.fastUpdateFee(STRATEGY1, 1);
        checkFee(STRATEGY1, USER1, 1);
    }

    function testRevert_StrategyFastFeeUpdateInvalidPercentage() public {
        test_StrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentageIncrement.selector));
        proxiedManager.fastUpdateFee(STRATEGY1, 100);
    }

    function testRevert_ProposeUpdateObligationWithNonOwner() public {
        test_StrategyOptInToBApp(9000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(ATTACKER);
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
            proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock), 1000);
        }
    }

    function testRevert_ProposeUpdateObligationWithTooHighPercentage(uint32 obligationPercentage) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(obligationPercentage > 10_000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
            proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock), obligationPercentage);
        }
    }

    function testRevert_FinalizeFeeUpdateWithWrongOwner() public {
        test_StrategyProposeFeeUpdate();
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD());
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
    }

    function test_proposeStrategyObligationPercentage(uint32 initialObligationPercentage, uint32 proposedObligationPercentage)
        public
    {
        vm.assume(
            initialObligationPercentage > 0 && initialObligationPercentage <= proxiedManager.MAX_PERCENTAGE()
                && proposedObligationPercentage >= 0 && proposedObligationPercentage <= proxiedManager.MAX_PERCENTAGE()
                && proposedObligationPercentage != initialObligationPercentage
        );

        test_StrategyOptInToBApp(initialObligationPercentage);

        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.ObligationUpdateProposed(
                STRATEGY1, address(bApps[i]), address(erc20mock), proposedObligationPercentage
            );
            proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock), proposedObligationPercentage);
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

    function test_UpdateStrategyObligationFinalizeOnInitialLimit() public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        test_proposeStrategyObligationPercentage(initialObligationPercentage, proposedObligationPercentage);
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.ObligationUpdated(
                STRATEGY1, address(bApps[i]), address(erc20mock), proposedObligationPercentage, false
            );
            proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock));
            checkProposedObligation(STRATEGY1, address(bApps[i]), address(erc20mock), proposedObligationPercentage, 0, 0, true);
        }
    }

    function test_UpdateStrategyObligationFinalizeOnLatestLimit() public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        test_proposeStrategyObligationPercentage(initialObligationPercentage, proposedObligationPercentage);
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + proxiedManager.OBLIGATION_EXPIRE_TIME());
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.ObligationUpdated(
                STRATEGY1, address(bApps[i]), address(erc20mock), proposedObligationPercentage, false
            );
            proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock));
            checkProposedObligation(STRATEGY1, address(bApps[i]), address(erc20mock), proposedObligationPercentage, 0, 0, true);
        }
    }

    function test_UpdateStrategyObligationFinalizeWithZeroValue() public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 0;
        test_proposeStrategyObligationPercentage(initialObligationPercentage, proposedObligationPercentage);

        vm.startPrank(USER1);
        uint32 usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock));
        assertEq(usedTokens, bApps.length, "Used tokens");

        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + proxiedManager.OBLIGATION_EXPIRE_TIME());
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.ObligationUpdated(
                STRATEGY1, address(bApps[i]), address(erc20mock), proposedObligationPercentage, false
            );
            proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock));
            checkProposedObligation(STRATEGY1, address(bApps[i]), address(erc20mock), proposedObligationPercentage, 0, 0, true);
        }
        usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock));
        assertEq(usedTokens, 0, "Used tokens");
        vm.stopPrank();
    }

    function testRevert_UpdateStrategyObligationFinalizeTooLate(uint256 timeAfterLimit) public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        test_proposeStrategyObligationPercentage(initialObligationPercentage, proposedObligationPercentage);
        vm.assume(timeAfterLimit > proxiedManager.OBLIGATION_EXPIRE_TIME() && timeAfterLimit < 100 * 365 days);
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + timeAfterLimit);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.RequestTimeExpired.selector));
            proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock));
        }
    }

    function testRevert_UpdateStrategyObligationFinalizeTooEarly(uint256 timeToLimit) public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        test_proposeStrategyObligationPercentage(initialObligationPercentage, proposedObligationPercentage);
        vm.assume(timeToLimit > 0 && timeToLimit < proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() - timeToLimit);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
            proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock));
        }
    }

    function testRevert_UpdateStrategyObligationWithNonOwner() public {
        uint32 initialObligationPercentage = 9000;
        uint32 proposedObligationPercentage = 1000;
        test_proposeStrategyObligationPercentage(initialObligationPercentage, proposedObligationPercentage);
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(ATTACKER);
            vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
            proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock));
        }
    }

    function testRevert_FinalizeUpdateObligationFailWithNoPendingRequest() public {
        uint32 initialObligationPercentage = 9000;
        test_StrategyOptInToBApp(initialObligationPercentage);
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingObligationUpdate.selector));
            proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock));
        }
        vm.stopPrank();
    }

    function test_ProposeWithdrawalFromStrategy()
        public
        returns (uint256 withdrawalAmount, IERC20 token, uint256 currentBalance)
    {
        test_CreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        withdrawalAmount = 1000;
        token = erc20mock;
        currentBalance = 120_000;
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyWithdrawalProposed(STRATEGY1, USER1, address(token), withdrawalAmount);
        vm.prank(USER1);
        proxiedManager.proposeWithdrawal(STRATEGY1, address(token), withdrawalAmount);
        checkStrategyTokenBalance(STRATEGY1, USER1, address(token), currentBalance);
        checkProposedWithdrawal(STRATEGY1, USER1, address(token), block.timestamp, withdrawalAmount);
    }

    function test_FinalizeWithdrawFromStrategy() public {
        (uint256 withdrawalAmount, IERC20 token, uint256 currentBalance) = test_ProposeWithdrawalFromStrategy();
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD());
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyWithdrawal(STRATEGY1, USER1, address(token), withdrawalAmount, false);
        vm.prank(USER1);
        proxiedManager.finalizeWithdrawal(STRATEGY1, token);
        checkStrategyTokenBalance(STRATEGY1, USER1, address(token), currentBalance - withdrawalAmount);
        checkProposedWithdrawal(STRATEGY1, USER1, address(token), 0, 0);
    }

    function testRevert_AsyncWithdrawFromStrategyOnlyFinalize() public {
        test_CreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingWithdrawal.selector));
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
    }

    function test_ProposeWithdrawalETHFromStrategy(uint256 withdrawalAmount) public returns (uint256 currentBalance) {
        test_CreateStrategyETHAndDepositETH();
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        currentBalance = 1 ether;
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyWithdrawalProposed(STRATEGY1, USER1, ETH_ADDRESS, withdrawalAmount);
        vm.prank(USER1);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, withdrawalAmount);
        checkStrategyTokenBalance(STRATEGY1, USER1, ETH_ADDRESS, currentBalance);
        checkProposedWithdrawal(STRATEGY1, USER1, ETH_ADDRESS, block.timestamp, withdrawalAmount);
    }

    function test_AsyncWithdrawETHFromStrategy(uint256 withdrawalAmount) public {
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        uint256 currentBalance = test_ProposeWithdrawalETHFromStrategy(withdrawalAmount);
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD());
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategyWithdrawal(STRATEGY1, USER1, ETH_ADDRESS, withdrawalAmount, false);
        vm.prank(USER1);
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        checkStrategyTokenBalance(STRATEGY1, USER1, ETH_ADDRESS, currentBalance - withdrawalAmount);
        checkProposedWithdrawal(STRATEGY1, USER1, ETH_ADDRESS, 0, 0);
    }

    function testRevert_AsyncWithdrawETHFromStrategyOnlyFinalize() public {
        test_CreateStrategyETHAndDepositETH();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingWithdrawalETH.selector));
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
    }

    function testRevert_AsyncWithdrawETHFromStrategyWithMadeUpToken() public {
        test_CreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InsufficientBalance.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, address(1), 1000);
    }

    function testRevert_AsyncFailedWithdrawETHFromStrategyTooEarly(uint256 withdrawalAmount) public {
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        test_ProposeWithdrawalETHFromStrategy(withdrawalAmount);
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() - 1 seconds);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
    }

    function testRevert_AsyncFailedWithdrawETHFromStrategyTooLate(uint256 withdrawalAmount) public {
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        test_ProposeWithdrawalETHFromStrategy(withdrawalAmount);
        vm.warp(
            block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() + proxiedManager.WITHDRAWAL_EXPIRE_TIME() + 1 seconds
        );
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.RequestTimeExpired.selector));
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
    }

    function testRevert_AsyncFailedWithdrawFromStrategyETHInsteadOfERC20(uint256 withdrawalAmount) public {
        test_CreateStrategyETHAndDepositETH();
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidToken.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, ETH_ADDRESS, withdrawalAmount);
        vm.stopPrank();
    }

    function testRevert_AsyncFailedWithdrawFromStrategyTooEarly() public {
        test_ProposeWithdrawalFromStrategy();
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() - 1 seconds);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        vm.stopPrank();
    }

    function testRevert_AsyncFailedWithdrawFromStrategyTooLate() public {
        test_ProposeWithdrawalFromStrategy();
        vm.warp(
            block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() + proxiedManager.WITHDRAWAL_EXPIRE_TIME() + 1 seconds
        );
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.RequestTimeExpired.selector));
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
    }

    function test_CreateObligationETH(uint32 percentage) public {
        vm.assume(percentage > 0 && percentage <= proxiedManager.MAX_PERCENTAGE());
        test_CreateStrategies();
        test_RegisterBAppWithETHAndErc20();
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), percentage);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.BAppOptedInByStrategy(
                STRATEGY1, address(bApps[i]), abi.encodePacked("0x00"), tokensInput, obligationPercentagesInput
            );
            proxiedManager.optInToBApp(1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
            checkObligationInfo(STRATEGY1, address(bApps[i]), address(erc20mock), percentage, uint32(i) + 1, true, proxiedManager);

            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.ObligationCreated(STRATEGY1, address(bApps[i]), ETH_ADDRESS, proxiedManager.MAX_PERCENTAGE());
            proxiedManager.createObligation(STRATEGY1, address(bApps[i]), ETH_ADDRESS, proxiedManager.MAX_PERCENTAGE());
            checkObligationInfo(
                STRATEGY1, address(bApps[i]), ETH_ADDRESS, proxiedManager.MAX_PERCENTAGE(), uint32(i) + 1, true, proxiedManager
            );
        }

        vm.stopPrank();
    }

    function test_CreateObligationETHWithZeroPercentage() public {
        test_CreateStrategies();
        test_RegisterBAppWithETHAndErc20();
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), 0);

        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.BAppOptedInByStrategy(
                STRATEGY1, address(bApps[i]), abi.encodePacked("0x00"), tokensInput, obligationPercentagesInput
            );
            proxiedManager.optInToBApp(1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
            checkObligationInfo(STRATEGY1, address(bApps[i]), address(erc20mock), 0, 0, true, proxiedManager);

            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.ObligationCreated(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 0);
            proxiedManager.createObligation(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 0);
            checkObligationInfo(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 0, 0, true, proxiedManager);
        }
        vm.stopPrank();
    }

    function test_updateObligationFromZeroToHigher() public {
        test_CreateObligationETHWithZeroPercentage();
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 5000);
            vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
            proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApps[i]), ETH_ADDRESS);
            checkObligationInfo(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 5000, uint32(i) + 1, true, proxiedManager);
        }
        vm.stopPrank();
    }

    function test_fastUpdateObligationETHFromZeroToHigher() public {
        test_CreateObligationETHWithZeroPercentage();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit(true, true, true, true);
            emit ISSVBasedApps.ObligationUpdated(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 5000, true);
            proxiedManager.fastUpdateObligation(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 5000);
            checkObligationInfo(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 5000, uint32(i) + 1, true, proxiedManager);
        }
    }

    function testRevert_proposeUpdateObligationWithBAppNotOptedIN() public {
        test_CreateStrategies();
        test_RegisterBApp();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotOptedIn.selector));
            proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 5000);
        }
    }

    function testRevert_proposeUpdateObligationWithSamePercentage() public {
        test_CreateObligationETH(10_000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);

            vm.expectRevert(abi.encodeWithSelector(IStorage.ObligationAlreadySet.selector));
            proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApps[i]), ETH_ADDRESS, 10_000);
        }
    }

    function testRevert_proposeUpdateObligationNotCreated() public {
        test_CreateObligationETH(10_000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);

            vm.expectRevert(abi.encodeWithSelector(IStorage.ObligationHasNotBeenCreated.selector));
            proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock2), 8000);
        }
    }

    function testRevert_fastUpdateObligationNotCreated() public {
        test_CreateObligationETH(10_000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.ObligationHasNotBeenCreated.selector));
            proxiedManager.fastUpdateObligation(STRATEGY1, address(bApps[i]), address(erc20mock2), 10_000);
        }
    }

    function test_UpdateStrategyMetadata() public {
        test_CreateStrategies();
        string memory metadataURI = "https://metadata.com";
        vm.startPrank(USER1);
        vm.expectEmit(true, false, false, false);
        emit ISSVBasedApps.StrategyMetadataURIUpdated(STRATEGY1, metadataURI);
        proxiedManager.updateStrategyMetadataURI(STRATEGY1, metadataURI);
        vm.stopPrank();
    }

    function testRevert_UpdateStrategyMetadataWithWrongOwner() public {
        test_CreateStrategies();
        string memory metadataURI = "https://metadata-attacker.com";
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidStrategyOwner.selector, address(ATTACKER), address(USER1)));
        proxiedManager.updateStrategyMetadataURI(STRATEGY1, metadataURI);
        vm.stopPrank();
    }

    function test_updateUsedTokensCorrectly() public {
        test_CreateNewObligationSuccessful();
        vm.startPrank(USER1);
        address TOKEN = address(erc20mock2);

        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), TOKEN, 9700);
        checkObligationInfo(STRATEGY1, address(bApp1), TOKEN, 9700, uint32(bApps.length), true, proxiedManager);

        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), TOKEN, 0);
        checkProposedObligation(STRATEGY1, address(bApp1), TOKEN, 9700, 0, block.timestamp, true);
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), TOKEN);
        checkProposedObligation(STRATEGY1, address(bApp1), TOKEN, 0, 0, 0, true);
        checkObligationInfo(STRATEGY1, address(bApp1), TOKEN, 0, uint32(bApps.length) - 1, true, proxiedManager);

        vm.expectRevert(abi.encodeWithSelector(IStorage.ObligationAlreadySet.selector));
        proxiedManager.createObligation(STRATEGY1, address(bApp1), TOKEN, 1000);
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), TOKEN, 1000);
        checkObligationInfo(STRATEGY1, address(bApp1), TOKEN, 1000, uint32(bApps.length), true, proxiedManager);
        vm.stopPrank();
    }

    function test_UpdateUsedTokens() public {
        uint32 percentage = 10_000;
        test_CreateStrategies();
        test_RegisterBAppWith2Tokens();
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), 100_000);
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), percentage);
        proxiedManager.optInToBApp(STRATEGY1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        proxiedManager.optInToBApp(STRATEGY1, address(bApp2), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, STRATEGY1, "Strategy id");
        strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp2));
        assertEq(strategyId, STRATEGY1, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(strategyId, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 2, "Used tokens");
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp2), address(erc20mock), 0);
        usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 2, "Used tokens");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp2), address(erc20mock));
        usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, IERC20(erc20mock), 1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 0);
        usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock));
        usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 0, "Used tokens");
        proxiedManager.fastWithdrawERC20(STRATEGY1, IERC20(erc20mock), 1);
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp2), address(erc20mock), 1);
        usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp2), address(erc20mock), 2);
        usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 1);
        usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 2, "Used tokens");
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 2);
        usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 2, "Used tokens");
        vm.stopPrank();
    }

    function test_UpdateUsedTokensETH() public {
        uint32 percentage = 10_000;
        test_CreateStrategies();
        test_RegisterBAppWithETH();
        vm.startPrank(USER1);
        proxiedManager.depositETH{value: 1 ether}(STRATEGY1);
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(ETH_ADDRESS, percentage);

        proxiedManager.optInToBApp(STRATEGY1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        checkObligationInfo(STRATEGY1, address(bApp1), ETH_ADDRESS, percentage, 1, true, proxiedManager);

        proxiedManager.optInToBApp(STRATEGY1, address(bApp2), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        checkObligationInfo(STRATEGY1, address(bApp2), ETH_ADDRESS, percentage, 2, true, proxiedManager);

        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp2), ETH_ADDRESS, 0);
        checkObligationInfo(STRATEGY1, address(bApp2), ETH_ADDRESS, percentage, 2, true, proxiedManager);

        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());

        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp2), ETH_ADDRESS);
        checkObligationInfo(STRATEGY1, address(bApp2), ETH_ADDRESS, 0, 1, true, proxiedManager);

        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawETH(STRATEGY1, 1);

        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, 0);
        checkObligationInfo(STRATEGY1, address(bApp1), ETH_ADDRESS, percentage, 1, true, proxiedManager);

        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());

        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS);
        checkObligationInfo(STRATEGY1, address(bApp1), ETH_ADDRESS, 0, 0, true, proxiedManager);
        checkObligationInfo(STRATEGY1, address(bApp2), ETH_ADDRESS, 0, 0, true, proxiedManager);

        proxiedManager.fastWithdrawETH(STRATEGY1, 1);
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp2), ETH_ADDRESS, 1);
        checkObligationInfo(STRATEGY1, address(bApp2), ETH_ADDRESS, 1, 1, true, proxiedManager);
        checkObligationInfo(STRATEGY1, address(bApp1), ETH_ADDRESS, 0, 1, true, proxiedManager);

        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp2), ETH_ADDRESS, 2);
        checkObligationInfo(STRATEGY1, address(bApp2), ETH_ADDRESS, 2, 1, true, proxiedManager);

        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, 1);
        checkObligationInfo(STRATEGY1, address(bApp1), ETH_ADDRESS, 1, 2, true, proxiedManager);

        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, 2);
        checkObligationInfo(STRATEGY1, address(bApp1), ETH_ADDRESS, 2, 2, true, proxiedManager);

        vm.stopPrank();
    }

    function test_advancedWithdrawalFlow() public {
        uint32 percentage = 0;
        test_CreateStrategies();
        test_RegisterBAppWith2Tokens();
        vm.prank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), 100_000);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), 200_000);
        assertEq(proxiedManager.strategyTokenBalances(STRATEGY1, USER2, address(erc20mock)), 200_000);
        assertEq(proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)), 100_000);
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), percentage);
        vm.prank(USER1);
        proxiedManager.optInToBApp(STRATEGY1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        vm.prank(USER2);
        proxiedManager.fastWithdrawERC20(STRATEGY1, IERC20(erc20mock), 110_000);
        vm.prank(USER1);
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 10_000);
        vm.prank(USER2);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, IERC20(erc20mock), 90_000);
        vm.startPrank(USER2);
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 80_000);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(erc20mock));
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD());
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(erc20mock));
        assertEq(proxiedManager.strategyTokenBalances(STRATEGY1, USER2, address(erc20mock)), 10_000);
        assertEq(proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)), 100_000);
        vm.stopPrank();
    }

    function test_advancedWithdrawalFlowETH() public {
        uint32 percentage = 0;
        test_CreateStrategies();
        test_RegisterBAppWithETH();
        vm.prank(USER1);
        proxiedManager.depositETH{value: 1 ether}(STRATEGY1);
        vm.prank(USER2);
        proxiedManager.depositETH{value: 2 ether}(STRATEGY1);
        assertEq(proxiedManager.strategyTokenBalances(STRATEGY1, USER2, ETH_ADDRESS), 2 ether);
        assertEq(proxiedManager.strategyTokenBalances(STRATEGY1, USER1, ETH_ADDRESS), 1 ether);
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(ETH_ADDRESS, percentage);
        vm.prank(USER1);
        proxiedManager.optInToBApp(STRATEGY1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        vm.prank(USER2);
        proxiedManager.fastWithdrawETH(STRATEGY1, 5 * 10 ** 17);
        vm.prank(USER1);
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, 10_000);
        vm.prank(USER2);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawETH(STRATEGY1, 90_000);
        vm.startPrank(USER2);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 10 ** 18);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD());
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        assertEq(proxiedManager.strategyTokenBalances(STRATEGY1, USER2, ETH_ADDRESS), 0.5 ether);
        assertEq(proxiedManager.strategyTokenBalances(STRATEGY1, USER1, ETH_ADDRESS), 1 ether);
        vm.stopPrank();
    }

    function test_tokenRemovalWithActiveObligations() public {
        uint32 percentage = 10_000;
        test_CreateStrategies();
        test_RegisterBAppWith2Tokens();
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), 100_000);
        (address[] memory tokensInput, uint32[] memory obligationPercentagesInput) =
            createSingleTokenAndSingleObligationPercentage(address(erc20mock), percentage);
        for (uint256 i = 0; i < bApps.length; i++) {
            proxiedManager.optInToBApp(
                STRATEGY1, address(bApps[i]), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00")
            );
        }
        bApp1.proposeBAppTokensRemoval(tokensInput);
        vm.warp(block.timestamp + proxiedManager.TOKEN_REMOVAL_TIMELOCK_PERIOD());
        bApp1.finalizeBAppTokensRemoval();
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, IERC20(erc20mock), 100_000);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp2), address(erc20mock), 0);
        uint32 usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock));
        assertEq(usedTokens, bApps.length, "Used tokens");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp2), address(erc20mock));
        usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock));
        assertEq(usedTokens, bApps.length - 1, "Used tokens");
        vm.stopPrank();
    }
}
