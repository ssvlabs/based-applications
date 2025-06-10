// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {
    IBasedAppWhitelisted
} from "@ssv/src/middleware/interfaces/IBasedAppWhitelisted.sol";
import { IBasedApp } from "@ssv/test/helpers/Setup.t.sol";
import { UtilsTest } from "@ssv/test/helpers/Utils.t.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";

contract WhitelistExampleTest is UtilsTest {
    function testCreateStrategies() public {
        vm.startPrank(USER1);
        erc20mock.approve(address(proxiedManager), INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.approve(
            address(proxiedManager),
            INITIAL_USER1_BALANCE_ERC20
        );
        uint32 strategyId1 = proxiedManager.createStrategy(
            STRATEGY1_INITIAL_FEE,
            ""
        );
        assertEq(strategyId1, STRATEGY1, "Should set the correct strategy ID");
        (address owner, uint32 delegationFeeOnRewards) = proxiedManager
            .strategies(strategyId1);
        assertEq(owner, USER1, "Should set the correct strategy owner");
        assertEq(
            delegationFeeOnRewards,
            STRATEGY1_INITIAL_FEE,
            "Should set the correct strategy fee"
        );
        vm.stopPrank();
    }

    function testRegisterECDSAVerifierExampleBApp() public {
        vm.startPrank(USER1);
        ICore.TokenConfig[] memory tokenConfigsInput = createSingleTokenConfig(
            address(erc20mock),
            102
        );
        ecdsaVerifierExample.registerBApp(tokenConfigsInput, "");
        checkBAppInfo(
            tokenConfigsInput,
            address(ecdsaVerifierExample),
            proxiedManager
        );
        vm.stopPrank();
    }

    function testRevertOptInToBAppWithUnauthorizedCaller() public {
        vm.prank(USER1);
        (
            address[] memory tokensInput,
            uint32[] memory riskLevelInput
        ) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
        vm.expectRevert(
            abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector)
        );
        ecdsaVerifierExample.optInToBApp(
            STRATEGY1,
            tokensInput,
            riskLevelInput,
            ""
        );
    }

    function testOptInToBApp() public {
        testCreateStrategies();
        testRegisterECDSAVerifierExampleBApp();
        vm.prank(USER1);
        (
            address[] memory tokensInput,
            uint32[] memory riskLevelInput
        ) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
        proxiedManager.optInToBApp(
            STRATEGY1,
            address(ecdsaVerifierExample),
            tokensInput,
            riskLevelInput,
            "0x000000000000000000000000beb1bcdb71315d5900817ba831bdb0bfff957d795b001f2ad81fe86899545b51f8ecd1ca08674437d5c4748e1b70ba5dcf85ed8600000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000041182ef41c205e2a4a97c002670ea99231f32f8acb5f29284e2eac5874bf781e372e7789fc29e106481746f982e522456a6f80aef0806dbf2a69c1fe8cd2282aee1b00000000000000000000000000000000000000000000000000000000000000"
        );
    }
}
