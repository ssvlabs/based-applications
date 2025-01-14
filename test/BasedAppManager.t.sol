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
    address ATTACKER = makeAddr("Attacker");
    address RECEIVER = makeAddr("Receiver");
    address RECEIVER2 = makeAddr("Receiver2");
    address SERVICE1 = makeAddr("BApp1");
    address SERVICE2 = makeAddr("BApp2");

    uint256 STRATEGY1 = 1;
    uint32 STRATEGY1_INITIAL_FEE = 5;
    uint32 STRATEGY1_UPDATE_FEE = 10;
    address ERC20_ADDRESS1 = address(erc20mock);
    address ERC20_ADDRESS2 = address(erc20mock2);

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 constant INITIAL_USER1_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 constant INITIAL_USER1_BALANCE_ETH = 10 ether;
    uint256 constant INITIAL_RECEIVER_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 constant INITIAL_RECEIVER_BALANCE_ETH = 10 ether;

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

    // *****************************************
    // ** Section: Ownership **
    // *****************************************

    // Check the owner of the BasedAppManager
    function testOwner() public view {
        assertEq(proxiedManager.owner(), OWNER, "Owner should be the deployer");
    }

    function testImplementation() public view {
        address currentImplementation = address(
            uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1))))
        );
        assertEq(
            currentImplementation, address(implementation), "Implementation should be the BasedAppManager contract"
        );
    }

    function testUpgradeUnauthorized() public {
        // Deploy a new implementation contract
        BasedAppManager newImplementation = new BasedAppManager();
        // Test that a non-owner cannot upgrade the contract
        vm.prank(address(1)); // Simulate call from a non-owner
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(1)));
        proxiedManager.upgradeToAndCall(address(newImplementation), bytes(""));
    }

    function testUpgradeAuthorized() public {
        // Deploy a new implementation contract
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

    function testDelegateMinimumBalance() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1, "Delegated amount should be 0.01%");
        assertEq(totalDelegatedPercentage, 1, "Delegated percentage should be 0.01%");
        vm.stopPrank();
    }

    function testDelegatePartialBalance(
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

    function testDelegateFullBalance() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 10_000);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 10_000, "Delegated amount should be 100%");
        assertEq(totalDelegatedPercentage, 10_000, "Delegated percentage should be 100%");
        vm.stopPrank();
    }

    function testDelegateBalanceTooLow() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, 0);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        assertEq(delegatedAmount, 0, "Delegated amount should be 0%");
        vm.stopPrank();
    }

    function testDelegateBalanceTooHigh(
        uint32 highBalance
    ) public {
        vm.assume(highBalance > 10_000);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, highBalance);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        assertEq(delegatedAmount, 0, "Delegated amount should be 0%");

        vm.stopPrank();
    }

    function testUpdateTotalDelegatedPercentage(uint32 percentage1, uint32 percentage2) public {
        vm.assume(percentage1 > 0 && percentage2 > 0); // Optional if the inputs are unsigned
        vm.assume(percentage1 < 10_000 && percentage2 < 10_000);
        vm.assume(percentage1 + percentage2 <= 10_000);
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

    function testRevertTotalDelegatePercentage() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        vm.expectRevert("Total percentage exceeds 100%");
        proxiedManager.delegateBalance(RECEIVER2, 1e4);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 delegatedAmount2 = proxiedManager.delegations(USER1, RECEIVER2);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1, "Delegated amount should be 0.01%");
        assertEq(delegatedAmount2, 0, "Delegated amount should be 0%");
        assertEq(totalDelegatedPercentage, 1, "Total delegated percentage should be 0.01%");
        vm.stopPrank();
    }

    function testRevertDoubleDelegateSameReceiver() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        vm.expectRevert(abi.encodeWithSelector(ICore.DelegationAlreadyExists.selector));
        proxiedManager.delegateBalance(RECEIVER, 2);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1, "Delegated amount should be 0.01%");
        assertEq(totalDelegatedPercentage, 1, "Total delegated percentage should be 0.01%");
        vm.stopPrank();
    }

    function testRevertInvalidPercentageDelegateBalance() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, 1e4 + 1);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 0, "Delegated amount should be 0.01%");
        assertEq(totalDelegatedPercentage, 0, "Total delegated percentage should be 0.01%");
        vm.stopPrank();
    }

    function testUpdateTotalDelegatePercentageByTheSameUser() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        proxiedManager.updateDelegatedBalance(RECEIVER, 1e4);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, 1e4 + 1);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1e4, "Delegated amount should be 100%");
        assertEq(totalDelegatedPercentage, 1e4, "Total delegated percentage should be 100%");
        vm.stopPrank();
    }

    function testRevertUpdateBalanceNotExisting() public {
        vm.startPrank(USER1);
        vm.expectRevert("Delegation does not exist");
        proxiedManager.updateDelegatedBalance(RECEIVER, 1e4);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 0, "Delegated amount should be 100%");
        assertEq(totalDelegatedPercentage, 0, "Total delegated percentage should be 100%");
        vm.stopPrank();
    }

    function testRevertUpdateBalanceTooHigh() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        proxiedManager.delegateBalance(RECEIVER2, 1);
        vm.expectRevert("Percentage exceeds 100%");
        proxiedManager.updateDelegatedBalance(RECEIVER, 1e4);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 delegatedAmount2 = proxiedManager.delegations(USER1, RECEIVER2);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1, "Delegated amount should be 100%");
        assertEq(delegatedAmount2, 1, "Delegated amount should be 100%");
        assertEq(totalDelegatedPercentage, 2, "Total delegated percentage should be 100%");
        vm.stopPrank();
    }

    function testRemoveDelegateBalance() public {
        testDelegateFullBalance();
        vm.startPrank(USER1);
        proxiedManager.removeDelegatedBalance(RECEIVER);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 0, "Delegated amount should be 0%");
        assertEq(totalDelegatedPercentage, 0, "Total delegated percentage should be 0%");
        vm.stopPrank();
    }

    function testRemoveDelegatedBalanceAndComputeTotal() public {
        testUpdateTotalDelegatedPercentage(100, 200);
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

    function testRevertRemoveNonExistingBalance() public {
        vm.startPrank(USER1);
        vm.expectRevert("No delegation exists");
        proxiedManager.removeDelegatedBalance(RECEIVER);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 0, "Delegated amount should be 0%");
        assertEq(totalDelegatedPercentage, 0, "Total delegated percentage should be 0%");
        vm.stopPrank();
    }

    // ***********************
    // ** Section: Strategy **
    // ***********************

    function testCreateStrategy() public {
        vm.startPrank(USER1);
        uint256 strategyId1 = proxiedManager.createStrategy(STRATEGY1_INITIAL_FEE);
        proxiedManager.createStrategy(100);
        proxiedManager.createStrategy(1000);
        uint256 strategyId4 = proxiedManager.createStrategy(10_000);
        assertEq(strategyId1, 1, "Strategy id 1 was saved correctly");
        assertEq(strategyId4, 4, "Strategy id 4 was saved correctly");
        (address owner, uint32 delegationFeeOnRewards,,) = proxiedManager.strategies(strategyId1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(delegationFeeOnRewards, STRATEGY1_INITIAL_FEE, "Strategy fee");
        vm.stopPrank();
    }

    function testCreateStrategyWithZeroFee() public {
        vm.startPrank(USER1);
        vm.expectRevert("Invalid delegation fee");
        proxiedManager.createStrategy(0);
        vm.stopPrank();
    }

    function testCreateStrategyWithTooHighFee() public {
        vm.startPrank(USER1);
        vm.expectRevert("Invalid delegation fee");
        proxiedManager.createStrategy(10_001);
        vm.stopPrank();
    }

    function testCreateStrategyAndSingleDeposit() public {
        vm.startPrank(USER1);
        uint256 strategyId = proxiedManager.createStrategy(STRATEGY1_INITIAL_FEE);
        erc20mock.approve(address(proxiedManager), 200_000);
        proxiedManager.depositERC20(strategyId, erc20mock, 100_000);

        assertEq(
            proxiedManager.strategyTokenBalances(strategyId, USER1, address(erc20mock)),
            100_000,
            "User strategy balance should be 100_000"
        );
        vm.stopPrank();
    }

    function testCreateStrategyAndMultipleDeposits() public {
        vm.startPrank(USER1);
        uint256 strategyId = proxiedManager.createStrategy(STRATEGY1_INITIAL_FEE);
        uint256 strategyId2 = proxiedManager.createStrategy(100);
        erc20mock.approve(address(proxiedManager), 200_000);
        proxiedManager.depositERC20(strategyId, erc20mock, 100_000);
        assertEq(
            proxiedManager.strategyTokenBalances(strategyId, USER1, address(erc20mock)),
            100_000,
            "User strategy balance should be 100_000"
        );
        proxiedManager.depositERC20(strategyId2, erc20mock, 50_000);
        assertEq(
            proxiedManager.strategyTokenBalances(strategyId2, USER1, address(erc20mock)),
            50_000,
            "User strategy balance should be 50_000"
        );
        proxiedManager.depositERC20(strategyId, erc20mock, 20_000);
        assertEq(
            proxiedManager.strategyTokenBalances(strategyId, USER1, address(erc20mock)),
            120_000,
            "User strategy balance should be 120_000"
        );
        vm.stopPrank();
    }

    function testCreateStrategyAndSingleDepositAndSingleWithdrawal() public {
        vm.startPrank(USER1);
        uint256 strategyId = proxiedManager.createStrategy(STRATEGY1_INITIAL_FEE);
        erc20mock.approve(address(proxiedManager), 200_000);
        proxiedManager.depositERC20(strategyId, erc20mock, 100_000);

        assertEq(
            proxiedManager.strategyTokenBalances(strategyId, USER1, address(erc20mock)),
            100_000,
            "User strategy balance should be 100_000"
        );
        proxiedManager.fastWithdrawERC20(strategyId, erc20mock, 50_000);

        assertEq(
            proxiedManager.strategyTokenBalances(strategyId, USER1, address(erc20mock)),
            50_000,
            "User strategy balance should be 50_000"
        );
        vm.stopPrank();
    }

    function testCreateStrategyAndSingleDepositAndMultipleFastWithdrawals() public {
        vm.startPrank(USER1);
        uint256 strategyId = proxiedManager.createStrategy(STRATEGY1_INITIAL_FEE);
        erc20mock.approve(address(proxiedManager), 200_000);
        proxiedManager.depositERC20(strategyId, erc20mock, 100_000);
        assertEq(
            proxiedManager.strategyTokenBalances(strategyId, USER1, address(erc20mock)),
            100_000,
            "User strategy balance should be 100_000"
        );
        // There was no opt-in so the fast withdraw is allowed
        proxiedManager.fastWithdrawERC20(strategyId, erc20mock, 50_000);
        proxiedManager.fastWithdrawERC20(strategyId, erc20mock, 10_000);
        assertEq(
            proxiedManager.strategyTokenBalances(strategyId, USER1, address(erc20mock)),
            40_000,
            "User strategy balance should be 50_000"
        );
        vm.stopPrank();
    }

    function testStrategyOptInToBApp() public {
        testCreateStrategy();
        testRegisterBApp();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 9000; // 90%
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, 9000, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
        vm.stopPrank();
    }

    function testStrategyOptInToBAppWithMultipleTokens() public {
        testCreateStrategy();
        testRegisterBAppWith2Tokens();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 9000; // 90%
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, 9000, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
        vm.stopPrank();
    }

    function testStrategyOptInToBAppWithETH() public {
        testCreateStrategy();
        testRegisterBAppWithETH();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = ETH_ADDRESS;
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 10_000; // 100%
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, ETH_ADDRESS);
        assertEq(obligationPercentage, 10_000, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, ETH_ADDRESS);
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
        vm.stopPrank();
    }

    function testStrategyOptInWithNonOwner() public {
        testCreateStrategy();
        testRegisterBApp();
        vm.startPrank(ATTACKER);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 9000; // 90%
        vm.expectRevert("Strategy: not the owner");
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        vm.stopPrank();
    }

    function testStrategyOptInToBAppNonMatchingTokensAndObligations() public {
        testCreateStrategy();
        testRegisterBApp();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 10_000; // 100%
        vm.expectRevert("Strategy: tokens and percentages length mismatch");
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 0, "Strategy id was not saved");
        vm.stopPrank();
    }

    function testStrategyOptInToBAppNotAllowNonMatchingStrategyTokensWithBAppTokens() public {
        testCreateStrategy();
        testRegisterBApp();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](2);
        obligationPercentagesInput[0] = 6000; // 60%
        obligationPercentagesInput[1] = 5000; // 50%
        vm.expectRevert("Strategy: token not supported by bApp");
        proxiedManager.optInToBApp(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE1);
        assertEq(strategyId, 0, "Strategy id was not saved");
        vm.stopPrank();
    }

    function testCreateObligationToExistingStrategyRevert() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address tokensInput = address(erc20mock2);
        uint32 obligationPercentagesInput = 7000; // 70%
        vm.expectRevert("BApp not opted-in");
        proxiedManager.createObligation(1, SERVICE2, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountBAppStrategy(USER1, SERVICE2);
        assertEq(strategyId, 0, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE2, address(erc20mock2));
        assertEq(obligationPercentage, 0, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock2));
        assertEq(usedTokens, 0, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE2);
        assertEq(numberOfObligations, 0, "Number of obligations");
        vm.stopPrank();
    }

    function testStrategyOwnerDepositERC20WithNoObligation(
        uint256 amount
    ) public {
        vm.assume(amount > 0 && amount < INITIAL_USER1_BALANCE_ERC20);
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        proxiedManager.depositERC20(1, erc20mock2, amount);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, amount, "User strategy balance not matching");
        vm.stopPrank();
    }

    function testStrategyOwnerDepositETHWithNoObligation() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        proxiedManager.depositETH{value: 1 ether}(1);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, ETH_ADDRESS);
        assertEq(strategyTokenBalance, 1 ether, "User strategy balance not matching");
        vm.stopPrank();
    }

    function testRevertObligationNotMatchTokensBApp() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        vm.expectRevert("Strategy: token not supported by bApp");
        proxiedManager.createObligation(1, SERVICE1, address(erc20mock2), 100);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokens.length, 1, "BApp token length");
        vm.stopPrank();
    }

    function testCreateStrategyETHAndDepositETH() public {
        testStrategyOptInToBAppWithETH();
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        proxiedManager.depositETH{value: 1 ether}(1);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, ETH_ADDRESS);
        assertEq(strategyTokenBalance, 1 ether, "User strategy balance not matching");
        vm.stopPrank();
    }

    function testRevertObligationHigherThanMaxPercentage() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        vm.expectRevert("Invalid obligation percentage");
        proxiedManager.createObligation(1, SERVICE1, address(erc20mock2), 10_001);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.stopPrank();
    }

    function testCreateObligationToNonExistingBAppRevert() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        vm.expectRevert("BApp not opted-in");
        proxiedManager.createObligation(1, SERVICE2, address(erc20mock), 100);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.stopPrank();
    }

    function testCreateObligationToNonExistingStrategyRevert() public {
        vm.startPrank(USER1);
        vm.expectRevert("Not the strategy owner");
        proxiedManager.createObligation(3, SERVICE1, address(erc20mock), 100);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.stopPrank();
    }

    function testCreateObligationToNotOwnedStrategyRevert() public {
        vm.startPrank(ATTACKER);
        vm.expectRevert("Not the strategy owner");
        proxiedManager.createObligation(1, SERVICE1, address(erc20mock), 100);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, ATTACKER, address(erc20mock));
        assertEq(strategyTokenBalance, 0, "User strategy balance should be 0");
        vm.stopPrank();
    }

    function testCreateNewObligationSuccessful() public {
        testStrategyOptInToBAppWithMultipleTokens();
        vm.startPrank(USER1);
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokens[1], address(erc20mock2), "BApp token 2");
        assertEq(tokens.length, 2, "BApp token length");
        proxiedManager.createObligation(STRATEGY1, SERVICE1, address(erc20mock2), 10_000);
        vm.stopPrank();
    }

    function testFastWithdrawErc20FromStrategy() public {
        testStrategyOwnerDepositERC20WithNoObligation(200);
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 200, "User strategy balance should be 200");
        proxiedManager.fastWithdrawERC20(1, erc20mock2, 50);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, address(erc20mock2));
        assertEq(strategyTokenBalance, 150, "User strategy balance should be 150");
        vm.stopPrank();
    }

    function testWithdrawETHFromStrategy() public {
        testStrategyOwnerDepositETHWithNoObligation();
        vm.startPrank(USER1);
        uint256 strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, ETH_ADDRESS);
        assertEq(strategyTokenBalance, 1 ether, "User strategy balance should be 1 ether");
        proxiedManager.fastWithdrawETH(1, 0.4 ether);
        strategyTokenBalance = proxiedManager.strategyTokenBalances(1, USER1, ETH_ADDRESS);
        assertEq(strategyTokenBalance, 0.6 ether, "User strategy balance should be 0.6 ether");
        vm.stopPrank();
    }

    function testFastUpdateObligation() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        uint32 strategyId = 1;
        proxiedManager.fastUpdateObligation(strategyId, SERVICE1, address(erc20mock), 10_000);
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, 10_000, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
        vm.stopPrank();
    }

    function testStrategyFeeUpdateOnInitialLimit() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
        vm.warp(block.timestamp + 7 days);
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        (owner, fee, feeProposed, feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, 20, "Strategy fee");
        assertEq(feeProposed, 0, "Strategy fee proposed");
        assertEq(feeUpdateTime, 0, "Strategy fee update time");
        vm.stopPrank();
    }

    function testStrategyFeeUpdateOnFinalTimeLimit() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
        vm.warp(block.timestamp + 7 days + 1 days);
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        (owner, fee, feeProposed, feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, 20, "Strategy fee");
        assertEq(feeProposed, 0, "Strategy fee proposed");
        assertEq(feeUpdateTime, 0, "Strategy fee update time");
        vm.stopPrank();
    }

    function testStrategyFeeUpdateTooLate() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
        vm.warp(block.timestamp + 7 days + 1 days + 1 seconds);
        vm.expectRevert("Fee update expired");
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        (owner, fee, feeProposed, feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
        vm.stopPrank();
    }

    function testStrategyFeeUpdateTooEarly() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        proxiedManager.proposeFeeUpdate(STRATEGY1, 20);
        (address owner, uint32 fee, uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
        vm.warp(block.timestamp + 7 days - 1 seconds);
        vm.expectRevert("Timelock not passed");
        proxiedManager.finalizeFeeUpdate(STRATEGY1);
        (owner, fee, feeProposed, feeUpdateTime) = proxiedManager.strategies(STRATEGY1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(fee, STRATEGY1_INITIAL_FEE, "Strategy fee");
        assertEq(feeProposed, 20, "Strategy fee proposed");
        assertEq(feeUpdateTime, 604_801, "Strategy fee update time");
        vm.stopPrank();
    }

    function testUpdateStrategyObligationFinalizeOnInitialLimit() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + 7 days);
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        uint32 newPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(newPercentage, 1000, "Obligation new percentage");
        vm.stopPrank();
    }

    function testUpdateStrategyObligationFinalizeOnLatestLimit() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + 7 days + 1 days);
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        uint32 newPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(newPercentage, 1000, "Obligation new percentage");
        vm.stopPrank();
    }

    function testUpdateStrategyObligationRemoval() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 0);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 obligationCounter = proxiedManager.obligationsCounter(STRATEGY1, SERVICE1);
        assertEq(obligationCounter, 1, "Obligation counter");
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + 7 days + 1 days);
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(percentage, 0, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        uint32 newPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(newPercentage, 0, "Obligation new percentage");
        uint32 newObligationCounter = proxiedManager.obligationsCounter(STRATEGY1, SERVICE1);
        assertEq(newObligationCounter, 0, "Obligation counter");
        vm.stopPrank();
    }

    function testUpdateStrategyObligationFinalizeTooLate() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + 7 days + 1 days + 1 seconds);
        vm.expectRevert("Update expired");
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        uint32 newPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(newPercentage, 9000, "Obligation new percentage is still the same");
        vm.stopPrank();
    }

    function testUpdateStrategyObligationFinalizeTooEarly() public {
        testStrategyOptInToBApp();
        vm.startPrank(USER1);
        proxiedManager.proposeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock), 1000);
        (uint32 percentage, uint256 requestTime) =
            proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        uint32 oldPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(oldPercentage, 9000, "Obligation percentage proposed");
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        vm.warp(block.timestamp + 7 days - 1 seconds);
        vm.expectRevert("Timelock not elapsed");
        proxiedManager.finalizeUpdateObligation(STRATEGY1, SERVICE1, address(erc20mock));
        (percentage, requestTime) = proxiedManager.obligationRequests(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(percentage, 1000, "Obligation percentage proposed");
        assertEq(requestTime, 1, "Obligation update time");
        uint32 newPercentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock));
        assertEq(newPercentage, 9000, "Obligation new percentage is still the same");
        vm.stopPrank();
    }

    function testAsyncWithdrawFromStrategy() public {
        testCreateStrategyAndMultipleDeposits();
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
        vm.warp(block.timestamp + 5 days);
        proxiedManager.finalizeWithdrawal(STRATEGY1, erc20mock);
        assertEq(
            proxiedManager.strategyTokenBalances(STRATEGY1, USER1, address(erc20mock)),
            119_000,
            "User strategy balance should be 110_000"
        );
        (amount, requestTime) = proxiedManager.withdrawalRequests(STRATEGY1, USER1, address(erc20mock));
        assertEq(requestTime, 0, "Request time");
        assertEq(amount, 0, "Request amount");
        vm.stopPrank();
    }

    // function testFastRemovalObligation() public {
    //      testStrategyOptInToBApp();
    //     vm.startPrank(USER1);
    //     proxiedManager.createObligation(STRATEGY1, SERVICE1, address(erc20mock2), 10000);
    //     uint32 percentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock2));
    //     assertEq(percentage, 10000, "Obligation percentage");
    //     uint32 numberOfObligations = proxiedManager.obligationsCounter(STRATEGY1, SERVICE1);
    //     assertEq(numberOfObligations, 2, "Number of obligations");
    //     proxiedManager.fastRemoveObligation(STRATEGY1, SERVICE1, address(erc20mock2));
    //     percentage = proxiedManager.obligations(STRATEGY1, SERVICE1, address(erc20mock2));
    //     assertEq(percentage, 0, "Obligation percentage");
    //     numberOfObligations = proxiedManager.obligationsCounter(STRATEGY1, SERVICE1);
    //     assertEq(numberOfObligations, 1, "Number of obligations");
    //     vm.stopPrank();
    // }

    // function testRevertFastRemovalObligationInvalid() public {

    // }

    // todo check update removal obligation
    // todo test empty updates, when no request was sent before, so just the finalize.
    // todo test double finalize
    // fastRemove obligation

    // ********************
    // ** Section: bApps **
    // ********************

    function testRegisterBApp() public {
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

    function testRegisterBAppWith2Tokens() public {
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

    function testRegisterBAppWithETH() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
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

    function testRegisterBAppTwice() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput);
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        vm.expectRevert("BApp already registered");
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, 2);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokensInput[0], address(erc20mock), "BApp token");
        vm.stopPrank();
    }

    function testRegisterBAppOverwrite() public {
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
        vm.expectRevert("BApp already registered");
        proxiedManager.registerBApp(ATTACKER, SERVICE1, tokensInput, 2);
        vm.stopPrank();
    }

    function testUpdateBAppWithNewTokens() public {
        testRegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock2);
        tokensInput[1] = address(ETH_ADDRESS);
        proxiedManager.addTokensToBApp(SERVICE1, tokensInput);
        vm.stopPrank();
    }

    function testUpdateBAppWithAlreadyPresentTokensRevert() public {
        testRegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(ETH_ADDRESS);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenAlreadyAddedToBApp.selector, address(erc20mock)));
        proxiedManager.addTokensToBApp(SERVICE1, tokensInput);
        vm.stopPrank();
    }
}
