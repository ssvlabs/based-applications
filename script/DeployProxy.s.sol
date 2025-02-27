// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ssv/forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "src/SSVBasedApps.sol";

contract DeployProxy is Script {
    function run() external {
        // 1. Start a broadcast for deploying transactions
        vm.startBroadcast();

        // 2. Deploy the implementation contract
        SSVBasedApps implementation = new SSVBasedApps();

        uint32 maxFeeIncrement = 500;

        // 3. Encode initializer data for the proxy
        bytes memory initData = abi.encodeWithSignature("initialize(address,uint32)", msg.sender, maxFeeIncrement);

        // 4. Deploy the proxy and link it to the implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        // Log deployed addresses
        console.log("Implementation deployed at:", address(implementation));
        console.log("Proxy deployed at:", address(proxy));

        vm.stopBroadcast();
    }
}
