// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IStorage {
    /// @notice Represents a SharedRiskLevel
    struct SharedRiskLevel {
        /// @dev The shared risk level
        /// Encoding: The value is stored as a uint32. However, it represents a real (float) value. To get the actual real value (decode), divide by 10^6.
        uint32 value;
        /// @dev if the shared risk level is set
        bool isSet;
    }

    /// @notice Represents an Obligation
    struct Obligation {
        /// @dev The obligation percentage
        uint32 percentage;
        /// @dev if the obligation is set
        bool isSet;
    }

    /// @notice Represents a Strategy
    struct Strategy {
        /// @dev The owner of the strategy
        address owner;
        /// @dev The fee in percentage
        uint32 fee;
        /// @dev The proposed fee
        uint32 feeProposed;
        /// @dev The block time when the fee update request was sent
        uint32 feeRequestTime;
    }

    /// @notice Represents a request for a withdrawal from a participant of a strategy
    struct WithdrawalRequest {
        /// @dev The amount requested to withdraw
        uint256 amount;
        /// @dev The block time when the withdrawal request was sent
        uint32 requestTime;
    }

    /// @notice Represents a change in the obligation in a strategy. Only the owner can submit one.
    struct ObligationRequest {
        /// @dev The new obligation percentage
        uint32 percentage;
        /// @dev The block time when the update obligation request was sent
        uint32 requestTime;
    }

    error BAppAlreadyOptedIn();
    error BAppAlreadyRegistered();
    error BAppNotOptedIn();
    error BAppOptInFailed();
    error BAppDoesNotSupportInterface();
    error DelegationAlreadyExists();
    error DelegationDoesNotExist();
    error DelegationExistsWithSameValue();
    error DelegateCallFailed(bytes returnData);
    error EmptyTokenList();
    error ExceedingPercentageUpdate();
    error FeeAlreadySet();
    error InsufficientBalance();
    error InvalidAmount();
    error InvalidBAppOwner(address caller, address expectedOwner);
    error InvalidMaxFeeIncrement();
    error InvalidPercentage();
    error InvalidPercentageIncrement();
    error InvalidSharedRiskLevel();
    error InvalidStrategyFee();
    error InvalidStrategyOwner(address caller, address expectedOwner);
    error InvalidToken();
    error LengthsNotMatching();
    error NoPendingFeeUpdate();
    error NoPendingObligationUpdate();
    error NoPendingWithdrawal();
    error NoPendingWithdrawalETH();
    error ObligationAlreadySet();
    error ObligationHasNotBeenCreated();
    error PercentageAlreadySet();
    error RequestTimeExpired();
    error SharedRiskLevelAlreadySet();
    error TimelockNotElapsed();
    error TokenAlreadyAddedToBApp(address token);
    error TokenIsUsedByTheBApp();
    error TokenNoTSupportedByBApp(address token);
    error UpdateObligationExpired();
    error ZeroAddressNotAllowed();
}
