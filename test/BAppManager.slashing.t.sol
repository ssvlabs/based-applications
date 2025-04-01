// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {IERC20, IStrategyManager, IBasedApp} from "@ssv/test/BAppManager.setup.t.sol";
import {BasedAppManagerStrategyTest} from "@ssv/test/BAppManager.strategy.t.sol";

import {ICore} from "@ssv/src/interfaces/ICore.sol";

contract BasedAppManagerSlashingTest is BasedAppManagerStrategyTest {
    function checkSlashableBalance(uint32 strategyId, address bApp, address token, uint256 expectedSlashableBalance) internal view {
        (uint256 slashableBalance) = proxiedManager.getSlashableBalance(strategyId, bApp, token);
        assertEq(slashableBalance, expectedSlashableBalance);
    }

    function checkSlashingFund(address account, address token, uint256 expectedAmount) internal view {
        (uint256 slashingFund) = proxiedManager.slashingFund(account, token);
        assertEq(slashingFund, expectedAmount);
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
        // testStrategyOptInToBApp(percentage);
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
        // todo should check if there is an obligation? But the 0 percentage will make the value go to 0
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
}
