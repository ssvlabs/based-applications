// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { ETH_ADDRESS } from "@ssv/src/core/libraries/ValidationLib.sol";

import { Setup } from "@ssv/test/helpers/Setup.t.sol";
import { IProtocolManager } from "@ssv/src/core/interfaces/IProtocolManager.sol";
import { IBasedAppManager } from "@ssv/src/core/interfaces/IBasedAppManager.sol";
import { IStrategyManager } from "@ssv/src/core/interfaces/IStrategyManager.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { SSVBasedApps } from "@ssv/src/core/SSVBasedApps.sol";

contract ProtocolManagerTest is Setup, Ownable2StepUpgradeable {
    function testUpdateFeeTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateFeeTimelockPeriod(3 days);
        assertEq(
            proxiedManager.feeTimelockPeriod(),
            3 days,
            "Fee timelock update failed"
        );
    }

    function testUpdateFeeExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.updateFeeExpireTime(1 days);
        assertEq(
            proxiedManager.feeExpireTime(),
            1 days,
            "Fee expire time update failed"
        );
    }

    function testUpdateWithdrawalTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateWithdrawalTimelockPeriod(5 days);
        assertEq(
            proxiedManager.withdrawalTimelockPeriod(),
            5 days,
            "Withdrawal timelock update failed"
        );
    }

    function testUpdateWithdrawalExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.updateWithdrawalExpireTime(1 days);
        assertEq(
            proxiedManager.withdrawalExpireTime(),
            1 days,
            "Withdrawal expire time update failed"
        );
    }

    function testUpdateObligationTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateObligationTimelockPeriod(7 days);
        assertEq(
            proxiedManager.obligationTimelockPeriod(),
            7 days,
            "Obligation timelock update failed"
        );
    }

    function testUpdateObligationExpireTime() public {
        vm.prank(OWNER);
        proxiedManager.updateObligationExpireTime(1 days);
        assertEq(
            proxiedManager.obligationExpireTime(),
            1 days,
            "Obligation expire time update failed"
        );
    }

    function testUpdateTokenUpdateTimelockPeriod() public {
        vm.prank(OWNER);
        proxiedManager.updateTokenUpdateTimelockPeriod(7 days);
        assertEq(
            proxiedManager.tokenUpdateTimelockPeriod(),
            7 days,
            "TokenUpdate timelock update failed"
        );
    }

    function testMaxPercentage() public view {
        assertEq(
            proxiedManager.maxPercentage(),
            10_000,
            "Max percentage set failed"
        );
    }

    function testEthAddress() public view {
        assertEq(
            proxiedManager.ethAddress(),
            ETH_ADDRESS,
            "ETH address set failed"
        );
    }

    function testUpdateMaxShares() public {
        vm.prank(OWNER);
        uint256 newValue = 1e18;
        proxiedManager.updateMaxShares(newValue);
        assertEq(
            proxiedManager.maxShares(),
            newValue,
            "Max shares update failed"
        );
    }

    function testUpdateMaxFeeIncrement() public {
        vm.prank(OWNER);
        proxiedManager.updateMaxFeeIncrement(501);
        assertEq(
            proxiedManager.maxFeeIncrement(),
            501,
            "Max fee increment update failed"
        );
    }

    function testRevertUpdateFeeTimelockPeriodWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        proxiedManager.updateFeeTimelockPeriod(3 days);
    }

    function testRevertUpdateFeeExpireTimeWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        proxiedManager.updateFeeExpireTime(1 days);
    }

    function testRevertUpdateWithdrawalTimelockPeriodWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        proxiedManager.updateWithdrawalTimelockPeriod(5 days);
    }

    function testRevertUpdateWithdrawalExpireTimeWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        proxiedManager.updateWithdrawalExpireTime(1 days);
    }

    function testRevertUpdateObligationTimelockPeriodWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        proxiedManager.updateObligationTimelockPeriod(7 days);
    }

    function testRevertUpdateObligationExpireTimeWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        proxiedManager.updateObligationExpireTime(1 days);
    }

    function testRevertUpdateTokenUpdateTimelockPeriodWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        proxiedManager.updateTokenUpdateTimelockPeriod(7 days);
    }

    function testRevertUpdateMaxSharesWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        uint256 newValue = 1e18;
        proxiedManager.updateMaxShares(newValue);
    }

    function testRevertUpdateMaxFeeIncrementWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        proxiedManager.updateMaxFeeIncrement(501);
    }

    /// @notice By default, no features should be disabled
    function testDefaultDisabledFeaturesIsZero() public view {
        assertEq(
            proxiedManager.disabledFeatures(),
            0,
            "default disabledFeatures should be zero"
        );
    }

    /// @notice The initializer should respect `config.disabledFeatures`
    function testInitializeDisabledFeaturesFromConfig() public {
        // Override config in Setup
        config.disabledFeatures = 3; // slashing & withdrawals disabled

        // Re-deploy a fresh proxy with the modified config
        bytes memory initData = abi.encodeWithSelector(
            implementation.initialize.selector,
            address(OWNER),
            IBasedAppManager(basedAppsManagerMod),
            IStrategyManager(strategyManagerMod),
            IProtocolManager(protocolManagerMod),
            config
        );
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        SSVBasedApps proxiedManager = SSVBasedApps(payable(address(proxy)));

        // It should read back exactly what we set
        assertEq(
            proxiedManager.disabledFeatures(),
            3,
            "initializer did not set disabledFeatures from config"
        );
    }

    /// @notice Only the owner can update the feature mask
    function testUpdateFeatureDisabledFlagsAsOwner() public {
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(2);
        assertEq(
            proxiedManager.disabledFeatures(),
            2,
            "owner update of disabledFeatures failed"
        );
    }

    /// @notice Updating the flags should emit DisabledFeaturesUpdated
    function testEmitDisabledFeaturesUpdatedEvent() public {
        vm.prank(OWNER);
        vm.expectEmit(true, false, false, true);
        emit IProtocolManager.DisabledFeaturesUpdated(5);
        proxiedManager.updateDisabledFeatures(5);
    }

    function testRevertUpdateDisabledFeaturesWithNonOwner() public {
        vm.prank(ATTACKER);
        vm.expectRevert(
            abi.encodeWithSelector(
                OwnableUnauthorizedAccount.selector,
                address(ATTACKER)
            )
        );
        proxiedManager.updateDisabledFeatures(1);
    }

    function testSetIndividualDisabledFeatureBits() public {
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(1 << 0);
        assertEq(
            proxiedManager.disabledFeatures(),
            1,
            "slashingDisabled bit not set correctly"
        );
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(1 << 1);
        assertEq(
            proxiedManager.disabledFeatures(),
            2,
            "withdrawalsDisabled bit not set correctly"
        );
    }

    function testClearFlags() public {
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(3);
        assertEq(proxiedManager.disabledFeatures(), 3, "mask precondition");
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(0);
        assertEq(proxiedManager.disabledFeatures(), 0, "flags not cleared");
    }

    function testCombinedFlags() public {
        uint32 mask = (1 << 0) | (1 << 2) | (1 << 4);
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(mask);
        assertEq(
            proxiedManager.disabledFeatures(),
            mask,
            "combined mask mismatch"
        );
    }

    function testOtherParamsUnaffectedByFeatureMask() public {
        vm.prank(OWNER);
        proxiedManager.updateDisabledFeatures(type(uint32).max);
        vm.prank(OWNER);
        proxiedManager.updateFeeTimelockPeriod(2 days);
        assertEq(
            proxiedManager.feeTimelockPeriod(),
            2 days,
            "feeTimelockPeriod should update despite flags"
        );
    }
}
