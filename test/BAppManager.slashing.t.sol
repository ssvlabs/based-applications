// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IStorage, IBasedAppManager, IERC20, BasedAppMock, ISSVBasedApps, IBasedApp} from "@ssv/test/BAppManager.setup.t.sol";
import {BasedAppManagerStrategyTest} from "@ssv/test/BAppManager.strategy.t.sol";
import {TestUtils} from "@ssv/test/Utils.t.sol";

contract BasedAppManagerSlashingTest is BasedAppManagerStrategyTest {
    function checkSlashableBalance(uint32 strategyId, address bApp, address token, uint256 expectedSlashableBalance)
        internal
        view
    {
        (uint256 slashableBalance) = proxiedManager.getSlashableBalance(strategyId, bApp, token);
        assertEq(slashableBalance, expectedSlashableBalance);
    }

    function checkSlashingFund(address account, address token, uint256 expectedAmount) internal view {
        (uint256 slashingFund) = proxiedManager.slashingFund(account, token);
        assertEq(slashingFund, expectedAmount);
    }

    function test_GetSlashableBalanceBasic() public {
        uint256 depositAmount = 100_000;
        uint32 percentage = 9000;
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        checkSlashableBalance(STRATEGY1, USER1, address(erc20mock), 90_000); // 100,000 * 90% = 90,000 ERC20
    }

    function test_GetSlashableBalance(uint32 percentage) public {
        vm.assume(percentage <= 10_000);
        uint256 depositAmount = 100_000;
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        checkSlashableBalance(STRATEGY1, USER1, address(erc20mock), depositAmount * percentage / proxiedManager.MAX_PERCENTAGE());
    }

    function test_slashEOABasic() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 1000;
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"), USER1);
        uint256 newStrategyBalance = depositAmount - slashAmount; // 100,000 - 1,000 = 99,000 ERC20
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkTotalShares(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkSlashableBalance(STRATEGY1, USER1, token, 89_100); // 99,000 * 90% = 89,100 ERC20
        checkSlashingFund(USER1, token, slashAmount);
    }

    function test_slashEOA(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.MAX_PERCENTAGE());
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        checkTotalShares(STRATEGY1, address(erc20mock), depositAmount, depositAmount);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        vm.prank(USER1);
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"), USER2);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalShares(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, newStrategyBalance * percentage / proxiedManager.MAX_PERCENTAGE());
        checkSlashingFund(USER2, token, slashAmount);
    }

    function test_SlashNonCompatibleBApp(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.MAX_PERCENTAGE());
        test_StrategyOptInToBAppNonCompliant(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategySlashed(STRATEGY1, address(nonCompliantBApp), token, slashAmount, "");
        nonCompliantBApp.slash(STRATEGY1, token, slashAmount);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalShares(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(
            STRATEGY1, address(nonCompliantBApp), token, newStrategyBalance * percentage / proxiedManager.MAX_PERCENTAGE()
        );
        checkSlashingFund(address(nonCompliantBApp), token, slashAmount);
    }

    function test_SlashBApp(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.MAX_PERCENTAGE());
        test_StrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ISSVBasedApps.StrategySlashed(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"));
        proxiedManager.slash(STRATEGY1, address(bApp1), token, slashAmount, abi.encodePacked("0x00"), USER1);
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalShares(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, newStrategyBalance * percentage / proxiedManager.MAX_PERCENTAGE());
        checkSlashingFund(USER1, token, slashAmount);
    }

    function test_SlashBAppButInternalSlashRevert(uint256 slashAmount) public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        vm.assume(slashAmount > 0 && slashAmount <= depositAmount * percentage / proxiedManager.MAX_PERCENTAGE());
        test_StrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppSlashingFailed.selector));
        proxiedManager.slash(STRATEGY1, address(bApp2), token, slashAmount, abi.encodePacked("0x00"), USER1);
        checkTotalShares(STRATEGY1, token, depositAmount, depositAmount);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, address(bApp1), token, depositAmount * percentage / proxiedManager.MAX_PERCENTAGE());
        checkSlashingFund(USER1, token, 0);
    }

    function testRevert_SlashWithZeroAmount() public {
        test_StrategyOptInToBAppEOA(1000);
        vm.prank(USER1);
        uint256 slashAmount = 0;
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidAmount.selector));
        proxiedManager.slash(STRATEGY1, USER1, address(erc20mock), slashAmount, abi.encodePacked("0x00"), USER1);
    }

    function testRevert_SlashBAppNotRegistered() public {
        uint256 depositAmount = 100_000;
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        uint256 slashAmount = 1;
        // todo should check if there is an obligation? But the 0 percentage will make the value go to 0
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        proxiedManager.slash(STRATEGY1, USER1, address(erc20mock), slashAmount, abi.encodePacked("0x00"), USER1);
    }

    function testRevert_slashWithInsufficientBalance() public {
        uint32 percentage = 9000;
        address token = address(erc20mock);
        uint256 slashAmount = 1;
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InsufficientBalance.selector));
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"), USER1);
    }

    function testRevert_SlashEOAWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 1000;
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER2);
        vm.expectRevert();
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"), USER1);
    }

    function testRevert_SlashNonCompatibleBAppWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 2;
        test_StrategyOptInToBAppNonCompliant(percentage);
        vm.startPrank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidBAppOwner.selector, USER2, address(nonCompliantBApp)));
        proxiedManager.slash(STRATEGY1, address(nonCompliantBApp), token, slashAmount, abi.encodePacked("0x00"), USER1);
        vm.stopPrank();
    }

    function testRevert_SlashBAppWithNonOwner() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 1000;
        test_StrategyOptInToBApp(percentage);
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER2);
            vm.expectRevert(abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector));
            bApps[i].slash(STRATEGY1, token, slashAmount, abi.encodePacked("0x00"));
        }
    }
}
