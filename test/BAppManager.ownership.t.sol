// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "./BAppManager.setup.t.sol";

contract BasedAppManagerOwnershipTest is BasedAppManagerSetupTest {
    function test_OwnerOfBasedAppManager() public view {
        assertEq(proxiedManager.owner(), OWNER, "Owner should be the deployer");
    }

    function test_Implementation() public view {
        address currentImplementation = address(
            uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1))))
        );
        assertEq(
            currentImplementation, address(implementation), "Implementation should be the BasedAppManager contract"
        );
    }

    function testRevert_UpgradeUnauthorizedFromNonOwner() public {
        BasedAppManager newImplementation = new BasedAppManager();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.upgradeToAndCall(address(newImplementation), bytes(""));
    }

    function test_UpgradeAuthorized() public {
        BasedAppManager newImplementation = new BasedAppManager();

        vm.prank(OWNER);
        proxiedManager.upgradeToAndCall(address(newImplementation), bytes(""));

        address currentImplementation = address(
            uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1))))
        );
        assertEq(currentImplementation, address(newImplementation), "Implementation should be upgraded");
    }
}
