// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {SSVBasedApps} from "src/SSVBasedApps.sol";
import {IStorage} from "@ssv/src/interfaces/IStorage.sol";
import {IBasedAppManager} from "@ssv/src/interfaces/IBasedAppManager.sol";
import {ISSVBasedApps} from "@ssv/src/interfaces/ISSVBasedApps.sol";

import {IERC20, ERC20Mock} from "@ssv/test/mocks/MockERC20.sol";
import {BasedAppMock} from "@ssv/test/mocks/MockBApp.sol";
import {NonCompliantBApp} from "@ssv/test/mocks/MockNonCompliantBApp.sol";
import {WhitelistExample} from "@ssv/src/middleware/examples/WhitelistExample.sol";

contract BasedAppManagerSetupTest is Test, OwnableUpgradeable {
    SSVBasedApps public implementation;
    ERC1967Proxy proxy; // UUPS Proxy contract
    SSVBasedApps proxiedManager; // Proxy interface for interaction
    BasedAppMock bApp1;
    BasedAppMock bApp2;
    NonCompliantBApp nonCompliantBApp;
    WhitelistExample whitelistExample;

    IERC20 public erc20mock;
    IERC20 public erc20mock2;
    IERC20 public erc20mock3;
    IERC20 public erc20mock4;
    IERC20 public erc20mock5;

    address OWNER = makeAddr("Owner");
    address USER1 = makeAddr("User1");
    address USER2 = makeAddr("User2");
    address BAPP1 = makeAddr("BApp1");
    address BAPP2 = makeAddr("BApp2");
    address ATTACKER = makeAddr("Attacker");
    address RECEIVER = makeAddr("Receiver");
    address RECEIVER2 = makeAddr("Receiver2");

    uint32 STRATEGY1 = 1;
    uint32 STRATEGY2 = 2;
    uint32 STRATEGY3 = 3;
    uint32 STRATEGY4 = 4;
    uint32 STRATEGY1_INITIAL_FEE = 5;
    uint32 STRATEGY2_INITIAL_FEE = 0;
    uint32 STRATEGY3_INITIAL_FEE = 1000;
    uint32 STRATEGY4_INITIAL_FEE = 900;
    uint32 STRATEGY1_UPDATE_FEE = 10;

    uint256 constant INITIAL_USER1_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 constant INITIAL_USER1_BALANCE_ETH = 10 ether;
    uint256 constant INITIAL_RECEIVER_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 constant INITIAL_RECEIVER_BALANCE_ETH = 10 ether;
    uint256 constant INITIAL_ATTACKER_BALANCE_ETH = 10 ether;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint32 constant MAX_FEE_INCREMENT = 500;

    function setUp() public {
        vm.label(OWNER, "Owner");
        vm.label(USER1, "User1");
        vm.label(ATTACKER, "Attacker");
        vm.label(RECEIVER, "Receiver");
        vm.label(RECEIVER2, "Receiver2");
        vm.label(BAPP1, "BApp1");
        vm.label(BAPP2, "BApp2");

        vm.startPrank(OWNER);
        implementation = new SSVBasedApps();
        bytes memory data = abi.encodeWithSelector(implementation.initialize.selector, address(OWNER), MAX_FEE_INCREMENT); // Encodes initialize() call

        proxy = new ERC1967Proxy(address(implementation), data);
        proxiedManager = SSVBasedApps(payable(address(proxy)));

        assertEq(proxiedManager.maxFeeIncrement(), 500, "Initialization failed");
        vm.stopPrank();
        vm.prank(USER1);
        bApp1 = new BasedAppMock(address(proxiedManager), USER1);
        nonCompliantBApp = new NonCompliantBApp(address(proxiedManager));
        whitelistExample = new WhitelistExample(address(proxiedManager), USER1);

        vm.startPrank(OWNER);
        vm.label(address(bApp1), "BasedApp1");
        vm.label(address(proxiedManager), "BasedAppManagerProxy");

        vm.deal(USER1, INITIAL_USER1_BALANCE_ETH);
        vm.deal(RECEIVER, INITIAL_RECEIVER_BALANCE_ETH);
        vm.deal(ATTACKER, INITIAL_ATTACKER_BALANCE_ETH);

        erc20mock = new ERC20Mock();
        erc20mock.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        erc20mock2 = new ERC20Mock();
        erc20mock2.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        erc20mock3 = new ERC20Mock();
        erc20mock4 = new ERC20Mock();
        erc20mock5 = new ERC20Mock();

        vm.stopPrank();
    }
}
