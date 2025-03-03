// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedAppWhitelisted} from "@ssv/src/interfaces/IBasedAppWhitelisted.sol";

import {BasedAppManagerSetupTest} from "@ssv/test/BAppManager.setup.t.sol";

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

    function testRevert_addWhitelistedZeroAddress() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IBasedAppWhitelisted.ZeroAddress.selector));
        whitelistExample.addWhitelisted(address(0));
    }
}
