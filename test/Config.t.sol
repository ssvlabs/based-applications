// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { Test } from "forge-std/Test.sol";

import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { BasedAppsManager } from "@ssv/src/core/modules/BasedAppsManager.sol";
import {
    IBasedAppManager
} from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import {
    IProtocolManager
} from "@ssv/src/core/interfaces/IProtocolManager.sol";
import {
    IStrategyManager
} from "@ssv/src/core/interfaces/IStrategyManager.sol";
import { SSVBasedApps } from "@ssv/src/core/SSVBasedApps.sol";
import { ProtocolManager } from "@ssv/src/core/modules/ProtocolManager.sol";
import { StrategyManager } from "@ssv/src/core/modules/StrategyManager.sol";
import {
    ProtocolStorageLib
} from "@ssv/src/core/libraries/ProtocolStorageLib.sol";
import { ISSVBasedApps } from "@ssv/src/core/interfaces/ISSVBasedApps.sol";

contract Config is Test {
    // Main Contract
    SSVBasedApps public implementation;
    // Modules
    StrategyManager public strategyManagerMod;
    BasedAppsManager public basedAppsManagerMod;
    ProtocolManager public protocolManagerMod;

    // Proxies
    ERC1967Proxy public proxy; // UUPS Proxy contract
    SSVBasedApps public proxiedManager; // Proxy interface for interaction

    // EOAs
    address public immutable OWNER = makeAddr("Owner");

    // Constants
    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint32 public constant MAX_FEE_INCREMENT = 500; // 5%
    // Array containing all the BApps created
    ProtocolStorageLib.Data public config;

    function setUp() public virtual {
        vm.label(OWNER, "Owner");
        vm.startPrank(OWNER);
        basedAppsManagerMod = new BasedAppsManager();
        strategyManagerMod = new StrategyManager();
        protocolManagerMod = new ProtocolManager();
        implementation = new SSVBasedApps();
        vm.stopPrank();
    }

    function testRevertInvalidMaxFeeIncrementWithZeroFee() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: 0,
            feeTimelockPeriod: 0 days,
            feeExpireTime: 1 days,
            withdrawalTimelockPeriod: 14 days,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISSVBasedApps.InvalidMaxFeeIncrement.selector
            )
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }

    function testRevertInvalidMaxFeeIncrementWithExcessiveFee() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: 10001,
            feeTimelockPeriod: 0 days,
            feeExpireTime: 1 days,
            withdrawalTimelockPeriod: 14 days,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISSVBasedApps.InvalidMaxFeeIncrement.selector
            )
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }

    function testRevertInvalidFeeTimelockPeriod() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 0 days,
            feeExpireTime: 1 days,
            withdrawalTimelockPeriod: 14 days,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISSVBasedApps.InvalidFeeTimelockPeriod.selector
            )
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }

    function testRevertInvalidFeeExpireTime() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 1 days,
            feeExpireTime: 59 minutes,
            withdrawalTimelockPeriod: 14 days,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(ISSVBasedApps.InvalidFeeExpireTime.selector)
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }

    function testRevertInvalidWithdrawalTimelockPeriod() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 1 days,
            feeExpireTime: 1 hours,
            withdrawalTimelockPeriod: 0 days,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISSVBasedApps.InvalidWithdrawalTimelockPeriod.selector
            )
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }

    function testRevertInvalidWithdrawalExpireTime() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 1 days,
            feeExpireTime: 1 hours,
            withdrawalTimelockPeriod: 1 days,
            withdrawalExpireTime: 0 hours,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISSVBasedApps.InvalidWithdrawalExpireTime.selector
            )
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }

    function testRevertInvalidObligationTimelockPeriod() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 1 days,
            feeExpireTime: 1 hours,
            withdrawalTimelockPeriod: 1 days,
            withdrawalExpireTime: 1 hours,
            obligationTimelockPeriod: 23 hours,
            obligationExpireTime: 3 days,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISSVBasedApps.InvalidObligationTimelockPeriod.selector
            )
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }

    function testRevertInvalidObligationExpireTime() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 1 days,
            feeExpireTime: 1 hours,
            withdrawalTimelockPeriod: 1 days,
            withdrawalExpireTime: 1 hours,
            obligationTimelockPeriod: 1 days,
            obligationExpireTime: 0 hours,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISSVBasedApps.InvalidObligationExpireTime.selector
            )
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }

    function testRevertInvalidTokenUpdateTimelockPeriod() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 1 days,
            feeExpireTime: 1 hours,
            withdrawalTimelockPeriod: 1 days,
            withdrawalExpireTime: 1 hours,
            obligationTimelockPeriod: 1 days,
            obligationExpireTime: 1 hours,
            tokenUpdateTimelockPeriod: 0 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISSVBasedApps.InvalidTokenUpdateTimelockPeriod.selector
            )
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }

    function testRevertInvalidMaxShares() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 1 days,
            feeExpireTime: 1 hours,
            withdrawalTimelockPeriod: 1 days,
            withdrawalExpireTime: 1 hours,
            obligationTimelockPeriod: 1 days,
            obligationExpireTime: 1 hours,
            tokenUpdateTimelockPeriod: 1 days,
            maxShares: 1e49,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(ISSVBasedApps.InvalidMaxShares.selector)
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }
    function testRevertInvalidDisabledFeatures() public virtual {
        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 1 days,
            feeExpireTime: 1 hours,
            withdrawalTimelockPeriod: 1 days,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 4
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISSVBasedApps.InvalidDisabledFeatures.selector
            )
        );
        proxy = new ERC1967Proxy(address(implementation), data);
    }
}
