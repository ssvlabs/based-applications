# SSVBasedApps
[Git Source](https://github.com/ssvlabs/based-applications/blob/506ac6ae02f84ad3df44eadfe12c8fc0cb108f44/src/core/SSVBasedApps.sol)

**Inherits:**
[ISSVBasedApps](/src/core/interfaces/ISSVBasedApps.sol/interface.ISSVBasedApps.md), UUPSUpgradeable, Ownable2StepUpgradeable, [IBasedAppManager](/src/core/interfaces/IBasedAppManager.sol/interface.IBasedAppManager.md), [IStrategyManager](/src/core/interfaces/IStrategyManager.sol/interface.IStrategyManager.md), [IProtocolManager](/src/core/interfaces/IProtocolManager.sol/interface.IProtocolManager.md)

**Author:**

Marco Tabasco
Riccardo Persiani

The Core Contract to manage Based Applications, Validator Balance Delegations & Strategies for SSV Based Applications Platform.
GLOSSARY **

*The following terms are used throughout the contract:
- **Account**: An Ethereum address that can:
1. Delegate its balance to another address.
2. Create and manage a strategy.
3. Create and manage or be a bApp.
- **Based Application**: or bApp.
The entity that requests validation services from operators. On-chain is represented by an Ethereum address.
A bApp can be created by registering to this Core Contract, specifying the risk level.
The bApp can also specify one or many tokens as slashable capital to be provided by strategies.
During the bApp registration, the bApp owner can set the shared risk level and optionally a metadata URI, to be used in the SSV bApp marketplace.
- **Delegator**: An Ethereum address that has Ethereum Validator Balance of Staked ETH within the SSV platform. This capital delegated is non-slashable.
The delegator can decide to delegate its balance to itself or/and to a single or many receiver accounts.
The delegator has to set its address as the receiver account, when the delegator wants to delegate its balance to itself.
The delegated balance goes to an account and not to a strategy. This receiver account can manage only a single strategy.
- **Strategy**: The entity that manages the slashable assets bounded to based apps.
The strategy has its own balance, accounted in this core contract.
The strategy can be created by an account that becomes its owner.
The assets can be ERC20 tokens or Native ETH tokens, that can be deposited or withdrawn by the participants.
The strategy can manage its assets via s.obligations to one or many bApps.
- **Obligation**: A percentage of the strategy's balance of ERC20 (or Native ETH), that is reserved for securing a bApp.
The obligation is set exclusively by the strategy owner and can be updated by the strategy owner.
The tokens specified in an obligation needs to match the tokens specified in the bApp.
AUTHORS ***


## Functions
### initialize


```solidity
function initialize(
    address owner_,
    IBasedAppManager ssvBasedAppManger_,
    IStrategyManager ssvStrategyManager_,
    IProtocolManager protocolManager_,
    ProtocolStorageLib.Data calldata config
) external override initializer onlyProxy;
```

### __SSVBasedApplications_init_unchained


```solidity
function __SSVBasedApplications_init_unchained(
    IBasedAppManager ssvBasedAppManger_,
    IStrategyManager ssvStrategyManager_,
    IProtocolManager protocolManager_,
    ProtocolStorageLib.Data calldata config
) internal onlyInitializing;
```

### constructor

**Note:**
oz-upgrades-unsafe-allow: constructor


```solidity
constructor();
```

### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address) internal override onlyOwner;
```

### updateBAppMetadataURI


```solidity
function updateBAppMetadataURI(string calldata metadataURI) external;
```

### registerBApp


```solidity
function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;
```

### updateBAppsTokens


```solidity
function updateBAppsTokens(ICore.TokenConfig[] calldata tokenConfigs) external;
```

### createObligation


```solidity
function createObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external;
```

### createStrategy


```solidity
function createStrategy(uint32 fee, string calldata metadataURI) external returns (uint32 strategyId);
```

### delegateBalance


```solidity
function delegateBalance(address receiver, uint32 percentage) external;
```

### depositERC20


```solidity
function depositERC20(uint32 strategyId, IERC20 token, uint256 amount) external;
```

### depositETH


```solidity
function depositETH(uint32 strategyId) external payable;
```

### finalizeFeeUpdate


```solidity
function finalizeFeeUpdate(uint32 strategyId) external;
```

### finalizeUpdateObligation


```solidity
function finalizeUpdateObligation(uint32 strategyId, address bApp, address token) external;
```

### finalizeWithdrawal


```solidity
function finalizeWithdrawal(uint32 strategyId, IERC20 token) external;
```

### finalizeWithdrawalETH


```solidity
function finalizeWithdrawalETH(uint32 strategyId) external;
```

### getSlashableBalance


```solidity
function getSlashableBalance(uint32 strategyId, address bApp, address token) public view returns (uint256 slashableBalance);
```

### proposeFeeUpdate


```solidity
function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external;
```

### proposeUpdateObligation


```solidity
function proposeUpdateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external;
```

### proposeWithdrawal


```solidity
function proposeWithdrawal(uint32 strategyId, address token, uint256 amount) external;
```

### proposeWithdrawalETH


```solidity
function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external;
```

### reduceFee


```solidity
function reduceFee(uint32 strategyId, uint32 proposedFee) external;
```

### removeDelegatedBalance


```solidity
function removeDelegatedBalance(address receiver) external;
```

### updateDelegatedBalance


```solidity
function updateDelegatedBalance(address receiver, uint32 percentage) external;
```

### updateStrategyMetadataURI


```solidity
function updateStrategyMetadataURI(uint32 strategyId, string calldata metadataURI) external;
```

### updateAccountMetadataURI


```solidity
function updateAccountMetadataURI(string calldata metadataURI) external;
```

### slash


```solidity
function slash(uint32 strategyId, address bApp, address token, uint32 percentage, bytes calldata data) external;
```

### withdrawSlashingFund


```solidity
function withdrawSlashingFund(address token, uint256 amount) external;
```

### withdrawETHSlashingFund


```solidity
function withdrawETHSlashingFund(uint256 amount) external;
```

### optInToBApp


```solidity
function optInToBApp(uint32 strategyId, address bApp, address[] calldata tokens, uint32[] calldata obligationPercentages, bytes calldata data) external;
```

### updateFeeTimelockPeriod


```solidity
function updateFeeTimelockPeriod(uint32 value) external onlyOwner;
```

### updateFeeExpireTime


```solidity
function updateFeeExpireTime(uint32 value) external onlyOwner;
```

### updateWithdrawalTimelockPeriod


```solidity
function updateWithdrawalTimelockPeriod(uint32 value) external onlyOwner;
```

### updateWithdrawalExpireTime


```solidity
function updateWithdrawalExpireTime(uint32 value) external onlyOwner;
```

### updateObligationTimelockPeriod


```solidity
function updateObligationTimelockPeriod(uint32 value) external onlyOwner;
```

### updateObligationExpireTime


```solidity
function updateObligationExpireTime(uint32 value) external onlyOwner;
```

### updateTokenUpdateTimelockPeriod


```solidity
function updateTokenUpdateTimelockPeriod(uint32 value) external onlyOwner;
```

### updateMaxShares


```solidity
function updateMaxShares(uint256 value) external onlyOwner;
```

### updateMaxFeeIncrement


```solidity
function updateMaxFeeIncrement(uint32 value) external onlyOwner;
```

### updateDisabledFeatures


```solidity
function updateDisabledFeatures(uint32 disabledFeatures) external onlyOwner;
```

### delegations


```solidity
function delegations(address account, address receiver) external view returns (uint32);
```

### totalDelegatedPercentage


```solidity
function totalDelegatedPercentage(address delegator) external view returns (uint32);
```

### registeredBApps


```solidity
function registeredBApps(address bApp) external view returns (bool isRegistered);
```

### strategies


```solidity
function strategies(uint32 strategyId) external view returns (address strategyOwner, uint32 fee);
```

### ownedStrategies


```solidity
function ownedStrategies(address owner) external view returns (uint32[] memory strategyIds);
```

### strategyAccountShares


```solidity
function strategyAccountShares(uint32 strategyId, address account, address token) external view returns (uint256);
```

### strategyTotalBalance


```solidity
function strategyTotalBalance(uint32 strategyId, address token) external view returns (uint256);
```

### strategyTotalShares


```solidity
function strategyTotalShares(uint32 strategyId, address token) external view returns (uint256);
```

### strategyGeneration


```solidity
function strategyGeneration(uint32 strategyId, address token) external view returns (uint256);
```

### obligations


```solidity
function obligations(uint32 strategyId, address bApp, address token) external view returns (uint32 percentage, bool isSet);
```

### bAppTokens


```solidity
function bAppTokens(address bApp, address token) external view returns (uint32 currentValue, bool isSet, uint32 pendingValue, uint32 effectTime);
```

### accountBAppStrategy


```solidity
function accountBAppStrategy(address account, address bApp) external view returns (uint32);
```

### feeUpdateRequests


```solidity
function feeUpdateRequests(uint32 strategyId) external view returns (uint32 percentage, uint32 requestTime);
```

### withdrawalRequests


```solidity
function withdrawalRequests(uint32 strategyId, address account, address token) external view returns (uint256 shares, uint32 requestTime);
```

### obligationRequests


```solidity
function obligationRequests(uint32 strategyId, address token, address bApp) external view returns (uint32 percentage, uint32 requestTime);
```

### slashingFund


```solidity
function slashingFund(address account, address token) external view returns (uint256);
```

### maxPercentage


```solidity
function maxPercentage() external pure returns (uint32);
```

### ethAddress


```solidity
function ethAddress() external pure returns (address);
```

### maxShares


```solidity
function maxShares() external view returns (uint256);
```

### maxFeeIncrement


```solidity
function maxFeeIncrement() external view returns (uint32);
```

### feeTimelockPeriod


```solidity
function feeTimelockPeriod() external view returns (uint32);
```

### feeExpireTime


```solidity
function feeExpireTime() external view returns (uint32);
```

### withdrawalTimelockPeriod


```solidity
function withdrawalTimelockPeriod() external view returns (uint32);
```

### withdrawalExpireTime


```solidity
function withdrawalExpireTime() external view returns (uint32);
```

### obligationTimelockPeriod


```solidity
function obligationTimelockPeriod() external view returns (uint32);
```

### obligationExpireTime


```solidity
function obligationExpireTime() external view returns (uint32);
```

### disabledFeatures


```solidity
function disabledFeatures() external view returns (uint32);
```

### tokenUpdateTimelockPeriod


```solidity
function tokenUpdateTimelockPeriod() external view returns (uint32);
```

### getVersion


```solidity
function getVersion() external pure returns (string memory);
```

### getModuleAddress

Retrieves the currently configured Module contract address.


```solidity
function getModuleAddress(SSVCoreModules moduleId) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`SSVCoreModules`|The ID of the SSV Module.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the SSV Module.|


### updateModule


```solidity
function updateModule(SSVCoreModules[] calldata moduleIds, address[] calldata moduleAddresses) external onlyOwner;
```

### _delegateTo


```solidity
function _delegateTo(SSVCoreModules moduleId) internal;
```

