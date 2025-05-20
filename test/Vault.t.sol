// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Vault } from "@ssv/src/core/Vault.sol";

contract VaultTest is Test {
    Vault public vault;
    Vault public vault2;

    address OWNER = makeAddr("Owner");
    address USER1 = makeAddr("User1");
    address USER2 = makeAddr("User2");

    IERC20 usdc;
    IERC20 stEth;

    address usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address usdcWhale = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;

    address stEthAddress = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address stEthWhale = 0xE53FFF67f9f384d20Ebea36F43b93DC49Ed22753;

    uint256 mainnetFork;

    function setUp() public virtual {
        vm.label(OWNER, "Owner");
        vm.label(USER1, "User1");
        vm.label(USER2, "User2");

        vm.deal(usdcWhale, 1 ether);
        vm.deal(stEthWhale, 1 ether);
        vm.deal(USER1, 1 ether);

        mainnetFork = vm.createFork(
            "wss://ethereum-rpc.publicnode.com",
            21820489
        );

        vm.selectFork(mainnetFork);

        usdc = IERC20(usdcAddress);
        stEth = IERC20(stEthAddress);
        vm.label(address(usdc), "USDC");
        vm.label(address(stEth), "stETH");

        vm.startPrank(OWNER);
        vault = new Vault(address(usdc));
        vault2 = new Vault(address(stEth));
        vm.stopPrank();

        vm.label(address(vault), "Vault");
    }

    function test_total() public view {
        assertEq(vault.totalSupply(), 0);
        assertEq(vault2.totalSupply(), 0);
    }

    function test_deposit() public {
        vm.selectFork(mainnetFork);
        vm.prank(usdcWhale);
        uint256 amount = 1000 * 10 ** 6;
        usdc.transfer(USER1, amount);
        assertEq(usdc.balanceOf(USER1), amount);

        vm.prank(stEthWhale);
        uint256 amount2 = 1000 * 10 ** 18;
        uint256 depositAmount = 50 * 10 ** 18;
        uint256 nonDepositAmount = amount2 - depositAmount;
        stEth.transfer(USER1, amount2);

        vm.startPrank(USER1);
        usdc.approve(address(vault), amount);
        stEth.approve(address(vault2), amount2);
        assertEq(vm.activeFork(), mainnetFork);
        vault.deposit(amount, USER1);
        vault2.deposit(depositAmount, USER1);
        assertEq(usdc.balanceOf(USER1), 0);
        assertEq(vault.balanceOf(USER1), amount);
        //assertEq(stEth.balanceOf(USER1), nonDepositAmount);
        assertEq(vault2.balanceOf(USER1), depositAmount);
        vm.warp(block.timestamp + 90 days);
        assertEq(stEth.balanceOf(USER1), nonDepositAmount);
        assertEq(vault2.balanceOf(USER1), depositAmount);
        vm.stopPrank();
    }

    function test_usdc() public {
        vm.selectFork(mainnetFork);
        assertEq(usdc.balanceOf(USER1), 0);
    }

    // function test_vaultBalance() public {
    //     vm.selectFork(mainnetFork);
    //     assertEq(vault.balanceAave(), 0);
    //     assertEq(vault.balanceCompound(), 0);
    // }
}
