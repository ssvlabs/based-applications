// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { Script, console } from "forge-std/Script.sol";
import { DeployAll } from "./DeployAll.sol";

contract DeployAllHoodi is Script, DeployAll {
    function run() external {
        if (block.chainid != 1) {
            revert("This script is only for Mainnet");
        }

        string memory finalJson = _deployAll(
            vm.readFile("script/config/mainnet.json")
        );

        vm.writeJson(finalJson, "artifacts/deploy-mainnet.json");
    }
}
