// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IERC20, IStrategyManager, IBasedAppManager} from "@ssv/test/helpers/Setup.t.sol";
import {StrategyManagerTest} from "@ssv/test/modules/StrategyManager.t.sol";

contract SlashingManagerEOATest is StrategyManagerTest {
    function testGetSlashableBalanceBasic() public {
        uint256 depositAmount = 100_000;
        uint32 percentage = 9000;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        checkSlashableBalance(STRATEGY1, USER1, address(erc20mock), 90_000); // 100,000 * 90% = 90,000 ERC20
    }

    function testGetSlashableBalance(uint32 percentage) public {
        vm.assume(percentage <= 10_000);
        uint256 depositAmount = 100_000;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        checkSlashableBalance(STRATEGY1, USER1, address(erc20mock), depositAmount * percentage / proxiedManager.maxPercentage());
    }

    function testSlashEOABasic() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 1000;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount; // 100,000 - 1,000 = 99,000 ERC20
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkSlashableBalance(STRATEGY1, USER1, token, 0); // 99,000 * 90% = 89,100 ERC20
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testSlashEOA(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.maxPercentage());
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        checkTotalSharesAndTotalBalance(STRATEGY1, address(erc20mock), depositAmount, depositAmount);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        vm.prank(USER1);
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testSlashEOAWithEth(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 3 ether;
        address token = ETH_ADDRESS;

        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.maxPercentage());

        testStrategyOptInToBAppEOAWithETH(percentage);
        vm.prank(USER2);
        proxiedManager.depositETH{value: depositAmount}(STRATEGY1);
        checkTotalSharesAndTotalBalance(STRATEGY1, ETH_ADDRESS, depositAmount, depositAmount);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        vm.prank(USER1);

        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testRevertSlashEOAWithZeroAmount() public {
        testStrategyOptInToBAppEOA(1000);
        vm.prank(USER1);
        uint256 slashAmount = 0;
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector));
        proxiedManager.slash(STRATEGY1, USER1, address(erc20mock), slashAmount, abi.encodePacked("0x00"));
    }

    function testRevertSlashEOAWithInsufficientBalance() public {
        uint32 percentage = 9000;
        address token = address(erc20mock);
        uint256 slashAmount = 1;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InsufficientBalance.selector));
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
    }

    function testRevertSlashEOAWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 1000;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER2);
        vm.expectRevert();
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
    }

    function testWithdrawSlashingFundErc20FromEOA() public {
        uint256 slashAmount = 100;
        testSlashEOA(slashAmount);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.SlashingFundWithdrawn(address(erc20mock), slashAmount);
        vm.prank(USER1);
        proxiedManager.withdrawSlashingFund(address(erc20mock), slashAmount);
    }

    function testWithdrawSlashingFundEthFromEOA() public {
        uint256 slashAmount = 0.2 ether;
        testSlashEOAWithEth(slashAmount);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.SlashingFundWithdrawn(ETH_ADDRESS, slashAmount);
        vm.prank(USER1);
        proxiedManager.withdrawETHSlashingFund(slashAmount);
    }

    // Slash Non Compatible BApp

    function testSlashNonCompatibleBApp(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.maxPercentage());
        testStrategyOptInToBAppNonCompliant(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(STRATEGY1, address(nonCompliantBApp), token, slashAmount, address(nonCompliantBApp));
        nonCompliantBApp.slash(STRATEGY1, token, slashAmount);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(nonCompliantBApp), token, 0);
        checkSlashingFund(address(nonCompliantBApp), token, slashAmount);
    }

    function testRevertSlashNonCompatibleBAppWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 2;
        testStrategyOptInToBAppNonCompliant(percentage);
        vm.startPrank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InvalidBAppOwner.selector, USER2, address(nonCompliantBApp)));
        proxiedManager.slash(STRATEGY1, address(nonCompliantBApp), token, slashAmount, abi.encodePacked("0x00"));
        vm.stopPrank();
    }

    function testRevertSlashEOANotRegistered() public {
        uint256 depositAmount = 100_000;
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        uint256 slashAmount = 1;
        vm.expectRevert(abi.encodeWithSelector(IBasedAppManager.BAppNotRegistered.selector));
        proxiedManager.slash(STRATEGY1, USER1, address(erc20mock), slashAmount, abi.encodePacked("0x00"));
    }

    function testRevertWithdrawSlashingFundErc20WithEthEOA() public {
        uint256 slashAmount = 100;
        testSlashEOA(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InvalidToken.selector));
        proxiedManager.withdrawSlashingFund(ETH_ADDRESS, slashAmount);
    }

    function testRevertWithdrawSlashingFundErc20WithInsufficientBalanceEOA() public {
        uint256 slashAmount = 100;
        testSlashEOA(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InsufficientBalance.selector));
        proxiedManager.withdrawSlashingFund(address(erc20mock), slashAmount + 1);
    }

    function testRevertWithdrawSlashingFundErc20WithZeroAmountEOA() public {
        uint256 slashAmount = 100;
        testSlashEOA(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector));
        proxiedManager.withdrawSlashingFund(address(erc20mock), 0);
    }

    function testRevertWithdrawETHSlashingFundErc20WithInsufficientBalanceEOA() public {
        uint256 slashAmount = 100;
        testSlashEOA(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InsufficientBalance.selector));
        proxiedManager.withdrawETHSlashingFund(slashAmount + 1);
    }

    function testRevertWithdrawETHSlashingFundErc20WithZeroAmountEOA() public {
        uint256 slashAmount = 100;
        testSlashEOA(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InvalidAmount.selector));
        proxiedManager.withdrawETHSlashingFund(0);
    }

    function testFinalizeWithdrawalAfterSlashingRedeemsLowerAmountEOA() public {
        uint256 slashAmount = 100;
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        uint256 withdrawalAmount = depositAmount * 50 / 100;
        address token = address(erc20mock);

        testStrategyOptInToBAppEOA(percentage);

        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);

        vm.prank(USER2);
        proxiedManager.proposeWithdrawal(STRATEGY1, token, withdrawalAmount);
        checkProposedWithdrawal(STRATEGY1, USER2, address(token), block.timestamp, withdrawalAmount);

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(STRATEGY1, USER1, token, slashAmount, USER1);
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount;

        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);

        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        vm.prank(USER2);
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(erc20mock));

        checkTotalSharesAndTotalBalance(STRATEGY1, token, 50_000, 49_950);
        checkAccountShares(STRATEGY1, USER2, token, 50_000);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testFinalizeWithdrawalETHAfterSlashingRedeemsLowerAmountEOA() public {
        uint256 slashAmount = 100;
        uint32 percentage = 10_000;
        uint256 depositAmount = 100_000;
        uint256 withdrawalAmount = depositAmount * 50 / 100;
        address token = ETH_ADDRESS;

        testStrategyOptInToBAppEOAWithETH(percentage);

        vm.prank(USER2);
        proxiedManager.depositETH{value: depositAmount}(STRATEGY1);

        vm.prank(USER2);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, withdrawalAmount);
        checkProposedWithdrawal(STRATEGY1, USER2, address(token), block.timestamp, withdrawalAmount);

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(STRATEGY1, USER1, token, slashAmount, USER1);
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount;

        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);

        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        vm.prank(USER2);
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);

        checkTotalSharesAndTotalBalance(STRATEGY1, token, 50_000, 49_950);
        checkAccountShares(STRATEGY1, USER2, token, 50_000);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testSlashTotalBalanceEOA(uint256 depositAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= proxiedManager.maxShares());
        uint32 percentage = 10_000;
        address token = address(erc20mock);
        uint256 slashAmount = depositAmount;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        checkGeneration(STRATEGY1, token, 0);
        vm.prank(USER1);
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
        checkGeneration(STRATEGY1, token, 1);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        assertEq(newStrategyBalance, 0, "The new strategy balance should be 0");
        checkTotalSharesAndTotalBalance(STRATEGY1, token, 0, newStrategyBalance);
        checkSlashableBalance(STRATEGY1, USER1, token, 0); // 99,000 * 90% = 89,100 ERC20
        checkSlashingFund(USER1, token, slashAmount);
        checkAccountShares(STRATEGY1, USER2, token, 0);
    }

    function testDepositAfterSlashingEOATotalBalance() public {
        uint256 firstDepositAmount = 100_000;
        testSlashTotalBalanceEOA(firstDepositAmount);
        uint256 depositAmount = 20_000;
        address token = address(erc20mock);
        checkGeneration(STRATEGY1, token, 1);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        checkGeneration(STRATEGY1, token, 1);
        checkTotalSharesAndTotalBalance(STRATEGY1, address(erc20mock), depositAmount, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
    }

    function testDepositAfterSlashingBAppTotalBalance() public {
        uint256 depositAmount = 100_000 * 10 ** 18;
        uint256 firstDepositAmount = 100_000;
        testSlashTotalBalanceEOA(firstDepositAmount);
        address token = address(erc20mock);
        checkGeneration(STRATEGY1, token, 1);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        checkGeneration(STRATEGY1, token, 1);
        checkTotalSharesAndTotalBalance(STRATEGY1, address(erc20mock), depositAmount, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
    }

    function testRevertProposeWithdrawalAfterSlashingBAppTotalBalance() public {
        uint256 withdrawalAmount = 100_000 * 10 ** 18;
        uint256 firstDepositAmount = 100_000;
        testSlashTotalBalanceEOA(firstDepositAmount);
        address token = address(erc20mock);
        checkGeneration(STRATEGY1, token, 1);
        vm.prank(USER2);
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InvalidAccountGeneration.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, token, withdrawalAmount);
    }

    function testFinalizeWithdrawalAfterPartialSlashBAppWithdrawSmallerAmountEOA() public {
        testStrategyOptInToBAppEOA(proxiedManager.maxPercentage());
        uint256 depositAmount = 1000;
        uint256 withdrawalAmount = 800;
        uint256 slashAmount = 300;
        address token = address(erc20mock);
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        proxiedManager.proposeWithdrawal(STRATEGY1, token, withdrawalAmount);
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount; // 700
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER1, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
        checkGeneration(STRATEGY1, token, 0);
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(token)); // this ends up withdrawing 560 (800 * 70% since 30% was slashed)
        uint256 effectiveWithdrawalAmount = 560;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount - withdrawalAmount, newStrategyBalance - effectiveWithdrawalAmount);
        checkAccountShares(STRATEGY1, USER1, token, depositAmount - withdrawalAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, 0);
        checkSlashingFund(USER1, token, slashAmount);
        checkGeneration(STRATEGY1, token, 0);
    }

    function testRevertWithdrawSlashingFundErc20WithEthOnEOA() public {
        uint256 slashAmount = 100;
        testSlashEOA(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStrategyManager.InvalidToken.selector));
        proxiedManager.withdrawSlashingFund(ETH_ADDRESS, slashAmount);
    }
}
