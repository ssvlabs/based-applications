// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {BasedAppManagerSetupTest, IStrategyManager, ICore} from "@ssv/test/BAppManager.setup.t.sol";

contract BasedAppManagerDelegateTest is BasedAppManagerSetupTest {
    function checkDelegation(
        address owner,
        address receiver,
        uint32 expectedDelegatedAmount,
        uint32 expectedTotalDelegatedPercentage
    ) internal view {
        uint32 delegatedAmount = proxiedManager.delegations(owner, receiver);
        uint32 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(owner);
        assertEq(delegatedAmount, expectedDelegatedAmount, "Delegated percentage to the receiver should be the expected one");
        assertEq(totalDelegatedPercentage, expectedTotalDelegatedPercentage, "Total delegated percentage should be the expected");
    }

    function checkDelegationZero(address owner, address receiver, uint32 expectedTotalDelegatedPercentage) internal view {
        uint32 delegatedAmount = proxiedManager.delegations(owner, receiver);
        uint32 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(owner);
        assertEq(delegatedAmount, 0, "Delegated percentage to the receiver should be 0");
        assertEq(totalDelegatedPercentage, expectedTotalDelegatedPercentage, "Total delegated percentage should be the expected");
    }

    function test_DelegateMinimumBalance() public {
        uint32 delegatedAmount = 1;
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationCreated(USER1, RECEIVER, delegatedAmount);
        proxiedManager.delegateBalance(RECEIVER, delegatedAmount);
        checkDelegation(USER1, RECEIVER, delegatedAmount, delegatedAmount);
    }

    function test_DelegatePartialBalance(uint32 percentageAmount) public {
        vm.assume(percentageAmount > 0 && percentageAmount < proxiedManager.maxPercentage());
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationCreated(USER1, RECEIVER, percentageAmount);
        proxiedManager.delegateBalance(RECEIVER, percentageAmount);
        checkDelegation(USER1, RECEIVER, percentageAmount, percentageAmount);
    }

    function test_DelegateFullBalance() public {
        uint32 delegatedAmount = proxiedManager.maxPercentage();
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, delegatedAmount);
        checkDelegation(USER1, RECEIVER, delegatedAmount, delegatedAmount);
        vm.stopPrank();
    }

    function testRevert_DelegateBalanceTooLow() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, 0);
    }

    function testRevert_DelegateBalanceTooHigh(uint32 highBalance) public {
        vm.assume(highBalance > proxiedManager.maxPercentage());
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, highBalance);
    }

    function test_UpdateTotalDelegatedPercentage(uint32 percentage1, uint32 percentage2) public {
        vm.assume(percentage1 > 0 && percentage2 > 0);
        vm.assume(percentage1 < proxiedManager.maxPercentage() && percentage2 < proxiedManager.maxPercentage());
        vm.assume(percentage1 + percentage2 <= proxiedManager.maxPercentage());

        vm.startPrank(USER1);

        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationCreated(USER1, RECEIVER, percentage1);
        proxiedManager.delegateBalance(RECEIVER, percentage1);
        vm.expectEmit(true, true, true, true);
        checkDelegation(USER1, RECEIVER, percentage1, percentage1);

        emit IStrategyManager.DelegationCreated(USER1, RECEIVER2, percentage2);
        proxiedManager.delegateBalance(RECEIVER2, percentage2);
        checkDelegation(USER1, RECEIVER, percentage1, percentage1 + percentage2);

        vm.stopPrank();
    }

    function testRevert_TotalDelegatePercentageOverMax(uint32 percentage1) public {
        test_DelegatePartialBalance(percentage1);

        uint32 percentage2 = proxiedManager.maxPercentage();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.ExceedingPercentageUpdate.selector));
        proxiedManager.delegateBalance(RECEIVER2, percentage2);
        checkDelegationZero(USER1, RECEIVER2, percentage1);
        vm.stopPrank();
    }

    function testRevert_DoubleDelegateSameReceiver(uint32 percentage1, uint32 percentage2) public {
        vm.assume(percentage1 > 0 && percentage2 > 0);
        vm.assume(percentage1 <= proxiedManager.maxPercentage() && percentage2 <= proxiedManager.maxPercentage());

        vm.startPrank(USER1);

        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationCreated(USER1, RECEIVER, percentage1);
        proxiedManager.delegateBalance(RECEIVER, percentage1);
        checkDelegation(USER1, RECEIVER, percentage1, percentage1);

        vm.expectRevert(abi.encodeWithSelector(ICore.DelegationAlreadyExists.selector));
        proxiedManager.delegateBalance(RECEIVER, percentage2);

        vm.stopPrank();
    }

    function testRevert_InvalidPercentageDelegateBalance() public {
        uint32 maxPlusOne = proxiedManager.maxPercentage() + 1;
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, maxPlusOne);
    }

    function test_UpdateDelegatedBalance() public {
        test_DelegateMinimumBalance();

        uint32 updatePercentage = proxiedManager.maxPercentage();
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationUpdated(USER1, RECEIVER, updatePercentage);
        proxiedManager.updateDelegatedBalance(RECEIVER, updatePercentage);
        checkDelegation(USER1, RECEIVER, updatePercentage, updatePercentage);
    }

    function testRevert_UpdateTotalDelegatePercentageByTheSameUser() public {
        test_UpdateDelegatedBalance();
        uint32 maxPlusOne = proxiedManager.maxPercentage() + 1;
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, maxPlusOne);
    }

    function testRevert_UpdateTotalDelegatePercentageWithZero() public {
        test_DelegateMinimumBalance();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidPercentage.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 0);
    }

    function testRevert_UpdateTotalDelegatePercentageWithSameBalance() public {
        test_DelegateMinimumBalance();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.DelegationExistsWithSameValue.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 1);
    }

    function testRevert_UpdateBalanceNotExisting() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.DelegationDoesNotExist.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 1e4);
    }

    function testRevert_UpdateBalanceTooHigh() public {
        uint32 delegatedAmount1 = 1;
        uint32 delegatedAmount2 = 1;

        vm.startPrank(USER1);

        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationCreated(USER1, RECEIVER, delegatedAmount1);
        proxiedManager.delegateBalance(RECEIVER, delegatedAmount1);
        checkDelegation(USER1, RECEIVER, delegatedAmount1, delegatedAmount1);

        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationCreated(USER1, RECEIVER2, delegatedAmount2);
        proxiedManager.delegateBalance(RECEIVER2, delegatedAmount1);
        checkDelegation(USER1, RECEIVER2, delegatedAmount2, delegatedAmount1 + delegatedAmount2);

        vm.expectRevert(abi.encodeWithSelector(ICore.ExceedingPercentageUpdate.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 1e4);

        vm.stopPrank();
    }

    function test_RemoveDelegateBalance() public {
        test_DelegateFullBalance();

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationRemoved(USER1, RECEIVER);
        proxiedManager.removeDelegatedBalance(RECEIVER);
        checkDelegationZero(USER1, RECEIVER, 0);
    }

    function test_RemoveDelegatedBalanceAndComputeTotal() public {
        uint32 delegatedAmount1 = 100;
        uint32 delegatedAmount2 = 200;

        test_UpdateTotalDelegatedPercentage(delegatedAmount1, delegatedAmount2);

        vm.startPrank(USER1);

        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationRemoved(USER1, RECEIVER);
        proxiedManager.removeDelegatedBalance(RECEIVER);
        checkDelegationZero(USER1, RECEIVER, delegatedAmount2);
        checkDelegation(USER1, RECEIVER2, delegatedAmount2, delegatedAmount2);

        uint32 newDelegatedAmount1 = 1;
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.DelegationCreated(USER1, RECEIVER, newDelegatedAmount1);
        proxiedManager.delegateBalance(RECEIVER, newDelegatedAmount1);
        checkDelegation(USER1, RECEIVER, newDelegatedAmount1, newDelegatedAmount1 + delegatedAmount2);

        vm.stopPrank();
    }

    function testRevert_RemoveNonExistingBalance() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.DelegationDoesNotExist.selector));
        proxiedManager.removeDelegatedBalance(RECEIVER);
        vm.stopPrank();
    }

    function test_UpdateAccountMetadata() public {
        string memory metadataURI = "https://account-metadata.com";
        vm.startPrank(USER1);
        vm.expectEmit(true, false, false, false);
        emit IStrategyManager.AccountMetadataURIUpdated(USER1, metadataURI);
        proxiedManager.updateAccountMetadataURI(metadataURI);
        vm.stopPrank();
    }

    function test_DoubleUpdateAccountMetadata() public {
        test_UpdateAccountMetadata();
        string memory metadataURI2 = "https://account-metadata-2.com";
        vm.startPrank(USER1);
        vm.expectEmit(true, false, false, false);
        emit IStrategyManager.AccountMetadataURIUpdated(USER1, metadataURI2);
        proxiedManager.updateAccountMetadataURI(metadataURI2);
        vm.stopPrank();
    }
}
