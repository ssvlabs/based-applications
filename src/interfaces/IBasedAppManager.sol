// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasedAppManager {
    event BAppMetadataURIUpdated(address indexed bAppAddress, string metadataURI);
    event BAppTokensCreated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    event BAppTokensUpdated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    event DelegationCreated(address indexed delegator, address indexed receiver, uint32 percentage);
    event DelegationRemoved(address indexed delegator, address indexed receiver);
    event DelegationUpdated(address indexed delegator, address indexed receiver, uint32 percentage);
    event MaxFeeIncrementSet(uint32 newMaxFeeIncrement);
    event ObligationCreated(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage);
    event ObligationUpdated(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage, bool isFast);
    event ObligationUpdateProposed(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage);
    event StrategyCreated(uint32 indexed strategyId, address indexed owner, uint32 fee);
    event StrategyDeposit(uint32 indexed strategyId, address indexed account, address token, uint256 amount);
    event StrategyFeeUpdated(uint32 indexed strategyId, address owner, uint32 fee, uint32 oldFee);
    event StrategyFeeUpdateProposed(uint32 indexed strategyId, address owner, uint32 proposedFee, uint32 fee);
    event StrategyWithdrawal(uint32 indexed strategyId, address indexed account, address token, uint256 amount, bool isFast);
    event StrategyWithdrawalProposed(uint32 indexed strategyId, address indexed account, address token, uint256 amount);
    event BAppOptedInByStrategy(
        uint32 indexed strategyId, address indexed bApp, bytes data, address[] tokens, uint32[] obligationPercentages
    );
    event BAppRegistered(
        address indexed bAppAddress, address indexed owner, address[] tokens, uint32[] sharedRiskLevel, string metadataURI
    );

    function addTokensToBApp(address bAppAddress, address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function createObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external;

    function createStrategy(uint32 fee) external returns (uint32 strategyId);

    function delegateBalance(address receiver, uint32 percentage) external;

    function depositERC20(uint32 strategyId, IERC20 token, uint256 amount) external;

    function depositETH(uint32 strategyId) external payable;

    function fastUpdateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external;

    function fastWithdrawERC20(uint32 strategyId, IERC20 token, uint256 amount) external;

    function fastWithdrawETH(uint32 strategyId, uint256 amount) external;

    function finalizeFeeUpdate(uint32 strategyId) external;

    function finalizeUpdateObligation(uint32 strategyId, address bApp, address token) external;

    function finalizeWithdrawal(uint32 strategyId, IERC20 token) external;

    function finalizeWithdrawalETH(uint32 strategyId) external;

    function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external;

    function proposeUpdateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external;

    function proposeWithdrawal(uint32 strategyId, address token, uint256 amount) external;

    function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external;

    function removeDelegatedBalance(address receiver) external;

    function updateDelegatedBalance(address receiver, uint32 percentage) external;

    function updateMetadataURI(address bAppAddress, string calldata metadataURI) external;

    function optInToBApp(
        uint32 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external;

    function registerBApp(
        address bAppAddress,
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external;
}
