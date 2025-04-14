pragma solidity 0.8.29;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {ValidationLib} from "@ssv/src/core/libraries/ValidationLib.sol";
import {ISSVBasedApps} from "@ssv/src/core/interfaces/ISSVBasedApps.sol";
import {Setup} from "@ssv/test/helpers/Setup.t.sol";
import {SSVCoreModules} from "@ssv/src/core/libraries/CoreStorageLib.sol";

contract ValidationLibTest is Setup, Ownable2StepUpgradeable {
    function testUpdateStrategyModule() public {
        vm.expectEmit(true, true, true, true);
        emit ValidationLib.ModuleUpgraded(SSVCoreModules.SSV_STRATEGY_MANAGER, address(strategyManagerMod));
        vm.prank(OWNER);
        proxiedManager.updateModule(SSVCoreModules.SSV_STRATEGY_MANAGER, address(strategyManagerMod));
    }

    function testUpdateBasedAppsModule() public {
        vm.expectEmit(true, true, true, true);
        emit ValidationLib.ModuleUpgraded(SSVCoreModules.SSV_BAPPS_MANAGER, address(basedAppsManagerMod));
        vm.prank(OWNER);
        proxiedManager.updateModule(SSVCoreModules.SSV_BAPPS_MANAGER, address(basedAppsManagerMod));
    }

    function testUpdateDAOModule() public {
        vm.expectEmit(true, true, true, true);
        emit ValidationLib.ModuleUpgraded(SSVCoreModules.SSV_PROTOCOL_MANAGER, address(protocolManagerMod));
        vm.prank(OWNER);
        proxiedManager.updateModule(SSVCoreModules.SSV_PROTOCOL_MANAGER, address(protocolManagerMod));
    }

    function testRevertUpdateModuleWithNonOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        vm.prank(ATTACKER);
        proxiedManager.updateModule(SSVCoreModules.SSV_STRATEGY_MANAGER, address(strategyManagerMod));
    }

    function testRevertUpdateModuleWithNonContract() public {
        vm.expectRevert(abi.encodeWithSelector(ISSVBasedApps.TargetModuleDoesNotExist.selector, uint8(SSVCoreModules.SSV_STRATEGY_MANAGER)));
        vm.prank(OWNER);
        proxiedManager.updateModule(SSVCoreModules.SSV_STRATEGY_MANAGER, address(0));
    }

    function testIsBApp() public {
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bool success = ValidationLib.isBApp(address(bApps[i]));
            assertEq(success, true, "isBApp");
        }
    }
}
