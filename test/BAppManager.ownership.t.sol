// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    BasedAppManagerSetupTest,
    IStrategyManager,
    IBasedAppManager,
    ISlashingManager,
    IDelegationManager,
    ISSVDAO,
    SSVBasedApps,
    ERC1967Proxy
} from "@ssv/test/BAppManager.setup.t.sol";
import {ICore} from "@ssv/src/interfaces/ICore.sol";
import {IStrategyManager} from "@ssv/src/interfaces/IStrategyManager.sol";
import {CoreLib} from "@ssv/src/libraries/CoreLib.sol";

contract BasedAppManagerOwnershipTest is BasedAppManagerSetupTest, OwnableUpgradeable {
    function testOwnerOfBasedAppManager() public view {
        assertEq(proxiedManager.owner(), OWNER, "Owner should be the deployer");
    }

    function testImplementation() public view {
        address currentImplementation = address(uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)))));
        assertEq(currentImplementation, address(implementation), "Implementation should be the SSVBasedApps contract");
    }

    function testRevertUpgradeUnauthorizedFromNonOwner() public {
        SSVBasedApps newImplementation = new SSVBasedApps();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.upgradeToAndCall(address(newImplementation), bytes(""));
    }

    function testUpgradeAuthorized() public {
        SSVBasedApps newImplementation = new SSVBasedApps();

        vm.prank(OWNER);
        proxiedManager.upgradeToAndCall(address(newImplementation), bytes(""));

        address currentImplementation = address(uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)))));
        assertEq(currentImplementation, address(newImplementation), "Implementation should be upgraded");
    }

    function testRevertTryToCallInitializeAgainFromAttacker() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        vm.prank(ATTACKER);
        proxiedManager.initialize(
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            ISSVDAO(ssvDAOMod),
            ISlashingManager(slashingManagerMod),
            IDelegationManager(delegationManagerMod),
            10
        );
    }

    function testRevertTryToCallInitializeAgainFromOwner() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        vm.prank(OWNER);
        proxiedManager.initialize(
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            ISSVDAO(ssvDAOMod),
            ISlashingManager(slashingManagerMod),
            IDelegationManager(delegationManagerMod),
            10
        );
    }

    function testRevertInitializeWithZeroFee() public {
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidMaxFeeIncrement.selector));
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address,address,address,address,uint32)",
            address(OWNER),
            address(basedAppsManagerMod),
            address(strategyManagerMod),
            address(ssvDAOMod),
            address(slashingManagerMod),
            address(delegationManagerMod),
            0
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
    }

    function testRevertInitializeWithExcessiveFee() public {
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidMaxFeeIncrement.selector));
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address,address,address,address,uint32)",
            address(OWNER),
            address(basedAppsManagerMod),
            address(strategyManagerMod),
            address(ssvDAOMod),
            address(slashingManagerMod),
            address(delegationManagerMod),
            10_001
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
    }
}
