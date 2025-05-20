// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { Script } from "forge-std/Script.sol";

import { console } from "forge-std/console.sol";

import { Vault } from "@ssv/src/core/Vault.sol";

contract DeployAllHoodi is Script {
    function run() external {
        vm.startBroadcast();

        address stEth = 0x3508A952176b3c15387C97BE809eaffB1982176a; //stETH hoodi: https://hoodi.etherscan.io/address/0x3508A952176b3c15387C97BE809eaffB1982176a

        Vault vault = new Vault(address(stEth));

        console.log("Vault deployed at: ", address(vault));

        vm.stopBroadcast();
    }
}
