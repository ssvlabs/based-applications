// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "./BAppManager.setup.t.sol";

contract BasedAppManagerBAppTest is BasedAppManagerSetupTest {
    string metadataURI = "http://metadata.com";

    function createSingleTokenAndSingleRiskLevel(address token, uint32 sharedRiskLevel)
        private
        pure
        returns (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput)
    {
        tokensInput = new address[](1);
        tokensInput[0] = token;
        sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = sharedRiskLevel;
    }

    function createTwoTokenAndRiskInputs()
        private
        view
        returns (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput)
    {
        tokensInput = new address[](2);
        sharedRiskLevelInput = new uint32[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 103;
    }

    function createFiveTokenAndRiskInputs()
        private
        view
        returns (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput)
    {
        tokensInput = new address[](5);
        sharedRiskLevelInput = new uint32[](5);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        tokensInput[2] = address(erc20mock3);
        tokensInput[3] = address(erc20mock4);
        tokensInput[4] = address(erc20mock5);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 103;
        sharedRiskLevelInput[2] = 104;
        sharedRiskLevelInput[3] = 105;
        sharedRiskLevelInput[4] = 106;
    }

    function checkBAppInfo(address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) public view {
        address owner = proxiedManager.bAppOwners(BAPP1);
        assertEq(tokensInput.length, sharedRiskLevelInput.length, "BApp tokens and sharedRiskLevel length");
        assertEq(owner, USER1, "BApp owner");
        for (uint256 i = 0; i < tokensInput.length; i++) {
            (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(BAPP1, tokensInput[i]);
            assertEq(sharedRiskLevelInput[i], sharedRiskLevel, "BApp sharedRiskLevel");
            assertEq(isSet, true, "BApp sharedRiskLevel set");
        }
    }

    function test_RegisterBApp() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function test_RegisterBAppWith2Tokens() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createTwoTokenAndRiskInputs();
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function test_RegisterBAppWithETH() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 100);
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function test_RegisterBAppWithNoTokens() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](0);
        uint32[] memory sharedRiskLevelInput = new uint32[](0);
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "http://metadata.com");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
    }

    function test_RegisterBAppWithFiveTokens() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createFiveTokenAndRiskInputs();
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
    }

    function test_RegisterBAppWithETHAndErc20() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = ETH_ADDRESS;
        tokensInput[1] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 102;
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function testRevert_RegisterBAppTwice() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "");
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "");
        vm.stopPrank();
    }

    function testRevert_RegisterBAppOverwrite() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        proxiedManager.registerBApp(BAPP1, tokensInput, sharedRiskLevelInput, "");
        vm.stopPrank();
    }

    function test_UpdateBAppWithNewTokens() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock2);
        tokensInput[1] = address(ETH_ADDRESS);
        uint32[] memory sharedRiskLevelInput = new uint32[](2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 103;
        proxiedManager.addTokensToBApp(BAPP1, tokensInput, sharedRiskLevelInput);
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function testRevert_UpdateBAppWithNotMatchingLengths() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock2);
        tokensInput[1] = address(ETH_ADDRESS);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        vm.expectRevert(abi.encodeWithSelector(ICore.LengthsNotMatching.selector));
        proxiedManager.addTokensToBApp(BAPP1, tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function testRevert_UpdateBAppWithAlreadyPresentTokensRevert() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(ETH_ADDRESS);
        uint32[] memory sharedRiskLevelInput = new uint32[](2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 103;
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenAlreadyAddedToBApp.selector, address(erc20mock)));
        proxiedManager.addTokensToBApp(BAPP1, tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function testRevert_AddTokensToBAppWithNonOwner() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidBAppOwner.selector, address(ATTACKER), address(USER1)));
        proxiedManager.addTokensToBApp(BAPP1, new address[](0), new uint32[](0));
    }

    function testRevert_AddTokensToBAppWithEmptyTokenList() public {
        test_RegisterBApp();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.EmptyTokenList.selector));
        proxiedManager.addTokensToBApp(BAPP1, new address[](0), new uint32[](0));
    }

    function testRevert_AddTokensToBAppWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.ZeroAddressNotAllowed.selector));
        proxiedManager.addTokensToBApp(BAPP1, tokensInput, sharedRiskLevelInput);
    }

    function test_UpdateBAppMetadata() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        vm.expectEmit(true, false, false, false);
        emit IBasedAppManager.BAppMetadataURIUpdated(BAPP1, metadataURI);
        proxiedManager.updateBAppMetadataURI(BAPP1, metadataURI);
        vm.stopPrank();
    }

    function testRevert_UpdateBAppMetadataWithWrongOwner() public {
        test_RegisterBApp();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidBAppOwner.selector, address(ATTACKER), address(USER1)));
        proxiedManager.updateBAppMetadataURI(BAPP1, metadataURI);
        vm.stopPrank();
    }

    function testRevert_updateBAppTokensWithNonOwner() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(ICore.InvalidBAppOwner.selector, address(ATTACKER), address(USER1)));
        proxiedManager.updateBAppTokens(BAPP1, new address[](0), new uint32[](0));
    }

    function testRevert_updateBAppTokensWithEmptyTokenList() public {
        test_RegisterBApp();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.EmptyTokenList.selector));
        proxiedManager.updateBAppTokens(BAPP1, new address[](0), new uint32[](0));
    }

    function testRevert_updateBAppTokensWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.ZeroAddressNotAllowed.selector));
        proxiedManager.updateBAppTokens(BAPP1, tokensInput, sharedRiskLevelInput);
    }

    function testRevert_updateBAppTokensWithTokenNotSet() public {
        test_RegisterBApp();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock2), 100);
        proxiedManager.updateBAppTokens(BAPP1, tokensInput, sharedRiskLevelInput);
    }

    function test_updateBAppTokensWithOneToken() public {
        test_RegisterBApp();
        vm.prank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 1000);
        proxiedManager.updateBAppTokens(BAPP1, tokensInput, sharedRiskLevelInput);
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
    }

    function testRevert_updateBAppTokensWithSharedRiskLevelAlreadySet() public {
        test_RegisterBApp();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(ICore.SharedRiskLevelAlreadySet.selector));
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        proxiedManager.updateBAppTokens(BAPP1, tokensInput, sharedRiskLevelInput);
    }
}
