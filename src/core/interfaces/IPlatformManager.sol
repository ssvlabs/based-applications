// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.29;

interface IPlatformManager {
    event BAppMetadataURIUpdated(address indexed bAppAddress, string metadataURI);
    event BAppRegistered(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevel, string metadataURI);
    event BAppTokensCreated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);
    event BAppTokensRemoved(address indexed bAppAddress, address[] tokens);
    event BAppTokensUpdated(address indexed bAppAddress, address[] tokens, uint32[] sharedRiskLevels);

    event AccountMetadataURIUpdated(address indexed account, string metadataURI);
    event DelegationCreated(address indexed delegator, address indexed receiver, uint32 percentage);
    event DelegationRemoved(address indexed delegator, address indexed receiver);
    event DelegationUpdated(address indexed delegator, address indexed receiver, uint32 percentage);

    event EthAddressUpdated(address ethAddress);
    event FeeExpireTimeUpdated(uint32 feeExpireTime);
    event FeeTimelockPeriodUpdated(uint32 feeTimelockPeriod);
    event ObligationExpireTimeUpdated(uint32 obligationExpireTime);
    event ObligationTimelockPeriodUpdated(uint32 obligationTimelockPeriod);
    event StrategyMaxFeeIncrementUpdated(uint32 maxFeeIncrement);
    event StrategyMaxSharesUpdated(uint256 maxShares);
    event WithdrawalExpireTimeUpdated(uint32 withdrawalExpireTime);
    event WithdrawalTimelockPeriodUpdated(uint32 withdrawalTimelockPeriod);


    function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;
    function updateBAppMetadataURI(string calldata metadataURI) external;

    function delegateBalance(address receiver, uint32 percentage) external;
    function removeDelegatedBalance(address receiver) external;
    function updateAccountMetadataURI(string calldata metadataURI) external;
    function updateDelegatedBalance(address receiver, uint32 percentage) external;

    function updateFeeExpireTime(uint32 value) external;
    function updateFeeTimelockPeriod(uint32 value) external;
    function updateMaxFeeIncrement(uint32 value) external;
    function updateMaxShares(uint256 value) external;
    function updateObligationExpireTime(uint32 value) external;
    function updateObligationTimelockPeriod(uint32 value) external;
    function updateWithdrawalExpireTime(uint32 value) external;
    function updateWithdrawalTimelockPeriod(uint32 value) external;

    error BAppAlreadyRegistered();
    error BAppDoesNotSupportInterface();
    error BAppNotRegistered();
    error BAppSlashingFailed();
    error TokenAlreadyAddedToBApp(address token);
    error ZeroAddressNotAllowed();

    error DelegationAlreadyExists();
    error ExceedingPercentageUpdate();
    error DelegationDoesNotExist();
    error DelegationExistsWithSameValue();
}
