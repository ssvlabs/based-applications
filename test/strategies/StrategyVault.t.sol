// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { StrategyManagerTest } from "@ssv/test/modules/StrategyManager.t.sol";

import { IStrategyVault } from "@ssv/src/core/interfaces/IStrategyVault.sol";

contract StrategyVaultTest is StrategyManagerTest {
    function testRevertAttackerTryingWithdrawal() public {
        testCreateStrategyAndSingleDeposit(1 ether);
        vm.startPrank(ATTACKER);
        (address strategyAddress, , ) = proxiedManager.strategies(STRATEGY1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyVault.UnauthorizedCaller.selector)
        );
        IStrategyVault(strategyAddress).withdraw(
            erc20mock,
            1,
            address(ATTACKER)
        );
    }

    function testRevertAttackerTryingWithdrawalETH() public {
        testCreateStrategyAndSingleDeposit(1 ether);
        vm.startPrank(ATTACKER);
        (address strategyAddress, , ) = proxiedManager.strategies(STRATEGY1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyVault.UnauthorizedCaller.selector)
        );
        IStrategyVault(strategyAddress).withdrawETH(1, address(ATTACKER));
    }

    function testRevertFailTryingWithdrawalETH() public {
        testCreateStrategyAndSingleDeposit(1 ether);
        vm.startPrank(address(proxiedManager));
        (address strategyAddress, , ) = proxiedManager.strategies(STRATEGY1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyVault.ETHTransferFailed.selector)
        );
        // this results in EvmError: OutOfFunds
        IStrategyVault(strategyAddress).withdrawETH(1, address(proxiedManager));
    }

    function testRevertZeroAmountWithdrawal() public {
        testCreateStrategyAndSingleDeposit(1 ether);
        vm.startPrank(address(proxiedManager));
        (address strategyAddress, , ) = proxiedManager.strategies(STRATEGY1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyVault.InvalidZeroAmount.selector)
        );
        IStrategyVault(strategyAddress).withdraw(
            erc20mock,
            0,
            address(proxiedManager)
        );
    }

    function testRevertZeroAmountWithdrawalETH() public {
        testCreateStrategyAndSingleDeposit(1 ether);
        vm.startPrank(address(proxiedManager));
        (address strategyAddress, , ) = proxiedManager.strategies(STRATEGY1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyVault.InvalidZeroAmount.selector)
        );
        IStrategyVault(strategyAddress).withdrawETH(0, address(proxiedManager));
    }

    function testRevertSendEth() public {
        testCreateStrategyAndSingleDeposit(1 ether);
        vm.startPrank(ATTACKER);
        (address strategyAddress, , ) = proxiedManager.strategies(STRATEGY1);
        vm.expectRevert(
            abi.encodeWithSelector(IStrategyVault.UnauthorizedCaller.selector)
        );
        payable(strategyAddress).transfer(1 ether);
    }

    // todo: test if they can receive eth from other users
}
