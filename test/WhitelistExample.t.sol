// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppCore} from "middleware/modules/core/BasedAppCore.sol";
// import {WhitelistExample} from "../src/middleware/modules/examples/WhitelistExample.sol";

import "./BAppManager.setup.t.sol";

contract BasedAppManagerBAppTest is BasedAppManagerSetupTest {
    string metadataURI = "http://metadata.com";
}
