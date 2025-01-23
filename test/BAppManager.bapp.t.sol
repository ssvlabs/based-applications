// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "./BAppManager.setup.t.sol";

contract BasedAppManagerBAppTest is BasedAppManagerSetupTest {
    string metadataURI = "http://metadata.com";

    function test_RegisterBApp() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, BAPP1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(BAPP1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(BAPP1);
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
        proxiedManager.registerBApp(USER1, BAPP1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(BAPP1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(BAPP1);
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
        proxiedManager.registerBApp(USER1, BAPP1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(BAPP1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(BAPP1);
        assertEq(tokens[0], ETH_ADDRESS, "BApp token");
        assertEq(tokensInput[0], ETH_ADDRESS, "BApp token input");
        vm.stopPrank();
    }

    function test_RegisterBAppWithNoTokens() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](0);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, BAPP1, tokensInput, sharedRiskLevelInput, "http://metadata.com");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(BAPP1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(BAPP1);
        assertEq(tokens.length, 0, "BApp token");
    }

    function test_RegisterBAppWithTwentyToken() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](20);
        tokensInput[0] = address(erc20mock2);
        for (uint256 i = 1; i < 20; i++) {
            tokensInput[i] = address(erc20mock);
        }
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, BAPP1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(BAPP1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(BAPP1);
            assertEq(tokens[0], address(erc20mock2), "BApp token");
        for (uint256 i = 1; i < 20; i++) {
            assertEq(tokens[i], address(erc20mock), "BApp token");
            assertEq(tokensInput[i], address(erc20mock), "BApp token");
        }
    }

    function test_RegisterBAppWithETHAndErc20() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = ETH_ADDRESS;
        tokensInput[1] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, BAPP1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(BAPP1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(BAPP1);
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
        proxiedManager.registerBApp(USER1, BAPP1, tokensInput, sharedRiskLevelInput, "");
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        proxiedManager.registerBApp(USER1, BAPP1, tokensInput, 2, "");
        vm.stopPrank();
    }

    function testRevert_RegisterBAppOverwrite() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32 sharedRiskLevelInput = 102;
        proxiedManager.registerBApp(USER1, BAPP1, tokensInput, sharedRiskLevelInput, "");
        (address owner, uint32 sharedRiskLevel) = proxiedManager.bApps(BAPP1);
        assertEq(owner, USER1, "BApp owner");
        assertEq(sharedRiskLevelInput, sharedRiskLevel, "BApp sharedRiskLevel");
        address[] memory tokens = proxiedManager.getBAppTokens(BAPP1);
        assertEq(tokens[0], address(erc20mock), "BApp token");
        assertEq(tokensInput[0], address(erc20mock), "BApp token");
        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        proxiedManager.registerBApp(ATTACKER, BAPP1, tokensInput, 2, "");
        vm.stopPrank();
    }

    function test_UpdateBAppWithNewTokens() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock2);
        tokensInput[1] = address(ETH_ADDRESS);
        proxiedManager.addTokensToBApp(BAPP1, tokensInput);
        vm.stopPrank();
    }

    function testRevert_UpdateBAppWithAlreadyPresentTokensRevert() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(ETH_ADDRESS);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenAlreadyAddedToBApp.selector, address(erc20mock)));
        proxiedManager.addTokensToBApp(BAPP1, tokensInput);
        vm.stopPrank();
    }

    function test_UpdateBAppMetadata() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        vm.expectEmit(true, false, false, false);
        emit IBasedAppManager.BAppMetadataURIUpdated(BAPP1, metadataURI);
        proxiedManager.updateMetadataURI(BAPP1, metadataURI);
        vm.stopPrank();
    }

    function testRevert_UpdateBAppMetadataWithWrongOwner() public {
        test_RegisterBApp();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidBAppOwner.selector, address(ATTACKER), address(USER1)));
        proxiedManager.updateMetadataURI(BAPP1, metadataURI);
        vm.stopPrank();
    }
}
