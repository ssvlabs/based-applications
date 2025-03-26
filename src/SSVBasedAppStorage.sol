// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IStorage} from "@ssv/src/interfaces/IStorage.sol";
import {ISSVBasedApps} from "@ssv/src/interfaces/ISSVBasedApps.sol";

abstract contract SSVBasedAppStorage is ISSVBasedApps {
    uint32 public feeTimelockPeriod = 7 days;
    uint32 public feeExpireTime = 1 days;
    uint32 public withdrawalTimelockPeriod = 5 days;
    uint32 public withdrawalExpireTime = 1 days;
    uint32 public obligationTimelockPeriod = 7 days;
    uint32 public obligationExpireTime = 1 days;
    uint32 public maxPercentage = 1e4;
    address public ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public maxShares = 1e50;
    uint32 public maxFeeIncrement;

    uint32 internal _strategyCounter;

    /**
     * @notice Tracks the strategies created
     * @dev The strategy ID is incremental and unique
     */
    mapping(uint32 strategyId => IStorage.Strategy) public strategies;
    /**
     * @notice Links an account to a single strategy for a specific bApp
     * @dev Guarantees that an account cannot have more than one strategy for a given bApp
     */
    mapping(address account => mapping(address bApp => uint32 strategyId)) public accountBAppStrategy;
    /**
     * @notice Tracks the percentage of validator balance a delegator has delegated to a specific receiver account
     * @dev Each delegator can allocate a portion of their validator balance to multiple accounts including itself
     */
    mapping(address delegator => mapping(address account => uint32 percentage)) public delegations;
    /**
     * @notice Tracks the total percentage of validator balance a delegator has delegated across all receiver accounts
     * @dev Ensures that a delegator cannot delegate more than 100% of their validator balance
     */
    mapping(address delegator => uint32 totalPercentage) public totalDelegatedPercentage;
    /**
     * @notice Tracks the token shares for individual strategies.
     * @dev Tracks that how much shares an account owns in a specific strategy.
     */
    mapping(uint32 strategyId => mapping(address account => mapping(address token => uint256 balance))) public
        strategyAccountShares;
    /**
     * @notice Tracks the total balance for individual strategies.
     * @dev Tracks that how much token balance a strategy has.
     */
    mapping(uint32 strategyId => mapping(address token => uint256 balance)) public strategyTotalBalance;
    /**
     * @notice Tracks the total shares for individual strategies.
     * @dev Tracks that how much share balance a strategy has.
     */
    mapping(uint32 strategyId => mapping(address token => uint256 balance)) public strategyTotalShares;
    /**
     * @notice Tracks obligation percentages for a strategy based on specific bApps and tokens.
     * @dev Uses a hash of the bApp and token to map the obligation percentage for the strategy.
     */
    mapping(uint32 strategyId => mapping(address bApp => mapping(address token => IStorage.Obligation))) public obligations;
    /**
     * @notice Tracks unallocated tokens in a strategy.
     * @dev Count the number of bApps that have one obligation set for the token.
     * If the counter is 0, the token is unused and we can allow fast withdrawal.
     */
    mapping(uint32 strategyId => mapping(address token => uint32 bAppsCounter)) public usedTokens;
    /**
     * @notice Tracks all the withdrawal requests divided by token per strategy.
     * @dev User can have only one pending withdrawal request per token.
     *  Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint32 strategyId => mapping(address account => mapping(address token => IStorage.WithdrawalRequest))) public
        withdrawalRequests;
    /**
     * @notice Tracks all the obligation change requests divided by token per strategy.
     * @dev Strategy can have only one pending obligation change request per token.
     * Only the strategy owner can submit one.
     * Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint32 strategyId => mapping(address token => mapping(address bApp => IStorage.ObligationRequest))) public
        obligationRequests;
    /**
     * @notice Tracks the fee update requests for a strategy
     * @dev Only the strategy owner can submit one.
     * Submitting a new request will overwrite the previous one and reset the timer.
     */
    mapping(uint32 strategyId => IStorage.FeeUpdateRequest) public feeUpdateRequests;
    /**
     * @notice Tracks the slashing fund for a specific token
     * @dev The slashing fund is used to store the tokens that are slashed from the strategies
     */
    mapping(address owner => mapping(address token => uint256 amount)) public slashingFund;
}
