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

    // todo: test if they can receive eth from other users
}
