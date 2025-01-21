// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {BasedAppManager} from "../src/BasedAppManager.sol";
import {ICore} from "../src/interfaces/ICore.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./mocks/MockERC20.sol";

contract BasedAppManagerSetupTest is Test, OwnableUpgradeable {
    BasedAppManager public implementation;
    ERC1967Proxy proxy; // UUPS Proxy contract
    BasedAppManager proxiedManager; // Proxy interface for interaction

    IERC20 public erc20mock;
    IERC20 public erc20mock2;

    address OWNER = makeAddr("Owner");
    address USER1 = makeAddr("User1");
    address SERVICE1 = makeAddr("BApp1");
    address SERVICE2 = makeAddr("BApp2");
    address ATTACKER = makeAddr("Attacker");
    address RECEIVER = makeAddr("Receiver");
    address RECEIVER2 = makeAddr("Receiver2");

    uint256 STRATEGY1 = 1;
    uint256 STRATEGY2 = 2;
    uint256 STRATEGY3 = 3;
    uint256 STRATEGY4 = 4;
    uint32 STRATEGY1_INITIAL_FEE = 5;
    uint32 STRATEGY2_INITIAL_FEE = 0;
    uint32 STRATEGY3_INITIAL_FEE = 1000;
    uint32 STRATEGY1_UPDATE_FEE = 10;

    address ERC20_ADDRESS1 = address(erc20mock);
    address ERC20_ADDRESS2 = address(erc20mock2);

    uint256 constant INITIAL_USER1_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 constant INITIAL_USER1_BALANCE_ETH = 10 ether;
    uint256 constant INITIAL_RECEIVER_BALANCE_ERC20 = 1000 * 10 ** 18;
    uint256 constant INITIAL_RECEIVER_BALANCE_ETH = 10 ether;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint32 constant MAX_FEE_INCREMENT = 500;

    function setUp() public {
        vm.label(OWNER, "Owner");
        vm.label(USER1, "User1");
        vm.label(ATTACKER, "Attacker");
        vm.label(RECEIVER, "Receiver");
        vm.label(RECEIVER2, "Receiver2");
        vm.label(SERVICE1, "BApp1");
        vm.label(SERVICE2, "BApp2");

        vm.startPrank(OWNER);

        implementation = new BasedAppManager();
        bytes memory data = abi.encodeWithSelector(implementation.initialize.selector, MAX_FEE_INCREMENT); // Encodes initialize() call

        proxy = new ERC1967Proxy(address(implementation), data);
        proxiedManager = BasedAppManager(address(proxy));

        assertEq(proxiedManager.maxFeeIncrement(), 500, "Initialization failed");

        vm.label(address(proxiedManager), "BasedAppManagerProxy");

        vm.deal(USER1, INITIAL_USER1_BALANCE_ETH);
        vm.deal(RECEIVER, INITIAL_RECEIVER_BALANCE_ETH);

        erc20mock = new ERC20Mock();
        erc20mock.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        erc20mock2 = new ERC20Mock();
        erc20mock2.transfer(USER1, INITIAL_USER1_BALANCE_ERC20);
        erc20mock2.transfer(RECEIVER, INITIAL_RECEIVER_BALANCE_ERC20);

        vm.stopPrank();
    }
}
