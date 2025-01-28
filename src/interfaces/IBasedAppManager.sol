// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasedAppManager {
    event BAppMetadataURIUpdated(address indexed bAppAddress, string metadataURI);
    event BAppOptedInByStrategy(
        uint256 indexed strategyId, address indexed bApp, bytes data, address[] tokens, uint32[] obligationPercentages
    );
    event BAppRegistered(
        address indexed bAppAddress,
        address indexed owner,
        address[] tokens,
        uint32[] sharedRiskLevel,
        string metadataURI
    );
    event BAppTokensCreated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    event BAppTokensUpdated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    event DelegationCreated(address indexed delegator, address indexed receiver, uint32 percentage);
    event DelegationRemoved(address indexed delegator, address indexed receiver);
    event DelegationUpdated(address indexed delegator, address indexed receiver, uint32 percentage);
    event MaxFeeIncrementSet(uint32 indexed newMaxFeeIncrement);
    event ObligationCreated(
        uint256 indexed strategyId, address indexed bApp, address indexed token, uint256 obligationPercentage
    );
    event ObligationUpdated(
        uint256 indexed strategyId,
        address indexed bApp,
        address indexed token,
        uint256 obligationPercentage,
        bool isFast
    );
    event ObligationUpdateProposed(
        uint256 indexed strategyId,
        address indexed account,
        address indexed token,
        uint32 percentage,
        uint256 finalizeTime
    );
    event StrategyCreated(uint256 indexed strategyId, address indexed owner, uint32 fee);
    event StrategyDeposit(
        uint256 indexed strategyId, address indexed contributor, address indexed token, uint256 amount
    );
    event StrategyFeeUpdateProposed(
        uint256 indexed strategyId, address owner, uint32 proposedFee, uint32 fee, uint256 expirationTime
    );
    event StrategyFeeUpdated(uint256 indexed strategyId, address owner, uint32 fee, uint32 oldFee);
    event StrategyWithdrawal(
        uint256 indexed strategyId, address indexed contributor, address indexed token, uint256 amount, bool isFast
    );
    event StrategyWithdrawalProposed(
        uint256 indexed strategyId, address indexed account, address indexed token, uint256 amount, uint256 finalizeTime
    );

    function delegateBalance(address receiver, uint32 percentage) external;

    function updateDelegatedBalance(address receiver, uint32 percentage) external;

    function removeDelegatedBalance(
        address receiver
    ) external;

    function registerBApp(
        address bAppAddress,
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels,
        string calldata metadataURI
    ) external;

    function updateMetadataURI(address bAppAddress, string calldata metadataURI) external;

    function addTokensToBApp(
        address bAppAddress,
        address[] calldata tokens,
        uint32[] calldata sharedRiskLevels
    ) external;

    function createStrategy(
        uint32 fee
    ) external returns (uint256 strategyId);

    function optInToBApp(
        uint256 strategyId,
        address bApp,
        address[] calldata tokens,
        uint32[] calldata obligationPercentages,
        bytes calldata data
    ) external;

    function depositERC20(uint256 strategyId, IERC20 token, uint256 amount) external;

    function depositETH(
        uint256 strategyId
    ) external payable;

    function fastWithdrawERC20(uint256 strategyId, IERC20 token, uint256 amount) external;

    function fastWithdrawETH(uint256 strategyId, uint256 amount) external;

    function proposeWithdrawal(uint256 strategyId, address token, uint256 amount) external;

    function finalizeWithdrawal(uint256 strategyId, IERC20 token) external;

    function proposeWithdrawalETH(uint256 strategyId, uint256 amount) external;

    function finalizeWithdrawalETH(
        uint256 strategyId
    ) external;

    function createObligation(uint256 strategyId, address bApp, address token, uint32 obligationPercentage) external;

    function fastUpdateObligation(
        uint256 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external;

    function proposeUpdateObligation(
        uint256 strategyId,
        address bApp,
        address token,
        uint32 obligationPercentage
    ) external;

    function finalizeUpdateObligation(uint256 strategyId, address bApp, address token) external;

    function proposeFeeUpdate(uint256 strategyId, uint32 proposedFee) external;

    function finalizeFeeUpdate(
        uint256 strategyId
    ) external;
}
