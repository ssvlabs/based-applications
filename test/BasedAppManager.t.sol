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
    address SERVICE1 = makeAddr("Service1");
    address SERVICE2 = makeAddr("Service2");

    function setUp() public {
        vm.label(OWNER, "Owner");
        vm.label(USER1, "User1");
        vm.label(ATTACKER, "Attacker");
        vm.label(RECEIVER, "Receiver");
        vm.label(RECEIVER2, "Receiver2");
        vm.label(SERVICE1, "Service1");
        vm.label(SERVICE2, "Service2");
        vm.startPrank(OWNER);
        implementation = new BasedAppManager();
        bytes memory data = abi.encodeWithSelector(implementation.initialize.selector); // Encodes initialize() call
        proxy = new ERC1967Proxy(address(implementation), data);
        proxiedManager = BasedAppManager(address(proxy));

        vm.label(address(proxiedManager), "BasedAppManagerProxy");

        erc20mock = new ERC20Mock();
        erc20mock.transfer(USER1, 1000 * 10 ** 18);
        erc20mock.transfer(RECEIVER, 1000 * 10 ** 18);

        erc20mock2 = new ERC20Mock();
        erc20mock2.transfer(USER1, 1000 * 10 ** 18);
        erc20mock2.transfer(RECEIVER, 1000 * 10 ** 18);

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
        vm.expectRevert("Invalid percentage");
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
        vm.expectRevert("Invalid percentage");
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
        vm.expectRevert("Delegation already exists");
        proxiedManager.delegateBalance(RECEIVER, 2);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1, "Delegated amount should be 0.01%");
        assertEq(totalDelegatedPercentage, 1, "Total delegated percentage should be 0.01%");
        vm.stopPrank();
    }

    function testRevertInvalidPercentageDelegateBalance() public {
        vm.startPrank(USER1);
        vm.expectRevert("Invalid percentage");
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
        vm.expectRevert("Invalid percentage");
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

    function testRemoveDelgateBalanceAndComputeTotal() public {
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
        uint256 strategyId1 = proxiedManager.createStrategy(5);
        proxiedManager.createStrategy(100);
        proxiedManager.createStrategy(1000);
        uint256 strategyId4 = proxiedManager.createStrategy(10_000);
        assertEq(strategyId1, 1, "Strategy id 1 was saved correctly");
        assertEq(strategyId4, 4, "Strategy id 4 was saved correctly");
        (address owner, uint32 delegationFeeOnRewards,,) = proxiedManager.strategies(strategyId1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(delegationFeeOnRewards, 5, "Strategy fee");
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
        uint256 strategyId = proxiedManager.createStrategy(1);
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
        uint256 strategyId = proxiedManager.createStrategy(1);
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
        uint256 strategyId = proxiedManager.createStrategy(1);
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

    function testCreateStrategyAndSingleDepositAndMultipleWithdrawal() public {
        vm.startPrank(USER1);
        uint256 strategyId = proxiedManager.createStrategy(1);
        erc20mock.approve(address(proxiedManager), 200_000);
        proxiedManager.depositERC20(strategyId, erc20mock, 100_000);

        assertEq(
            proxiedManager.strategyTokenBalances(strategyId, USER1, address(erc20mock)),
            100_000,
            "User strategy balance should be 100_000"
        );
        proxiedManager.fastWithdrawERC20(strategyId, erc20mock, 50_000);
        proxiedManager.fastWithdrawERC20(strategyId, erc20mock, 10_000);

        assertEq(
            proxiedManager.strategyTokenBalances(strategyId, USER1, address(erc20mock)),
            40_000,
            "User strategy balance should be 50_000"
        );
        vm.stopPrank();
    }

    function testStrategyOptInToService() public {
        testCreateStrategy();
        testRegisterService();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 10_000; // 100%
        proxiedManager.optInToService(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountServiceStrategy(USER1, SERVICE1);
        assertEq(strategyId, 1, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE1, address(erc20mock));
        assertEq(obligationPercentage, 10_000, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock));
        assertEq(usedTokens, 1, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE1);
        assertEq(numberOfObligations, 1, "Number of obligations");
        vm.stopPrank();
    }

    function testStrategyOptInToServiceNonMatchingTokensAndObligations() public {
        testCreateStrategy();
        testRegisterService();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](1);
        obligationPercentagesInput[0] = 10_000; // 100%
        vm.expectRevert("Strategy: tokens and percentages length mismatch");
        proxiedManager.optInToService(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountServiceStrategy(USER1, SERVICE1);
        assertEq(strategyId, 0, "Strategy id was not saved");
        vm.stopPrank();
    }

    function testStrategyOptInToServiceNotAllowNonMatchingStrategyTokensWithServiceTokens() public {
        testCreateStrategy();
        testRegisterService();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32[] memory obligationPercentagesInput = new uint32[](2);
        obligationPercentagesInput[0] = 6000; // 60%
        obligationPercentagesInput[1] = 5000; // 50%
        vm.expectRevert("Strategy: token not supported by service");
        proxiedManager.optInToService(1, SERVICE1, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountServiceStrategy(USER1, SERVICE1);
        assertEq(strategyId, 0, "Strategy id was not saved");
        vm.stopPrank();
    }

    function testCreateObligationToExistingStrategyRevert() public {
        testStrategyOptInToService();
        vm.startPrank(USER1);
        (address owner,,,) = proxiedManager.strategies(1);
        assertEq(owner, USER1, "Strategy owner");
        address tokensInput = address(erc20mock2);
        uint32 obligationPercentagesInput = 7000; // 70%
        vm.expectRevert("Service not opted-in");
        proxiedManager.createObligation(1, SERVICE2, tokensInput, obligationPercentagesInput);
        uint256 strategyId = proxiedManager.accountServiceStrategy(USER1, SERVICE2);
        assertEq(strategyId, 0, "Strategy id");
        uint256 obligationPercentage = proxiedManager.obligations(strategyId, SERVICE2, address(erc20mock2));
        assertEq(obligationPercentage, 0, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, address(erc20mock2));
        assertEq(usedTokens, 0, "Used tokens");
        uint32 numberOfObligations = proxiedManager.obligationsCounter(strategyId, SERVICE2);
        assertEq(numberOfObligations, 0, "Number of obligations");
        vm.stopPrank();
    }

    function checkUserTotalAndObligationNumber() public {}
    function testRevertNotMatchTokensServiceAndStrategy() public {}
    function testRevertDepositNonSupportedTokensIntoStrategy() public {}
    function testRevertDepositNonSupportedETHIntoStrategy() public {}
    function testRevertObligationHigherThanMaxPercentage() public {}
    function testCreateObligationToNonExistingServiceRevert() public {}
    function testCreateObligationToNonExistingStrategyRevert() public {}
    function testCreateObligationToNotOwnedStrategyRevert() public {}
    function testWithdrawErc20FromStrategy() public {}
    function testWithdrawETHFromStrategy() public {}
    function testUpdateStrategy() public {}
    function testRevertObligationWithNonMatchingToken() public {}

    // ********************
    // ** Section: bApps **
    // ********************

    function testRegisterService() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        uint32 slashingCorrelationPenaltyInput = 100;
        proxiedManager.registerService(
            USER1, SERVICE1, tokensInput, sharedRiskLevelInput, slashingCorrelationPenaltyInput
        );
        (address owner, uint32 slashingCorrelationPenalty, uint32 sharedRiskLevel) = proxiedManager.services(SERVICE1);
        assertEq(owner, USER1, "Service owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "Service sharedRiskLevel");
        assertEq(slashingCorrelationPenaltyInput, slashingCorrelationPenalty, "Service slashingCorrelationPenalty");
        address[] memory tokens = proxiedManager.getServiceTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "Service token");
        assertEq(tokensInput[0], address(erc20mock), "Service token");
        vm.stopPrank();
    }

    function testRegisterServiceTwice() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        uint32 slashingCorrelationPenaltyInput = 100;
        proxiedManager.registerService(
            USER1, SERVICE1, tokensInput, sharedRiskLevelInput, slashingCorrelationPenaltyInput
        );
        (address owner, uint32 slashingCorrelationPenalty, uint32 sharedRiskLevel) = proxiedManager.services(SERVICE1);
        vm.expectRevert("Service already registered");
        proxiedManager.registerService(USER1, SERVICE1, tokensInput, 2, 2);
        assertEq(owner, USER1, "Service owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "Service sharedRiskLevel");
        assertEq(slashingCorrelationPenaltyInput, slashingCorrelationPenalty, "Service slashingCorrelationPenalty");
        address[] memory tokens = proxiedManager.getServiceTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "Service token");
        assertEq(tokensInput[0], address(erc20mock), "Service token");
        vm.stopPrank();
    }

    function testRegisterServiceOverwrite() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        uint32 slashingCorrelationPenaltyInput = 100;
        proxiedManager.registerService(
            USER1, SERVICE1, tokensInput, sharedRiskLevelInput, slashingCorrelationPenaltyInput
        );
        (address owner, uint32 slashingCorrelationPenalty, uint32 sharedRiskLevel) = proxiedManager.services(SERVICE1);
        assertEq(owner, USER1, "Service owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "Service sharedRiskLevel");
        assertEq(slashingCorrelationPenaltyInput, slashingCorrelationPenalty, "Service slashingCorrelationPenalty");
        address[] memory tokens = proxiedManager.getServiceTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "Service token");
        assertEq(tokensInput[0], address(erc20mock), "Service token");
        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert("Service already registered");
        proxiedManager.registerService(ATTACKER, SERVICE1, tokensInput, 2, 2);
        vm.stopPrank();
    }

    function testUpdateService() public {}
}
