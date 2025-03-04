// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppCore} from "@ssv/src/middleware/modules/core/BasedAppCore.sol";

import {BasedAppManagerSetupTest, IStorage, IBasedAppManager} from "@ssv/test/BAppManager.setup.t.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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
        assertEq(tokensInput.length, sharedRiskLevelInput.length, "BApp tokens and sharedRiskLevel length");
        bool isRegistered = proxiedManager.registeredBApps(address(bApp1));
        assertEq(isRegistered, true, "BApp registered");
        for (uint32 i = 0; i < tokensInput.length; i++) {
            (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(address(bApp1), tokensInput[i]);
            assertEq(sharedRiskLevelInput[i], sharedRiskLevel, "BApp sharedRiskLevel");
            assertEq(isSet, true, "BApp sharedRiskLevel set");
        }
    }

    function test_RegisterBApp() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, metadataURI);
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function test_RegisterBAppWith2Tokens() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createTwoTokenAndRiskInputs();
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function test_RegisterBAppWithETH() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 100);
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function test_RegisterBAppWithNoTokens() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](0);
        uint32[] memory sharedRiskLevelInput = new uint32[](0);
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "http://metadata.com");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
    }

    function test_RegisterBAppWithFiveTokens() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createFiveTokenAndRiskInputs();
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
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
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function testRevert_RegisterBAppTwice() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppAlreadyRegistered.selector));
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.stopPrank();
    }

    function test_RegisterBAppFromEOA() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.stopPrank();
    }

    function testRevert_RegisterBAppFromNonBAppContract() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppDoesNotSupportInterface.selector));
        nonCompliantBApp.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.stopPrank();
    }

    function test_isBapp() public {
        vm.startPrank(USER1);
        bool success = proxiedManager._isBApp(address(bApp1));
        assertEq(success, true, "isBApp");
        vm.stopPrank();
    }

    function testRevert_RegisterBAppOverwrite() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppAlreadyRegistered.selector));
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
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
        bApp1.addTokensToBApp(tokensInput, sharedRiskLevelInput);
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
        vm.expectRevert(abi.encodeWithSelector(IStorage.LengthsNotMatching.selector));
        bApp1.addTokensToBApp(tokensInput, sharedRiskLevelInput);
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
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenAlreadyAddedToBApp.selector, address(erc20mock)));
        bApp1.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function testRevert_AddTokensToBAppWithNonOwner() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        bApp1.addTokensToBApp(new address[](0), new uint32[](0));
    }

    function testRevert_AddTokensToBAppWithEmptyTokenList() public {
        test_RegisterBApp();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp1.addTokensToBApp(new address[](0), new uint32[](0));
    }

    function testRevert_AddTokensToBAppWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
        bApp1.addTokensToBApp(tokensInput, sharedRiskLevelInput);
    }

    function test_UpdateBAppMetadata() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        vm.expectEmit(true, false, false, false);
        emit IBasedAppManager.BAppMetadataURIUpdated(address(bApp1), metadataURI);
        bApp1.updateBAppMetadataURI(metadataURI);
        vm.stopPrank();
    }

    function testRevert_UpdateBAppMetadataWithWrongOwner() public {
        test_RegisterBApp();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        bApp1.updateBAppMetadataURI(metadataURI);
        vm.stopPrank();
    }

    function testRevert_proposeBAppTokensUpdateWithNonOwner() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        bApp1.proposeBAppTokensUpdate(new address[](0), new uint32[](0));
    }

    function testRevert_finalizeBAppTokensUpdateWithNonOwner() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        bApp1.finalizeBAppTokensRemoval();
    }

    function testRevert_proposeBAppTokensUpdateWithNonOwnerFromMainContract() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        proxiedManager.proposeBAppTokensUpdate(new address[](0), new uint32[](0));
    }

    function testRevert_finalizeBAppTokensUpdateWithNonOwnerFromMainContract() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        proxiedManager.finalizeBAppTokensUpdate();
    }

    function testRevert_updateBAppTokensWithEmptyTokenList() public {
        test_RegisterBApp();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp1.proposeBAppTokensUpdate(new address[](0), new uint32[](0));
    }

    function testRevert_removeBAppTokensWithEmptyTokenList() public {
        test_RegisterBApp();
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp1.proposeBAppTokensRemoval(new address[](0));
    }

    function testRevert_updateBAppTokensWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
        bApp1.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
    }

    function testRevert_removeBAppTokensWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
        bApp1.proposeBAppTokensRemoval(tokensInput);
    }

    function testRevert_updateBAppTokensWithTokenNotSet() public {
        test_RegisterBApp();
        vm.prank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock2), 100);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
        bApp1.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
    }

    function testRevert_removeBAppTokensWithTokenNotSet() public {
        test_RegisterBApp();
        vm.prank(USER1);
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(erc20mock2), 100);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
        bApp1.proposeBAppTokensRemoval(tokensInput);
    }

    function test_proposeBAppTokensUpdate() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        uint32[] memory sharedRiskLevelsOld = new uint32[](1);
        sharedRiskLevelsOld[0] = 102;
        bApp1.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        (address[] memory tokens, uint32[] memory sharedRiskLevels, uint32 requestTime) =
            proxiedManager.getTokenUpdateRequest(address(bApp1));
        checkBAppInfo(tokensInput, sharedRiskLevelsOld);
        assertEq(tokens, tokensInput, "Token update request tokens");
        assertEq(sharedRiskLevels[0], sharedRiskLevelInput[0], "Token update request sharedRiskLevel");
        assertEq(requestTime, block.timestamp, "Token update request time");
        vm.stopPrank();
    }

    function test_proposeBAppTokensUpdateETH() public {
        test_RegisterBAppWithETH();
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 500);
        uint32[] memory sharedRiskLevelsOld = new uint32[](1);
        sharedRiskLevelsOld[0] = 100;
        bApp1.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        (address[] memory tokens, uint32[] memory sharedRiskLevels, uint32 requestTime) =
            proxiedManager.getTokenUpdateRequest(address(bApp1));
        checkBAppInfo(tokensInput, sharedRiskLevelsOld);
        assertEq(tokens, tokensInput, "Token update request tokens");
        assertEq(sharedRiskLevels[0], sharedRiskLevelInput[0], "Token update request sharedRiskLevel");
        assertEq(requestTime, block.timestamp, "Token update request time");
        vm.stopPrank();
    }

    function test_proposeBAppTokensRemoval() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        uint32[] memory sharedRiskLevelsOld = new uint32[](1);
        sharedRiskLevelsOld[0] = 102;
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 100);
        bApp1.proposeBAppTokensRemoval(tokensInput);
        (address[] memory tokens, uint32 requestTime) = proxiedManager.getTokenRemovalRequest(address(bApp1));
        assertEq(tokens[0], tokensInput[0], "Token removal request tokens");
        checkBAppInfo(tokensInput, sharedRiskLevelsOld);
        assertEq(requestTime, block.timestamp, "Token removal request time");
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensUpdateTimelockNotElapsed() public {
        test_proposeBAppTokensUpdate();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
        bApp1.finalizeBAppTokensUpdate();
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensRemovalTimelockNotElapsed() public {
        test_proposeBAppTokensRemoval();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
        bApp1.finalizeBAppTokensRemoval();
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensUpdateNoPendingRequest() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingTokenUpdate.selector));
        bApp1.finalizeBAppTokensUpdate();
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensRemovalNoPendingRequest() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingTokenRemoval.selector));
        bApp1.finalizeBAppTokensRemoval();
        vm.stopPrank();
    }

    function test_finalizeBAppTokensUpdateOneToken() public {
        test_proposeBAppTokensUpdate();
        vm.startPrank(USER1);
        vm.warp(block.timestamp + proxiedManager.TOKEN_UPDATE_TIMELOCK_PERIOD() + 1 minutes);
        bApp1.finalizeBAppTokensUpdate();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        (address[] memory tokens, uint32[] memory sharedRiskLevels, uint32 requestTime) =
            proxiedManager.getTokenUpdateRequest(address(bApp1));
        assertEq(requestTime, 0, "Token update request time");
        assertEq(tokens.length, 0, "Token update request length");
        assertEq(sharedRiskLevels.length, 0, "Token update request length");
        vm.stopPrank();
    }


    function test_finalizeBAppTokensUpdateOneTokenETH() public {
        test_proposeBAppTokensUpdateETH();
        vm.startPrank(USER1);
        vm.warp(block.timestamp + proxiedManager.TOKEN_UPDATE_TIMELOCK_PERIOD() + 1 minutes);
        bApp1.finalizeBAppTokensUpdate();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 500);
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        (address[] memory tokens, uint32[] memory sharedRiskLevels, uint32 requestTime) =
            proxiedManager.getTokenUpdateRequest(address(bApp1));
        assertEq(requestTime, 0, "Token update request time");
        assertEq(tokens.length, 0, "Token update request length");
        assertEq(sharedRiskLevels.length, 0, "Token update request length");
        vm.stopPrank();
    }

    function test_finalizeBAppTokensRemovalOneToken() public {
        test_proposeBAppTokensRemoval();
        vm.startPrank(USER1);
        vm.warp(block.timestamp + proxiedManager.TOKEN_REMOVAL_TIMELOCK_PERIOD() + 1 minutes);
        bApp1.finalizeBAppTokensRemoval();
        (address[] memory tokens, uint32 requestTime) = proxiedManager.getTokenRemovalRequest(address(bApp1));
        assertEq(requestTime, 0, "Token update request time");
        assertEq(tokens.length, 0, "Token update request length");
        (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(address(bApp1), address(erc20mock));
        assertEq(sharedRiskLevel, 0, "Token update request sharedRiskLevel");
        assertEq(isSet, false, "Token should be not set");
        vm.stopPrank();
    }

    function testRevert_callBAppWithNoManager() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 1000);
        vm.expectRevert(abi.encodeWithSelector(BasedAppCore.UnauthorizedCaller.selector));
        bApp1.optInToBApp(0, tokensInput, sharedRiskLevelInput, "");
        vm.stopPrank();
    }
}
