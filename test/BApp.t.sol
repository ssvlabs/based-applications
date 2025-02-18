// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "./BAppManager.setup.t.sol";
import "./BAppManager.strategy.t.sol";
import "./BAppManager.bapp.t.sol";

contract BasedAppCoreTest is BasedAppManagerSetupTest, BasedAppManagerStrategyTest {
// function test_addTokensToBApp() public {
//     test_CreateStrategies();
//     test_RegisterBApp();
//     vm.prank(USER1);
//     string memory metadataURI = "metadataURI";
//     address[] memory tokens = new address[](1);
//     tokens[0] = address(0x1);
//     uint32[] memory sharedRiskLevels = new uint32[](tokens.length);
//     for (uint256 i = 0; i < tokens.length; i++) {
//         sharedRiskLevels[i] = 1;
//     }
//     bApp1.addTokensToBApp(tokens, sharedRiskLevels);
// }

// function test_updateBAppMetadataURI() public {
//     string memory metadataURI = "newMetadataURI";
//     vm.prank(USER1);
//     bApp1.updateBAppMetadataURI(metadataURI);
// }

// function test_optInToBApp() public {
//     bytes memory data = abi.encodePacked("0x1");
//     vm.prank(USER1);
//     bApp1.optInToBApp(STRATEGY1, data);
// }

// function test_updateBAppTokens() public {
//     test_addTokensToBApp();
//     vm.prank(USER1);
//     address[] memory tokens = new address[](1);
//     tokens[0] = address(0x1);
//     uint32[] memory sharedRiskLevels = new uint32[](tokens.length);
//     for (uint256 i = 0; i < tokens.length; i++) {
//         sharedRiskLevels[i] = 2;
//     }
//     bApp1.updateBAppTokens(tokens, sharedRiskLevels);
// }
// todo update with tokens never seen before
}
