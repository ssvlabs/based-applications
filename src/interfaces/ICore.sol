// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface ICore {
    /// @notice Represents a SharedRiskLevel
    struct SharedRiskLevel {
        /// @dev The shared risk level
        /// Encoding: The value is stored as a uint32. However, it represents a real (float) value.
        /// To get the actual real value (decode), divide by 10^6.
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
        /// @dev The current generation is used to track full slashing events, since we cannot reset mapping in solidity
        /// It is incremented when a full slashing event occurs
        uint256 currentGeneration;
        /// @dev The account share balance
        mapping(address => uint256) accountShareBalance;
        /// @dev The account generation
        mapping(address => uint256) accountGeneration;
    }

    error BAppAlreadyOptedIn();
    error BAppAlreadyRegistered();
    error BAppDoesNotSupportInterface();
    error BAppNotOptedIn();
    error BAppNotRegistered();
    error BAppOptInFailed();
    error BAppSlashingFailed();
    error DelegateCallFailed(bytes returnData);
    error DelegationAlreadyExists();
    error DelegationDoesNotExist();
    error DelegationExistsWithSameValue();
    error EmptyTokenList();
    error ExceedingMaxShares();
    error ExceedingPercentageUpdate();
    error FeeAlreadySet();
    error InsufficientBalance();
    error InsufficientLiquidity();
    error InvalidAccountGeneration();
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
    error NoPendingTokenRemoval();
    error NoPendingTokenUpdate();
    error NoPendingWithdrawal();
    error ObligationAlreadySet();
    error ObligationHasNotBeenCreated();
    error PercentageAlreadySet();
    error RequestTimeExpired();
    error SharedRiskLevelAlreadySet();
    error TargetModuleDoesNotExistWithData(uint8 moduleId); // 0x208bb85d
    error TimelockNotElapsed();
    error TokenAlreadyAddedToBApp(address token);
    error TokenIsUsedByTheBApp();
    error TokenNotSupportedByBApp(address token);
    error UpdateObligationExpired();
    error ZeroAddressNotAllowed();
}
