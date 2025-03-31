// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {BasedAppManagerSetupTest} from "@ssv/test/BAppManager.setup.t.sol";

contract BasedAppManagerFallbackTest is BasedAppManagerSetupTest {
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
}
