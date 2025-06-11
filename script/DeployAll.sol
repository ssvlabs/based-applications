// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Script, console } from "forge-std/Script.sol";
import { stdJson } from "forge-std/StdJson.sol";

import { StrategyManager } from "src/core/modules/StrategyManager.sol";
import { BasedAppsManager } from "src/core/modules/BasedAppsManager.sol";
import { ProtocolManager } from "src/core/modules/ProtocolManager.sol";
import { SSVBasedApps } from "src/core/SSVBasedApps.sol";
import { ProtocolStorageLib } from "src/core/libraries/ProtocolStorageLib.sol";

contract DeployAll is Script {
    using stdJson for string;

    function _deployAll(string memory raw) internal returns (string memory) {
        vm.startBroadcast();

        SSVBasedApps impl = new SSVBasedApps();
        StrategyManager strategyMod = new StrategyManager();
        BasedAppsManager bAppsMod = new BasedAppsManager();
        ProtocolManager protocolMod = new ProtocolManager();

        ERC1967Proxy proxy = deployProxy(
            impl,
            strategyMod,
            bAppsMod,
            protocolMod,
            raw
        );

        vm.stopBroadcast();

        console.log("SSVBasedApps Impl:  ", address(impl));
        console.log("StrategyModule:     ", address(strategyMod));
        console.log("BAppsModule:        ", address(bAppsMod));
        console.log("ProtocolModule:     ", address(protocolMod));
        console.log("SSVBasedApps Proxy: ", address(proxy));

        return saveToJson(impl, proxy, strategyMod, bAppsMod, protocolMod, raw);
    }

    function saveToJson(
        SSVBasedApps impl,
        ERC1967Proxy proxy,
        StrategyManager strategyMod,
        BasedAppsManager bAppsMod,
        ProtocolManager protocolMod,
        string memory raw
    ) internal returns (string memory) {
        string memory parent = "parent";

        string memory deployed_addresses = "addresses";
        vm.serializeAddress(
            deployed_addresses,
            "SSVBasedAppsProxy",
            address(proxy)
        );
        vm.serializeAddress(
            deployed_addresses,
            "SSVBasedAppsImpl",
            address(impl)
        );
        vm.serializeAddress(
            deployed_addresses,
            "StrategyModule",
            address(strategyMod)
        );
        vm.serializeAddress(
            deployed_addresses,
            "BAppsModule",
            address(bAppsMod)
        );

        string memory deployed_addresses_output = vm.serializeAddress(
            deployed_addresses,
            "ProtocolModule",
            address(protocolMod)
        );

        string memory parameters = "parameters";
        vm.serializeUint(
            parameters,
            "feeTimelockPeriod",
            raw.readUint(".feeTimelockPeriod")
        );
        vm.serializeUint(
            parameters,
            "feeExpireTime",
            raw.readUint(".feeExpireTime")
        );
        vm.serializeUint(
            parameters,
            "withdrawalTimelockPeriod",
            raw.readUint(".withdrawalTimelockPeriod")
        );
        vm.serializeUint(
            parameters,
            "withdrawalExpireTime",
            raw.readUint(".withdrawalExpireTime")
        );
        vm.serializeUint(
            parameters,
            "obligationTimelockPeriod",
            raw.readUint(".obligationTimelockPeriod")
        );
        vm.serializeUint(
            parameters,
            "obligationExpireTime",
            raw.readUint(".obligationExpireTime")
        );
        vm.serializeUint(
            parameters,
            "tokenUpdateTimelockPeriod",
            raw.readUint(".tokenUpdateTimelockPeriod")
        );
        vm.serializeUint(parameters, "maxShares", raw.readUint(".maxShares"));
        vm.serializeUint(
            parameters,
            "maxFeeIncrement",
            raw.readUint(".maxFeeIncrement")
        );
        string memory parameters_output = vm.serializeUint(
            parameters,
            "disabledFeatures",
            raw.readUint(".disabledFeatures")
        );

        string memory chain_info = "chainInfo";
        vm.serializeUint(chain_info, "deploymentBlock", block.number);
        string memory chain_info_output = vm.serializeUint(
            chain_info,
            "chainId",
            block.chainid
        );

        // serialize all the data
        vm.serializeString(
            parent,
            deployed_addresses,
            deployed_addresses_output
        );
        vm.serializeString(parent, chain_info, chain_info_output);
        return vm.serializeString(parent, parameters, parameters_output);
    }

    function deployProxy(
        SSVBasedApps impl,
        StrategyManager strategyMod,
        BasedAppsManager bAppsMod,
        ProtocolManager protocolMod,
        string memory raw
    ) internal returns (ERC1967Proxy proxy) {
        return
            new ERC1967Proxy(
                address(impl),
                abi.encodeWithSelector(
                    impl.initialize.selector,
                    msg.sender,
                    address(bAppsMod),
                    address(strategyMod),
                    address(protocolMod),
                    ProtocolStorageLib.Data({
                        feeTimelockPeriod: uint32(
                            raw.readUint(".feeTimelockPeriod")
                        ),
                        feeExpireTime: uint32(raw.readUint(".feeExpireTime")),
                        withdrawalTimelockPeriod: uint32(
                            raw.readUint(".withdrawalTimelockPeriod")
                        ),
                        withdrawalExpireTime: uint32(
                            raw.readUint(".withdrawalExpireTime")
                        ),
                        obligationTimelockPeriod: uint32(
                            raw.readUint(".obligationTimelockPeriod")
                        ),
                        obligationExpireTime: uint32(
                            raw.readUint(".obligationExpireTime")
                        ),
                        tokenUpdateTimelockPeriod: uint32(
                            raw.readUint(".tokenUpdateTimelockPeriod")
                        ),
                        maxShares: raw.readUint(".maxShares"),
                        maxFeeIncrement: uint32(
                            raw.readUint(".maxFeeIncrement")
                        ),
                        disabledFeatures: uint32(
                            raw.readUint(".disabledFeatures")
                        )
                    })
                )
            );
    }
}
