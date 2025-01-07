// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasedAppManager {
    event StrategyCreated(uint256 indexed strategyId, address indexed owner);
    event ServiceRegistered(address indexed serviceAddress, address indexed owner, address from);
    event ServiceTokensUpdated(address indexed serviceAddress, address[] tokens);
    event DelegatedBalance(address indexed delegator, address indexed receiver, uint32 percentage);
    event RemoveDelegatedBalance(address indexed delegator, address indexed receiver);
    event StrategyDeposit(
        uint256 indexed strategyId, address indexed contributor, address indexed token, uint256 amount
    );
    event StrategyWithdrawal(
        uint256 indexed strategyId, address indexed contributor, address indexed token, uint256 amount
    );
    event ServiceOptedIn(uint256 indexed strategyId, address indexed service);
    event ServiceObligationSet(
        uint256 indexed strategyId, address indexed service, address indexed token, uint256 obligationPercentage
    );
    event ServiceObligationUpdated(
        uint256 indexed strategyId, address indexed service, address indexed token, uint256 obligationPercentage
    );
    event StrategyFeeUpdateRequested(
        uint256 indexed strategyId, address owner, uint32 proposedFee, uint32 fee, uint256 expirationTime
    );
    event StrategyFeeUpdated(uint256 indexed strategyId, address owner, uint32 fee, uint32 oldFee);
    event WithdrawalProposed(
        uint256 indexed strategyId, address indexed account, address indexed token, uint256 amount, uint256 finalizeTime
    );
    event WithdrawalFinalized(
        uint256 indexed strategyId, address indexed account, address indexed token, uint256 amount
    );
    event ObligationUpdateProposed(
        uint256 indexed strategyId,
        address indexed account,
        address indexed token,
        uint32 percentage,
        uint256 finalizeTime
    );
    event ObligationUpdateFinalized(
        uint256 indexed strategyId, address indexed account, address indexed token, uint32 percentage
    );

    function delegateBalance(address receiver, uint32 percentage) external;

    function updateDelegatedBalance(address receiver, uint32 percentage) external;

    function removeDelegatedBalance(address receiver) external;

    function registerService(
        address owner,
        address serviceAddress,
        address[] calldata tokens,
        uint32 sharedRiskLevel,
        uint32 slashingCorrelationPenalty
    ) external;

    function addTokensToService(address serviceAddress, address[] calldata tokens) external;

    function getServiceTokens(address serviceAddress) external view returns (address[] memory);

    function createStrategy(uint32 fee) external returns (uint256 strategyId);

    function optInToService(
        uint256 strategyId,
        address service,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages
    ) external;

    function depositERC20(uint256 strategyId, IERC20 token, uint256 amount) external;

    function fastWithdrawERC20(uint256 strategyId, IERC20 token, uint256 amount) external;

    function proposeWithdrawal(uint256 strategyId, address token, uint256 amount) external;

    function finalizeWithdrawal(uint256 strategyId, IERC20 token) external;

    function depositETH(uint256 strategyId) external payable;

    function fastWithdrawETH(uint256 strategyId, uint256 amount) external;

    function createObligation(
        uint256 strategyId,
        address service,
        address token,
        uint32 obligationPercentage
    ) external;

    function fastUpdateObligation(
        uint256 strategyId,
        address service,
        address token,
        uint32 obligationPercentage
    ) external;

    function fastRemoveObligation(uint256 strategyId, address service, address token) external;

    function proposeUpdateObligation(
        uint256 strategyId,
        address service,
        address token,
        uint32 obligationPercentage
    ) external;

    function finalizeUpdateObligation(uint256 strategyId, address service, address token) external;

    function proposeFeeUpdate(uint256 strategyId, uint32 proposedFee) external;

    function finalizeFeeUpdate(uint256 strategyId) external;
}