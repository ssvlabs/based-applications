// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { Script } from "forge-std/Script.sol";
import { DeployAll } from "./DeployAll.sol";

contract DeployAllHoodi is Script, DeployAll {
    function run(bool isTestnet) external {
        if (block.chainid != 560_048) {
            revert("This script is only for the Hoodi testnet");
        }

        string memory cfgPath;
        string memory outPath;
        if (isTestnet) {
            cfgPath = "script/config/hoodi_testnet.json";
            outPath = "artifacts/deploy-hoodi-testnet.json";
        } else {
            cfgPath = "script/config/hoodi_stage.json";
            outPath = "artifacts/deploy-hoodi-stage.json";
        }

        string memory finalJson = _deployAll(vm.readFile(cfgPath));

        vm.writeJson(finalJson, outPath);
    }
}
