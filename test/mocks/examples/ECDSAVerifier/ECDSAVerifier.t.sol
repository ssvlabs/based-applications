// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { IBasedApp } from "@ssv/test/helpers/Setup.t.sol";
import { UtilsTest } from "@ssv/test/helpers/Utils.t.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";
import { ECDSAVerifier } from "@ssv/src/middleware/examples/ECDSAVerifier.sol";

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
        (, address owner, uint32 delegationFeeOnRewards) = proxiedManager
            .strategies(strategyId1);
        assertEq(owner, USER1, "Should set the correct strategy owner");
        assertEq(
            delegationFeeOnRewards,
            STRATEGY1_INITIAL_FEE,
            "Should set the correct strategy fee"
        );
        vm.stopPrank();
        vm.prank(USER2);
        uint32 strategyId2 = proxiedManager.createStrategy(
            STRATEGY1_INITIAL_FEE,
            ""
        );
        assertEq(strategyId2, STRATEGY2, "Should set the correct strategy ID");
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
        (
            address[] memory tokensInput,
            uint32[] memory riskLevelInput
        ) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
        address signer = 0x763569566a3CE4f8D73f96c4996aBdf297f74ADE;
        bytes32 messageHash = 0x5b001f2ad81fe86899545b51f8ecd1ca08674437d5c4748e1b70ba5dcf85ed86;
        bytes
            memory signature = hex"ddc30e871857b9a4d2dce47f49aec426404e69c98e05abc345df2f096e47fcb33d3e061da2435584d92df8731522d35ae485447311eb4a3c0bfdb09150cbad081b";

        bytes memory data = abi.encode(signer, messageHash, signature);
        vm.prank(USER1);
        proxiedManager.optInToBApp(
            STRATEGY1,
            address(ecdsaVerifierExample),
            tokensInput,
            riskLevelInput,
            data
        );
    }

    function testRevertOptInToBAppWithInvalidSignature() public {
        testCreateStrategies();
        testRegisterECDSAVerifierExampleBApp();
        (
            address[] memory tokensInput,
            uint32[] memory riskLevelInput
        ) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
        address signer = 0x763569566a3CE4f8D73f96c4996aBdf297f74ADE;
        bytes32 messageHash = 0x5b001f2ad81fe86899545b51f8ecd1ca08674437d5c4748e1b70ba5dcf85ed86;
        bytes
            memory signature = hex"ddc30e871857b9a4d2dce47f49aec426404e69c98e05abc345df2f096e47fcb33d3e061da2435584d92df8731522d35ae485447311eb4a3c0bfdb09150cbad081c";

        bytes memory data = abi.encode(signer, messageHash, signature);
        vm.prank(USER1);
        vm.expectRevert(
            abi.encodeWithSelector(ECDSAVerifier.InvalidSignature.selector)
        );
        proxiedManager.optInToBApp(
            STRATEGY1,
            address(ecdsaVerifierExample),
            tokensInput,
            riskLevelInput,
            data
        );
    }

    function testRevertReplayAttackOnAnotherStrategy() public {
        testOptInToBApp();
        (
            address[] memory tokensInput,
            uint32[] memory riskLevelInput
        ) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
        address signer = 0x763569566a3CE4f8D73f96c4996aBdf297f74ADE;
        bytes32 messageHash = 0x5b001f2ad81fe86899545b51f8ecd1ca08674437d5c4748e1b70ba5dcf85ed86;
        bytes
            memory signature = hex"ddc30e871857b9a4d2dce47f49aec426404e69c98e05abc345df2f096e47fcb33d3e061da2435584d92df8731522d35ae485447311eb4a3c0bfdb09150cbad081b";

        bytes memory data = abi.encode(signer, messageHash, signature);
        vm.prank(USER2);
        vm.expectRevert(
            abi.encodeWithSelector(ECDSAVerifier.SignerAlreadyOptedIn.selector)
        );
        proxiedManager.optInToBApp(
            STRATEGY2,
            address(ecdsaVerifierExample),
            tokensInput,
            riskLevelInput,
            data
        );
    }
}
