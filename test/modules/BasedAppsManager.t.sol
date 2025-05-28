// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { UtilsTest } from "@ssv/test/helpers/Utils.t.sol";
import { IBasedAppManager, IBasedApp } from "@ssv/test/helpers/Setup.t.sol";
import { IBasedAppManager } from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { ValidationLib } from "@ssv/src/core/libraries/ValidationLib.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";

contract BasedAppsManagerTest is UtilsTest {
    string public metadataURI = "http://metadata.com";
    string public metadataURI2 = "http://metadata2.com";
    string public metadataURI3 = "http://metadata3.com";

    string[] public metadataURIs = [
        "http://metadata.com",
        "http://metadata2.com",
        "http://metadata3.com",
        "http://metadata4.com"
    ];

    function createTwoTokenAndRiskInputs()
        private
        view
        returns (ICore.TokenConfig[] memory tokenConfigsInput)
    {
        address[] memory tokensInput = new address[](2);
        uint32[] memory sharedRiskLevelInput = new uint32[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 103;
        tokenConfigsInput = new ICore.TokenConfig[](2);
        for (uint256 i = 0; i < tokensInput.length; i++) {
            tokenConfigsInput[i] = ICore.TokenConfig({
                token: tokensInput[i],
                sharedRiskLevel: sharedRiskLevelInput[i]
            });
        }
    }

    function createTwoTokenAndRiskInputsWithTheSameToken()
        private
        view
        returns (ICore.TokenConfig[] memory tokenConfigsInput)
    {
        tokenConfigsInput = new ICore.TokenConfig[](2);
        address[] memory tokensInput = new address[](2);
        uint32[] memory sharedRiskLevelInput = new uint32[](2);
        tokensInput[0] = address(erc20mock);
        tokensInput[1] = address(erc20mock);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 103;
        for (uint256 i = 0; i < tokensInput.length; i++) {
            tokenConfigsInput[i] = ICore.TokenConfig({
                token: tokensInput[i],
                sharedRiskLevel: sharedRiskLevelInput[i]
            });
        }
    }

    function createFiveTokenAndRiskInputs()
        private
        view
        returns (ICore.TokenConfig[] memory tokenConfigsInput)
    {
        address[] memory tokensInput = new address[](5);
        uint32[] memory sharedRiskLevelInput = new uint32[](5);
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
        tokenConfigsInput = new ICore.TokenConfig[](5);
        for (uint256 i = 0; i < tokensInput.length; i++) {
            tokenConfigsInput[i] = ICore.TokenConfig({
                token: tokensInput[i],
                sharedRiskLevel: sharedRiskLevelInput[i]
            });
        }
    }

    function testRegisterBApp() public {
        ICore.TokenConfig[] memory tokenConfigsInput = createSingleTokenConfig(
            address(erc20mock),
            102
        );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit(true, true, true, true);
            emit IBasedAppManager.BAppRegistered(
                address(bApps[i]),
                tokenConfigsInput,
                metadataURIs[i]
            );
            bApps[i].registerBApp(tokenConfigsInput, metadataURIs[i]);
            checkBAppInfo(tokenConfigsInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithEOA() public {
        ICore.TokenConfig[] memory tokenConfigsInput = createSingleTokenConfig(
            address(erc20mock),
            102
        );
        vm.prank(USER1);
        proxiedManager.registerBApp(tokenConfigsInput, metadataURIs[0]);
        checkBAppInfo(tokenConfigsInput, USER1, proxiedManager);
    }

    function testRegisterBAppWithEOAWithEth() public {
        ICore.TokenConfig[] memory tokenConfigsInput = createSingleTokenConfig(
            ETH_ADDRESS,
            102
        );
        vm.prank(USER1);
        proxiedManager.registerBApp(tokenConfigsInput, metadataURIs[0]);
        checkBAppInfo(tokenConfigsInput, USER1, proxiedManager);
    }

    function testRegisterBAppWith2Tokens() public {
        ICore.TokenConfig[]
            memory tokenConfigsInput = createTwoTokenAndRiskInputs();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokenConfigsInput, "");
            checkBAppInfo(tokenConfigsInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithETH() public {
        ICore.TokenConfig[] memory tokenConfigsInput = createSingleTokenConfig(
            ETH_ADDRESS,
            100
        );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokenConfigsInput, "");
            checkBAppInfo(tokenConfigsInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithNoTokens() public {
        ICore.TokenConfig[] memory tokenConfigsInput = new ICore.TokenConfig[](
            0
        );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokenConfigsInput, "");
            checkBAppInfo(tokenConfigsInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithFiveTokens() public {
        ICore.TokenConfig[]
            memory tokenConfigsInput = createFiveTokenAndRiskInputs();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokenConfigsInput, "");
            checkBAppInfo(tokenConfigsInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRegisterBAppWithETHAndErc20() public {
        address[] memory tokensInput = new address[](2);
        tokensInput[0] = ETH_ADDRESS;
        tokensInput[1] = address(erc20mock);
        uint32[] memory sharedRiskLevelInput = new uint32[](2);
        sharedRiskLevelInput[0] = 102;
        sharedRiskLevelInput[1] = 102;
        ICore.TokenConfig[] memory tokenConfigsInput = new ICore.TokenConfig[](
            tokensInput.length
        );
        for (uint256 i = 0; i < tokensInput.length; i++) {
            tokenConfigsInput[i] = ICore.TokenConfig({
                token: tokensInput[i],
                sharedRiskLevel: sharedRiskLevelInput[i]
            });
        }
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            bApps[i].registerBApp(tokenConfigsInput, "");
            checkBAppInfo(tokenConfigsInput, address(bApps[i]), proxiedManager);
        }
    }

    function testRevertRegisterBAppWithSameTokens() public {
        ICore.TokenConfig[]
            memory tokenConfigsInput = createTwoTokenAndRiskInputsWithTheSameToken();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IBasedAppManager.TokenAlreadyAddedToBApp.selector,
                    tokenConfigsInput[0].token
                )
            );
            bApps[i].registerBApp(tokenConfigsInput, "");
        }
    }

    function testRevertRegisterBAppWithTokenZero() public {
        ICore.TokenConfig[] memory tokenConfigsInput = createSingleTokenConfig(
            address(0),
            102
        );
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(
                    ValidationLib.ZeroAddressNotAllowed.selector
                )
            );
            bApps[i].registerBApp(tokenConfigsInput, metadataURIs[i]);
        }
    }

    function testRevertRegisterBAppTwice() public {
        vm.startPrank(USER1);
        ICore.TokenConfig[] memory tokenConfigsInput = createSingleTokenConfig(
            address(erc20mock),
            102
        );
        bApp1.registerBApp(tokenConfigsInput, "");
        vm.expectRevert(
            abi.encodeWithSelector(
                IBasedAppManager.BAppAlreadyRegistered.selector
            )
        );
        bApp1.registerBApp(tokenConfigsInput, "");
        bApp2.registerBApp(tokenConfigsInput, "");
        vm.expectRevert(
            abi.encodeWithSelector(
                IBasedAppManager.BAppAlreadyRegistered.selector
            )
        );
        bApp2.registerBApp(tokenConfigsInput, "");
        bApp3.registerBApp(tokenConfigsInput, "");
        vm.expectRevert(
            abi.encodeWithSelector(
                IBasedAppManager.BAppAlreadyRegistered.selector
            )
        );
        bApp3.registerBApp(tokenConfigsInput, "");
        vm.stopPrank();
    }

    function testRegisterBAppFromNonBAppContract() public {
        vm.startPrank(USER1);
        ICore.TokenConfig[] memory tokenConfigsInput = createSingleTokenConfig(
            address(erc20mock),
            102
        );
        nonCompliantBApp.registerBApp(tokenConfigsInput, "");
        checkBAppInfo(
            tokenConfigsInput,
            address(nonCompliantBApp),
            proxiedManager
        );
        vm.stopPrank();
    }

    function testUpdateBAppMetadata() public {
        testRegisterBApp();
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.expectEmit(true, false, false, false);
            emit IBasedAppManager.BAppMetadataURIUpdated(
                address(bApps[i]),
                metadataURI
            );
            vm.prank(USER1);
            bApps[i].updateBAppMetadataURI(metadataURI);
        }
    }

    function testRevertUpdateBAppMetadataWithWrongOwner() public {
        testRegisterBApp();
        vm.startPrank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        bApp1.updateBAppMetadataURI(metadataURI);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                address(ATTACKER),
                bApp3.MANAGER_ROLE()
            )
        );
        bApp3.updateBAppMetadataURI(metadataURI);
        vm.stopPrank();
    }

    function testRevertUpdateBAppMetadataWithNonRegisteredBApp() public {
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(
                    IBasedAppManager.BAppNotRegistered.selector
                )
            );
            bApps[i].updateBAppMetadataURI(metadataURI);
        }
    }

    function testRevertCallBAppWithNoManager() public {
        (
            address[] memory tokensInput,
            uint32[] memory sharedRiskLevelInput
        ) = createSingleTokenAndSingleRiskLevel(address(erc20mock), 1000);
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectRevert(
                abi.encodeWithSelector(IBasedApp.UnauthorizedCaller.selector)
            );
            bApps[i].optInToBApp(0, tokensInput, sharedRiskLevelInput, "");
        }
    }

    function testUpdateBAppTokens() public {
        testRegisterBApp();
        ICore.TokenConfig[]
            memory tokenConfigsInput = createTwoTokenAndRiskInputs();
        // ICore.TokenConfig[] memory tokenConfigs = new ICore.TokenConfig[](
        //     tokensInput.length
        // );
        // for (uint256 i = 0; i < tokensInput.length; i++) {
        //     tokenConfigs[i] = ICore.TokenConfig({
        //         token: tokensInput[i],
        //         sharedRiskLevel: sharedRiskLevelInput[i] + 1000
        //     });
        // }
        for (uint256 i = 0; i < bApps.length; i++) {
            vm.prank(USER1);
            vm.expectEmit(true, true, false, false);
            emit IBasedAppManager.BAppTokensUpdated(
                address(bApps[i]),
                tokenConfigsInput
            );
            bApps[i].updateBAppTokens(tokenConfigsInput);
            checkBAppUpdatedTokens(tokenConfigsInput, address(bApps[i]));
        }
    }
}
