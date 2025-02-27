// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.28;

interface IBasedAppManager {
    // event AccountMetadataURIUpdated(address indexed account, string metadataURI);
    event BAppMetadataURIUpdated(address indexed bAppAddress, string metadataURI);
    event BAppTokensCreated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    event BAppTokensUpdated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    // event DelegationCreated(address indexed delegator, address indexed receiver, uint32 percentage);
    // event DelegationRemoved(address indexed delegator, address indexed receiver);
    // event DelegationUpdated(address indexed delegator, address indexed receiver, uint32 percentage);
    // event MaxFeeIncrementSet(uint32 newMaxFeeIncrement);
    // event ObligationCreated(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage);
    // event ObligationUpdated(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage, bool isFast);
    // event ObligationUpdateProposed(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage);
    // event StrategyCreated(uint32 indexed strategyId, address indexed owner, uint32 fee, string metadataURI);
    // event StrategyDeposit(uint32 indexed strategyId, address indexed account, address token, uint256 amount);
    // event StrategyFeeUpdated(uint32 indexed strategyId, address owner, uint32 fee, uint32 oldFee);
    // event StrategyFeeUpdateProposed(uint32 indexed strategyId, address owner, uint32 proposedFee, uint32 fee);
    // event StrategyWithdrawal(uint32 indexed strategyId, address indexed account, address token, uint256 amount, bool isFast);
    // event StrategyWithdrawalProposed(uint32 indexed strategyId, address indexed account, address token, uint256 amount);
    // event StrategyMetadataURIUpdated(uint32 indexed strategyId, string metadataURI);
    // event BAppOptedInByStrategy(
    //     uint32 indexed strategyId, address indexed bApp, bytes data, address[] tokens, uint32[] obligationPercentages
    // );
    event BAppRegistered(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevel, string metadataURI);

    function addTokensToBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function updateBAppTokens(address[] calldata tokens, uint32[] calldata sharedRiskLevels) external;

    function updateBAppMetadataURI(string calldata metadataURI) external;

    //    function updateStrategyMetadataURI(uint32 strategyId, string calldata metadataURI) external;

    //  function updateAccountMetadataURI(string calldata metadataURI) external;

    // function optInToBApp(
    //     uint32 strategyId,
    //     address bApp,
    //     address[] calldata tokens,
    //     uint32[] calldata obligationPercentages,
    //     bytes calldata data
    // ) external;

    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;
}
