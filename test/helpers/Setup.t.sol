// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { Test } from "forge-std/Test.sol";

import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { BasedAppMock } from "@ssv/test/mocks/MockBApp.sol";
import { BasedAppMock2 } from "@ssv/test/mocks/MockBApp2.sol";
import { BasedAppMock3 } from "@ssv/test/mocks/MockBAppAccessControl.sol";
import { BasedAppMock4 } from "@ssv/test/mocks/MockBApp4RejectEth.sol";
import { BasedAppsManager } from "@ssv/src/core/modules/BasedAppsManager.sol";
import {
    IBasedAppManager
} from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { IERC20, ERC20Mock } from "@ssv/test/mocks/MockERC20.sol";
import {
    IProtocolManager
} from "@ssv/src/core/interfaces/IProtocolManager.sol";
import {
    IStrategyManager
} from "@ssv/src/core/interfaces/IStrategyManager.sol";
import { NonCompliantBApp } from "@ssv/test/mocks/MockNonCompliantBApp.sol";
import { SSVBasedApps } from "@ssv/src/core/SSVBasedApps.sol";
import { ProtocolManager } from "@ssv/src/core/modules/ProtocolManager.sol";
import { StrategyManager } from "@ssv/src/core/modules/StrategyManager.sol";
import {
    ProtocolStorageLib
} from "@ssv/src/core/libraries/ProtocolStorageLib.sol";

import {
    WhitelistExample
} from "@ssv/src/middleware/examples/WhitelistExample.sol";
import { ECDSAVerifier } from "@ssv/src/middleware/examples/ECDSAVerifier.sol";
import { IBasedApp } from "@ssv/src/middleware/interfaces/IBasedApp.sol";

contract Setup is Test {
    // Main Contract
    SSVBasedApps public implementation;
    // Modules
    StrategyManager public strategyManagerMod;
    BasedAppsManager public basedAppsManagerMod;
    ProtocolManager public protocolManagerMod;

    // Proxies
    ERC1967Proxy public proxy; // UUPS Proxy contract
    SSVBasedApps public proxiedManager; // Proxy interface for interaction
    // BApps
    BasedAppMock public bApp1;
    BasedAppMock2 public bApp2;
    BasedAppMock3 public bApp3;
    BasedAppMock4 public bApp4;
    NonCompliantBApp public nonCompliantBApp;
    WhitelistExample public whitelistExample;
    ECDSAVerifier public ecdsaVerifierExample;
    // Tokens
    IERC20 public erc20mock;
    IERC20 public erc20mock2;
    IERC20 public erc20mock3;
    IERC20 public erc20mock4;
    IERC20 public erc20mock5;
    // EOAs
    address public immutable OWNER = makeAddr("Owner");
    address public immutable USER1 = makeAddr("User1");
    address public immutable USER2 = makeAddr("User2");
    address public immutable USER3 = makeAddr("User3");
    address public immutable NON_EXISTENT_BAPP = makeAddr("NonExistentBApp");
    address public immutable ATTACKER = makeAddr("Attacker");
    address public immutable RECEIVER = makeAddr("Receiver");
    address public immutable RECEIVER2 = makeAddr("Receiver2");
    // Strategies Ids
    uint32 public constant STRATEGY1 = 1;
    uint32 public constant STRATEGY2 = 2;
    uint32 public constant STRATEGY3 = 3;
    uint32 public constant STRATEGY4 = 4;
    // Fees
    uint32 public constant STRATEGY1_INITIAL_FEE = 5; // %0.05
    uint32 public constant STRATEGY2_INITIAL_FEE = 0; // %0.00
    uint32 public constant STRATEGY3_INITIAL_FEE = 1000; // %10.00
    uint32 public constant STRATEGY4_INITIAL_FEE = 900; // %9.00
    uint32 public constant STRATEGY1_UPDATE_FEE = 10;
    // Initial Balances
    uint256 public constant INITIAL_USER1_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 public constant INITIAL_USER1_BALANCE_ETH = 1_000_000 ether;
    uint256 public constant INITIAL_USER2_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 public constant INITIAL_USER2_BALANCE_ETH = 10 ether;
    uint256 public constant INITIAL_RECEIVER_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 public constant INITIAL_RECEIVER_BALANCE_ETH = 10 ether;
    uint256 public constant INITIAL_ATTACKER_BALANCE_ERC20 =
        100_000_000 * 10 ** 18;
    uint256 public constant INITIAL_ATTACKER_BALANCE_ETH = 10 ether;
    uint256 public constant INITIAL_USER3_BALANCE_ERC20 = 1e51;
    uint256 public constant INITIAL_USER3_BALANCE_ETH = 1e51;
    // Constants
    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint32 public constant MAX_FEE_INCREMENT = 500; // 5%
    // Array containing all the BApps created
    IBasedApp[] public bApps;
    ProtocolStorageLib.Data public config;

    function setUp() public virtual {
        vm.label(OWNER, "Owner");
        vm.label(USER1, "User1");
        vm.label(USER2, "User2");
        vm.label(ATTACKER, "Attacker");
        vm.label(RECEIVER, "Receiver");
        vm.label(RECEIVER2, "Receiver2");

        vm.startPrank(OWNER);
        basedAppsManagerMod = new BasedAppsManager();
        strategyManagerMod = new StrategyManager();
        protocolManagerMod = new ProtocolManager();
        implementation = new SSVBasedApps();

        config = ProtocolStorageLib.Data({
            maxFeeIncrement: MAX_FEE_INCREMENT,
            feeTimelockPeriod: 7 days,
            feeExpireTime: 1 days,
            withdrawalTimelockPeriod: 14 days,
            withdrawalExpireTime: 3 days,
            obligationTimelockPeriod: 14 days,
            obligationExpireTime: 3 days,
            tokenUpdateTimelockPeriod: 14 days,
            maxShares: 1e50,
            disabledFeatures: 0
        });

        bytes memory data = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        proxy = new ERC1967Proxy(address(implementation), data);
        proxiedManager = SSVBasedApps(payable(address(proxy)));
        assertEq(proxiedManager.getVersion(), "0.2.0", "Version mismatch");
        assertEq(
            proxiedManager.maxFeeIncrement(),
            500,
            "Initialization failed"
        );
        vm.stopPrank();

        vm.startPrank(USER1);
        bApp1 = new BasedAppMock(address(proxiedManager), USER1);
        bApp2 = new BasedAppMock2(address(proxiedManager));
        bApp3 = new BasedAppMock3(address(proxiedManager), USER1);
        bApp4 = new BasedAppMock4(address(proxiedManager), USER1);
        bApp3.hasRole(bApp3.OWNER_ROLE(), USER1);
        bApp3.hasRole(bApp3.MANAGER_ROLE(), USER1);
        bApp3.grantManagerRole(USER1);
        bApp3.hasRole(bApp3.MANAGER_ROLE(), USER1);
        vm.stopPrank();

        nonCompliantBApp = new NonCompliantBApp(address(proxiedManager));
        whitelistExample = new WhitelistExample(address(proxiedManager), USER1);
        ecdsaVerifierExample = new ECDSAVerifier(
            address(proxiedManager),
            USER1
        );

        bApps.push(bApp1);
        bApps.push(bApp2);
        bApps.push(bApp3);
        bApps.push(bApp4);

        vm.startPrank(OWNER);
        vm.label(address(bApp1), "BasedApp1");
        vm.label(address(bApp2), "BasedApp2");
        vm.label(address(bApp3), "BasedApp3");
        vm.label(address(bApp4), "BasedApp4");
        vm.label(address(nonCompliantBApp), "NonCompliantBApp");
        vm.label(address(whitelistExample), "WhitelistExample");
        vm.label(address(ecdsaVerifierExample), "ECDSAVerifierExample");
        vm.label(address(proxiedManager), "BasedAppManagerProxy");

        vm.deal(USER1, INITIAL_USER1_BALANCE_ETH);
        vm.deal(USER2, INITIAL_USER2_BALANCE_ETH);
        vm.deal(USER3, INITIAL_USER3_BALANCE_ETH);
        vm.deal(RECEIVER, INITIAL_RECEIVER_BALANCE_ETH);
        vm.deal(ATTACKER, INITIAL_ATTACKER_BALANCE_ETH);

        erc20mock = new ERC20Mock();
        erc20mock2 = new ERC20Mock();
        erc20mock3 = new ERC20Mock();
        erc20mock4 = new ERC20Mock();
        erc20mock5 = new ERC20Mock();

        erc20mock.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock.transfer(USER2, INITIAL_USER2_BALANCE_ERC20);
        erc20mock.transfer(USER3, INITIAL_USER3_BALANCE_ERC20);
        erc20mock.transfer(ATTACKER, INITIAL_ATTACKER_BALANCE_ERC20);
        erc20mock.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        erc20mock2.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        vm.stopPrank();
    }
}
