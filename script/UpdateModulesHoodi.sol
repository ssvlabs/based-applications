// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { Script } from "forge-std/Script.sol";

import { SSVCoreModules } from "@ssv/src/core/libraries/CoreStorageLib.sol";
import { UpdateModules } from "./UpdateModules.s.sol";

contract UpdateModulesHoodi is Script, UpdateModules {
    function run(bool isProd, SSVCoreModules[] memory moduleIds) external {
        if (block.chainid != 560_048) {
            revert("This script is only for the Hoodi");
        }

        string memory cfgPath;
        string memory outPath;
        if (isProd) {
            cfgPath = "script/config/hoodi-prod.json";
            outPath = "artifacts/deploy-hoodi-prod.json";
        } else {
            cfgPath = "script/config/hoodi-stage.json";
            outPath = "artifacts/deploy-hoodi-stage.json";
        }

        _deployAndUpdate(outPath, moduleIds);
    }
}
