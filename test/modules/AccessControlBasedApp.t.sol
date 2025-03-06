// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppManagerSetupTest} from "@ssv/test/BAppManager.setup.t.sol";

contract AccessControlBasedApp is BasedAppManagerSetupTest {
    function test_RevokeManagerRole() public {
        assertEq(bApp3.hasRole(bApp3.MANAGER_ROLE(), USER1), true, "User is manager");
        vm.prank(USER1);
        bApp3.revokeManagerRole(USER1);
        assertEq(bApp3.hasRole(bApp3.MANAGER_ROLE(), USER1), false, "User is not manager");
    }

    function test_GrantManagerRole() public {
        assertEq(bApp3.hasRole(bApp3.MANAGER_ROLE(), USER2), false, "User is not manager");
        vm.prank(USER1);
        bApp3.grantManagerRole(USER2);
        assertEq(bApp3.hasRole(bApp3.MANAGER_ROLE(), USER2), true, "User is manager");
    }
}
