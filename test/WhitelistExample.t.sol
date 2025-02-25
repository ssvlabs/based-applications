// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedAppWhitelisted} from "interfaces/IBasedAppWhitelisted.sol";

import "./BAppManager.setup.t.sol";

contract BasedAppManagerBAppTest is BasedAppManagerSetupTest {
    function test_addWhitelistedAccount() public {
        vm.prank(USER1);
        whitelistExample.addWhitelisted(USER2);
        assertEq(whitelistExample.isWhitelisted(USER2), true);
    }

    function test_removeWhitelistedAccount() public {
        test_addWhitelistedAccount();
        vm.prank(USER1);
        whitelistExample.removeWhitelisted(USER2);
        assertEq(whitelistExample.isWhitelisted(USER2), false);
    }

    function testRevert_addWhitelistedAccount() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IBasedAppWhitelisted.AlreadyWhitelisted.selector));
        whitelistExample.addWhitelisted(USER1);
    }

    
    function testRevert_removeWhitelistedAccount() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IBasedAppWhitelisted.NotWhitelisted.selector));
        whitelistExample.removeWhitelisted(USER2);
    }
}
