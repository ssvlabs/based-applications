// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {BAppsCore} from "src/BAppsCore.sol";

contract TestUtils is Test {
    function createSingleTokenAndSingleRiskLevel(address token, uint32 sharedRiskLevel)
        internal
        pure
        returns (address[] memory tokensInput, uint32[] memory sharedRiskLevelInput)
    {
        tokensInput = new address[](1);
        tokensInput[0] = token;
        sharedRiskLevelInput = new uint32[](1);
        sharedRiskLevelInput[0] = sharedRiskLevel;
    }

    function createSingleTokenAndSingleObligationPercentage(address token, uint32 obligationPercentage)
        internal
        pure
        returns (address[] memory tokensInput, uint32[] memory obligationPercentageInput)
    {
        tokensInput = new address[](1);
        tokensInput[0] = token;
        obligationPercentageInput = new uint32[](1);
        obligationPercentageInput[0] = obligationPercentage;
    }

    function checkBAppInfo(address[] memory tokensInput, uint32[] memory riskLevelInput, address bApp, BAppsCore proxiedManager) internal view {
        assertEq(tokensInput.length, riskLevelInput.length, "BApp tokens and sharedRiskLevel length");
        bool isRegistered = proxiedManager.registeredBApps(bApp);
        assertEq(isRegistered, true, "BApp registered");
        for (uint32 i = 0; i < tokensInput.length; i++) {
            (uint32 sharedRiskLevel, bool isSet) = proxiedManager.bAppTokens(bApp, tokensInput[i]);
            assertEq(riskLevelInput[i], sharedRiskLevel, "BApp risk level percentage");
            assertEq(isSet, true, "BApp token set");
        }
    }

    function checkStrategyInfo(
        address owner,
        uint32 strategyId,
        address bApp,
        address token,
        uint32 percentage,
        BAppsCore proxiedManager,
        uint32 expectedTokens,
        bool expectedIsSet
    ) internal view {
        uint32 id = proxiedManager.accountBAppStrategy(owner, bApp);
        assertEq(strategyId, id, "Strategy id");
        (uint256 obligationPercentage, bool isSet) = proxiedManager.obligations(strategyId, bApp, token);
        assertEq(isSet, expectedIsSet, "Obligation is set");
        assertEq(obligationPercentage, percentage, "Obligation percentage");
        uint256 usedTokens = proxiedManager.usedTokens(strategyId, token);
        assertEq(usedTokens, expectedTokens, "Used tokens");
        (address strategyOwner,) = proxiedManager.strategies(strategyId);
        if (strategyOwner != address(0)) {
            assertEq(owner, strategyOwner, "Strategy owner");
        }
    }

    function checkObligationInfo(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 expectedPercentage,
        uint32 expectedUsedTokens,
        bool expectedIsSet,
        BAppsCore proxiedManager
    ) internal view {
        (uint32 percentage, bool isSet) = proxiedManager.obligations(strategyId, bApp, token);
        assertEq(percentage, expectedPercentage, "Obligation percentage");
        assertEq(isSet, expectedIsSet, "Obligation is set");
        uint32 usedTokens = proxiedManager.usedTokens(strategyId, token);
        assertEq(usedTokens, expectedUsedTokens, "Used tokens");
    }
}
