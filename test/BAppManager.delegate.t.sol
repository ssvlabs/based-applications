// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppManagerSetupTest, IBasedAppManager, ISSVBasedApps, IStorage} from "@ssv/test/BAppManager.setup.t.sol";

contract BasedAppManagerDelegateTest is BasedAppManagerSetupTest {
    function test_DelegateMinimumBalance() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1, "Delegated amount should be 0.01%");
        assertEq(totalDelegatedPercentage, 1, "Delegated percentage should be 0.01%");
        vm.stopPrank();
    }

    function test_DelegatePartialBalance(uint32 percentageAmount) public {
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
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, 0);
    }

    function testRevert_DelegateBalanceTooHigh(uint32 highBalance) public {
        vm.assume(highBalance > proxiedManager.MAX_PERCENTAGE());
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
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

    function testRevert_TotalDelegatePercentageOverMax(uint32 percentage1) public {
        vm.assume(percentage1 > 0 && percentage1 <= proxiedManager.MAX_PERCENTAGE());
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, percentage1);
        uint32 percentage2 = proxiedManager.MAX_PERCENTAGE();
        vm.expectRevert(abi.encodeWithSelector(IStorage.ExceedingPercentageUpdate.selector));
        proxiedManager.delegateBalance(RECEIVER2, percentage2);
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 delegatedAmount2 = proxiedManager.delegations(USER1, RECEIVER2);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, percentage1, "First delegated amount should be set");
        assertEq(delegatedAmount2, 0, "Second delegated amount should be not set");
        assertEq(totalDelegatedPercentage, percentage1, "Total delegated percentage should be equal to the first delegation");
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
        vm.expectRevert(abi.encodeWithSelector(IStorage.DelegationAlreadyExists.selector));
        proxiedManager.delegateBalance(RECEIVER, percentage2);
        vm.stopPrank();
    }

    function testRevert_InvalidPercentageDelegateBalance() public {
        vm.startPrank(USER1);
        uint32 maxPlusOne = proxiedManager.MAX_PERCENTAGE() + 1;
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, maxPlusOne);
        vm.stopPrank();
    }

    function test_UpdateDelegatedBalance() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        proxiedManager.updateDelegatedBalance(RECEIVER, proxiedManager.MAX_PERCENTAGE());
        uint256 delegatedAmount = proxiedManager.delegations(USER1, RECEIVER);
        uint256 totalDelegatedPercentage = proxiedManager.totalDelegatedPercentage(USER1);
        assertEq(delegatedAmount, 1e4, "Delegated amount should be 100%");
        assertEq(totalDelegatedPercentage, 1e4, "Total delegated percentage should be 100%");
        vm.stopPrank();
    }

    function testRevert_UpdateTotalDelegatePercentageByTheSameUser() public {
        test_UpdateDelegatedBalance();
        uint32 maxPlusOne = proxiedManager.MAX_PERCENTAGE() + 1;
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
        proxiedManager.delegateBalance(RECEIVER, maxPlusOne);
    }

    function testRevert_UpdateTotalDelegatePercentageWithZero() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidPercentage.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 0);
        vm.stopPrank();
    }

    function testRevert_UpdateTotalDelegatePercentageWithSameBalance() public {
        vm.startPrank(USER1);
        proxiedManager.delegateBalance(RECEIVER, 1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.DelegationExistsWithSameValue.selector));
        proxiedManager.updateDelegatedBalance(RECEIVER, 1);
        vm.stopPrank();
    }

    function testRevert_UpdateBalanceNotExisting() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.DelegationDoesNotExist.selector));
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
        vm.expectRevert(abi.encodeWithSelector(IStorage.ExceedingPercentageUpdate.selector));
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
        vm.expectRevert(abi.encodeWithSelector(IStorage.DelegationDoesNotExist.selector));
        proxiedManager.removeDelegatedBalance(RECEIVER);
        vm.stopPrank();
    }

    function test_UpdateAccountMetadata() public {
        string memory metadataURI = "https://account-metadata.com";
        vm.startPrank(USER1);
        vm.expectEmit(true, false, false, false);
        emit ISSVBasedApps.AccountMetadataURIUpdated(USER1, metadataURI);
        proxiedManager.updateAccountMetadataURI(metadataURI);
        vm.stopPrank();
    }
}
