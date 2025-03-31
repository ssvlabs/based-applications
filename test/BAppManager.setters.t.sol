// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {BasedAppManagerSetupTest} from "@ssv/test/BAppManager.setup.t.sol";

contract BasedAppManagerSettersTest is BasedAppManagerSetupTest {
    function test_updateFeeTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateFeeTimelockPeriod(3 days);
        assertEq(proxiedManager.feeTimelockPeriod(), 3 days, "Fee timelock update failed");
    }

    function test_updateFeeExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.updateFeeExpireTime(1 days);
        assertEq(proxiedManager.feeExpireTime(), 1 days, "Fee expire time update failed");
    }

    function test_updateWithdrawalTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateWithdrawalTimelockPeriod(5 days);
        assertEq(proxiedManager.withdrawalTimelockPeriod(), 5 days, "Withdrawal timelock update failed");
    }

    function test_updateWithdrawalExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.updateWithdrawalExpireTime(1 days);
        assertEq(proxiedManager.withdrawalExpireTime(), 1 days, "Withdrawal expire time update failed");
    }

    function test_updateObligationTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateObligationTimelockPeriod(7 days);
        assertEq(proxiedManager.obligationTimelockPeriod(), 7 days, "Obligation timelock update failed");
    }

    function test_updateObligationExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.updateObligationExpireTime(1 days);
        assertEq(proxiedManager.obligationExpireTime(), 1 days, "Obligation expire time update failed");
    }

    function test_updateMaxPercentage() public {
        vm.prank(OWNER);
        proxiedManager.updateMaxPercentage(1234);
        assertEq(proxiedManager.maxPercentage(), 1234, "Max percentage update failed");
    }

    function test_updateEthAddress() public {
        vm.prank(OWNER);
        address newAddress = address(0x1234567890123456789012345678901234567890);
        proxiedManager.updateEthAddress(newAddress);
        assertEq(proxiedManager.ethAddress(), newAddress, "ETH address update failed");
    }

    function test_updateMaxShares() public {
        vm.prank(OWNER);
        uint256 newValue = 1e18;
        proxiedManager.updateMaxShares(newValue);
        assertEq(proxiedManager.maxShares(), newValue, "Max shares update failed");
    }

    function test_updateMaxFeeIncrement() public {
        vm.prank(OWNER);
        proxiedManager.updateMaxFeeIncrement(501);
        assertEq(proxiedManager.maxFeeIncrement(), 501, "Max fee increment update failed");
    }
}
