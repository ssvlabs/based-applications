// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import { SSVBasedApps } from "@ssv/src/core/SSVBasedApps.sol";
import { Setup } from "@ssv/test/helpers/Setup.t.sol";
import { ICore } from "@ssv/src/core/interfaces/ICore.sol";

contract UtilsTest is Setup {
    function createSingleTokenAndSingleRiskLevel(
        address token,
        uint32 sharedRiskLevel
    )
        internal
        pure
        returns (
            address[] memory tokensInput,
            uint32[] memory sharedRiskLevelInput
        )
    {
        tokensInput = new address[](1);
        tokensInput[0] = token;
        sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = sharedRiskLevel;
    }
    function createSingleTokenConfig(
        address token,
        uint32 sharedRiskLevel
    ) internal pure returns (ICore.TokenConfig[] memory tokenConfigs) {
        tokenConfigs = new ICore.TokenConfig[](1);
        tokenConfigs[0] = ICore.TokenConfig({
            token: token,
            sharedRiskLevel: sharedRiskLevel
        });
    }

    function createSingleTokenAndSingleObligationPercentage(
        address token,
        uint32 obligationPercentage
    )
        internal
        pure
        returns (
            address[] memory tokensInput,
            uint32[] memory obligationPercentageInput
        )
    {
        tokensInput = new address[](1);
        tokensInput[0] = token;
        obligationPercentageInput = new uint32[](1);
        obligationPercentageInput[0] = obligationPercentage;
    }

    function checkBAppInfo(
        ICore.TokenConfig[] memory tokenConfigsInput,
        address bApp,
        SSVBasedApps proxiedManager
    ) internal view {
        bool isRegistered = proxiedManager.registeredBApps(bApp);
        assertEq(isRegistered, true, "BApp registered");
        for (uint32 i = 0; i < tokenConfigsInput.length; i++) {
            (uint32 sharedRiskLevel, bool isSet, , ) = proxiedManager
                .bAppTokens(bApp, tokenConfigsInput[i].token);
            assertEq(
                tokenConfigsInput[i].sharedRiskLevel,
                sharedRiskLevel,
                "BApp risk level percentage"
            );
            assertEq(isSet, true, "BApp token set");
        }
    }

    function checkStrategyInfo(
        address owner,
        uint32 strategyId,
        address bApp,
        address token,
        uint32 percentage,
        SSVBasedApps proxiedManager,
        bool expectedIsSet
    ) internal view {
        uint32 id = proxiedManager.accountBAppStrategy(owner, bApp);
        assertEq(strategyId, id, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(
            strategyId,
            bApp,
            token
        );
        assertEq(isSet, expectedIsSet, "Obligation is set");
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        (, address strategyOwner, ) = proxiedManager.strategies(strategyId);
        if (strategyOwner != address(0)) {
            assertEq(owner, strategyOwner, "Strategy owner");
        }
    }

    function checkObligationInfo(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 expectedPercentage,
        bool expectedIsSet,
        SSVBasedApps proxiedManager
    ) internal view {
        (uint32 percentage, bool isSet) = proxiedManager.obligations(
            strategyId,
            bApp,
            token
        );
        assertEq(percentage, expectedPercentage, "Obligation percentage");
        assertEq(isSet, expectedIsSet, "Obligation is set");
    }

    function checkSlashableBalance(
        uint32 strategyId,
        address bApp,
        address token,
        uint256 expectedSlashableBalance
    ) internal view {
        uint256 slashableBalance = proxiedManager.getSlashableBalance(
            strategyId,
            bApp,
            token
        );
        assertEq(
            slashableBalance,
            expectedSlashableBalance,
            "Should match the expected slashable balance"
        );
    }

    function checkSlashingFund(
        address account,
        address token,
        uint256 expectedAmount
    ) internal view {
        uint256 slashingFund = proxiedManager.slashingFund(account, token);
        assertEq(
            slashingFund,
            expectedAmount,
            "Should match the expected slashing fund balance"
        );
    }

    function checkGeneration(
        uint32 strategyId,
        address token,
        uint256 expectedValue
    ) internal view {
        proxiedManager.strategyGeneration(strategyId, token);
        assertEq(
            proxiedManager.strategyGeneration(strategyId, token),
            expectedValue,
            "Should match the expected generation number"
        );
    }

    function checkTotalSharesAndTotalBalance(
        uint32 strategyId,
        address token,
        uint256 expectedTotalShares,
        uint256 expectedTotalBalance
    ) internal view {
        uint256 totalShares = proxiedManager.strategyTotalShares(
            strategyId,
            token
        );
        assertEq(
            totalShares,
            expectedTotalShares,
            "Should match the expected total shares"
        );
        uint256 totalBalance = proxiedManager.strategyTotalBalance(
            strategyId,
            token
        );
        assertEq(
            totalBalance,
            expectedTotalBalance,
            "Should match the expected total balance"
        );
    }

    function checkAccountShares(
        uint32 strategyId,
        address owner,
        address token,
        uint256 expectedShares
    ) internal view {
        uint256 accountShares = proxiedManager.strategyAccountShares(
            strategyId,
            owner,
            token
        );
        assertEq(
            accountShares,
            expectedShares,
            "Should match the expected account shares"
        );
    }

    function checkProposedFee(
        uint32 strategyId,
        address expectedOwner,
        uint32 expectedInitialFee,
        uint32 expectedProposedFee,
        uint256 expectedUpdateTime
    ) internal view {
        (, address owner, uint32 fee) = proxiedManager.strategies(strategyId);
        (uint32 feeProposed, uint256 feeUpdateTime) = proxiedManager
            .feeUpdateRequests(strategyId);
        assertEq(
            owner,
            expectedOwner,
            "Should match the expected strategy owner"
        );
        assertEq(
            fee,
            expectedInitialFee,
            "Should match the expected current strategy fee"
        );
        assertEq(
            feeProposed,
            expectedProposedFee,
            "Should match the expected strategy fee proposed"
        );
        assertEq(
            feeUpdateTime,
            expectedUpdateTime,
            "Should match the expected fee update time"
        );
    }

    function checkFee(
        uint32 strategyId,
        address expectedOwner,
        uint32 expectedFee
    ) internal view {
        (, address owner, uint32 fee) = proxiedManager.strategies(strategyId);
        assertEq(
            owner,
            expectedOwner,
            "Should match the expected strategy owner"
        );
        assertEq(fee, expectedFee, "Should match the expected fee percentage");
    }

    function checkProposedObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 expectedCurrentPercentage,
        uint32 expectedProposedPercentage,
        uint256 expectedRequestTime,
        bool expectedIsSet
    ) internal view {
        (uint32 proposedPercentage, uint256 requestTime) = proxiedManager
            .obligationRequests(strategyId, token, bApp);
        (uint32 oldPercentage, bool isSet) = proxiedManager.obligations(
            strategyId,
            bApp,
            token
        );
        assertEq(isSet, expectedIsSet, "Should match the expected isSet value");
        assertEq(
            oldPercentage,
            expectedCurrentPercentage,
            "Should match the expected current obligation percentage"
        );
        assertEq(
            proposedPercentage,
            expectedProposedPercentage,
            "Should match the expected proposed obligation percentage"
        );
        assertEq(
            requestTime,
            expectedRequestTime,
            "Should match the expected obligation request time"
        );
    }

    function checkProposedWithdrawal(
        uint32 strategyId,
        address owner,
        address token,
        uint256 expectedRequestTime,
        uint256 expectedAmount
    ) internal view {
        (uint256 amount, uint256 requestTime) = proxiedManager
            .withdrawalRequests(strategyId, owner, token);
        assertEq(
            requestTime,
            expectedRequestTime,
            "Should match the expected request time"
        );
        assertEq(
            amount,
            expectedAmount,
            "Should match the expected request amount"
        );
    }

    function checkAdjustedPercentage(
        address token,
        uint256 previousBalance,
        uint256 slashAmount,
        uint32 previousPercentage
    ) internal view returns (uint32) {
        uint256 previousObligatedBalance = (previousPercentage *
            previousBalance) / proxiedManager.maxPercentage();
        uint256 newObligatedBalance = previousObligatedBalance - slashAmount;
        uint256 newTotalBalance = previousBalance - slashAmount;
        uint32 expectedAdjustedPercentage = uint32(
            (newObligatedBalance * proxiedManager.maxPercentage()) /
                newTotalBalance
        );
        (uint32 adjustedPercentage, ) = proxiedManager.obligations(
            STRATEGY1,
            address(bApp3),
            token
        );
        assertEq(
            adjustedPercentage,
            expectedAdjustedPercentage,
            "Should match the calculated percentage with the one saved in storage"
        );
        return adjustedPercentage;
    }

    function checkBAppUpdatedTokens(
        ICore.TokenConfig[] memory tokenConfigs,
        address bApp
    ) internal view {
        bool isRegistered = proxiedManager.registeredBApps(bApp);
        assertEq(isRegistered, true, "BApp registered");
        for (uint32 i = 0; i < tokenConfigs.length; i++) {
            (
                ,
                bool isSet,
                uint32 pendingValue,
                uint32 effectiveTime
            ) = proxiedManager.bAppTokens(bApp, tokenConfigs[i].token);
            assertEq(
                tokenConfigs[i].sharedRiskLevel,
                pendingValue,
                "BApp risk level percentage"
            );
            assertNotEq(effectiveTime, 0);
            assertEq(isSet, true, "BApp token set");
        }
    }

    function calculateSlashAmount(
        uint256 depositAmount,
        uint32 obligationPercentage,
        uint32 slashingPercentage
    ) internal view returns (uint256) {
        uint256 obligatedAmount = (depositAmount * obligationPercentage) /
            proxiedManager.maxPercentage();
        return ((obligatedAmount * slashingPercentage) /
            proxiedManager.maxPercentage());
    }

    function createSlashContext(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 percentage
    ) public pure returns (ICore.SlashContext memory c) {
        c.strategyId = strategyId;
        c.bApp = bApp;
        c.token = token;
        c.percentage = percentage;
        return c;
    }
}
