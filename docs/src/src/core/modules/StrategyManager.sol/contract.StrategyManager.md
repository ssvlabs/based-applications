# StrategyManager
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/core/modules/StrategyManager.sol)

**Inherits:**
ReentrancyGuardTransient, [IStrategyManager](/src/core/interfaces/IStrategyManager.sol/interface.IStrategyManager.md)


## State Variables
### SLASHING_DISABLED

```solidity
uint32 private constant SLASHING_DISABLED = 1 << 0;
```


### WITHDRAWALS_DISABLED

```solidity
uint32 private constant WITHDRAWALS_DISABLED = 1 << 1;
```


## Functions
### _onlyStrategyOwner

Checks if the caller is the strategy owner


```solidity
function _onlyStrategyOwner(uint32 strategyId, CoreStorageLib.Data storage s) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`s`|`CoreStorageLib.Data`|The CoreStorageLib data|


### updateAccountMetadataURI

Function to update the metadata URI of the Account


```solidity
function updateAccountMetadataURI(string calldata metadataURI) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadataURI`|`string`|The new metadata URI|


### delegateBalance

Function to delegate a percentage of the account's balance to another account

*The percentage is scaled by 1e4 so the minimum unit is 0.01%*


```solidity
function delegateBalance(address account, uint32 percentage) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the account to delegate to|
|`percentage`|`uint32`|The percentage of the account's balance to delegate|


### updateDelegatedBalance

Function to update the delegated validator balance percentage to another account

*The percentage is scaled by 1e4 so the minimum unit is 0.01%*


```solidity
function updateDelegatedBalance(address account, uint32 percentage) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the account to delegate to|
|`percentage`|`uint32`|The updated percentage of the account's balance to delegate|


### removeDelegatedBalance

Removes delegation from an account.


```solidity
function removeDelegatedBalance(address account) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the account whose delegation is being removed.|


### createStrategy

Function to create a new Strategy


```solidity
function createStrategy(uint32 fee, string calldata metadataURI) external returns (uint32 strategyId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint32`||
|`metadataURI`|`string`|The metadata URI of the strategy|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the new Strategy|


### updateStrategyMetadataURI

Function to update the metadata URI of the Strategy


```solidity
function updateStrategyMetadataURI(uint32 strategyId, string calldata metadataURI) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The id of the strategy|
|`metadataURI`|`string`|The new metadata URI|


### optInToBApp

Opt-in to a bApp with a list of tokens and obligation percentages

*checks that each token is supported by the bApp, but not that the obligation is > 0*


```solidity
function optInToBApp(uint32 strategyId, address bApp, address[] calldata tokens, uint32[] calldata obligationPercentages, bytes calldata data) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`bApp`|`address`|The address of the bApp|
|`tokens`|`address[]`|The list of tokens to opt-in with|
|`obligationPercentages`|`uint32[]`|The list of obligation percentages for each token|
|`data`|`bytes`|Optional parameter that could be required by the service|


### _isContract

Function to check if an address is a contract


```solidity
function _isContract(address bApp) private view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bApp`|`address`|The address of the bApp|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the address is a contract|


### depositERC20

Deposit ERC20 tokens into the strategy


```solidity
function depositERC20(uint32 strategyId, IERC20 token, uint256 amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`token`|`IERC20`|The ERC20 token address|
|`amount`|`uint256`|The amount to deposit|


### depositETH

Deposit ETH into the strategy


```solidity
function depositETH(uint32 strategyId) external payable nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|


### proposeWithdrawal

Propose a withdrawal of ERC20 tokens from the strategy.


```solidity
function proposeWithdrawal(uint32 strategyId, address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy.|
|`token`|`address`|The ERC20 token address.|
|`amount`|`uint256`|The amount to withdraw.|


### finalizeWithdrawal

Finalize the ERC20 withdrawal after the timelock period has passed.


```solidity
function finalizeWithdrawal(uint32 strategyId, IERC20 token) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy.|
|`token`|`IERC20`|The ERC20 token address.|


### proposeWithdrawalETH

Propose an ETH withdrawal from the strategy.


```solidity
function proposeWithdrawalETH(uint32 strategyId, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy.|
|`amount`|`uint256`|The amount of ETH to withdraw.|


### finalizeWithdrawalETH

Finalize the ETH withdrawal after the timelock period has passed.


```solidity
function finalizeWithdrawalETH(uint32 strategyId) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy.|


### createObligation

Add a new obligation for a bApp


```solidity
function createObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`bApp`|`address`|The address of the bApp|
|`token`|`address`|The address of the token|
|`obligationPercentage`|`uint32`|The obligation percentage|


### proposeUpdateObligation

Propose a withdrawal of ERC20 tokens from the strategy.


```solidity
function proposeUpdateObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy.|
|`bApp`|`address`||
|`token`|`address`|The ERC20 token address.|
|`obligationPercentage`|`uint32`|The new percentage of the obligation|


### finalizeUpdateObligation

Finalize the withdrawal after the timelock period has passed.


```solidity
function finalizeUpdateObligation(uint32 strategyId, address bApp, address token) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy.|
|`bApp`|`address`|The address of the bApp.|
|`token`|`address`|The ERC20 token address.|


### reduceFee

Instantly lowers the fee for a strategy


```solidity
function reduceFee(uint32 strategyId, uint32 proposedFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`proposedFee`|`uint32`|The proposed fee|


### proposeFeeUpdate

Propose a new fee for a strategy


```solidity
function proposeFeeUpdate(uint32 strategyId, uint32 proposedFee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`proposedFee`|`uint32`|The proposed fee|


### finalizeFeeUpdate

Finalize the fee update for a strategy


```solidity
function finalizeFeeUpdate(uint32 strategyId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|


### _createOptInObligations

Set the obligation percentages for a strategy


```solidity
function _createOptInObligations(uint32 strategyId, address bApp, address[] calldata tokens, uint32[] calldata obligationPercentages) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`bApp`|`address`|The address of the bApp|
|`tokens`|`address[]`|The list of tokens to set s.obligations for|
|`obligationPercentages`|`uint32[]`|The list of obligation percentages for each token|


### _createSingleObligation

Set a single obligation for a strategy


```solidity
function _createSingleObligation(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`bApp`|`address`|The address of the bApp|
|`token`|`address`|The address of the token|
|`obligationPercentage`|`uint32`|The obligation percentage|


### _validateObligationUpdateInput

Validate the input for the obligation creation or update


```solidity
function _validateObligationUpdateInput(uint32 strategyId, address bApp, address token, uint32 obligationPercentage) private view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`bApp`|`address`|The address of the bApp|
|`token`|`address`|The address of the token|
|`obligationPercentage`|`uint32`|The obligation percentage|


### _checkTimelocks

Check the timelocks


```solidity
function _checkTimelocks(uint256 requestTime, uint256 timelockPeriod, uint256 expireTime) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requestTime`|`uint256`|The time of the request|
|`timelockPeriod`|`uint256`|The timelock period|
|`expireTime`|`uint256`|The expire time|


### _beforeDeposit


```solidity
function _beforeDeposit(uint32 strategyId, address token, uint256 amount) internal;
```

### _proposeWithdrawal

*override the previous share balance*


```solidity
function _proposeWithdrawal(uint32 strategyId, address token, uint256 amount) internal;
```

### _finalizeWithdrawal


```solidity
function _finalizeWithdrawal(uint32 strategyId, address token) private returns (uint256 amount);
```

### getSlashableBalance

Get the slashable balance for a strategy


```solidity
function getSlashableBalance(CoreStorageLib.Data storage s, uint32 strategyId, address bApp, address token, ICore.Shares storage strategyTokenShares)
    internal
    view
    returns (uint256 slashableBalance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`s`|`CoreStorageLib.Data`||
|`strategyId`|`uint32`|The ID of the strategy|
|`bApp`|`address`|The address of the bApp|
|`token`|`address`|The address of the token|
|`strategyTokenShares`|`ICore.Shares`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`slashableBalance`|`uint256`|The slashable balance|


### _checkStrategyOptedIn


```solidity
function _checkStrategyOptedIn(CoreStorageLib.Data storage s, uint32 strategyId, address bApp) internal view;
```

### slash

Slash a strategy


```solidity
function slash(uint32 strategyId, address bApp, address token, uint32 percentage, bytes calldata data) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`strategyId`|`uint32`|The ID of the strategy|
|`bApp`|`address`|The address of the bApp|
|`token`|`address`|The address of the token|
|`percentage`|`uint32`|The amount to slash|
|`data`|`bytes`|Optional parameter that could be required by the service|


### _exitStrategy


```solidity
function _exitStrategy(CoreStorageLib.Data storage s, uint32 strategyId, address bApp, address token) private;
```

### _adjustObligation


```solidity
function _adjustObligation(
    CoreStorageLib.Data storage s,
    uint32 strategyId,
    address bApp,
    address token,
    uint256 amount,
    ICore.Shares storage strategyTokenShares
) internal returns (uint32 obligationPercentage);
```

### withdrawSlashingFund

Withdraw the slashing fund for a token


```solidity
function withdrawSlashingFund(address token, uint256 amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token|
|`amount`|`uint256`|The amount to withdraw|


### withdrawETHSlashingFund

Withdraw the slashing fund for ETH


```solidity
function withdrawETHSlashingFund(uint256 amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount to withdraw|


### _withdrawSlashingFund

General withdraw code the slashing fund


```solidity
function _withdrawSlashingFund(address token, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token|
|`amount`|`uint256`|The amount to withdraw|


### _checkSlashingAllowed


```solidity
function _checkSlashingAllowed() internal view;
```

### _checkWithdrawalsAllowed


```solidity
function _checkWithdrawalsAllowed() internal view;
```

