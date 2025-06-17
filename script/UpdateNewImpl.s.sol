// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { Script, console } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { SSVBasedApps } from "src/core/SSVBasedApps.sol";

contract UpdateNewImpl is Script {
    using stdJson for string;

    function _deployAndUpdate(
        string memory outPath
    ) internal returns (address impl) {
        string memory json = vm.readFile(outPath);
        bytes memory raw = vm.parseJson(json, ".addresses.SSVBasedAppsProxy");
        address proxy = abi.decode(raw, (address));
        console.log("Proxy Address:", proxy);
        SSVBasedApps proxiedManager = SSVBasedApps(payable(proxy));

        vm.startBroadcast();
        SSVBasedApps newImplementation = new SSVBasedApps();
        console.log("SSVBasedAppsImpl:", address(newImplementation));

        proxiedManager.upgradeToAndCall(address(newImplementation), "");
        vm.stopBroadcast();

        return address(newImplementation);
    }

    function updateImplementationToJson(
        address newImplementation,
        string memory outPath
    ) internal {
        vm.writeJson(
            vm.toString(newImplementation),
            outPath,
            ".addresses.SSVBasedAppsImpl"
        );
    }
}
