// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface ICore {
    /// @notice Represents an AVS
    struct BApp {
        /// @dev The owner of the bApp
        address owner;
        /// @dev The erc20 tokens the bApp accepts (can accept multiple)
        address[] tokens;
        /// @dev beta parameter
        uint32 sharedRiskLevel;
    }

    /// @notice Represents a Strategy
    struct Strategy {
        /// @dev The owner of the strategy
        address owner;
        /// @dev The fee in percentage
        uint32 fee;
        /// @dev The proposed fee
        uint32 feeProposed; // TODO: here is transparent, but could be moved outside in a separate mapping?
        /// @dev The proposed fee expiration time
        uint256 feeUpdateTime;
    }

    /// @notice Represents a request for a withdrawal from a participant of a strategy
    struct WithdrawalRequest {
        /// @dev The amount requested to withdraw
        uint256 amount;
        /// @dev The block time when the request was sent
        uint256 requestTime;
    }

    /// @notice Represents a change in the obligation in a strategy. Only the owner can submit one.
    struct ObligationRequest {
        /// @dev The new obligation percentage
        uint32 percentage;
        /// @dev The block time when the request was sent
        uint256 requestTime;
    }

    error BAppAlreadyOptedIn();
    error DelegationAlreadyExists();
    error InvalidAmount();
    error InvalidDelegationFee();
    error InvalidPercentage();
    error InsufficientBalance();
    error NoPendingWithdrawal();
    error InvalidStrategyOwner(address caller, address expectedOwner);
    error TokenAlreadyAddedToBApp(address token);
    error TokensLengthNotMatchingPercentages();
    error TokenIsUsedByTheBApp();
    error TimelockNotElapsed();
    error WithdrawalExpired();
    error ObligationAlreadySet();
}
