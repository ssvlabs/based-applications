// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IStorage, IBasedAppManager, IERC20, BasedAppMock, ISSVBasedApps} from "@ssv/test/BAppManager.setup.t.sol";
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
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount; // 100,000 - 1,000 = 99,000 ERC20
        // checkStrategyTokenBalance(STRATEGY1, USER2, token, newStrategyBalance);
        checkSlashableBalance(STRATEGY1, USER1, token, 89_100); // 99,000 * 90% = 89,100 ERC20
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
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
        uint256 newStrategyBalance = depositAmount - slashAmount;
        checkTotalShares(STRATEGY1, token, depositAmount, newStrategyBalance);
        checkAccountShares(STRATEGY1, USER2, token, depositAmount);
        checkSlashableBalance(STRATEGY1, USER1, token, newStrategyBalance * percentage / proxiedManager.MAX_PERCENTAGE());
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
    }

    function test_SlashBApp() public {}

    function test_SlashBAppButInternalSlashRevert() public {
        // vm.expectRevert(abi.encodeWithSelector(IStorage.BAppSlashingFailed.selector));
        // proxiedManager.slash(STRATEGY1, USER1, address(erc20mock), 1000, abi.encodePacked("0x00"));
    }

    function testRevert_SlashWithZeroAmount() public {
        test_StrategyOptInToBAppEOA(1000);
        vm.prank(USER1);
        uint256 slashAmount = 0;
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidAmount.selector));
        proxiedManager.slash(STRATEGY1, USER1, address(erc20mock), slashAmount, abi.encodePacked("0x00"));
    }

    function testRevert_SlashBAppNotRegistered() public {
        // test_StrategyOptInToBAppEOA(2000);
        uint256 depositAmount = 100_000;
        vm.prank(USER2);
        proxiedManager.depositERC20(STRATEGY1, IERC20(erc20mock), depositAmount);
        vm.prank(USER1);
        uint256 slashAmount = 1;
        // todo should check if there is an obligation? But the 0 percentage will make the value go to 0
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        proxiedManager.slash(STRATEGY1, USER1, address(erc20mock), slashAmount, abi.encodePacked("0x00"));
    }

    function testRevert_slashWithInsufficientBalance() public {
        uint32 percentage = 9000;
        uint256 depositAmount = 100_000;
        address token = address(erc20mock);
        uint256 slashAmount = 1;
        test_StrategyOptInToBAppEOA(percentage);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.InsufficientBalance.selector));
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
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
        proxiedManager.slash(STRATEGY1, USER1, token, slashAmount, abi.encodePacked("0x00"));
    }

    function testRevert_SlashNonCompatibleBAppWithNonOwner() public {}
}
