// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Script, console} from "@ssv/forge-std/Script.sol";
import {StrategyManager} from "@ssv/src/modules/StrategyManager.sol";
import {BasedAppsManager} from "@ssv/src/modules/BasedAppsManager.sol";
import {SSVDAO} from "@ssv/src/modules/SSVDAO.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";
import {IStrategyManager} from "@ssv/src/interfaces/IStrategyManager.sol";
import {ISSVDAO} from "@ssv/src/interfaces/ISSVDAO.sol";
import {SSVBasedApps} from "src/SSVBasedApps.sol";

// solhint-disable no-console
contract DeployProxy is Script {
    function run() external {
        vm.startBroadcast();

        SSVBasedApps implementation = new SSVBasedApps();
        StrategyManager strategyManagerMod = new StrategyManager();
        BasedAppsManager basedAppsManagerMod = new BasedAppsManager();
        SSVDAO ssvDAOMod = new SSVDAO();

        uint32 maxFeeIncrement = 500;

        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,address,address,uint32)",
            msg.sender,
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            ISSVDAO(ssvDAOMod),
            maxFeeIncrement
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        console.log("Implementation deployed at:", address(implementation));
        console.log("Module StrategyManager deployed at:", address(strategyManagerMod));
        console.log("Module BasedAppsManager deployed at:", address(basedAppsManagerMod));
        console.log("Module SSVDAO deployed at:", address(ssvDAOMod));
        console.log("Proxy deployed at:", address(proxy));

        vm.stopBroadcast();
    }
}
