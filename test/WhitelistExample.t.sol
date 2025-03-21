// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedAppWhitelisted} from "@ssv/src/interfaces/IBasedAppWhitelisted.sol";
import {IBasedApp} from "@ssv/src/interfaces/IBasedApp.sol";

import {BasedAppManagerSetupTest} from "@ssv/test/BAppManager.setup.t.sol";
import {BasedAppManagerStrategyTest} from "@ssv/test/BAppManager.strategy.t.sol";
import {TestUtils} from "@ssv/test/Utils.t.sol";

contract WhitelistExampleTest is BasedAppManagerSetupTest, TestUtils {
    function test_CreateStrategies() public {
        vm.startPrank(USER1);
        erc20mock.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);
        uint32 strategyId1 = proxiedManager.createStrategy(STRATEGY1_INITIAL_FEE, "");
        assertEq(strategyId1, STRATEGY1, "Strategy id 1 was saved correctly");
        (address owner, uint32 delegationFeeOnRewards) = proxiedManager.strategies(strategyId1);
        assertEq(owner, USER1, "Strategy owner");
        assertEq(delegationFeeOnRewards, STRATEGY1_INITIAL_FEE, "Strategy fee");
        vm.stopPrank();
    }

    function test_addTokensToBApp() public {
        test_CreateStrategies();
        test_registerWhitelistExampleBApp();
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory riskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock2), 10_000);
        whitelistExample.addTokensToBApp(tokensInput, riskLevelInput);
        checkBAppInfo(tokensInput, riskLevelInput, address(whitelistExample), proxiedManager);
        vm.stopPrank();
    }

    function test_registerWhitelistExampleBApp() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        whitelistExample.registerBApp(tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput, address(whitelistExample), proxiedManager);
        vm.stopPrank();
    }

    function testRevert_optInToBAppWithUnauthorizedCaller() public {
        vm.prank(USER1);
        (address[] memory tokensInput, uint32[] memory riskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
        vm.expectRevert(abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector));
        whitelistExample.optInToBApp(STRATEGY1, tokensInput, riskLevelInput, "");
    }

    function testRevert_optInToBAppWithNonWhitelistedCaller() public {
        test_CreateStrategies();
        test_registerWhitelistExampleBApp();
        vm.prank(USER1);
        (address[] memory tokensInput, uint32[] memory riskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
        vm.expectRevert(abi.encodeWithSelector(IBasedAppWhitelisted.NonWhitelistedCaller.selector));
        proxiedManager.optInToBApp(STRATEGY1, address(whitelistExample), tokensInput, riskLevelInput, "");
    }

    function test_addWhitelistedAccount() public {
        vm.prank(USER1);
        whitelistExample.addWhitelisted(STRATEGY1);
        assertEq(whitelistExample.isWhitelisted(STRATEGY1), true);
    }

    function test_optInToBApp() public {
        test_CreateStrategies();
        test_registerWhitelistExampleBApp();
        test_addWhitelistedAccount();
        vm.prank(USER1);
        (address[] memory tokensInput, uint32[] memory riskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
        proxiedManager.optInToBApp(STRATEGY1, address(whitelistExample), tokensInput, riskLevelInput, "");
    }

    function test_removeWhitelistedAccount() public {
        test_addWhitelistedAccount();
        vm.prank(USER1);
        whitelistExample.removeWhitelisted(STRATEGY1);
        assertEq(whitelistExample.isWhitelisted(STRATEGY1), false);
    }

    function testRevert_addWhitelistedAccount() public {
        test_addWhitelistedAccount();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IBasedAppWhitelisted.AlreadyWhitelisted.selector));
        whitelistExample.addWhitelisted(STRATEGY1);
    }

    function testRevert_removeWhitelistedAccount() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IBasedAppWhitelisted.NotWhitelisted.selector));
        whitelistExample.removeWhitelisted(STRATEGY1);
    }

    function testRevert_addWhitelistedZeroID() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IBasedAppWhitelisted.ZeroID.selector));
        whitelistExample.addWhitelisted(0);
    }
}
