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

    string[] metadataURIs = ["http://metadata.com", "http://metadata2.com", "http://metadata3.com"];

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

    function checkTokenUpdateRequest(address bApp, address[] memory tokensInput, uint32[] memory sharedRiskLevelInput)
        internal
        view
    {
        (address[] memory tokens, uint32[] memory sharedRiskLevels, uint256 requestTime) =
            proxiedManager.getTokenUpdateRequest(bApp);
        assertEq(tokens, tokensInput, "Token update request tokens");
        assertEq(sharedRiskLevels[0], sharedRiskLevelInput[0], "Token update request sharedRiskLevel");
        assertEq(requestTime, block.timestamp, "Token update request time");
    }

    function checkTokenRemovalRequest(address bApp, address[] memory tokensInput) internal view {
        (address[] memory tokens, uint256 requestTime) = proxiedManager.getTokenRemovalRequest(bApp);
        assertEq(tokens, tokensInput, "Token removal request tokens");
        assertEq(requestTime, block.timestamp, "Token removal request time");
    }

    function checkTokenUpdateRequestCompleted(address bApp, uint32 newSharedRiskLevel) internal view {
        (address[] memory tokens, uint32[] memory requestSharedRiskLevel, uint32 requestTime) =
            proxiedManager.getTokenUpdateRequest(address(bApp));
        assertEq(requestTime, 0, "Token update request time");
        assertEq(tokens.length, 0, "Token update request length");
        assertEq(requestSharedRiskLevel.length, 0, "Risk Level update request length");
        (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(address(bApp), address(erc20mock));
        assertEq(sharedRiskLevel, newSharedRiskLevel, "Token update request sharedRiskLevel");
        assertEq(isSet, true, "Token should be not set");
    }

    function checkTokenUpdateRequestCompletedETH(address bApp, uint32 newSharedRiskLevel) internal view {
        (address[] memory tokens, uint32[] memory requestSharedRiskLevel, uint32 requestTime) =
            proxiedManager.getTokenUpdateRequest(address(bApp));
        assertEq(requestTime, 0, "Token update request time");
        assertEq(tokens.length, 0, "Token update request length");
        assertEq(requestSharedRiskLevel.length, 0, "Risk Level update request length");
        (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(address(bApp), address(ETH_ADDRESS));
        assertEq(sharedRiskLevel, newSharedRiskLevel, "Token update request sharedRiskLevel");
        assertEq(isSet, true, "Token should be not set");
    }

    function checkTokenRemovalRequestCompleted(address bApp) internal view {
        (address[] memory tokens, uint32 requestTime) = proxiedManager.getTokenRemovalRequest(address(bApp));
        assertEq(requestTime, 0, "Token removal request time");
        assertEq(tokens.length, 0, "Token removal request length");
        (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(address(bApp), address(erc20mock));
        assertEq(sharedRiskLevel, 0, "Token removal request sharedRiskLevel");
        assertEq(isSet, false, "Token should be not set");
    }

    function test_RegisterBApp() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, metadataURIs[i]);
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function test_RegisterBAppWithEOA() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        vm.prank(USER1);
        proxiedManager.registerBApp(tokensInput, sharedRiskLevelInput, metadataURIs[0]);
        checkBAppInfo(tokensInput, sharedRiskLevelInput, USER1, proxiedManager);
    }

    function test_RegisterBAppWith2Tokens() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createTwoTokenAndRiskInputs();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, "");
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function test_RegisterBAppWithETH() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, "");
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function test_RegisterBAppWithNoTokens() public {
        address[] memory tokensInput = new address[](0);
        uint32[] memory sharedRiskLevelInput = new uint32[](0);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, "");
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function test_RegisterBAppWithFiveTokens() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createFiveTokenAndRiskInputs();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, "");
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function test_RegisterBAppWithETHAndErc20() public {
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = ETH_ADDRESS;
        tokensInput[1] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 102;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, "");
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
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

    function test_RegisterBAppFromNonBAppContract() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        nonCompliantBApp.registerBApp(tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput, address(nonCompliantBApp), proxiedManager);
        vm.stopPrank();
    }

    function test_isBapp() public {
        vm.prank(USER1);
        bool success = proxiedManager._isBApp(address(bApp1));
        assertEq(success, true, "isBApp");
    }

    function test_UpdateBAppWithNewTokens() public {
        test_RegisterBApp();
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock2);
        tokensInput[1] = address(ETH_ADDRESS);
        uint32[] memory sharedRiskLevelInput = new uint32[](2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 103;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].addTokensToBApp(tokensInput, sharedRiskLevelInput);
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRevert_UpdateBAppWithNotMatchingLengths() public {
        test_RegisterBApp();
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock2);
        tokensInput[1] = address(ETH_ADDRESS);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.LengthsNotMatching.selector));
            bApps[i].addTokensToBApp(tokensInput, sharedRiskLevelInput);
        }
    }

    function testRevert_UpdateBAppWithAlreadyPresentTokensRevert() public {
        test_RegisterBApp();
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(ETH_ADDRESS);
        uint32[] memory sharedRiskLevelInput = new uint32[](2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 103;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.TokenAlreadyAddedToBApp.selector, address(erc20mock)));
            bApps[i].addTokensToBApp(tokensInput, sharedRiskLevelInput);
        }
    }

    function testRevert_AddTokensToOwnableBAppWithNonOwner() public {
        test_RegisterBApp();
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        bApp1.addTokensToBApp(new address[](0), new uint32[](0));
    }

    function testRevert_AddTokensToBAppWithEmptyTokenList() public {
        test_RegisterBApp();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
            bApps[i].addTokensToBApp(new address[](0), new uint32[](0));
        }
    }

    function testRevert_AddTokensToBAppWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
            bApps[i].addTokensToBApp(tokensInput, sharedRiskLevelInput);
        }
    }

    function test_UpdateBAppMetadata() public {
        test_RegisterBApp();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, false, false, false);
            emit IBasedAppManager.BAppMetadataURIUpdated(address(bApps[i]), metadataURI);
            vm.prank(USER1);
            bApps[i].updateBAppMetadataURI(metadataURI);
        }
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
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
            bApps[i].updateBAppMetadataURI(metadataURI);
        }
    }

    function testRevert_AddTokensWithNonRegisteredBApp() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock2), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
            bApps[i].addTokensToBApp(tokensInput, sharedRiskLevelInput);
        }
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
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
            bApps[i].proposeBAppTokensUpdate(new address[](0), new uint32[](0));
        }
    }

    function testRevert_removeBAppTokensWithEmptyTokenList() public {
        test_RegisterBApp();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.EmptyTokenList.selector));
            bApps[i].proposeBAppTokensRemoval(new address[](0));
        }
    }

    function testRevert_updateBAppTokensWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
            bApps[i].proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        }
    }

    function testRevert_removeBAppTokensWithTokenZeroAddress() public {
        test_RegisterBApp();
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(0x00), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.ZeroAddressNotAllowed.selector));
            bApps[i].proposeBAppTokensRemoval(tokensInput);
        }
    }

    function testRevert_updateBAppTokensWithTokenNotSet() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock2), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
            bApps[i].proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        }
    }

    function testRevert_removeBAppTokensWithTokenNotSet() public {
        test_RegisterBApp();
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(erc20mock2), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.TokenNoTSupportedByBApp.selector, address(erc20mock2)));
            bApps[i].proposeBAppTokensRemoval(tokensInput);
        }
    }

    function testRevert_proposeBAppTokensUpdateBAppNotRegistered() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
            bApps[i].proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        }
    }

    function testRevert_proposeBAppTokensRemovalBAppNotRegistered() public {
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
            bApps[i].proposeBAppTokensRemoval(tokensInput);
        }
    }

    function testRevert_finalizeBAppTokensUpdateBAppNotRegistered() public {
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
            bApps[i].finalizeBAppTokensUpdate();
        }
    }

    function testRevert_finalizeBAppTokensRemovalBAppNotRegistered() public {
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.BAppNotRegistered.selector));
            bApps[i].finalizeBAppTokensRemoval();
        }
    }

    function test_proposeBAppTokensUpdate() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        uint32[] memory sharedRiskLevelsOld = new uint32[](1);
        sharedRiskLevelsOld[0] = 102;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
            checkBAppInfo(tokensInput, sharedRiskLevelsOld, address(bApps[i]), proxiedManager);
            checkTokenUpdateRequest(address(bApps[i]), tokensInput, sharedRiskLevelInput);
        }
    }

    function testRevert_proposeBAppTokenUpdateWithSameRiskLevel() public {
        test_RegisterBApp();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.SharedRiskLevelAlreadySet.selector));
            bApps[i].proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
        }
    }

    function test_proposeBAppTokensUpdateETH() public {
        test_RegisterBAppWithETH();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 500);
        uint32[] memory sharedRiskLevelsOld = new uint32[](1);
        sharedRiskLevelsOld[0] = 100;
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].proposeBAppTokensUpdate(tokensInput, sharedRiskLevelInput);
            checkBAppInfo(tokensInput, sharedRiskLevelsOld, address(bApps[i]), proxiedManager);
            checkTokenUpdateRequest(address(bApps[i]), tokensInput, sharedRiskLevelInput);
        }
    }

    function test_proposeBAppTokensRemoval() public {
        test_RegisterBApp();
        uint32[] memory sharedRiskLevelsOld = new uint32[](1);
        sharedRiskLevelsOld[0] = 102;
        (address[] memory tokensInput,) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].proposeBAppTokensRemoval(tokensInput);
            checkBAppInfo(tokensInput, sharedRiskLevelsOld, address(bApps[i]), proxiedManager);
            checkTokenRemovalRequest(address(bApps[i]), tokensInput);
        }
    }

    function test_proposeBAppTokensRemovalFiveTokens() public {
        test_RegisterBAppWithFiveTokens();
        (address[] memory tokensInput, uint32[] memory sharedRiskLevels) = createFiveTokenAndRiskInputs();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].proposeBAppTokensRemoval(tokensInput);
            checkBAppInfo(tokensInput, sharedRiskLevels, address(bApps[i]), proxiedManager);
            checkTokenRemovalRequest(address(bApps[i]), tokensInput);
        }
    }

    function testRevert_finalizeBAppTokensUpdateTimelockNotElapsed() public {
        test_proposeBAppTokensUpdate();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
            bApps[i].finalizeBAppTokensUpdate();
        }
    }

    function testRevert_finalizeBAppTokensRemovalTimelockNotElapsed() public {
        test_proposeBAppTokensRemoval();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.TimelockNotElapsed.selector));
            bApps[i].finalizeBAppTokensRemoval();
        }
    }

    function testRevert_finalizeBAppTokensUpdateNoPendingRequest() public {
        test_RegisterBApp();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingTokenUpdate.selector));
            bApps[i].finalizeBAppTokensUpdate();
        }
    }

    function testRevert_finalizeBAppTokensRemovalNoPendingRequest() public {
        test_RegisterBApp();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IStorage.NoPendingTokenRemoval.selector));
            bApps[i].finalizeBAppTokensRemoval();
        }
    }

    function test_finalizeBAppTokensUpdateOneToken() public {
        test_proposeBAppTokensUpdate();
        vm.warp(block.timestamp + proxiedManager.TOKEN_UPDATE_TIMELOCK_PERIOD() + 1 minutes);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 500);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].finalizeBAppTokensUpdate();
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
            checkTokenUpdateRequestCompleted(address(bApps[i]), sharedRiskLevelInput[0]);
        }
    }

    function test_finalizeBAppTokensUpdateOneTokenETH() public {
        test_proposeBAppTokensUpdateETH();
        vm.warp(block.timestamp + proxiedManager.TOKEN_UPDATE_TIMELOCK_PERIOD() + 1 minutes);
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelsInput) =
            createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 500);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].finalizeBAppTokensUpdate();
            checkBAppInfo(tokensInput, sharedRiskLevelsInput, address(bApps[i]), proxiedManager);
            checkTokenUpdateRequestCompletedETH(address(bApps[i]), sharedRiskLevelsInput[0]);
        }
    }

    function test_finalizeBAppTokensRemovalOneToken() public {
        test_proposeBAppTokensRemoval();
        vm.warp(block.timestamp + proxiedManager.TOKEN_REMOVAL_TIMELOCK_PERIOD() + 1 minutes);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].finalizeBAppTokensRemoval();
            checkBAppInfo(new address[](0), new uint32[](0), address(bApps[i]), proxiedManager);
            checkTokenRemovalRequestCompleted(address(bApps[i]));
        }
    }

    function test_finalizeBAppTokensRemovalFiveTokens() public {
        test_proposeBAppTokensRemovalFiveTokens();
        vm.warp(block.timestamp + proxiedManager.TOKEN_REMOVAL_TIMELOCK_PERIOD() + 1 minutes);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].finalizeBAppTokensRemoval();
            checkBAppInfo(new address[](0), new uint32[](0), address(bApps[i]), proxiedManager);
            checkTokenRemovalRequestCompleted(address(bApps[i]));
        }
    }

    function testRevert_callBAppWithNoManager() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) =
            createSingleTokenAndSingleRiskLevel(address(erc20mock), 1000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector));
            bApps[i].optInToBApp(0, tokensInput, sharedRiskLevelInput, "");
        }
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
