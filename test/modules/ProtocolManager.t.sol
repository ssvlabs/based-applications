// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ETH_ADDRESS} from "@ssv/src/core/libraries/ValidationLib.sol";

import {Setup} from "@ssv/test/helpers/Setup.t.sol";

contract ProtocolManagerTest is Setup, Ownable2StepUpgradeable {
    function testUpdateFeeTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateFeeTimelockPeriod(3 days);
        assertEq(proxiedManager.feeTimelockPeriod(), 3 days, "Fee timelock update failed");
    }

    function testUpdateFeeExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.updateFeeExpireTime(1 days);
        assertEq(proxiedManager.feeExpireTime(), 1 days, "Fee expire time update failed");
    }

    function testUpdateWithdrawalTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateWithdrawalTimelockPeriod(5 days);
        assertEq(proxiedManager.withdrawalTimelockPeriod(), 5 days, "Withdrawal timelock update failed");
    }

    function testUpdateWithdrawalExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.updateWithdrawalExpireTime(1 days);
        assertEq(proxiedManager.withdrawalExpireTime(), 1 days, "Withdrawal expire time update failed");
    }

    function testUpdateObligationTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateObligationTimelockPeriod(7 days);
        assertEq(proxiedManager.obligationTimelockPeriod(), 7 days, "Obligation timelock update failed");
    }

    function testUpdateObligationExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.updateObligationExpireTime(1 days);
        assertEq(proxiedManager.obligationExpireTime(), 1 days, "Obligation expire time update failed");
    }

    function testMaxPercentage() public view {
        assertEq(proxiedManager.maxPercentage(), 10_000, "Max percentage set failed");
    }

    function testEthAddress() public view {
        assertEq(proxiedManager.ethAddress(), ETH_ADDRESS, "ETH address set failed");
    }

    function testUpdateMaxShares() public {
        vm.prank(OWNER);
        uint256 newValue = 1e18;
        proxiedManager.updateMaxShares(newValue);
        assertEq(proxiedManager.maxShares(), newValue, "Max shares update failed");
    }

    function testUpdateMaxFeeIncrement() public {
        vm.prank(OWNER);
        proxiedManager.updateMaxFeeIncrement(501);
        assertEq(proxiedManager.maxFeeIncrement(), 501, "Max fee increment update failed");
    }

    function testRevertUpdateFeeTimelockPeriodWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.updateFeeTimelockPeriod(3 days);
    }

    function testRevertUpdateFeeExpireTimeWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.updateFeeExpireTime(1 days);
    }

    function testRevertUpdateWithdrawalTimelockPeriodWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.updateWithdrawalTimelockPeriod(5 days);
    }

    function testRevertUpdateWithdrawalExpireTimeWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.updateWithdrawalExpireTime(1 days);
    }

    function testRevertUpdateObligationTimelockPeriodWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.updateObligationTimelockPeriod(7 days);
    }

    function testRevertUpdateObligationExpireTimeWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.updateObligationExpireTime(1 days);
    }

    function testRevertUpdateMaxSharesWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        uint256 newValue = 1e18;
        proxiedManager.updateMaxShares(newValue);
    }

    function testRevertUpdateMaxFeeIncrementWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, address(ATTACKER)));
        proxiedManager.updateMaxFeeIncrement(501);
    }
}
