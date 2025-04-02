// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IERC20, IStrategyManager, IBasedApp} from "@ssv/test/BAppManager.setup.t.sol";
import {BasedAppManagerStrategyTest} from "@ssv/test/BAppManager.strategy.t.sol";

import {ICore} from "@ssv/src/interfaces/ICore.sol";

contract BasedAppManagerSlashingTest is BasedAppManagerStrategyTest {
    function checkSlashableBalance(uint32 strategyId, address bApp, address token, uint256 expectedSlashableBalance) internal view {
        (uint256 slashableBalance) = proxiedManager.getSlashableBalance(strategyId, bApp, token);
        assertEq(slashableBalance, expectedSlashableBalance, "Should match the expected slashable balance");
    }

    function checkSlashingFund(address account, address token, uint256 expectedAmount) internal view {
        (uint256 slashingFund) = proxiedManager.slashingFund(account, token);
        assertEq(slashingFund, expectedAmount, "Should match the expected slashing fund balance");
    }

    function checkGeneration(uint32 strategyId, address token, uint256 expectedValue) internal view {
        proxiedManager.strategyGeneration(strategyId, token);
        assertEq(proxiedManager.strategyGeneration(strategyId, token), expectedValue, "Should match the expected generation number");
    }

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
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"), USER1);
        uint256 newStrategyBalance = depositAmount - slashAmount; // 100,000 - 1,000 = 99,000 ERC20
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkSlashableBalance(STRATEGY1, USER1, token, 89_100); // 99,000 * 90% = 89,100 ERC20
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
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"), USER2);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, newStrategyBalance * percentage / proxiedManager.maxPercentage());
        checkSlashingFund(USER2, token, slashAmount);
    }

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
        emit IStrategyManager.StrategySlashed(STRATEGY1, address(nonCompliantBApp), token, slashAmount, "");
        nonCompliantBApp.slash(STRATEGY1, token, slashAmount);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(nonCompliantBApp), token, newStrategyBalance * percentage / proxiedManager.maxPercentage());
        checkSlashingFund(address(nonCompliantBApp), token, slashAmount);
    }

    function testSlashBApp(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.maxPercentage());
        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"));
        proxiedManager.slash(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"), USER1);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, newStrategyBalance * percentage / proxiedManager.maxPercentage());
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testSlashBAppWithEth(uint256 slashAmount) public {
        testStrategyOptInToBAppWithETH();
        uint32 percentage = 10_000;
        uint256 depositAmount = 1 ether;
        address token = ETH_ADDRESS;
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.maxPercentage());
        vm.prank(USER2);
        proxiedManager.depositETH{value: depositAmount}(STRATEGY1);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"));
        proxiedManager.slash(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"), USER1);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, newStrategyBalance * percentage / proxiedManager.maxPercentage());
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testSlashBAppButInternalSlashRevert(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.maxPercentage());
        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppSlashingFailed.selector));
        proxiedManager.slash(STRATEGY1, address(bApp2), token, slashAmount, abi.encodePacked("0x00"), USER1);
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, depositAmount);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, depositAmount * percentage / proxiedManager.maxPercentage());
        checkSlashingFund(USER1, token, 0);
    }

    function testRevertSlashWithZeroAmount() public {
        testStrategyOptInToBAppEOA(1000);
        vm.prank(USER1);
        uint256 slashAmount = 0;
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAmount.selector));
        proxiedManager.slash(STRATEGY1, USER1, address(erc20mock), slashAmount, abi.encodePacked("0x00"), USER1);
    }

    function testRevertSlashBAppNotRegistered() public {
        uint256 depositAmount = 100_000;
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        uint256 slashAmount = 1;
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppNotRegistered.selector));
        proxiedManager.slash(STRATEGY1, USER1, address(erc20mock), slashAmount, abi.encodePacked("0x00"), USER1);
    }

    function testRevertSlashWithInsufficientBalance() public {
        uint32 percentage = 9000;
        address token = address(erc20mock);
        uint256 slashAmount = 1;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"), USER1);
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
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"), USER1);
    }

    function testRevertSlashNonCompatibleBAppWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 2;
        testStrategyOptInToBAppNonCompliant(percentage);
        vm.startPrank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidBAppOwner.selector, USER2, address(nonCompliantBApp)));
        proxiedManager.slash(STRATEGY1, address(nonCompliantBApp), token, slashAmount, abi.encodePacked("0x00"), USER1);
        vm.stopPrank();
    }

    function testRevertSlashBAppWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 1000;
        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER2);
            vm.expectRevert(abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector));
            bApps[i].slash(STRATEGY1, token, slashAmount, abi.encodePacked("0x00"));
        }
    }

    function testWithdrawSlashingFundErc20() public {
        uint256 slashAmount = 100;
        testSlashBApp(slashAmount);
        vm.prank(USER1);
        proxiedManager.withdrawSlashingFund(address(erc20mock), slashAmount);
    }

    function testWithdrawSlashingFundEth() public {
        uint256 slashAmount = 0.2 ether;
        testSlashBAppWithEth(slashAmount);
        vm.prank(USER1);
        proxiedManager.withdrawETHSlashingFund(slashAmount);
    }

    function testRevertWithdrawSlashingFundErc20WithEth() public {
        uint256 slashAmount = 100;
        testSlashBApp(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidToken.selector));
        proxiedManager.withdrawSlashingFund(ETH_ADDRESS, slashAmount);
    }

    function testRevertWithdrawSlashingFundErc20WithInsufficientBalance() public {
        uint256 slashAmount = 100;
        testSlashBApp(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.withdrawSlashingFund(address(erc20mock), slashAmount + 1);
    }

    function testRevertWithdrawSlashingFundErc20WithZeroAmount() public {
        uint256 slashAmount = 100;
        testSlashBApp(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAmount.selector));
        proxiedManager.withdrawSlashingFund(address(erc20mock), 0);
    }

    function testRevertWithdrawETHSlashingFundErc20WithInsufficientBalance() public {
        uint256 slashAmount = 100;
        testSlashBApp(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.withdrawETHSlashingFund(slashAmount + 1);
    }

    function testRevertWithdrawETHSlashingFundErc20WithZeroAmount() public {
        uint256 slashAmount = 100;
        testSlashBApp(slashAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAmount.selector));
        proxiedManager.withdrawETHSlashingFund(0);
    }

    function testFinalizeWithdrawalAfterSlashingRedeemsLowerAmount() public {
        uint256 slashAmount = 100;
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        uint256 withdrawalAmount = depositAmount * 50 / 100;
        address token = address(erc20mock);

        testStrategyOptInToBApp(percentage);

        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);

        vm.prank(USER2);
        proxiedManager.proposeWithdrawal(STRATEGY1, token, withdrawalAmount);
        checkProposedWithdrawal(STRATEGY1, USER2, address(token), block.timestamp, withdrawalAmount);

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"));
        proxiedManager.slash(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"), USER1);
        uint256 newStrategyBalance = depositAmount - slashAmount;

        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, newStrategyBalance * percentage / proxiedManager.maxPercentage());
        checkSlashingFund(USER1, token, slashAmount);

        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        vm.prank(USER2);
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(erc20mock));

        checkTotalSharesAndTotalBalance(STRATEGY1, token, 50_000, 49_950);
        checkAccountShares(STRATEGY1, USER2, token, 50_000);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 44_955);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testFinalizeWithdrawalETHAfterSlashingRedeemsLowerAmount() public {
        uint256 slashAmount = 100;
        uint32 percentage = 10_000;
        uint256 depositAmount = 100_000;
        uint256 withdrawalAmount = depositAmount * 50 / 100;
        address token = ETH_ADDRESS;

        testStrategyOptInToBAppWithETH();

        vm.prank(USER2);
        proxiedManager.depositETH{value: depositAmount}(STRATEGY1);

        vm.prank(USER2);
        proxiedManager.proposeWithdrawalETH(STRATEGY1, withdrawalAmount);
        checkProposedWithdrawal(STRATEGY1, USER2, address(token), block.timestamp, withdrawalAmount);

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"));
        proxiedManager.slash(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"), USER1);
        uint256 newStrategyBalance = depositAmount - slashAmount;

        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, newStrategyBalance * percentage / proxiedManager.maxPercentage());
        checkSlashingFund(USER1, token, slashAmount);

        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());

        vm.prank(USER2);
        proxiedManager.finalizeWithdrawalETH(STRATEGY1);

        checkTotalSharesAndTotalBalance(STRATEGY1, token, 50_000, 49_950);
        checkAccountShares(STRATEGY1, USER2, token, 50_000);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 49_950);
        checkSlashingFund(USER1, token, slashAmount);
    }

    function testSlashTotalBalanceEOA() public {
        uint32 percentage = 10_000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = depositAmount;
        testStrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        checkGeneration(STRATEGY1, token, 0);
        vm.prank(USER1);
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"), USER1);
        checkGeneration(STRATEGY1, token, 1);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        assertEq(newStrategyBalance, 0, "The new strategy balance should be 0");
        checkTotalSharesAndTotalBalance(STRATEGY1, token, 0, newStrategyBalance);
        checkSlashableBalance(STRATEGY1, USER1, token, 0); // 99,000 * 90% = 89,100 ERC20
        checkSlashingFund(USER1, token, slashAmount);
        checkAccountShares(STRATEGY1, USER2, token, 0);
    }

    function testDepositAfterSlashingEOATotalBalance() public {
        testSlashTotalBalanceEOA();
        uint256 depositAmount = 20_000;
        address token = address(erc20mock);
        checkGeneration(STRATEGY1, token, 1);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        checkGeneration(STRATEGY1, token, 1);
        checkTotalSharesAndTotalBalance(STRATEGY1, address(erc20mock), depositAmount, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, depositAmount);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
    }

    function testSlashBAppTotalBalance(uint256 depositAmount) public {
        uint32 percentage = 10_000;
        vm.assume(depositAmount > 0 && depositAmount <= proxiedManager.maxShares());
        address token = address(erc20mock);
        uint256 slashAmount = depositAmount;
        testStrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit IStrategyManager.StrategySlashed(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"));
        checkGeneration(STRATEGY1, token, 0);
        proxiedManager.slash(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"), USER1);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, 0, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, 0);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(USER1, token, slashAmount);
        checkGeneration(STRATEGY1, token, 1);
    }

    function testDepositAfterSlashingBAppTotalBalance() public {
        uint256 depositAmount = 100_000 * 10 ** 18;
        testSlashBAppTotalBalance(depositAmount);
        address token = address(erc20mock);
        checkGeneration(STRATEGY1, token, 1);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        checkGeneration(STRATEGY1, token, 1);
        checkTotalSharesAndTotalBalance(STRATEGY1, address(erc20mock), depositAmount, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, depositAmount);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
    }

    function testRevertProposeWithdrawalAfterSlashingBAppTotalBalance() public {
        uint256 withdrawalAmount = 100_000 * 10 ** 18;
        testSlashBAppTotalBalance(100_000);
        address token = address(erc20mock);
        checkGeneration(STRATEGY1, token, 1);
        vm.prank(USER2);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidAccountGeneration.selector));
        proxiedManager.proposeWithdrawal(STRATEGY1, token, withdrawalAmount);
    }

    function testSlashBAppWhenObligationIsZero() public {
        uint256 depositAmount = 100_000 * 10 ** 18;
        address token = address(erc20mock);
        uint256 slashAmount = depositAmount / 2;
        testStrategyOptInToBAppWithMultipleTokensWithPercentageZero();
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        checkGeneration(STRATEGY1, token, 0);
        vm.expectRevert(abi.encodeWithSelector(ICore.InsufficientBalance.selector));
        proxiedManager.slash(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"), USER1);
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, depositAmount);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, 0);
        checkSlashingFund(USER1, token, 0);
        checkGeneration(STRATEGY1, token, 0);
    }

    function testFinalizeWithdrawalAfterPartialSlashBAppWithdrawSmallerAmount() public {
        testStrategyOptInToBApp(proxiedManager.maxPercentage());
        uint256 depositAmount = 1000;
        uint256 withdrawalAmount = 800;
        uint256 slashAmount = 300;
        address token = address(erc20mock);
        vm.startPrank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        proxiedManager.proposeWithdrawal(STRATEGY1, token, withdrawalAmount);
        proxiedManager.slash(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"), USER1);
        uint256 newStrategyBalance = depositAmount - slashAmount; // 700
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER1, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, newStrategyBalance);
        checkSlashingFund(USER1, token, slashAmount);
        checkGeneration(STRATEGY1, token, 0);
        vm.warp(block.timestamp + proxiedManager.withdrawalTimelockPeriod());
        proxiedManager.finalizeWithdrawal(STRATEGY1, IERC20(token)); // this ends up withdrawing 560 (800 * 70% since 30% was slashed)
        uint256 effectiveWithdrawalAmount = 560;
        checkTotalSharesAndTotalBalance(STRATEGY1, token, depositAmount - withdrawalAmount, newStrategyBalance - effectiveWithdrawalAmount);
        checkAccountShares(STRATEGY1, USER1, token, depositAmount - withdrawalAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, newStrategyBalance - effectiveWithdrawalAmount);
        checkSlashingFund(USER1, token, slashAmount);
        checkGeneration(STRATEGY1, token, 0);
    }
}
