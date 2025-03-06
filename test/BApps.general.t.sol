// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IBasedApp} from "@ssv/src/interfaces/IBasedApp.sol";

import {BasedAppManagerSetupTest, IStorage, IBasedAppManager} from "@ssv/test/BAppManager.setup.t.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {TestUtils} from "@ssv/test/Utils.t.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract BasedAppsTest is BasedAppManagerSetupTest, TestUtils {
    string metadataURI = "http://metadata.com";
    string metadataURI2 = "http://metadata2.com";
    string metadataURI3 = "http://metadata3.com";

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

    function checkTokenUpdateRequest(address bApp, address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) internal {
        (address[] memory tokens, uint32[] memory sharedRiskLevels, uint256 requestTime) =
            proxiedManager.getTokenUpdateRequest(bApp);
        assertEq(tokens, tokensInput, "Token update request tokens");
        assertEq(sharedRiskLevels[0], sharedRiskLevelInput[0], "Token update request sharedRiskLevel");
        assertEq(requestTime, block.timestamp, "Token update request time");
    }

    function checkTokenRemovalRequest(address bApp, address[] memory tokensInput) internal {
        (address[] memory tokens, uint256 requestTime) = proxiedManager.getTokenRemovalRequest(bApp);
        assertEq(tokens, tokensInput, "Token removal request tokens");
        assertEq(requestTime, block.timestamp, "Token removal request time");
    }

    function checkTokenUpdateRequestCompleted(address bApp, uint32 newSharedRiskLevel) internal {
        (address[] memory tokens, uint32[] memory requestSharedRiskLevel, uint32 requestTime) =
            proxiedManager.getTokenUpdateRequest(address(bApp));
        assertEq(requestTime, 0, "Token update request time");
        assertEq(tokens.length, 0, "Token update request length");
        assertEq(requestSharedRiskLevel.length, 0, "Risk Level update request length");
        (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(address(bApp), address(erc20mock));
        assertEq(sharedRiskLevel, newSharedRiskLevel, "Token update request sharedRiskLevel");
        assertEq(isSet, true, "Token should be not set");
    }

    function checkTokenUpdateRequestCompletedETH(address bApp, uint32 newSharedRiskLevel) internal {
        (address[] memory tokens, uint32[] memory requestSharedRiskLevel, uint32 requestTime) =
            proxiedManager.getTokenUpdateRequest(address(bApp));
        assertEq(requestTime, 0, "Token update request time");
        assertEq(tokens.length, 0, "Token update request length");
        assertEq(requestSharedRiskLevel.length, 0, "Risk Level update request length");
        (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(address(bApp), address(ETH_ADDRESS));
        assertEq(sharedRiskLevel, newSharedRiskLevel, "Token update request sharedRiskLevel");
        assertEq(isSet, true, "Token should be not set");
    }

    function checkTokenRemovalRequestCompleted(address bApp) internal {
        (address[] memory tokens, uint32 requestTime) = proxiedManager.getTokenRemovalRequest(address(bApp));
        assertEq(requestTime, 0, "Token removal request time");
        assertEq(tokens.length, 0, "Token removal request length");
        (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(address(bApp), address(erc20mock));
        assertEq(sharedRiskLevel, 0, "Token removal request sharedRiskLevel");
        assertEq(isSet, false, "Token should be not set");
    }

    function test_RegisterBApp() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, metadataURI);
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, metadataURI2);
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, metadataURI3);
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
        checkBAppInfo(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function test_RegisterBAppWith2Tokens() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createTwoTokenAndRiskInputs();
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, "");
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
        vm.stopPrank();
    }

    function test_RegisterBAppWithETH() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 100);
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, "");
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
        vm.stopPrank();
    }

    function test_RegisterBAppWithNoTokens() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](0);
        uint32[] memory sharedRiskLevelInput = new uint32[](0);
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "http://metadata.com");
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, "");
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function test_RegisterBAppWithFiveTokens() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createFiveTokenAndRiskInputs();
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, "");
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
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
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, "");
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
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
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppAlreadyRegistered.selector));
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppAlreadyRegistered.selector));
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.stopPrank();
    }

    // TODO double check EOA
    // function test_RegisterBAppFromEOA() public {
    //     vm.startPrank(USER1);
    //     address[] memory tokensInput = new address[](1);
    //     tokensInput[0] = address(erc20mock);
    //     uint32[] memory sharedRiskLevelInput = new uint32[](1);
    //     sharedRiskLevelInput[0] = 102;
    //     proxiedManager.registerBApp(tokensInput, sharedRiskLevelInput, "");
    //     vm.stopPrank();
    // }

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
        bApp2.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        bApp3.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
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
        vm.expectRevert(abi.encodeWithSelector(IStorage.LengthsNotMatching.selector));
        bApp2.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.LengthsNotMatching.selector));
        bApp3.addTokensToBApp(tokensInput, sharedRiskLevelInput);
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
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenAlreadyAddedToBApp.selector, address(erc20mock)));
        bApp2.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.TokenAlreadyAddedToBApp.selector, address(erc20mock)));
        bApp3.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function testRevert_AddTokensToBAppWithNonOwner() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        bApp1.addTokensToBApp(new address[](0), new uint32[](0));
    }

    function testRevert_AddTokensToBAppWithEmptyTokenList() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp1.addTokensToBApp(new address[](0), new uint32[](0));
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp2.addTokensToBApp(new address[](0), new uint32[](0));
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp3.addTokensToBApp(new address[](0), new uint32[](0));
    }

    function testRevert_AddTokensToBAppWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
        bApp1.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
        bApp2.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
        bApp3.addTokensToBApp(tokensInput, sharedRiskLevelInput);
    }

    function test_UpdateBAppMetadata() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, false, false, false);
            emit IBasedAppManager.BAppMetadataURIUpdated(address(bApps[i]), metadataURI);
            bApps[i].updateBAppMetadataURI(metadataURI);
        }
        vm.stopPrank();
    }

    function testRevert_UpdateBAppMetadataWithWrongOwner() public {
        test_RegisterBApp();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        bApp1.updateBAppMetadataURI(metadataURI);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, address(ATTACKER), bApp3.MANAGER_ROLE()
            )
        );
        bApp3.updateBAppMetadataURI(metadataURI);
        vm.stopPrank();
    }

    function testRevert_UpdateBAppMetadataWithNonRegisteredBApp() public {
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
            bApps[i].updateBAppMetadataURI(metadataURI);
        }
        vm.stopPrank();
    }

    function testRevert_AddTokensWithNonRegisteredBApp() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock2), 100);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp1.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp2.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp3.addTokensToBApp(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function testRevert_proposeBAppTokensUpdateWithNonOwner() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        bApp1.proposeBAppTokensUpdate(new address[](0), new uint32[](0));
    }

    function testRevert_finalizeBAppTokensUpdateWithNonOwner() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
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
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp1.proposeBAppTokensUpdate(new address[](0), new uint32[](0));
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp2.proposeBAppTokensUpdate(new address[](0), new uint32[](0));
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp3.proposeBAppTokensUpdate(new address[](0), new uint32[](0));
    }

    function testRevert_removeBAppTokensWithEmptyTokenList() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp1.proposeBAppTokensRemoval(new address[](0));
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp2.proposeBAppTokensRemoval(new address[](0));
        vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
        bApp3.proposeBAppTokensRemoval(new address[](0));
    }

    function testRevert_updateBAppTokensWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
        bApp1.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
        bApp2.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
        bApp3.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
    }

    function testRevert_removeBAppTokensWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
            vm.prank(USER1);
            bApps[i].proposeBAppTokensRemoval(tokensInput);
        }
    }

    function testRevert_updateBAppTokensWithTokenNotSet() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock2), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
            vm.prank(USER1);
            bApps[i].proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        }
    }

    function testRevert_removeBAppTokensWithTokenNotSet() public {
        test_RegisterBApp();
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(erc20mock2), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
            vm.prank(USER1);
            bApps[i].proposeBAppTokensRemoval(tokensInput);
        }
    }

    function testRevert_proposeBAppTokensUpdateBAppNotRegistered() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp1.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp2.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp3.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        vm.stopPrank();
    }

    function testRevert_proposeBAppTokensRemovalBAppNotRegistered() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp1.proposeBAppTokensRemoval(tokensInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp2.proposeBAppTokensRemoval(tokensInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp3.proposeBAppTokensRemoval(tokensInput);
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensUpdateBAppNotRegistered() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp1.finalizeBAppTokensUpdate();
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp2.finalizeBAppTokensUpdate();
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp3.finalizeBAppTokensUpdate();
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensRemovalBAppNotRegistered() public {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp1.finalizeBAppTokensRemoval();
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp2.finalizeBAppTokensRemoval();
        vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
        bApp3.finalizeBAppTokensRemoval();
        vm.stopPrank();
    }

    function test_proposeBAppTokensUpdate() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        uint32[] memory sharedRiskLevelsOld = new uint32[](1);
        sharedRiskLevelsOld[0] = 102;
        bApp1.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        bApp2.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        bApp3.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelsOld, address(bApps[i]), proxiedManager);
            checkTokenUpdateRequest(address(bApps[i]), tokensInput, sharedRiskLevelInput);
        }
        vm.stopPrank();
    }

    function testRevert_proposeBAppTokenUpdateWithSameRiskLevel() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        vm.expectRevert(abi.encodeWithSelector(IStorage.SharedRiskLevelAlreadySet.selector));
        bApp1.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.SharedRiskLevelAlreadySet.selector));
        bApp2.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        vm.expectRevert(abi.encodeWithSelector(IStorage.SharedRiskLevelAlreadySet.selector));
        bApp3.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
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
        bApp2.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        bApp3.proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelsOld, address(bApps[i]), proxiedManager);
            checkTokenUpdateRequest(address(bApps[i]), tokensInput, sharedRiskLevelInput);
        }
        vm.stopPrank();
    }

    function test_proposeBAppTokensRemoval() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        uint32[] memory sharedRiskLevelsOld = new uint32[](1);
        sharedRiskLevelsOld[0] = 102;
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 100);
        bApp1.proposeBAppTokensRemoval(tokensInput);
        bApp2.proposeBAppTokensRemoval(tokensInput);
        bApp3.proposeBAppTokensRemoval(tokensInput);
        for (uint256 i = 0; i < bApps.length; i++) {
            checkBAppInfo(tokensInput, sharedRiskLevelsOld, address(bApps[i]), proxiedManager);
            checkTokenRemovalRequest(address(bApps[i]), tokensInput);
        }
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensUpdateTimelockNotElapsed() public {
        test_proposeBAppTokensUpdate();
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
            bApps[i].finalizeBAppTokensUpdate();
        }
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensRemovalTimelockNotElapsed() public {
        test_proposeBAppTokensRemoval();
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
            bApps[i].finalizeBAppTokensRemoval();
        }
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensUpdateNoPendingRequest() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingTokenUpdate.selector));
            bApps[i].finalizeBAppTokensUpdate();
        }
        vm.stopPrank();
    }

    function testRevert_finalizeBAppTokensRemovalNoPendingRequest() public {
        test_RegisterBApp();
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingTokenRemoval.selector));
            bApps[i].finalizeBAppTokensRemoval();
        }
        vm.stopPrank();
    }

    function test_finalizeBAppTokensUpdateOneToken() public {
        test_proposeBAppTokensUpdate();
        vm.startPrank(USER1);
        vm.warp(block.timestamp + proxiedManager.TOKEN_UPDATE_TIMELOCK_PERIOD() + 1 minutes);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        for (uint256 i = 0; i < bApps.length; i++) {
            bApps[i].finalizeBAppTokensUpdate();
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
            checkTokenUpdateRequestCompleted(address(bApps[i]), sharedRiskLevelInput[0]);
        }
        vm.stopPrank();
    }

    function test_finalizeBAppTokensUpdateOneTokenETH() public {
        test_proposeBAppTokensUpdateETH();
        vm.startPrank(USER1);
        vm.warp(block.timestamp + proxiedManager.TOKEN_UPDATE_TIMELOCK_PERIOD() + 1 minutes);

        (address[] memory tokensInput, uint32[] memory sharedRiskLevelsInput) =
            createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 500);
        for (uint256 i = 0; i < bApps.length; i++) {
            bApps[i].finalizeBAppTokensUpdate();
            checkBAppInfo(tokensInput, sharedRiskLevelsInput, address(bApps[i]), proxiedManager);
            checkTokenUpdateRequestCompletedETH(address(bApps[i]), sharedRiskLevelsInput[0]);
        }
        vm.stopPrank();
    }

    function test_finalizeBAppTokensRemovalOneToken() public {
        test_proposeBAppTokensRemoval();
        vm.startPrank(USER1);
        vm.warp(block.timestamp + proxiedManager.TOKEN_REMOVAL_TIMELOCK_PERIOD() + 1 minutes);
        for (uint256 i = 0; i < bApps.length; i++) {
            bApps[i].finalizeBAppTokensRemoval();
            checkBAppInfo(new address[](0), new uint32[](0), address(bApps[i]), proxiedManager);
            checkTokenRemovalRequestCompleted(address(bApps[i]));
        }
        vm.stopPrank();
    }

    function testRevert_callBAppWithNoManager() public {
        vm.startPrank(USER1);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 1000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectRevert(abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector));
            bApps[i].optInToBApp(0, tokensInput, sharedRiskLevelInput, "");
        }
        vm.stopPrank();
    }

    function test_supportInterface() public {
        vm.startPrank(USER1);
        for (uint256 i = 0; i < bApps.length; i++) {
            bool success = bApps[i].supportsInterface(type(IBasedApp).interfaceId);
            assertEq(success, true, "supportsInterface based app");
            bool failed = bApps[i].supportsInterface(type(IBasedAppManager).interfaceId);
            assertEq(failed, false, "does not supportsInterface based app manager");
            bool failed2 = bApps[i].supportsInterface(type(IERC20).interfaceId);
            assertEq(failed2, false, "does not supportsInterface");
            bool success2 = bApps[i].supportsInterface(type(IERC165).interfaceId);
            assertEq(success2, true, "does supportsInterface of IERC165");
        }
        vm.stopPrank();
    }
}
