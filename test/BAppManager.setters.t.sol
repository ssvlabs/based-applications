// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {BasedAppManagerSetupTest, IBasedAppManager, ISSVBasedApps, IStorage} from "@ssv/test/BAppManager.setup.t.sol";

contract BasedAppManagerSettersTest is BasedAppManagerSetupTest {
    function test_setFeeTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.setFeeTimelockPeriod(3 days);
        assertEq(proxiedManager.feeTimelockPeriod(), 3 days, "Fee timelock update failed");
    }

    function test_setFeeExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.setFeeExpireTime(1 days);
        assertEq(proxiedManager.feeExpireTime(), 1 days, "Fee expire time update failed");
    }

    function test_setWithdrawalTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.setWithdrawalTimelockPeriod(5 days);
        assertEq(proxiedManager.withdrawalTimelockPeriod(), 5 days, "Withdrawal timelock update failed");
    }

    function test_setWithdrawalExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.setWithdrawalExpireTime(1 days);
        assertEq(proxiedManager.withdrawalExpireTime(), 1 days, "Withdrawal expire time update failed");
    }

    function test_setObligationTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.setObligationTimelockPeriod(7 days);
        assertEq(proxiedManager.obligationTimelockPeriod(), 7 days, "Obligation timelock update failed");
    }

    function test_setObligationExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.setObligationExpireTime(1 days);
        assertEq(proxiedManager.obligationExpireTime(), 1 days, "Obligation expire time update failed");
    }

    function test_setMaxPercentage() public {
        vm.prank(OWNER);
        proxiedManager.setMaxPercentage(1234);
        assertEq(proxiedManager.maxPercentage(), 1234, "Max percentage update failed");
    }

    function test_setEthAddress() public {
        vm.prank(OWNER);
        address newAddress = address(0x1234567890123456789012345678901234567890);
        proxiedManager.setEthAddress(newAddress);
        assertEq(proxiedManager.ethAddress(), newAddress, "ETH address update failed");
    }

    function test_setMaxShares() public {
        vm.prank(OWNER);
        uint256 newValue = 1e18;
        proxiedManager.setMaxShares(newValue);
        assertEq(proxiedManager.maxShares(), newValue, "Max shares update failed");
    }

    function test_setMaxFeeIncrement() public {
        vm.prank(OWNER);
        proxiedManager.setMaxFeeIncrement(501);
        assertEq(proxiedManager.maxFeeIncrement(), 501, "Max fee increment update failed");
    }

    function test_setTokenUpdateTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.setTokenUpdateTimelockPeriod(3 days);
        assertEq(proxiedManager.tokenUpdateTimelockPeriod(), 3 days, "Token update timelock update failed");
    }

    function test_setTokenUpdateExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.setTokenUpdateExpireTime(3 days);
        assertEq(proxiedManager.tokenUpdateExpireTime(), 3 days, "Token update timelock update failed");
    }

    function test_setTokenRemovalTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.setTokenRemovalTimelockPeriod(3 days);
        assertEq(proxiedManager.tokenRemovalTimelockPeriod(), 3 days, "Token removal timelock update failed");
    }

    function test_setTokenRemovalExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.setTokenRemovalExpireTime(3 days);
        assertEq(proxiedManager.tokenRemovalExpireTime(), 3 days, "Token removal expire time update failed");
    }

    function test_initializedParamsBasedAppManager() public view {
        assertEq(proxiedManager.tokenUpdateTimelockPeriod(), 7 days);
        assertEq(proxiedManager.tokenUpdateExpireTime(), 1 days);
        assertEq(proxiedManager.tokenRemovalTimelockPeriod(), 7 days);
        assertEq(proxiedManager.tokenRemovalExpireTime(), 1 days);
    }
}
