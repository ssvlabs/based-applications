// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "@ssv/test/BAppManager.setup.t.sol";

contract BasedAppManagerOwnershipTest is BasedAppManagerSetupTest {
    function test_OwnerOfBasedAppManager() public view {
        assertEq(proxiedManager.owner(), OWNER, "Owner should be the deployer");
    }

    function test_Implementation() public view {
        address currentImplementation =
            address(uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)))));
        assertEq(currentImplementation, address(implementation), "Implementation should be the SSVBasedApps contract");
    }

    function testRevert_UpgradeUnauthorizedFromNonOwner() public {
        SSVBasedApps newImplementation = new SSVBasedApps();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.upgradeToAndCall(address(newImplementation), bytes(""));
    }

    function test_UpgradeAuthorized() public {
        SSVBasedApps newImplementation = new SSVBasedApps();

        vm.prank(OWNER);
        proxiedManager.upgradeToAndCall(address(newImplementation), bytes(""));

        address currentImplementation =
            address(uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)))));
        assertEq(currentImplementation, address(newImplementation), "Implementation should be upgraded");
    }

    function testRevert_TryToCallInitializeAgainFromAttacker() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        vm.prank(ATTACKER);
        proxiedManager.initialize(address(OWNER), 10);
    }

    function testRevert_TryToCallInitializeAgainFromOwner() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidInitialization.selector));
        vm.prank(OWNER);
        proxiedManager.initialize(address(OWNER), 10);
    }

    function testRevert_InitializeWithZeroFee() public {
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidMaxFeeIncrement.selector));
        bytes memory initData = abi.encodeWithSignature("initialize(address,uint32)", address(OWNER), 0);
        proxy = new ERC1967Proxy(address(implementation), initData);
    }

    function testRevert_InitializeWithExcessiveFee() public {
        vm.expectRevert(abi.encodeWithSelector(IStorage.InvalidMaxFeeIncrement.selector));
        bytes memory initData = abi.encodeWithSignature("initialize(address,uint32)", address(OWNER), 10_001);
        proxy = new ERC1967Proxy(address(implementation), initData);
    }
}
