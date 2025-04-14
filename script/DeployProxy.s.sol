// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Script, console} from "@ssv/forge-std/Script.sol";
import {StrategyManager} from "@ssv/src/core/modules/StrategyManager.sol";
import {BasedAppsManager} from "@ssv/src/core/modules/BasedAppsManager.sol";
import {ProtocolManager} from "@ssv/src/core/modules/ProtocolManager.sol";
import {IBasedAppManager} from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import {IStrategyManager} from "@ssv/src/core/interfaces/IStrategyManager.sol";
import {IProtocolManager} from "@ssv/src/core/interfaces/IProtocolManager.sol";
import {SSVBasedApps} from "src/core/SSVBasedApps.sol";
import {StorageProtocol} from "@ssv/src/core/libraries/SSVBasedAppsStorageProtocol.sol";

// solhint-disable no-console
contract DeployProxy is Script {
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function run() external {
        vm.startBroadcast();

        SSVBasedApps implementation = new SSVBasedApps();

        StrategyManager strategyManagerMod = new StrategyManager();
        BasedAppsManager basedAppsManagerMod = new BasedAppsManager();
        ProtocolManager protocolManagerMod = new ProtocolManager();

        StorageProtocol memory config = StorageProtocol({
            feeTimelockPeriod: 5 days,
            feeExpireTime: 1 days,
            withdrawalTimelockPeriod: 14 days,
            ethAddress: ETH_ADDRESS,
            maxShares: 1e50,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            maxPercentage: 10_000,
            maxFeeIncrement: 500
        });

        bytes memory initData = abi.encodeWithSelector(
            implementation.initialize.selector,
            msg.sender,
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        console.log("Implementation deployed at:", address(implementation));
        console.log("Module StrategyManager deployed at:", address(strategyManagerMod));
        console.log("Module BasedAppsManager deployed at:", address(basedAppsManagerMod));
        console.log("Module ProtocolManager deployed at:", address(protocolManagerMod));
        console.log("Proxy deployed at:", address(proxy));

        console.log("Fee Timelock Period:", config.feeTimelockPeriod);
        console.log("Fee Expire Time:", config.feeExpireTime);
        console.log("Withdrawal Timelock Period:", config.withdrawalTimelockPeriod);
        console.log("Withdrawal Expire Time:", config.withdrawalExpireTime);
        console.log("Obligation Timelock Period:", config.obligationTimelockPeriod);
        console.log("Obligation Expire Time:", config.obligationExpireTime);
        console.log("Max Shares:", config.maxShares);
        console.log("Max Percentage:", config.maxPercentage);
        console.log("Max Fee Increment:", config.maxFeeIncrement);
        console.log("ETH Address:", config.ethAddress);
        vm.stopBroadcast();
    }
}
