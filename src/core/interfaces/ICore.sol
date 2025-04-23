// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface ICore {
    /// @notice Represents a SharedRiskLevel
    struct SharedRiskLevel {
        /// @dev The shared risk level
        /// Encoding: The value is stored as a uint32. However, it represents a real (float) value.
        /// To get the actual real value (decode), divide by 10^6.
        uint32 currentValue;
        /// @dev if the shared risk level is set
        bool isSet;
        /// @dev The value to be updated
        uint32 pendingValue;
        /// @dev The block time when the update request was sent
        uint32 effectTime;
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
    }

    /// @notice Represents a FeeUpdateRequest
    struct FeeUpdateRequest {
        /// @dev The new fee percentage
        uint32 percentage;
        /// @dev The block time when the update fee request was sent
        uint32 requestTime;
    }

    /// @notice Represents a request for a withdrawal from a participant of a strategy
    struct WithdrawalRequest {
        /// @dev The shares requested to withdraw
        uint256 shares;
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

    /// @notice Represents the shares system of a strategy
    struct Shares {
        /// @dev The total token balance
        uint256 totalTokenBalance;
        /// @dev The total share balance
        uint256 totalShareBalance;
        /// @dev The current generation
        /// A generation (or versioning) system is required due to full slashing events.
        /// After such an event, the generation counter is bumped so that previous shares become outdated and are no longer able to be withdrawn.
        uint256 currentGeneration;
        /// @dev The account share balance
        mapping(address => uint256) accountShareBalance;
        /// @dev The account latest generation
        mapping(address => uint256) accountGeneration;
    }

    struct TokenUpdateRequest {
        TokenConfig[] tokens;
        uint32 requestTime;
    }

    struct TokenConfig {
        address token;
        uint32 sharedRiskLevel;
    }
}
