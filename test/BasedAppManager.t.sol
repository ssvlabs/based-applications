// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";

import {BasedAppManager} from "../src/BasedAppManager.sol";
import {ICore} from "../src/interfaces/ICore.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./mocks/MockERC20.sol";

contract BasedAppManagerTest is Test, OwnableUpgradeable {
    BasedAppManager public implementation;
    ERC1967Proxy proxy; // UUPS Proxy contract
    BasedAppManager proxiedManager; // Proxy interface for interaction

    IERC20 public erc20mock;
    IERC20 public erc20mock2;

    address OWNER = makeAddr("Owner");
    address USER1 = makeAddr("User1");
    address SERVICE1 = makeAddr("BApp1");
    address SERVICE2 = makeAddr("BApp2");
    address ATTACKER = makeAddr("Attacker");
    address RECEIVER = makeAddr("Receiver");
    address RECEIVER2 = makeAddr("Receiver2");

    uint256 STRATEGY1 = 1;
    uint256 STRATEGY2 = 2;
    uint256 STRATEGY3 = 3;
    uint256 STRATEGY4 = 4;
    uint32 STRATEGY1_INITIAL_FEE = 5;
    uint32 STRATEGY2_INITIAL_FEE = 0;
    uint32 STRATEGY3_INITIAL_FEE = 1000;
    uint32 STRATEGY1_UPDATE_FEE = 10;

    address ERC20_ADDRESS1 = address(erc20mock);
    address ERC20_ADDRESS2 = address(erc20mock2);

    uint256 constant INITIAL_USER1_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 constant INITIAL_USER1_BALANCE_ETH = 10 ether;
    uint256 constant INITIAL_RECEIVER_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 constant INITIAL_RECEIVER_BALANCE_ETH = 10 ether;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public {
        vm.label(OWNER, "Owner");
        vm.label(USER1, "User1");
        vm.label(ATTACKER, "Attacker");
        vm.label(RECEIVER, "Receiver");
        vm.label(RECEIVER2, "Receiver2");
        vm.label(SERVICE1, "BApp1");
        vm.label(SERVICE2, "BApp2");

        vm.startPrank(OWNER);

        implementation = new BasedAppManager();
        bytes memory data = abi.encodeWithSelector(implementation.initialize.selector); // Encodes initialize() call
        proxy = new ERC1967Proxy(address(implementation), data);
        proxiedManager = BasedAppManager(address(proxy));

        vm.label(address(proxiedManager), "BasedAppManagerProxy");

        vm.deal(USER1, INITIAL_USER1_BALANCE_ETH);
        vm.deal(RECEIVER, INITIAL_RECEIVER_BALANCE_ETH);

        erc20mock = new ERC20Mock();
        erc20mock.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        erc20mock2 = new ERC20Mock();
        erc20mock2.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        vm.stopPrank();
    }

    // ************************
    // ** Section: Ownership **
    // ************************

    function test_OwnerOfBasedAppManager() public view {
        assertEq(proxiedManager.owner(), OWNER, "Owner should be the deployer");
    }

    function test_Implementation() public view {
        address currentImplementation = address(
            uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1))))
        );
        assertEq(
            currentImplementation, address(implementation), "Implementation should be the BasedAppManager contract"
        );
    }

    function testRevert_UpgradeUnauthorizedFromNonOwner() public {
        BasedAppManager newImplementation = new BasedAppManager();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.upgradeToAndCall(address(newImplementation), bytes(""));
    }

    function test_UpgradeAuthorized() public {
        BasedAppManager newImplementation = new BasedAppManager();

        vm.prank(OWNER);
        proxiedManager.upgradeToAndCall(address(newImplementation), bytes(""));

        address currentImplementation = address(
            uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1))))
        );
        assertEq(currentImplementation, address(newImplementation), "Implementation should be upgraded");
    }

    // *****************************************
    // ** Section: Delegate Validator Balance **
    // *****************************************

    function test_DelegateMinimumBalance() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1, "Delegated amount should be 0.01%");
        assertEq(totalDelegatedPercentage, 1, "Delegated percentage should be 0.01%");
        vm.stopPrank();
    }

    function test_DelegatePartialBalance(
        uint32 percentageAmount
    ) public {
        vm.assume(percentageAmount > 0 && percentageAmount < 10_000);
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, percentageAmount);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, percentageAmount, "Delegated amount should be %1");
        assertEq(totalDelegatedPercentage, percentageAmount, "Delegated percentage should be 1%");
        vm.stopPrank();
    }

    function test_DelegateFullBalance() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 10_000);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 10_000, "Delegated amount should be 100%");
        assertEq(totalDelegatedPercentage, 10_000, "Delegated percentage should be 100%");
        vm.stopPrank();
    }

    function testRevert_DelegateBalanceTooLow() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, 0);
    }

    function testRevert_DelegateBalanceTooHigh(
        uint32 highBalance
    ) public {
        vm.assume(highBalance > proxiedManager.MAX_PERCENTAGE());
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, highBalance);
    }

    function test_UpdateTotalDelegatedPercentage(uint32 percentage1, uint32 percentage2) public {
        vm.assume(percentage1 > 0 && percentage2 > 0);
        vm.assume(percentage1 < proxiedManager.MAX_PERCENTAGE() && percentage2 < proxiedManager.MAX_PERCENTAGE());
        vm.assume(percentage1 + percentage2 <= proxiedManager.MAX_PERCENTAGE());
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, percentage1);
        proxiedManager.delegateBalance(RECEIVER2, percentage2);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 delegatedAmount2 = proxiedManager.delegations(USER1, RECEIVER2);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, percentage1, "Delegated amount should be the one specified in percentage1");
        assertEq(delegatedAmount2, percentage2, "Delegated amount should be the one specified in percentage2");
        assertEq(
            totalDelegatedPercentage,
            percentage1 + percentage2,
            "Total delegated percentage should be the sum of percentage1 and percentage2"
        );
        vm.stopPrank();
    }

    function testRevert_TotalDelegatePercentageOverMax(
        uint32 percentage1
    ) public {
        vm.assume(percentage1 > 0 && percentage1 <= proxiedManager.MAX_PERCENTAGE());
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, percentage1);
        uint32 percentage2 = proxiedManager.MAX_PERCENTAGE();
        vm.expectRevert(abi.encodeWithSelector(ICore.ExceedingPercentageUpdate.selector));
        proxiedManager.delegateBalance(RECEIVER2, percentage2);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 delegatedAmount2 = proxiedManager.delegations(USER1, RECEIVER2);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, percentage1, "First delegated amount should be set");
        assertEq(delegatedAmount2, 0, "Second delegated amount should be not set");
        assertEq(
            totalDelegatedPercentage, percentage1, "Total delegated percentage should be equal to the first delegation"
        );
        vm.stopPrank();
    }

    function testRevert_DoubleDelegateSameReceiver(uint32 percentage1, uint32 percentage2) public {
        vm.assume(percentage1 > 0 && percentage2 > 0);
        vm.assume(percentage1 <= proxiedManager.MAX_PERCENTAGE() && percentage2 <= proxiedManager.MAX_PERCENTAGE());
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, percentage1);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, percentage1, "Delegated amount should be set");
        assertEq(totalDelegatedPercentage, percentage1, "Total delegated percentage should be set");
        vm.expectRevert(abi.encodeWithSelector(ICore.DelegationAlreadyExists.selector));
        proxiedManager.delegateBalance(RECEIVER, percentage2);
        vm.stopPrank();
    }

    function testRevert_InvalidPercentageDelegateBalance() public {
        vm.startPrank(USER1);
        uint32 maxPlusOne = proxiedManager.MAX_PERCENTAGE() + 1;
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, maxPlusOne);
        vm.stopPrank();
    }

    function testRevert_UpdateTotalDelegatePercentageByTheSameUser() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        proxiedManager.updateDelegatedBalance(RECEIVER, proxiedManager.MAX_PERCENTAGE());
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1e4, "Delegated amount should be 100%");
        assertEq(totalDelegatedPercentage, 1e4, "Total delegated percentage should be 100%");
        uint32 maxPlusOne = proxiedManager.MAX_PERCENTAGE() + 1;
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, maxPlusOne);
        vm.stopPrank();
    }

    function testRevert_UpdateTotalDelegatePercentageWithZero() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 0);
        vm.stopPrank();
    }

    function testRevert_UpdateTotalDelegatePercentageWithSameBalance() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        vm.expectRevert(abi.encodeWithSelector(ICore.DelegationExistsWithSameValue.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 1);
        vm.stopPrank();
    }

    function testRevert_UpdateBalanceNotExisting() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.DelegationDoesNotExist.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 1e4);
        vm.stopPrank();
    }

    function testRevert_UpdateBalanceTooHigh() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        proxiedManager.delegateBalance(RECEIVER2, 1);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 delegatedAmount2 = proxiedManager.delegations(USER1, RECEIVER2);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1, "Delegated amount should be 100%");
        assertEq(delegatedAmount2, 1, "Delegated amount should be 100%");
        assertEq(totalDelegatedPercentage, 2, "Total delegated percentage should be 100%");
        vm.expectRevert(abi.encodeWithSelector(ICore.ExceedingPercentageUpdate.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 1e4);
        vm.stopPrank();
    }

    function test_RemoveDelegateBalance() public {
        test_DelegateFullBalance();
        vm.startPrank(USER1);
        proxiedManager.removeDelegatedBalance(RECEIVER);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 0, "Delegated amount should be 0%");
        assertEq(totalDelegatedPercentage, 0, "Total delegated percentage should be 0%");
        vm.stopPrank();
    }

    function test_RemoveDelegatedBalanceAndComputeTotal() public {
        test_UpdateTotalDelegatedPercentage(100, 200);
        vm.startPrank(USER1);
        proxiedManager.removeDelegatedBalance(RECEIVER);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 delegatedAmount2 = proxiedManager.delegations(USER1, RECEIVER2);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 0, "Delegated amount should be 0%");
        assertEq(delegatedAmount2, 200, "Delegated amount should be 0.01%");
        assertEq(totalDelegatedPercentage, 200, "Total delegated percentage should be 0.01%");
        proxiedManager.delegateBalance(RECEIVER, 1);
        delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        delegatedAmount2 = proxiedManager.delegations(USER1, RECEIVER2);
        totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1, "Delegated amount should be 0%");
        assertEq(delegatedAmount2, 200, "Delegated amount should be 0.01%");
        assertEq(totalDelegatedPercentage, 201, "Total delegated percentage should be 0.01%");
        vm.stopPrank();
    }

    function testRevert_RemoveNonExistingBalance() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.DelegationDoesNotExist.selector));
        proxiedManager.removeDelegatedBalance(RECEIVER);
        vm.stopPrank();
    }

    // ***********************
    // ** Section: Strategy **
    // ***********************

    function test_CreateObligationETH(
        uint32 percentage
    ) public {
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
        proxiedManager.createObligation(STRATEGY1, SERVICE1, ETH_ADDRESS, proxiedManager.MAX_PERCENTAGE());
        uint256 obligation = proxiedManager.obligations(STRATEGY1, SERVICE1, ETH_ADDRESS);
        assertEq(obligation, proxiedManager.MAX_PERCENTAGE(), "Obligation percentage should be max");
        usedTokens = proxiedManager.usedTokens(strategyId, ETH_ADDRESS);
        assertEq(usedTokens, 1, "Used tokens");
        numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 2, "Number of obligations");
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, 0, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 0, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
        proxiedManager.createObligation(STRATEGY1, SERVICE1, ETH_ADDRESS, 0);
        uint256 obligation = proxiedManager.obligations(STRATEGY1, SERVICE1, ETH_ADDRESS);
        assertEq(obligation, 0, "Obligation percentage should be zero");
        usedTokens = proxiedManager.usedTokens(strategyId, ETH_ADDRESS);
        assertEq(usedTokens, 0, "Used ETH tokens");
        numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 2, "Number of obligations");
        vm.stopPrank();
    }

    function test_CreateStrategies() public {
        vm.startPrank(USER1);
        erc20mock.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);
        uint256 strategyId1 = proxiedManager.createStrategy(STRATEGY1_INITIAL_FEE);
        proxiedManager.createStrategy(STRATEGY2_INITIAL_FEE);
        proxiedManager.createStrategy(STRATEGY3_INITIAL_FEE);
        uint256 strategyId4 = proxiedManager.createStrategy(proxiedManager.MAX_PERCENTAGE());
        assertEq(strategyId1, STRATEGY1, "Strategy id 1 was saved correctly");
        assertEq(strategyId4, STRATEGY4, "Strategy id 4 was saved correctly");
        (address owner, uint32 delegationFeeOnRewards,,) = proxiedManager.strategies(strategyId1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(delegationFeeOnRewards, STRATEGY1_INITIAL_FEE, "Strategy fee");
        vm.stopPrank();
    }

    function test_CreateStrategyWithZeroFee() public {
        vm.startPrank(USER1);
        uint256 strategyId1 = proxiedManager.createStrategy(0);
        (, uint32 delegationFeeOnRewards,,) = proxiedManager.strategies(strategyId1);
        assertEq(delegationFeeOnRewards, 0, "Strategy fee");
        vm.stopPrank();
    }

    function testRevert_CreateStrategyWithTooHighFee() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidDelegationFee.selector));
        proxiedManager.createStrategy(10_001);
        vm.stopPrank();
    }

    function test_CreateStrategyAndSingleDeposit(
        uint256 amount
    ) public {
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

    function test_CreateStrategyAndMultipleDeposits(
        uint256 deposit1S1,
        uint256 deposit2S1,
        uint256 deposit1S2
    ) public {
        vm.assume(deposit1S1 > 0 && deposit1S1 < INITIAL_USER1_BALANCE_ERC20);
        vm.assume(deposit2S1 > 0 && deposit2S1 <= INITIAL_USER1_BALANCE_ERC20);
        vm.assume(
            deposit1S2 > 0 && deposit1S2 < INITIAL_USER1_BALANCE_ERC20
                && deposit1S2 <= INITIAL_USER1_BALANCE_ERC20 - deposit1S1
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

    function test_StrategyOptInToBApp(
        uint32 percentage
    ) public {
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalWithUsedToken(
        uint32 amount
    ) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawERC20(STRATEGY1, erc20mock, amount);
        vm.stopPrank();
    }

    function test_StrategyOptInToBAppWithMultipleTokens(
        uint32 percentage
    ) public {
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, 0, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 0, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Used tokens");
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, ETH_ADDRESS);
        assertEq(obligationPercentage, proxiedManager.MAX_PERCENTAGE(), "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, ETH_ADDRESS);
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
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
        vm.expectRevert(abi.encodeWithSelector(ICore.TokensLengthNotMatchingPercentages.selector));
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 0, "Strategy id was not saved");
        vm.stopPrank();
    }

    function testRevert_StrategyAlreadyOptedIn(
        uint32 percentage
    ) public {
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
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
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
        proxiedManager.createObligation(1, SERVICE2, tokensInput, obligationPercentagesInput);
        vm.stopPrank();
    }

    function test_StrategyOwnerDepositERC20WithNoObligation(
        uint256 amount
    ) public {
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
        proxiedManager.createObligation(1, SERVICE1, address(erc20mock2), 100);
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
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenIsUsedByTheBApp.selector));
        proxiedManager.fastWithdrawETH(STRATEGY1, 0.5 ether);
        vm.stopPrank();
    }

    function testRevert_InvalidFastWithdrawalETHWithInvalidAmount() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.fastWithdrawETH(STRATEGY1, 100 ether);
        vm.stopPrank();
    }

    function testRevert_ObligationHigherThanMaxPercentage() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.createObligation(1, SERVICE1, address(erc20mock2), 10_001);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.stopPrank();
    }

    function testRevert_CreateObligationToNonExistingBApp() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppNotOptedIn.selector));
        proxiedManager.createObligation(1, SERVICE2, address(erc20mock), 100);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.stopPrank();
    }

    function testRevert_CreateObligationToNonExistingStrategy() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(USER1), 0x00));
        proxiedManager.createObligation(3, SERVICE1, address(erc20mock), 100);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.stopPrank();
    }

    function testRevert_CreateObligationToNotOwnedStrategy() public {
        test_CreateStrategies();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), address(USER1)));
        proxiedManager.createObligation(1, SERVICE1, address(erc20mock), 100);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, ATTACKER, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.stopPrank();
    }

    function test_CreateNewObligationSuccessful() public {
        test_StrategyOptInToBAppWithMultipleTokens(9000);
        vm.startPrank(USER1);
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokens[1], address(erc20mock2), "BApp token 2");
        assertEq(tokens.length, 2, "BApp token length");
        proxiedManager.createObligation(STRATEGY1, SERVICE1, address(erc20mock2), 10_000);
        vm.stopPrank();
    }

    function testRevert_CreateObligationFailCauseAlreadySet() public {
        test_CreateNewObligationSuccessful();
        vm.startPrank(USER1);
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokens[1], address(erc20mock2), "BApp token 2");
        assertEq(tokens.length, 2, "BApp token length");
        vm.expectRevert(abi.encodeWithSelector(ICore.ObligationAlreadySet.selector));
        proxiedManager.createObligation(STRATEGY1, SERVICE1, address(erc20mock2), 10_000);
        vm.stopPrank();
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

    function test_FastUpdateObligation(
        uint32 obligationPercentage
    ) public {
        vm.assume(obligationPercentage <= 10_000 && obligationPercentage > 0);
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint32 strategyId = 1;
        proxiedManager.fastUpdateObligation(strategyId, SERVICE1, address(erc20mock), 10_000);
        obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, 10_000, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithNonOwner() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(ATTACKER);
        uint32 strategyId = 1;
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.fastUpdateObligation(strategyId, SERVICE1, address(erc20mock), 10_000);
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithWrongHighPercentages(
        uint32 obligationPercentage
    ) public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint32 strategyId = 1;
        vm.assume(obligationPercentage > 10_000);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.fastUpdateObligation(strategyId, SERVICE1, address(erc20mock), obligationPercentage);
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithZeroPercentages(
        uint32 obligationPercentage
    ) public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.assume(obligationPercentage > 0 && obligationPercentage <= 9000);
        uint32 strategyId = 1;
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.fastUpdateObligation(strategyId, SERVICE1, address(erc20mock), obligationPercentage);
        vm.stopPrank();
    }

    function testRevert_FastUpdateObligationFailWithPercentageLowerThanCurrent() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        uint32 strategyId = 1;
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.fastUpdateObligation(strategyId, SERVICE1, address(erc20mock), 0);
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateFailsWithNonOwner(
        uint32 fee
    ) public {
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

    function testRevert_StrategyFeeUpdateFailsWithOverLimitFee(
        uint32 fee
    ) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(fee > proxiedManager.MAX_PERCENTAGE());
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.proposeFeeUpdate(STRATEGY1, fee);
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateFailsWithOverLimitIncrement(
        uint32 proposedFee
    ) public {
        test_StrategyOptInToBApp(9000);
        (, uint32 fee,,) = proxiedManager.strategies(STRATEGY1);
        vm.assume(
            proposedFee < proxiedManager.MAX_PERCENTAGE() && proposedFee > fee + proxiedManager.MAX_FEE_INCREMENT()
        );
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

    function test_StrategyFeeUpdate(
        uint256 timeBeforeLimit
    ) public {
        vm.assume(timeBeforeLimit < proxiedManager.FEE_EXPIRE_TIME());
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD() + timeBeforeLimit);
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        (owner, fee, feeProposed, feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, 20, "Strategy fee");
        assertEq(feeProposed, 0, "Strategy fee proposed");
        assertEq(feeUpdateTime, 0, "Strategy fee update time");
        vm.stopPrank();
    }

    function testRevert_StrategyFeeUpdateTooLate(
        uint256 timeAfterLimit
    ) public {
        vm.assume(timeAfterLimit > proxiedManager.FEE_EXPIRE_TIME() && timeAfterLimit < 100 * 365 days);
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD() + timeAfterLimit);
        vm.expectRevert(abi.encodeWithSelector(ICore.FeeUpdateExpired.selector));
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
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
        vm.warp(block.timestamp + proxiedManager.FEE_TIMELOCK_PERIOD() - 1 seconds);
        vm.expectRevert(abi.encodeWithSelector(ICore.FeeTimelockNotElapsed.selector));
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_ProposeUpdateObligationWithNonOwner() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        vm.stopPrank();
    }

    function testRevert_ProposeUpdateObligationWithTooHighPercentage(
        uint32 obligationPercentage
    ) public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.assume(obligationPercentage > 10_000);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), obligationPercentage);
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
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
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
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 0, "Obligation update time");
        uint32 newPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(newPercentage, 1000, "Obligation new percentage");
        vm.stopPrank();
    }

    function test_UpdateStrategyObligationFinalizeOnLatestLimit() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + proxiedManager.OBLIGATION_EXPIRE_TIME());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 0, "Obligation update time");
        uint32 newPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(newPercentage, 1000, "Obligation new percentage");
        vm.stopPrank();
    }

    function test_UpdateStrategyObligationFinalizeWithZeroValue() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 0);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        uint32 usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 obligationsCounter = proxiedManager.obligationsCounter(STRATEGY1, SERVICE1);
        assertEq(obligationsCounter, 1, "Obligations counter");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + proxiedManager.OBLIGATION_EXPIRE_TIME());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(percentage, 0, "Obligation percentage proposed after finalize update");
        assertEq(requestTime, 0, "Obligation update time after finalize update");
        uint32 newPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(newPercentage, 0, "Obligation new percentage");
        usedTokens = proxiedManager.usedTokens(STRATEGY1, address(erc20mock));
        assertEq(usedTokens, 0, "Used tokens");
        obligationsCounter = proxiedManager.obligationsCounter(STRATEGY1, SERVICE1);
        assertEq(obligationsCounter, 1, "Obligations counter");
        vm.stopPrank();
    }

    function test_UpdateStrategyObligationRemoval() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 0);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 obligationsCounter = proxiedManager.obligationsCounter(STRATEGY1, SERVICE1);
        assertEq(obligationsCounter, 1, "Obligations counter");
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + proxiedManager.OBLIGATION_EXPIRE_TIME());
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 0, "Obligation update time after finalize update");
        uint32 newPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(newPercentage, 0, "Obligation new percentage");
        uint32 newObligationsCounter = proxiedManager.obligationsCounter(STRATEGY1, SERVICE1);
        assertEq(newObligationsCounter, 1, "Obligations counter");
        vm.stopPrank();
    }

    function testRevert_UpdateStrategyObligationFinalizeTooLate(
        uint256 timeAfterLimit
    ) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(timeAfterLimit > proxiedManager.OBLIGATION_EXPIRE_TIME() && timeAfterLimit < 100 * 365 days);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() + timeAfterLimit);
        vm.expectRevert(abi.encodeWithSelector(ICore.UpdateObligationExpired.selector));
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        vm.stopPrank();
    }

    function testRevert_UpdateStrategyObligationFinalizeTooEarly(
        uint256 timeToLimit
    ) public {
        test_StrategyOptInToBApp(9000);
        vm.assume(timeToLimit > 0 && timeToLimit < proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD() - timeToLimit);
        vm.expectRevert(abi.encodeWithSelector(ICore.ObligationTimelockNotElapsed.selector));
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        vm.stopPrank();
    }

    function testRevert_UpdateStrategyObligationWithNonOwner() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.stopPrank();
        vm.warp(block.timestamp + proxiedManager.OBLIGATION_TIMELOCK_PERIOD());
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidStrategyOwner.selector, address(ATTACKER), USER1));
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        vm.stopPrank();
    }

    function testRevert_FinalizeUpdateObligationFailWithNoPendingRequest() public {
        test_StrategyOptInToBApp(9000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.NoPendingObligationUpdate.selector));
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
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

    function test_AsyncWithdrawETHFromStrategy(
        uint256 withdrawalAmount
    ) public {
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

    function testRevert_AsyncFailedWithdrawETHFromStrategyTooEarly(
        uint256 withdrawalAmount
    ) public {
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
        vm.expectRevert(abi.encodeWithSelector(ICore.WithdrawalTimelockNotElapsed.selector));
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_AsyncFailedWithdrawETHFromStrategyTooLate(
        uint256 withdrawalAmount
    ) public {
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
            block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() + proxiedManager.WITHDRAWAL_EXPIRE_TIME()
                + 1 seconds
        );
        vm.expectRevert(abi.encodeWithSelector(ICore.WithdrawalExpired.selector));
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);
        vm.stopPrank();
    }

    function testRevert_AsyncFailedWithdrawFromStrategyETHInsteadOfERC20(
        uint256 withdrawalAmount
    ) public {
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
        vm.expectRevert(abi.encodeWithSelector(ICore.WithdrawalTimelockNotElapsed.selector));
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
            block.timestamp + proxiedManager.WITHDRAWAL_TIMELOCK_PERIOD() + proxiedManager.WITHDRAWAL_EXPIRE_TIME()
                + 1 seconds
        );
        vm.expectRevert(abi.encodeWithSelector(ICore.WithdrawalExpired.selector));
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        vm.stopPrank();
    }

    // ********************
    // ** Section: bApps **
    // ********************

    function test_RegisterBApp() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput);
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokensInput[0], address(erc20mock), "BApp token");
        vm.stopPrank();
    }

    function test_RegisterBAppWith2Tokens() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput);
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokensInput[0], address(erc20mock), "BApp token");
        assertEq(tokens[1], address(erc20mock2), "BApp token 2");
        assertEq(tokensInput[1], address(erc20mock2), "BApp token 2");
        vm.stopPrank();
    }

    function test_RegisterBAppWithETH() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = ETH_ADDRESS;
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput);
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], ETH_ADDRESS, "BApp token");
        assertEq(tokensInput[0], ETH_ADDRESS, "BApp token input");
        vm.stopPrank();
    }

    function test_RegisterBAppWithETHAndErc20() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = ETH_ADDRESS;
        tokensInput[1] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput);
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], ETH_ADDRESS, "BApp token");
        assertEq(tokensInput[0], ETH_ADDRESS, "BApp token input");
        assertEq(tokens[1], address(erc20mock), "BApp token");
        assertEq(tokensInput[1], address(erc20mock), "BApp token input");
        vm.stopPrank();
    }

    function testRevert_RegisterBAppTwice() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, 2);
        vm.stopPrank();
    }

    function testRevert_RegisterBAppOverwrite() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput);
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokensInput[0], address(erc20mock), "BApp token");
        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        proxiedManager.registerBApp(ATTACKER, SERVICE1, tokensInput, 2);
        vm.stopPrank();
    }

    function test_UpdateBAppWithNewTokens() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock2);
        tokensInput[1] = address(ETH_ADDRESS);
        proxiedManager.addTokensToBApp(SERVICE1, tokensInput);
        vm.stopPrank();
    }

    function testRevert_UpdateBAppWithAlreadyPresentTokensRevert() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(ETH_ADDRESS);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenAlreadyAddedToBApp.selector, address(erc20mock)));
        proxiedManager.addTokensToBApp(SERVICE1, tokensInput);
        vm.stopPrank();
    }
}
