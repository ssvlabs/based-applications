// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { Script, console } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { StrategyManager } from "src/core/modules/StrategyManager.sol";
import { ProtocolManager } from "src/core/modules/ProtocolManager.sol";
import { BasedAppsManager } from "src/core/modules/BasedAppsManager.sol";
import { SSVBasedApps } from "src/core/SSVBasedApps.sol";
import { SSVCoreModules } from "@ssv/src/core/libraries/CoreStorageLib.sol";

contract DeployModule is Script {
    using stdJson for string;
    error InvalidModuleId();

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

        string memory json = vm.readFile(outPath);
        bytes memory mainRaw = vm.parseJson(json);

        bytes memory raw = vm.parseJson(json, ".addresses.SSVBasedAppsProxy");
        //            "SSVBasedAppsProxy": "0xCb06f27a0dD4A941790f83739867B44383375bBA",

        address proxy = abi.decode(raw, (address));
        console.log("Proxy Address:", proxy);

        address[] memory moduleAddresses = _deployAndUpdate(moduleIds, proxy);
        updateModuleToJson(moduleIds, moduleAddresses, outPath);
    }

    function _deployAndUpdate(
        SSVCoreModules[] memory moduleIds,
        address proxy
    ) internal returns (address[] memory moduleAddresses) {
        SSVBasedApps proxiedManager = SSVBasedApps(payable(proxy));
        moduleAddresses = new address[](moduleIds.length);

        vm.startBroadcast();
        for (uint256 i = 0; i < moduleIds.length; i++) {
            if (moduleIds[i] == SSVCoreModules.SSV_STRATEGY_MANAGER) {
                StrategyManager strategyMod = new StrategyManager();
                console.log("StrategyModule:", address(strategyMod));
                moduleAddresses[i] = address(strategyMod);
            } else if (moduleIds[i] == SSVCoreModules.SSV_PROTOCOL_MANAGER) {
                ProtocolManager protocolMod = new ProtocolManager();
                console.log("ProtocolModule:", address(protocolMod));
                moduleAddresses[i] = address(protocolMod);
            } else if (moduleIds[i] == SSVCoreModules.SSV_BAPPS_MANAGER) {
                BasedAppsManager bAppsMod = new BasedAppsManager();
                console.log("BasedAppModule:", address(bAppsMod));
                moduleAddresses[i] = address(bAppsMod);
            } else {
                revert InvalidModuleId();
            }
        }

        proxiedManager.updateModule(moduleIds, moduleAddresses);
        vm.stopBroadcast();

        return moduleAddresses;
    }

    function updateModuleToJson(
        SSVCoreModules[] memory moduleIds,
        address[] memory moduleAddresses,
        string memory outPath
    ) internal {
        for (uint256 i = 0; i < moduleIds.length; i++) {
            if (moduleIds[i] == SSVCoreModules.SSV_STRATEGY_MANAGER) {
                vm.writeJson(
                    vm.toString(moduleAddresses[i]),
                    outPath,
                    ".addresses.StrategyModule"
                );
            } else if (moduleIds[i] == SSVCoreModules.SSV_PROTOCOL_MANAGER) {
                vm.writeJson(
                    vm.toString(moduleAddresses[i]),
                    outPath,
                    ".addresses.ProtocolModule"
                );
            } else if (moduleIds[i] == SSVCoreModules.SSV_BAPPS_MANAGER) {
                vm.writeJson(
                    vm.toString(moduleAddresses[i]),
                    outPath,
                    ".addresses.BAppsModule"
                );
            } else {
                revert InvalidModuleId();
            }
        }
    }
}
