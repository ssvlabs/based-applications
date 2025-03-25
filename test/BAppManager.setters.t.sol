// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppManagerSetupTest, IBasedAppManager, ISSVBasedApps, IStorage} from "@ssv/test/BAppManager.setup.t.sol";

contract BasedAppManagerSettersTest is BasedAppManagerSetupTest {
    function test_setFeeTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.setFeeTimelockPeriod(3 days);
        assertEq(proxiedManager.__feeTimelockPeriod__(), 3 days, "Fee timelock update failed");
    }

    function test_setFeeExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.setFeeExpireTime(1 days);
        assertEq(proxiedManager.__feeExpireTime__(), 1 days, "Fee expire time update failed");
    }

    function test_setWithdrawalTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.setWithdrawalTimelockPeriod(5 days);
        assertEq(proxiedManager.__withdrawalTimelockPeriod__(), 5 days, "Withdrawal timelock update failed");
    }

    function test_setWithdrawalExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.setWithdrawalExpireTime(1 days);
        assertEq(proxiedManager.__withdrawalExpireTime__(), 1 days, "Withdrawal expire time update failed");
    }

    function test_setObligationTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.setObligationTimelockPeriod(7 days);
        assertEq(proxiedManager.__obligationTimelockPeriod__(), 7 days, "Obligation timelock update failed");
    }

    function test_setObligationExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.setObligationExpireTime(1 days);
        assertEq(proxiedManager.__obligationExpireTime__(), 1 days, "Obligation expire time update failed");
    }

    function test_setMaxPercentage() public {
        vm.prank(OWNER);
        proxiedManager.setMaxPercentage(1234);
        assertEq(proxiedManager.__maxPercentage__(), 1234, "Max percentage update failed");
    }

    function test_setEthAddress() public {
        vm.prank(OWNER);
        address newAddress = address(0x1234567890123456789012345678901234567890);
        proxiedManager.setEthAddress(newAddress);
        assertEq(proxiedManager.__ethAddress__(), newAddress, "ETH address update failed");
    }

    function test_setMaxShares() public {
        vm.prank(OWNER);
        uint256 newValue = 1e18;
        proxiedManager.setMaxShares(newValue);
        assertEq(proxiedManager.__maxShares__(), newValue, "Max shares update failed");
    }

    function test_setMaxFeeIncrement() public {
        vm.prank(OWNER);
        proxiedManager.setMaxFeeIncrement(777);
        assertEq(proxiedManager.__maxFeeIncrement__(), 777, "Max fee increment update failed");
    }
}
