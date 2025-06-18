// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { Script } from "forge-std/Script.sol";
import { DeployAll } from "./DeployAll.sol";

contract DeployAllHoodi is Script, DeployAll {
    function run(bool isProd) external {
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

        string memory finalJson = _deployAll(vm.readFile(cfgPath));

        vm.writeJson(finalJson, outPath);
    }
}
