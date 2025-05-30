// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { Script, console } from "@ssv/forge-std/Script.sol";

interface IUUPSUpgradeable {
    function upgradeToAndCall(
        address newImplementation,
        bytes calldata data
    ) external;
}

// solhint-disable no-console
contract UpgradeScript is Script {
    function run() external {
        vm.startBroadcast();

        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address newImplementation = vm.envAddress("IMPLEMENTATION_ADDRESS");

        IUUPSUpgradeable(proxyAddress).upgradeToAndCall(newImplementation, "");

        console.log(
            "Proxy ",
            proxyAddress,
            " upgraded to new implementation: ",
            newImplementation
        );

        vm.stopBroadcast();
    }
}
