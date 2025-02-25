// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppCore} from "middleware/modules/core/BasedAppCore.sol";

import "./BAppManager.setup.t.sol";

contract BasedAppManagerBAppTest is BasedAppManagerSetupTest {
    string metadataURI = "http://metadata.com";

    function test_addWhitelistedAccount() public {
        vm.prank(USER1);
        whitelistExample.addWhitelisted(USER2);
        assertEq(whitelistExample.isWhitelisted(USER2), true);
    }
}
