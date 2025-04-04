// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {Setup} from "@ssv/test/helpers/Setup.t.sol";

contract AccessControlBasedApp is Setup {
    function testRevokeManagerRole() public {
        assertEq(bApp3.hasRole(bApp3.MANAGER_ROLE(), USER1), true, "User is manager");
        vm.prank(USER1);
        bApp3.revokeManagerRole(USER1);
        assertEq(bApp3.hasRole(bApp3.MANAGER_ROLE(), USER1), false, "User is not manager");
    }

    function testGrantManagerRole() public {
        assertEq(bApp3.hasRole(bApp3.MANAGER_ROLE(), USER2), false, "User is not manager");
        vm.prank(USER1);
        bApp3.grantManagerRole(USER2);
        assertEq(bApp3.hasRole(bApp3.MANAGER_ROLE(), USER2), true, "User is manager");
    }
}
