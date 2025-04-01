// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {BasedAppManagerSetupTest, IBasedAppManager, IBasedApp} from "@ssv/test/BAppManager.setup.t.sol";

import {ICore} from "@ssv/src/interfaces/ICore.sol";

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

    function createTwoTokenAndRiskInputs() private view returns (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) {
        tokensInput = new address[](2);
        sharedRiskLevelInput = new uint32[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 103;
    }

    function createFiveTokenAndRiskInputs() private view returns (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) {
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

    function testRegisterBApp() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit(true, true, true, true);
            emit IBasedAppManager.BAppRegistered(address(bApps[i]), tokensInput, sharedRiskLevelInput, metadataURIs[i]);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, metadataURIs[i]);
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithEOA() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 102);
        vm.prank(USER1);
        proxiedManager.registerBApp(tokensInput, sharedRiskLevelInput, metadataURIs[0]);
        checkBAppInfo(tokensInput, sharedRiskLevelInput, USER1, proxiedManager);
    }

    function testRegisterBAppWith2Tokens() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createTwoTokenAndRiskInputs();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, "");
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithETH() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createSingleTokenAndSingleRiskLevel(ETH_ADDRESS, 100);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, "");
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithNoTokens() public {
        address[] memory tokensInput = new address[](0);
        uint32[] memory sharedRiskLevelInput = new uint32[](0);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, "");
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithFiveTokens() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createFiveTokenAndRiskInputs();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokensInput, sharedRiskLevelInput, "");
            checkBAppInfo(tokensInput, sharedRiskLevelInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithETHAndErc20() public {
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

    function testRevertRegisterBAppTwice() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        bApp1.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        bApp2.registerBApp(tokensInput, sharedRiskLevelInput, "");
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.expectRevert(abi.encodeWithSelector(ICore.BAppAlreadyRegistered.selector));
        bApp3.registerBApp(tokensInput, sharedRiskLevelInput, "");
        vm.stopPrank();
    }

    function testRegisterBAppFromNonBAppContract() public {
        vm.startPrank(USER1);
        address[] memory tokensInput = new address[](1);
        tokensInput[0] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = 102;
        nonCompliantBApp.registerBApp(tokensInput, sharedRiskLevelInput, "");
        checkBAppInfo(tokensInput, sharedRiskLevelInput, address(nonCompliantBApp), proxiedManager);
        vm.stopPrank();
    }

    // TODO
    // function testisBapp() public {
    //     vm.prank(USER1);
    //     bool success = CoreLib.isBApp(address(bApp1));
    //     assertEq(success, true, "isBApp");
    // }

    function testUpdateBAppMetadata() public {
        testRegisterBApp();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, false, false, false);
            emit IBasedAppManager.BAppMetadataURIUpdated(address(bApps[i]), metadataURI);
            vm.prank(USER1);
            bApps[i].updateBAppMetadataURI(metadataURI);
        }
    }

    function testRevertUpdateBAppMetadataWithWrongOwner() public {
        testRegisterBApp();
        vm.startPrank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        bApp1.updateBAppMetadataURI(metadataURI);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(ATTACKER), bApp3.MANAGER_ROLE()));
        bApp3.updateBAppMetadataURI(metadataURI);
        vm.stopPrank();
    }

    function testRevertUpdateBAppMetadataWithNonRegisteredBApp() public {
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(ICore.BAppNotRegistered.selector));
            bApps[i].updateBAppMetadataURI(metadataURI);
        }
    }

    function testRevertcallBAppWithNoManager() public {
        (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 1000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector));
            bApps[i].optInToBApp(0, tokensInput, sharedRiskLevelInput, "");
        }
    }

    function testsupportInterface() public {
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
