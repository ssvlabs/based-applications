// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { ICore } from "@ssv/src/core/interfaces/ICore.sol";

enum SSVCoreModules {
    SSV_PROTOCOL_MANAGER,
    SSV_BAPPS_MANAGER,
    SSV_STRATEGY_MANAGER
}

library CoreStorageLib {
    /// @title SSV Based Applications Storage Data
    /// @notice Represents all operational state required by the SSV Based Application platform.
    struct Data {
        uint32 _strategyCounter;
        /// @notice Maps each SSVCoreModules' module to its corresponding contract address
        mapping(SSVCoreModules => address) ssvContracts;
        /**
         * @notice Tracks the strategies created
         * @dev The strategy ID is incremental and unique
         */
        mapping(uint32 strategyId => ICore.Strategy) strategies;
        /**
         * @notice Links an account to a single strategy for a specific bApp
         * @dev Guarantees that an account cannot have more than one strategy for a given bApp
         */
        mapping(address account => mapping(address bApp => uint32 strategyId)) accountBAppStrategy;
        /**
         * @notice Tracks the percentage of validator balance a delegator has delegated to a specific receiver account
         * @dev Each delegator can allocate a portion of their validator balance to multiple accounts including itself
         */
        mapping(address delegator => mapping(address account => uint32 percentage)) delegations;
        /**
         * @notice Tracks the total percentage of validator balance a delegator has delegated across all receiver accounts
         * @dev Ensures that a delegator cannot delegate more than 100% of their validator balance
         */
        mapping(address delegator => uint32 totalPercentage) totalDelegatedPercentage;
        /**
         * @notice Tracks the total balance of shares and token for individual strategies,
         *  and also the balance of shares for individual accounts.
         * @dev Tracks that how much token balance a strategy has.
         */
        mapping(uint32 strategyId => mapping(address token => ICore.Shares shares)) strategyTokenShares;
        /**
         * @notice Tracks obligation percentages for a strategy based on specific bApps and tokens.
         * @dev Uses a hash of the bApp and token to map the obligation percentage for the strategy.
         */
        mapping(uint32 strategyId => mapping(address bApp => mapping(address token => ICore.Obligation))) obligations;
        /**
         * @notice Tracks unallocated tokens in a strategy.
         * @dev Count the number of bApps that have one obligation set for the token.
         * If the counter is 0, the token is unused and we can allow fast withdrawal.
         */
        mapping(uint32 strategyId => mapping(address token => uint32 bAppsCounter)) usedTokens;
        /**
         * @notice Tracks all the withdrawal requests divided by token per strategy.
         * @dev User can have only one pending withdrawal request per token.
         *  Submitting a new request will overwrite the previous one and reset the timer.
         */
        mapping(uint32 strategyId => mapping(address account => mapping(address token => ICore.WithdrawalRequest))) withdrawalRequests;
        /**
         * @notice Tracks all the obligation change requests divided by token per strategy.
         * @dev Strategy can have only one pending obligation change request per token.
         * Only the strategy owner can submit one.
         * Submitting a new request will overwrite the previous one and reset the timer.
         */
        mapping(uint32 strategyId => mapping(address token => mapping(address bApp => ICore.ObligationRequest))) obligationRequests;
        /**
         * @notice Tracks the fee update requests for a strategy
         * @dev Only the strategy owner can submit one.
         * Submitting a new request will overwrite the previous one and reset the timer.
         */
        mapping(uint32 strategyId => ICore.FeeUpdateRequest) feeUpdateRequests;
        /**
         * @notice Tracks the slashing fund for a specific token
         * @dev The slashing fund is used to store the tokens that are slashed from the strategies
         */
        mapping(address account => mapping(address token => uint256 amount)) slashingFund;
        /**
         * @notice Tracks the owners of the bApps
         * @dev The bApp is identified with its address
         */
        mapping(address bApp => bool isRegistered) registeredBApps;
        /**
         * @notice Tracks the tokens supported by the bApps
         * @dev The bApp is identified with its address
         */
        mapping(address bApp => mapping(address token => ICore.SharedRiskLevel)) bAppTokens;
    }

    uint256 private constant SSV_BASED_APPS_STORAGE_POSITION =
        uint256(keccak256("ssv.based-apps.storage.main")) - 1;

    function load() internal pure returns (Data storage sd) {
        uint256 position = SSV_BASED_APPS_STORAGE_POSITION;
        assembly {
            sd.slot := position
        }
    }
}
