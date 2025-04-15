// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategyManager {
    event AccountMetadataURIUpdated(
        address indexed account,
        string metadataURI
    );
    event BAppOptedInByStrategy(
        uint32 indexed strategyId,
        address indexed bApp,
        bytes data,
        address[] tokens,
        uint32[] obligationPercentages
    );
    event DelegationCreated(
        address indexed delegator,
        address indexed receiver,
        uint32 percentage
    );
    event DelegationRemoved(
        address indexed delegator,
        address indexed receiver
    );
    event DelegationUpdated(
        address indexed delegator,
        address indexed receiver,
        uint32 percentage
    );
    event MaxFeeIncrementSet(uint32 newMaxFeeIncrement);
    event ObligationCreated(
        uint32 indexed strategyId,
        address indexed bApp,
        address token,
        uint32 percentage
    );
    event ObligationUpdated(
        uint32 indexed strategyId,
        address indexed bApp,
        address token,
        uint32 percentage
    );
    event ObligationUpdateProposed(
        uint32 indexed strategyId,
        address indexed bApp,
        address token,
        uint32 percentage
    );
    event StrategyCreated(
        uint32 indexed strategyId,
        address indexed owner,
        uint32 fee,
        string metadataURI
    );
    event StrategyDeposit(
        uint32 indexed strategyId,
        address indexed account,
        address token,
        uint256 amount
    );
    event StrategyFeeUpdated(
        uint32 indexed strategyId,
        address owner,
        uint32 newFee,
        bool isFast
    );
    event StrategyFeeUpdateProposed(
        uint32 indexed strategyId,
        address owner,
        uint32 proposedFee
    );
    event StrategyMetadataURIUpdated(
        uint32 indexed strategyId,
        string metadataURI
    );
    event StrategyWithdrawal(
        uint32 indexed strategyId,
        address indexed account,
        address token,
        uint256 amount,
        bool isFast
    );
    event StrategyWithdrawalProposed(
        uint32 indexed strategyId,
        address indexed account,
        address token,
        uint256 amount
    );
    event SlashingFundWithdrawn(address token, uint256 amount);
    event StrategySlashed(
        uint32 indexed strategyId,
        address indexed bApp,
        address token,
        uint256 amount,
        address receiver
    );

    function createObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external;
    function createStrategy(
        uint32 fee,
        string calldata metadataURI
    ) external returns (uint32 strategyId);
    function delegateBalance(address receiver, uint32 percentage) external;
    function depositERC20(
        uint32 strategyId,
        IERC20 token,
        uint256 amount
    ) external;
    function depositETH(uint32 strategyId) external payable;
    function finalizeFeeUpdate(uint32 strategyId) external;
    function finalizeUpdateObligation(
        uint32 strategyId,
        address bApp,
        address token
    ) external;
    function finalizeWithdrawal(uint32 strategyId, IERC20 token) external;
    function finalizeWithdrawalETH(uint32 strategyId) external;
    function optInToBApp(
        uint32 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external;
    function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external;
    function proposeUpdateObligation(
        uint32 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external;
    function proposeWithdrawal(
        uint32 strategyId,
        address token,
        uint256 amount
    ) external;
    function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external;
    function reduceFee(uint32 strategyId, uint32 proposedFee) external;
    function removeDelegatedBalance(address receiver) external;
    function slash(
        uint32 strategyId,
        address bApp,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;
    function updateAccountMetadataURI(string calldata metadataURI) external;
    function updateDelegatedBalance(
        address receiver,
        uint32 percentage
    ) external;
    function updateStrategyMetadataURI(
        uint32 strategyId,
        string calldata metadataURI
    ) external;
    function withdrawETHSlashingFund(uint256 amount) external;
    function withdrawSlashingFund(address token, uint256 amount) external;

    error BAppAlreadyOptedIn();
    error BAppNotOptedIn();
    error BAppOptInFailed();
    error BAppSlashingFailed();
    error DelegationAlreadyExists();
    error DelegationDoesNotExist();
    error DelegationExistsWithSameValue();
    error ExceedingMaxShares();
    error ExceedingPercentageUpdate();
    error FeeAlreadySet();
    error InsufficientBalance();
    error InsufficientLiquidity();
    error InvalidAccountGeneration();
    error InvalidAmount();
    error InvalidBAppOwner(address caller, address expectedOwner);
    error InvalidPercentageIncrement();
    error InvalidStrategyFee();
    error InvalidStrategyOwner(address caller, address expectedOwner);
    error InvalidToken();
    error NoPendingFeeUpdate();
    error NoPendingObligationUpdate();
    error NoPendingWithdrawal();
    error ObligationAlreadySet();
    error ObligationHasNotBeenCreated();
    error RequestTimeExpired();
    error TimelockNotElapsed();
    error TokenNotSupportedByBApp(address token);
    error WithdrawTransferFailed();
}
