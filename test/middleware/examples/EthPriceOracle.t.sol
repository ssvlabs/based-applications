// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { UtilsTest } from "@ssv/test/helpers/Utils.t.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";
import { EthPriceOracle, IEthPriceOracle } from "@ssv/src/middleware/examples/EthPriceOracle.sol";
import { SSVBasedApps } from "@ssv/src/core/SSVBasedApps.sol";
import { ISSVBasedApps } from "@ssv/src/core/interfaces/ISSVBasedApps.sol";
import { IBasedApp } from "@ssv/src/middleware/interfaces/IBasedApp.sol";
import { IStrategyManager } from "@ssv/src/core/interfaces/IStrategyManager.sol";

contract HoodiTest is UtilsTest {
    IEthPriceOracle public ethPriceOracleHoodi;
    IStrategyManager public proxiedManagerHoodi;

    address BAPP_OWNER = 0xbc8e0973fE8898716Df33C15C26ea74D032Df98a;
    address STRATEGY1_OWNER = 0x87d1F995fe8C925EBe5210ADf02Cd9B99C7f3B54;
    address STRATEGY37_OWNER = 0xac5a7Ce31843e737CD38938A8EfDEc0BE5e728b4;

    uint256 hoodiFork;
    address public constant hoodiBAppAddress =
        0x253e9f96F4363870c1307C1e2328105b9900C1dc;
    // 0xb24AA078C87d859fe9ecf20D0CB372Bc3d41941F;
    address public constant ssvBasedAppsAddress =
        0x40d959B95e7c56962D6d388d87921c03734b9C2C;

    function testHoodi() public virtual {
        hoodiFork = vm.createFork(
            "https://ethereum-hoodi-rpc.publicnode.com",
            540470
        );

        vm.selectFork(hoodiFork);

        ethPriceOracleHoodi = IEthPriceOracle(hoodiBAppAddress);
        proxiedManagerHoodi = IStrategyManager(ssvBasedAppsAddress);

        vm.label(address(ethPriceOracleHoodi), "EthPriceOracle");
        vm.label(address(proxiedManagerHoodi), "SSVBasedApps");

        vm.startPrank(STRATEGY1_OWNER);
        (
            address[] memory tokensInput,
            uint32[] memory sharedRiskLevelInput
        ) = createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 102);

        proxiedManagerHoodi.optInToBApp(
            1,
            address(ethPriceOracleHoodi),
            tokensInput,
            sharedRiskLevelInput,
            ""
        );

        // address result = ethPriceOracleHoodi.testOne(35);

        // assertEq(
        //     result,
        //     0xac5a7Ce31843e737CD38938A8EfDEc0BE5e728b4,
        //     "Should set the correct strategy signer"
        // );

        vm.stopPrank();
    }
}

contract EthPriceOracleTest is UtilsTest {
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

    function testRegisterEthPriceOracleBApp() public {
        vm.startPrank(USER1);
        (
            address[] memory tokensInput,
            uint32[] memory sharedRiskLevelInput
        ) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        ethPriceOracle.registerBApp(tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(
            tokensInput,
            sharedRiskLevelInput,
            address(ethPriceOracle),
            proxiedManager
        );
        vm.stopPrank();
    }

    // function testRevertOptInToBAppWithUnauthorizedCaller() public {
    //     vm.prank(USER1);
    //     (
    //         address[] memory tokensInput,
    //         uint32[] memory riskLevelInput
    //     ) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
    //     vm.expectRevert(
    //         abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector)
    //     );
    //     ethPriceOracle.optInToBApp(STRATEGY1, tokensInput, riskLevelInput, "");
    // }

    function testOptInToBApp() public {
        testCreateStrategies();
        testRegisterEthPriceOracleBApp();
        (
            address[] memory tokensInput,
            uint32[] memory riskLevelInput
        ) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 10_000);
        bytes
            memory encodedAddress = hex"000000000000000000000000ac5a7ce31843e737cd38938a8efdec0be5e728b4";

        vm.expectEmit(true, true, false, false);
        emit EthPriceOracle.DebugOptIn(STRATEGY1);
        vm.prank(USER1);
        proxiedManager.optInToBApp(
            STRATEGY1,
            address(ethPriceOracle),
            tokensInput,
            riskLevelInput,
            encodedAddress
        );

        assertEq(
            ethPriceOracle.strategySigner(STRATEGY1),
            address(0xac5a7Ce31843e737CD38938A8EfDEc0BE5e728b4),
            "Should set the correct strategy signer"
        );
        assertNotEq(
            ethPriceOracle.strategySigner(STRATEGY1),
            address(0xAC5a7cE31843e737CD38938a8EFDEc0Be5E728b3),
            "Should not set the incorrect strategy signer"
        );
    }
}
