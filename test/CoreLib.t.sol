pragma solidity 0.8.29;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {BasedAppManagerSetupTest} from "@ssv/test/BAppManager.setup.t.sol";
import {CoreLib} from "@ssv/src/libraries/CoreLib.sol";
import {SSVBasedAppsModules} from "@ssv/src/libraries/SSVBasedAppsStorage.sol";
import {ICore} from "@ssv/src/interfaces/ICore.sol";

contract CoreLibTest is BasedAppManagerSetupTest, OwnableUpgradeable {
    function testUpdateStrategyModule() public {
        vm.expectEmit(true, true, true, true);
        emit CoreLib.ModuleUpgraded(SSVBasedAppsModules.SSV_STRATEGY_MANAGER, address(strategyManagerMod));
        vm.prank(OWNER);
        proxiedManager.updateModule(SSVBasedAppsModules.SSV_STRATEGY_MANAGER, address(strategyManagerMod));
    }

    function testUpdateBasedAppsModule() public {
        vm.expectEmit(true, true, true, true);
        emit CoreLib.ModuleUpgraded(SSVBasedAppsModules.SSV_BASED_APPS_MANAGER, address(basedAppsManagerMod));
        vm.prank(OWNER);
        proxiedManager.updateModule(SSVBasedAppsModules.SSV_BASED_APPS_MANAGER, address(basedAppsManagerMod));
    }

    function testUpdateDAOModule() public {
        vm.expectEmit(true, true, true, true);
        emit CoreLib.ModuleUpgraded(SSVBasedAppsModules.SSV_DAO, address(ssvDAOMod));
        vm.prank(OWNER);
        proxiedManager.updateModule(SSVBasedAppsModules.SSV_DAO, address(ssvDAOMod));
    }

    function testRevertUpdateModuleWithNonOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        vm.prank(ATTACKER);
        proxiedManager.updateModule(SSVBasedAppsModules.SSV_STRATEGY_MANAGER, address(strategyManagerMod));
    }

    function testRevertUpdateModuleWithNonContract() public {
        vm.expectRevert(abi.encodeWithSelector(ICore.TargetModuleDoesNotExistWithData.selector, uint8(SSVBasedAppsModules.SSV_STRATEGY_MANAGER)));
        vm.prank(OWNER);
        proxiedManager.updateModule(SSVBasedAppsModules.SSV_STRATEGY_MANAGER, address(0));
    }

    function testIsBApp() public {
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bool success = CoreLib.isBApp(address(bApps[i]));
            assertEq(success, true, "isBApp");
        }
    }
}
