// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { Script, console } from "forge-std/Script.sol";
import { DeployAll } from "./DeployAll.sol";

contract DeployAllHoodi is Script, DeployAll {
    function run() external {
        if (block.chainid != 11155111) {
            revert("This script is only for Sepolia");
        }

        string memory finalJson = _deployAll(
            vm.readFile("script/config/sepolia.json")
        );

        vm.writeJson(finalJson, "artifacts/deploy-sepolia.json");
    }
}
