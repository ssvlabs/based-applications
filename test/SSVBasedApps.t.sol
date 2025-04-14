// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import {Setup, IStrategyManager, IBasedAppManager, IProtocolManager, SSVBasedApps, ERC1967Proxy} from "@ssv/test/helpers/Setup.t.sol";
import {ISSVBasedApps} from "@ssv/src/core/interfaces/ISSVBasedApps.sol";
import {ICore} from "@ssv/src/core/interfaces/ICore.sol";
import {ProtocolStorageLib} from "@ssv/src/core/libraries/ProtocolStorageLib.sol";

contract SSVBasedAppsTest is Setup, Ownable2StepUpgradeable {
    function testInitialBalanceIsZero() public view {
        assertEq(address(proxiedManager).balance, 0);
    }

    function testRevertSendETHDirectly() public payable {
        vm.prank(USER1);
        vm.expectRevert();
        payable(address(proxiedManager)).transfer(1 ether);
        assertEq(address(proxiedManager).balance, 0);
    }

    function testRevertSendETHViaFallback() public {
        vm.prank(USER1);
        (bool success,) = payable(address(proxiedManager)).call{value: 1 ether}("");
        assertEq(success, false);
        assertEq(address(proxiedManager).balance, 0);
    }

    function testRevertViaFallbackInvalidFunctionCall() public {
        vm.prank(USER1);
        (bool success,) = payable(address(proxiedManager)).call{value: 0 ether}("");
        assertEq(success, false);
        assertEq(address(proxiedManager).balance, 0);
    }

    function testOwner() public view {
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

    function testUpdateOwner() public {
        vm.prank(OWNER);
        proxiedManager.transferOwnership(USER1);
        assertEq(proxiedManager.owner(), OWNER, "Owner should not be updated yet");
        vm.prank(USER1);
        proxiedManager.acceptOwnership();
        assertEq(proxiedManager.owner(), USER1, "Owner should be updated to USER1");
    }

    function testRevertUpdateOwnerUnauthorized() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.transferOwnership(USER1);
    }

    function testRevertTryToCallInitializeAgainFromAttacker() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        vm.prank(ATTACKER);
        proxiedManager.initialize(
            address(OWNER), IBasedAppManager(basedAppsManagerMod), IStrategyManager(strategyManagerMod), IProtocolManager(protocolManagerMod), config
        );
    }

    function testRevertTryToCallInitializeAgainFromOwner() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        vm.prank(OWNER);
        proxiedManager.initialize(
            address(OWNER), IBasedAppManager(basedAppsManagerMod), IStrategyManager(strategyManagerMod), IProtocolManager(protocolManagerMod), config
        );
    }

    function testRevertInitializeWithZeroFee() public {
        ProtocolStorageLib.Data memory configZeroFee = ProtocolStorageLib.Data({
            maxFeeIncrement: 0,
            feeTimelockPeriod: 5 days,
            feeExpireTime: 1 days,
            withdrawalTimelockPeriod: 14 days,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            maxShares: 1e50
        });
        vm.expectRevert(abi.encodeWithSelector(ISSVBasedApps.InvalidMaxFeeIncrement.selector));

        bytes memory initData = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            address(basedAppsManagerMod),
            address(strategyManagerMod),
            address(protocolManagerMod),
            configZeroFee
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
    }

    function testRevertInitializeWithExcessiveFee() public {
        ProtocolStorageLib.Data memory configExcessiveFee = ProtocolStorageLib.Data({
            feeTimelockPeriod: 5 days,
            feeExpireTime: 1 days,
            withdrawalTimelockPeriod: 14 days,
            maxShares: 1e50,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            maxFeeIncrement: 10_001
        });
        vm.expectRevert(abi.encodeWithSelector(ISSVBasedApps.InvalidMaxFeeIncrement.selector));
        bytes memory initData = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            address(basedAppsManagerMod),
            address(strategyManagerMod),
            address(protocolManagerMod),
            configExcessiveFee
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
    }
}
