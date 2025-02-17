// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "./BAppManager.setup.t.sol";
import "./BAppManager.bapp.t.sol";

contract BasedAppManagerStrategyTest is BasedAppManagerSetupTest, BasedAppManagerBAppTest {
    function test_CreateStrategies() public {
        vm.startPrank(USER1);
        erc20mock.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);
        uint32 strategyId1 = proxiedManager.createStrategy(STRATEGY1_INITIAL_FEE, "");
        proxiedManager.createStrategy(STRATEGY2_INITIAL_FEE, "");
        proxiedManager.createStrategy(STRATEGY3_INITIAL_FEE, "");
        uint32 strategyId4 = proxiedManager.createStrategy(proxiedManager.MAX_PERCENTAGE(), "");
        assertEq(strategyId1, STRATEGY1, "Strategy id 1 was saved correctly");
        assertEq(strategyId4, STRATEGY4, "Strategy id 4 was saved correctly");
        (address owner, uint32 delegationFeeOnRewards,,) = proxiedManager.strategies(strategyId1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(delegationFeeOnRewards, STRATEGY1_INITIAL_FEE, "Strategy fee");
        vm.stopPrank();
    }

    function test_CreateStrategyWithZeroFee() public {
        vm.startPrank(USER1);
        uint32 strategyId1 = proxiedManager.createStrategy(0, "");
        (, uint32 delegationFeeOnRewards,,) = proxiedManager.strategies(strategyId1);
        assertEq(delegationFeeOnRewards, 0, "Strategy fee");
        vm.stopPrank();
    }

    function testRevert_CreateStrategyWithTooHighFee() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyFee.selector));
        proxiedManager.createStrategy(10_001, "");
        vm.stopPrank();
    }

    function test_CreateStrategyAndSingleDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        test_CreateStrategies();
        vm.startPrank(USER1);
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
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAmount.selector));
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
        test_CreateStrategies();
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, erc20mock, 100_000);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            100_000,
            "User strategy balance should be 100_000"
        );
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 50_000);
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
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 50_000);
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalEth() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        proxiedManager.depositETH{value: 1 ether}(STRATEGY1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidToken.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, IERC20(ETH_ADDRESS), 50_000);
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalEthWithNonOwnerAddress() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(ATTACKER);
        proxiedManager.depositETH{value: 1 ether}(STRATEGY1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidToken.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, IERC20(ETH_ADDRESS), 50_000);
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalWithZeroAmount() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAmount.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 0);
        vm.stopPrank();
    }

    function testRevert_InvalidProposeWithdrawalWithZeroAmount() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAmount.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 0);
        vm.stopPrank();
    }

    function testRevert_InvalidProposeWithdrawalETHWithZeroAmount() public {
        test_CreateStrategyETHAndDepositETH();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAmount.selector));
        proxiedManager.proposeWithdrawalETH(STRATEGY1, 0);
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalWithInsufficientBalance() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 2000 * 10 ** 18);
        vm.stopPrank();
    }

    function testRevert_InvalidProposeWithdrawalWithInsufficientBalance() public {
        test_CreateStrategyAndSingleDepositAndSingleWithdrawal();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 2000 * 10 ** 18);
        vm.stopPrank();
    }

    function testRevert_InvalidProposeWithdrawalETHWithInsufficientBalance() public {
        test_CreateStrategyETHAndDepositETH();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
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
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, 50_000);
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
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        vm.expectEmit(true, true, true, true);
        emit BasedAppMock.OptInToBApp(STRATEGY1, abi.encodePacked("0x00"));
        proxiedManager.optInToBApp(STRATEGY1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, 1, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(strategyId, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 counter = bApp1.counter();
        assertEq(counter, 1, "Counter should be 1");
        vm.stopPrank();
    }

    function test_optInToBAppWithNoTokensWithNoTokens() public {
        test_CreateStrategies();
        test_RegisterBAppWithNoTokens();
        vm.startPrank(USER1);
        proxiedManager.optInToBApp(STRATEGY1, address(bApp1), new address[](0), new uint32[](0), abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, STRATEGY1, "Strategy id");
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
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, 1, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(strategyId, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint256 usedTokens2 = proxiedManager.usedTokens(strategyId, address(erc20mock2));
        assertEq(usedTokens2, 1, "Used tokens");
        vm.stopPrank();
    }

    function testRevert_optInToBAppWithNoTokensWithAToken() public {
        test_CreateStrategies();
        test_RegisterBAppWithNoTokens();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 10;
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenNoTSupportedByBApp.selector, address(erc20mock)));
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalWithUsedToken(uint32 amount) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, amount);
        vm.stopPrank();
    }

    function test_StrategyOptInToBAppWithMultipleTokens(uint32 percentage) public {
        test_CreateStrategies();
        test_RegisterBAppWith2Tokens();
        vm.assume(percentage > 0 && percentage <= proxiedManager.MAX_PERCENTAGE());
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, 1, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(strategyId, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        vm.stopPrank();
    }

    function testRevert_StrategyOptInToBAppWithMultipleTokensFailsPercentageOverMax() public {
        test_CreateStrategies();
        test_RegisterBAppWith2Tokens();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = proxiedManager.MAX_PERCENTAGE() + 1; // 100.01%
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        vm.stopPrank();
    }

    function test_StrategyOptInToBAppWithMultipleTokensWithPercentageZero() public {
        test_CreateStrategies();
        test_RegisterBAppWith2Tokens();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 0; // 0%
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, 1, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(strategyId, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, 0, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 0, "Used tokens");
        vm.stopPrank();
    }

    function test_StrategyOptInToBAppWithETH() public {
        test_CreateStrategies();
        test_RegisterBAppWithETH();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = ETH_ADDRESS;
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = proxiedManager.MAX_PERCENTAGE(); // 100%
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, 1, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(strategyId, address(bApp1), ETH_ADDRESS);
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, proxiedManager.MAX_PERCENTAGE(), "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, ETH_ADDRESS);
        assertEq(usedTokens, 1, "Used tokens");
        vm.stopPrank();
    }

    function testRevert_StrategyOptInWithNonOwner() public {
        test_CreateStrategies();
        test_RegisterBApp();
        vm.startPrank(ATTACKER);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 9000; // 90%
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), owner));
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        vm.stopPrank();
    }

    function testRevert_StrategyOptInToBAppNonMatchingTokensAndObligations() public {
        test_CreateStrategies();
        test_RegisterBApp();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = proxiedManager.MAX_PERCENTAGE(); // 100%
        vm.expectRevert(abi.encodeWithSelector(ICore.LengthsNotMatching.selector));
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        vm.stopPrank();
    }

    function testRevert_StrategyOptInToBAppNotAllowNonMatchingStrategyTokensWithBAppTokens() public {
        test_CreateStrategies();
        test_RegisterBApp();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](2);
        obligationPercentagesInput[0] = 6000; // 60%
        obligationPercentagesInput[1] = 5000; // 50%
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, 0, "Strategy id was not saved");
        vm.stopPrank();
    }

    function testRevert_StrategyAlreadyOptedIn(uint32 percentage) public {
        vm.assume(percentage > 0 && percentage <= proxiedManager.MAX_PERCENTAGE());
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage; // 90%
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyOptedIn.selector));
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        vm.stopPrank();
    }

    function testRevert_CreateObligationToExistingStrategyRevert() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address tokensInput = address(erc20mock2);
        uint32 obligationPercentagesInput = 7000; // 70%
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppNotOptedIn.selector));
        proxiedManager.createObligation(1, BAPP2, tokensInput, obligationPercentagesInput);
        vm.stopPrank();
    }

    function test_StrategyOwnerDepositERC20WithNoObligation(uint256 amount) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        proxiedManager.depositERC20(1, erc20mock2, amount);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, amount, "User strategy balance not matching");
        vm.stopPrank();
    }

    function test_StrategyOwnerDepositETHWithNoObligation() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        proxiedManager.depositETH{value: 1 ether}(1);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, ETH_ADDRESS);
        assertEq(strategyTokenBalance, 1 ether, "User strategy balance not matching");
        vm.stopPrank();
    }

    function testRevert_StrategyOwnerDepositETHWithNoObligationRevertWithZeroAmount() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAmount.selector));
        proxiedManager.depositETH{value: 0 ether}(1);
        vm.stopPrank();
    }

    function testRevert_ObligationNotMatchTokensBApp() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
        proxiedManager.createObligation(1, address(bApp1), address(erc20mock2), 100);
        vm.stopPrank();
    }

    function test_CreateStrategyETHAndDepositETH() public {
        test_StrategyOptInToBAppWithETH();
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        proxiedManager.depositETH{value: 1 ether}(1);
        uint256 strategyETHBalance = proxiedManager.strategyTokenBalances(1, USER1, ETH_ADDRESS);
        assertEq(strategyETHBalance, 1 ether, "User strategy balance not matching");
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalETHWithUsedToken() public {
        test_CreateStrategyETHAndDepositETH();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawETH(STRATEGY1, 0.5 ether);
    }

    function testRevert_InvalidFastWithdrawalETHWithInvalidAmount() public {
        test_StrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.fastWithdrawETH(STRATEGY1, 100 ether);
    }

    function testRevert_ObligationHigherThanMaxPercentage() public {
        test_StrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.createObligation(1, address(bApp1), address(erc20mock), 10_001);
    }

    function testRevert_CreateObligationToNonExistingBApp() public {
        test_StrategyOptInToBApp(9000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppNotOptedIn.selector));
        proxiedManager.createObligation(1, BAPP2, address(erc20mock), 100);
    }

    function testRevert_CreateObligationToNonExistingStrategy() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(USER1), 0x00));
        proxiedManager.createObligation(3, address(bApp1), address(erc20mock), 100);
    }

    function testRevert_CreateObligationToNotOwnedStrategy() public {
        test_CreateStrategies();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), address(USER1)));
        proxiedManager.createObligation(1, address(bApp1), address(erc20mock), 100);
    }

    function testRevert_CreateObligationFailsBecauseAlreadySet() public {
        test_StrategyOptInToBAppWithMultipleTokens(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.ObligationAlreadySet.selector));
        proxiedManager.createObligation(1, address(bApp1), address(erc20mock), 100);
        vm.stopPrank();
    }

    function test_CreateNewObligationSuccessful() public {
        test_StrategyOptInToBAppWithMultipleTokens(9000);
        vm.startPrank(USER1);
        proxiedManager.createObligation(STRATEGY1, address(bApp1), address(erc20mock2), 9500);
        (uint32 percentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock2));
        assertEq(percentage, 9500, "Obligation percentage");
        assertEq(isSet, true, "Obligation is set");
        uint32 usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock2));
        assertEq(usedTokens, 1, "Used tokens");
        vm.stopPrank();
    }

    function testRevert_CreateObligationFailCauseAlreadySet() public {
        test_CreateNewObligationSuccessful();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.ObligationAlreadySet.selector));
        proxiedManager.createObligation(STRATEGY1, address(bApp1), address(erc20mock2), 10_000);
    }

    function test_FastWithdrawErc20FromStrategy() public {
        test_StrategyOwnerDepositERC20WithNoObligation(200);
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 200, "User strategy balance should be 200");
        proxiedManager.fastWithdrawERC20(1, erc20mock2, 50);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 150, "User strategy balance should be 150");
        vm.stopPrank();
    }

    function test_WithdrawETHFromStrategy() public {
        test_StrategyOwnerDepositETHWithNoObligation();
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, ETH_ADDRESS);
        assertEq(strategyTokenBalance, 1 ether, "User strategy balance should be 1 ether");
        proxiedManager.fastWithdrawETH(1, 0.4 ether);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, ETH_ADDRESS);
        assertEq(strategyTokenBalance, 0.6 ether, "User strategy balance should be 0.6 ether");
        vm.stopPrank();
    }

    function testRevert_WithdrawETHFromStrategyRevertWithZeroAmount() public {
        test_StrategyOwnerDepositETHWithNoObligation();
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, ETH_ADDRESS);
        assertEq(strategyTokenBalance, 1 ether, "User strategy balance should be 1 ether");
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAmount.selector));
        proxiedManager.fastWithdrawETH(1, 0 ether);
        vm.stopPrank();
    }

    function test_FastUpdateObligation() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 10_000);
        (uint32 obligationPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(obligationPercentage, 10_000, "Obligation percentage");
        assertEq(isSet, true, "Obligation is set");
        uint256 usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationBAppNotOptedIn() public {
        test_CreateStrategies();
        test_RegisterBApp();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppNotOptedIn.selector));
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 10_000);
    }

    function testRevert_FastUpdateObligationFailWithNonOwner() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(ATTACKER);
        uint32 strategyId = 1;
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.fastUpdateObligation(strategyId, address(bApp1), address(erc20mock), 10_000);
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithWrongHighPercentages(uint32 obligationPercentage) public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint32 strategyId = 1;
        vm.assume(obligationPercentage > 10_000);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.fastUpdateObligation(strategyId, address(bApp1), address(erc20mock), obligationPercentage);
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithZeroPercentages(uint32 obligationPercentage) public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.assume(obligationPercentage > 0 && obligationPercentage <= 9000);
        uint32 strategyId = 1;
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.fastUpdateObligation(strategyId, address(bApp1), address(erc20mock), obligationPercentage);
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithPercentageLowerThanCurrent() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint32 strategyId = 1;
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.fastUpdateObligation(strategyId, address(bApp1), address(erc20mock), 0);
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateFailsWithNonOwner(uint32 fee) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(fee > 0 && fee <= proxiedManager.MAX_PERCENTAGE());
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateFailsWithNoProposal() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.NoPendingFeeUpdate.selector));
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateFailsWithOverLimitFee(uint32 fee) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(fee > proxiedManager.MAX_PERCENTAGE());
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateFailsWithOverLimitIncrement(uint32 proposedFee) public {
        test_StrategyOptInToBApp(9000);
        (, uint32 fee,,) = proxiedManager.strategies(STRATEGY1);
        vm.assume(proposedFee < proxiedManager.MAX_PERCENTAGE() && proposedFee > fee + proxiedManager.maxFeeIncrement());
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentageIncrement.selector));
        proxiedManager.proposeFeeUpdate(STRATEGY1, proposedFee);
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateFailsWithSameFeeValue() public {
        test_StrategyOptInToBApp(9000);
        (, uint32 fee,,) = proxiedManager.strategies(STRATEGY1);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.FeeAlreadySet.selector));
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
        vm.stopPrank();
    }

    function test_StrategyFeeUpdate(uint256 timeBeforeLimit) public {
        vm.assume(timeBeforeLimit < proxiedManager.FEE_EXPIRE_TIME());
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 1, "Strategy fee update time");
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD() + timeBeforeLimit);
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        (owner, fee, feeProposed, feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, 20, "Strategy fee");
        assertEq(feeProposed, 0, "Strategy fee proposed");
        assertEq(feeUpdateTime, 0, "Strategy fee update time");
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateTooLate(uint256 timeAfterLimit) public {
        vm.assume(timeAfterLimit > proxiedManager.FEE_EXPIRE_TIME() && timeAfterLimit < 100 * 365 days);
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 1, "Strategy fee update time");
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD() + timeAfterLimit);
        vm.expectRevert(abi.encodeWithSelector(ICore.RequestTimeExpired.selector));
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateTooEarly() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 1, "Strategy fee update time");
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD() - 1 seconds);
        vm.expectRevert(abi.encodeWithSelector(ICore.TimelockNotElapsed.selector));
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_ProposeUpdateObligationWithNonOwner() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 1000);
        vm.stopPrank();
    }

    function testRevert_ProposeUpdateObligationWithTooHighPercentage(uint32 obligationPercentage) public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.assume(obligationPercentage > 10_000);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), obligationPercentage);
        vm.stopPrank();
    }

    function testRevert_FinalizeFeeUpdateWithWrongOwner() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 1, "Strategy fee update time");
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD());
        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        vm.stopPrank();
    }

    function test_UpdateStrategyObligationFinalizeOnInitialLimit() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        (uint32 oldPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 0, "Obligation update time");
        (uint32 newPercentage, bool isSet2) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet2, true, "Obligation is set");
        assertEq(newPercentage, 1000, "Obligation new percentage");
        vm.stopPrank();
    }

    function test_UpdateStrategyObligationFinalizeOnLatestLimit() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        (uint32 oldPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + proxiedManager.OBLIGATION_EXPIRE_TIME());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 0, "Obligation update time");
        (uint32 newPercentage, bool isSet2) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet2, true, "Obligation is set");
        assertEq(newPercentage, 1000, "Obligation new percentage");
        vm.stopPrank();
    }

    function test_UpdateStrategyObligationFinalizeWithZeroValue() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 0);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        (uint32 oldPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        uint32 usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + proxiedManager.OBLIGATION_EXPIRE_TIME());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(percentage, 0, "Obligation percentage proposed after finalize update");
        assertEq(requestTime, 0, "Obligation update time after finalize update");
        (uint32 newPercentage, bool isSet2) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet2, true, "Obligation is set");
        assertEq(newPercentage, 0, "Obligation new percentage");
        usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock));
        assertEq(usedTokens, 0, "Used tokens");
        vm.stopPrank();
    }

    function test_UpdateStrategyObligationRemoval() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 0);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        (uint32 oldPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + proxiedManager.OBLIGATION_EXPIRE_TIME());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 0, "Obligation update time after finalize update");
        (uint32 newPercentage, bool isSet2) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet2, true, "Obligation is set");
        assertEq(newPercentage, 0, "Obligation new percentage");
        vm.stopPrank();
    }

    function testRevert_UpdateStrategyObligationFinalizeTooLate(uint256 timeAfterLimit) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(timeAfterLimit > proxiedManager.OBLIGATION_EXPIRE_TIME() && timeAfterLimit < 100 * 365 days);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        (uint32 oldPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + timeAfterLimit);
        vm.expectRevert(abi.encodeWithSelector(ICore.RequestTimeExpired.selector));
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock));
        vm.stopPrank();
    }

    function testRevert_UpdateStrategyObligationFinalizeTooEarly(uint256 timeToLimit) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(timeToLimit > 0 && timeToLimit < proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        (uint32 oldPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() - timeToLimit);
        vm.expectRevert(abi.encodeWithSelector(ICore.TimelockNotElapsed.selector));
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock));
        vm.stopPrank();
    }

    function testRevert_UpdateStrategyObligationWithNonOwner() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, address(bApp1), address(erc20mock));
        (uint32 oldPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.stopPrank();
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock));
        vm.stopPrank();
    }

    function testRevert_FinalizeUpdateObligationFailWithNoPendingRequest() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.NoPendingObligationUpdate.selector));
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock));
        vm.stopPrank();
    }

    function test_AsyncWithdrawFromStrategy() public {
        test_CreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        vm.startPrank(USER1);
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 1000);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            120_000,
            "User strategy balance should be 120_000"
        );
        (uint256 amount, uint256 requestTime) = proxiedManager.withdrawalRequests(STRATEGY1, USER1, address(erc20mock));
        assertEq(requestTime, block.timestamp, "Request time");
        assertEq(amount, 1000, "Request amount");
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD());
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            119_000,
            "User strategy balance should be 119_000"
        );
        (amount, requestTime) = proxiedManager.withdrawalRequests(STRATEGY1, USER1, address(erc20mock));
        assertEq(requestTime, 0, "Request time");
        assertEq(amount, 0, "Request amount");
        vm.stopPrank();
    }

    function testRevert_AsyncWithdrawFromStrategyOnlyFinalize() public {
        test_CreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.NoPendingWithdrawal.selector));
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        vm.stopPrank();
    }

    function test_AsyncWithdrawETHFromStrategy(uint256 withdrawalAmount) public {
        test_CreateStrategyETHAndDepositETH();
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        vm.startPrank(USER1);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, withdrawalAmount);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, ETH_ADDRESS),
            1 ether,
            "User strategy balance should be set correctly"
        );
        (uint256 amount, uint256 requestTime) = proxiedManager.withdrawalRequests(STRATEGY1, USER1, ETH_ADDRESS);
        assertEq(requestTime, block.timestamp, "Request time");
        assertEq(amount, withdrawalAmount, "Request amount");
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD());
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, ETH_ADDRESS),
            1 ether - withdrawalAmount,
            "User strategy balance should be reduced correctly"
        );
        (amount, requestTime) = proxiedManager.withdrawalRequests(STRATEGY1, USER1, ETH_ADDRESS);
        assertEq(requestTime, 0, "Request time");
        assertEq(amount, 0, "Request amount");
        vm.stopPrank();
    }

    function testRevert_AsyncWithdrawETHFromStrategyOnlyFinalize() public {
        test_CreateStrategyETHAndDepositETH();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.NoPendingWithdrawalETH.selector));
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_AsyncWithdrawETHFromStrategyWithMadeUpToken() public {
        test_CreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, address(1), 1000);
    }

    function testRevert_AsyncFailedWithdrawETHFromStrategyTooEarly(uint256 withdrawalAmount) public {
        test_CreateStrategyETHAndDepositETH();
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        vm.startPrank(USER1);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, withdrawalAmount);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, ETH_ADDRESS),
            1 ether,
            "User strategy balance should be set correctly"
        );
        (uint256 amount, uint256 requestTime) = proxiedManager.withdrawalRequests(STRATEGY1, USER1, ETH_ADDRESS);
        assertEq(requestTime, block.timestamp, "Request time");
        assertEq(amount, withdrawalAmount, "Request amount");
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() - 1 seconds);
        vm.expectRevert(abi.encodeWithSelector(ICore.TimelockNotElapsed.selector));
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_AsyncFailedWithdrawETHFromStrategyTooLate(uint256 withdrawalAmount) public {
        test_CreateStrategyETHAndDepositETH();
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        vm.startPrank(USER1);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, withdrawalAmount);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, ETH_ADDRESS),
            1 ether,
            "User strategy balance should be set correctly"
        );
        (uint256 amount, uint256 requestTime) = proxiedManager.withdrawalRequests(STRATEGY1, USER1, ETH_ADDRESS);
        assertEq(requestTime, block.timestamp, "Request time");
        assertEq(amount, withdrawalAmount, "Request amount");
        vm.warp(
            block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() + proxiedManager.WITHDRAWAL_EXPIRE_TIME() + 1 seconds
        );
        vm.expectRevert(abi.encodeWithSelector(ICore.RequestTimeExpired.selector));
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_AsyncFailedWithdrawFromStrategyETHInsteadOfERC20(uint256 withdrawalAmount) public {
        test_CreateStrategyETHAndDepositETH();
        vm.assume(withdrawalAmount > 0 && withdrawalAmount <= 1 ether);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidToken.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, ETH_ADDRESS, withdrawalAmount);
        vm.stopPrank();
    }

    function testRevert_AsyncFailedWithdrawFromStrategyTooEarly() public {
        test_CreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        vm.startPrank(USER1);
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 1000);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            120_000,
            "User strategy balance should be 120_000"
        );
        (uint256 amount, uint256 requestTime) = proxiedManager.withdrawalRequests(STRATEGY1, USER1, address(erc20mock));
        assertEq(requestTime, block.timestamp, "Request time");
        assertEq(amount, 1000, "Request amount");
        vm.warp(block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() - 1 seconds);
        vm.expectRevert(abi.encodeWithSelector(ICore.TimelockNotElapsed.selector));
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        vm.stopPrank();
    }

    function testRevert_AsyncFailedWithdrawFromStrategyTooLate() public {
        test_CreateStrategyAndMultipleDeposits(100_000, 20_000, 200_000);
        vm.startPrank(USER1);
        proxiedManager.proposeWithdrawal(STRATEGY1, address(erc20mock), 1000);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            120_000,
            "User strategy balance should be 120_000"
        );
        (uint256 amount, uint256 requestTime) = proxiedManager.withdrawalRequests(STRATEGY1, USER1, address(erc20mock));
        assertEq(requestTime, block.timestamp, "Request time");
        assertEq(amount, 1000, "Request amount");
        vm.warp(
            block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() + proxiedManager.WITHDRAWAL_EXPIRE_TIME() + 1 seconds
        );
        vm.expectRevert(abi.encodeWithSelector(ICore.RequestTimeExpired.selector));
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        vm.stopPrank();
    }

    function test_CreateObligationETH(uint32 percentage) public {
        vm.assume(percentage > 0 && percentage <= proxiedManager.MAX_PERCENTAGE());
        test_CreateStrategies();
        test_RegisterBAppWithETHAndErc20();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = percentage;
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, 1, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(strategyId, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        proxiedManager.createObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, proxiedManager.MAX_PERCENTAGE());
        (uint256 obligation, bool isSet2) = proxiedManager.obligations(STRATEGY1, address(bApp1), ETH_ADDRESS);
        assertEq(isSet2, true, "Obligation is set");
        assertEq(obligation, proxiedManager.MAX_PERCENTAGE(), "Obligation percentage should be max");
        usedTokens = proxiedManager.usedTokens(strategyId, ETH_ADDRESS);
        assertEq(usedTokens, 1, "Used tokens");
        vm.stopPrank();
    }

    function test_CreateObligationETHWithZeroPercentage() public {
        test_CreateStrategies();
        test_RegisterBAppWithETHAndErc20();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 0;
        proxiedManager.optInToBApp(1, address(bApp1), tokensInput, obligationPercentagesInput, abi.encodePacked("0x00"));
        uint32 strategyId = proxiedManager.accountBAppStrategy(USER1, address(bApp1));
        assertEq(strategyId, 1, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(strategyId, address(bApp1), address(erc20mock));
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, 0, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 0, "Used tokens");
        proxiedManager.createObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, 0);
        (uint256 obligation, bool isSet2) = proxiedManager.obligations(STRATEGY1, address(bApp1), ETH_ADDRESS);
        assertEq(isSet2, true, "Obligation is set");
        assertEq(obligation, 0, "Obligation percentage should be zero");
        usedTokens = proxiedManager.usedTokens(strategyId, ETH_ADDRESS);
        assertEq(usedTokens, 0, "Used ETH tokens");
        vm.stopPrank();
    }

    function test_updateObligationFromZeroToHigher() public {
        test_CreateObligationETHWithZeroPercentage();
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, 5000);
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS);
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), ETH_ADDRESS);
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, 5000, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(STRATEGY1, ETH_ADDRESS);
        assertEq(usedTokens, 1, "Used ETH");
        vm.stopPrank();
    }

    function test_fastUpdateObligationETHFromZeroToHigher() public {
        test_CreateObligationETHWithZeroPercentage();
        vm.prank(USER1);
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, 5000);
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), ETH_ADDRESS);
        uint256 usedTokens = proxiedManager.usedTokens(STRATEGY1, ETH_ADDRESS);
        assertEq(isSet, true, "Obligation is set");
        assertEq(obligationPercentage, 5000, "Obligation percentage");
        assertEq(usedTokens, 1, "Used ETH");
    }

    function testRevert_proposeUpdateObligationWithBAppNotOptedIN() public {
        test_CreateStrategies();
        test_RegisterBApp();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppNotOptedIn.selector));
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, 5000);
    }

    function testRevert_proposeUpdateObligationWithSamePercentage() public {
        test_CreateObligationETH(10_000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.ObligationAlreadySet.selector));
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), ETH_ADDRESS, 10_000);
    }

    function testRevert_proposeUpdateObligationNotCreated() public {
        test_CreateObligationETH(10_000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.ObligationHasNotBeenCreated.selector));
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock2), 8000);
    }

    function testRevert_fastUpdateObligationNotCreated() public {
        test_CreateObligationETH(10_000);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.ObligationHasNotBeenCreated.selector));
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), address(erc20mock2), 10_000);
    }

    function test_updateUsedTokensCorrectly() public {
        test_CreateNewObligationSuccessful();
        vm.startPrank(USER1);
        address TOKEN = address(erc20mock2);
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), TOKEN, 9700);
        (uint32 percentage, bool isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), TOKEN);
        assertEq(percentage, 9700, "Obligation percentage");
        assertEq(isSet, true, "Obligation is set");
        uint32 usedTokens = proxiedManager.usedTokens(STRATEGY1, TOKEN);
        assertEq(usedTokens, 1, "Used tokens");
        proxiedManager.proposeUpdateObligation(STRATEGY1, address(bApp1), TOKEN, 0);
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, address(bApp1), TOKEN);
        (percentage, isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), TOKEN);
        assertEq(percentage, 0, "Obligation percentage");
        assertEq(isSet, true, "Obligation is set");
        usedTokens = proxiedManager.usedTokens(STRATEGY1, TOKEN);
        assertEq(usedTokens, 0, "Used tokens");
        vm.expectRevert(abi.encodeWithSelector(ICore.ObligationAlreadySet.selector));
        proxiedManager.createObligation(STRATEGY1, address(bApp1), TOKEN, 1000);
        proxiedManager.fastUpdateObligation(STRATEGY1, address(bApp1), TOKEN, 1000);
        (percentage, isSet) = proxiedManager.obligations(STRATEGY1, address(bApp1), TOKEN);
        assertEq(percentage, 1000, "Obligation percentage");
        assertEq(isSet, true, "Obligation is set");
        usedTokens = proxiedManager.usedTokens(STRATEGY1, TOKEN);
        assertEq(usedTokens, 1, "Used tokens");
        vm.stopPrank();
    }

    function test_UpdateStrategyMetadata() public {
        test_CreateStrategies();
        string memory metadataURI = "https://metadata.com";
        vm.startPrank(USER1);
        vm.expectEmit(true, false, false, false);
        emit IBasedAppManager.StrategyMetadataURIUpdated(STRATEGY1, metadataURI);
        proxiedManager.updateStrategyMetadataURI(STRATEGY1, metadataURI);
        vm.stopPrank();
    }

    function testRevert_UpdateStrategyMetadataWithWrongOwner() public {
        test_CreateStrategies();
        string memory metadataURI = "https://metadata-attacker.com";
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), address(USER1)));
        proxiedManager.updateStrategyMetadataURI(STRATEGY1, metadataURI);
        vm.stopPrank();
    }
}
