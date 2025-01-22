// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "./BAppManager.setup.t.sol";

contract BasedAppManagerBAppTest is BasedAppManagerSetupTest {
    function test_RegisterBApp() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokensInput[0], address(erc20mock), "BApp token");
        vm.stopPrank();
    }

    function test_RegisterBAppWith2Tokens() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokensInput[0], address(erc20mock), "BApp token");
        assertEq(tokens[1], address(erc20mock2), "BApp token 2");
        assertEq(tokensInput[1], address(erc20mock2), "BApp token 2");
        vm.stopPrank();
    }

    function test_RegisterBAppWithETH() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = ETH_ADDRESS;
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], ETH_ADDRESS, "BApp token");
        assertEq(tokensInput[0], ETH_ADDRESS, "BApp token input");
        vm.stopPrank();
    }

    function test_RegisterBAppWithETHAndErc20() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = ETH_ADDRESS;
        tokensInput[1] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], ETH_ADDRESS, "BApp token");
        assertEq(tokensInput[0], ETH_ADDRESS, "BApp token input");
        assertEq(tokens[1], address(erc20mock), "BApp token");
        assertEq(tokensInput[1], address(erc20mock), "BApp token input");
        vm.stopPrank();
    }

    function testRevert_RegisterBAppTwice() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput, "");
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, 2, "");
        vm.stopPrank();
    }

    function testRevert_RegisterBAppOverwrite() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, SERVICE1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(SERVICE1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(SERVICE1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokensInput[0], address(erc20mock), "BApp token");
        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        proxiedManager.registerBApp(ATTACKER, SERVICE1, tokensInput, 2, "");
        vm.stopPrank();
    }

    function test_UpdateBAppWithNewTokens() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock2);
        tokensInput[1] = address(ETH_ADDRESS);
        proxiedManager.addTokensToBApp(SERVICE1, tokensInput);
        vm.stopPrank();
    }

    function testRevert_UpdateBAppWithAlreadyPresentTokensRevert() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(ETH_ADDRESS);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenAlreadyAddedToBApp.selector, address(erc20mock)));
        proxiedManager.addTokensToBApp(SERVICE1, tokensInput);
        vm.stopPrank();
    }
}
