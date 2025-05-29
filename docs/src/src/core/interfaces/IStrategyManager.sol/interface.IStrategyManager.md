# IStrategyManager
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/core/interfaces/IStrategyManager.sol)


## Functions
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

### optInToBApp


```solidity
function optInToBApp(uint32 strategyId, address bApp, address[] calldata tokens, uint32[] calldata obligationPercentages, bytes calldata data) external;
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

### slash


```solidity
function slash(uint32 strategyId, address bApp, address token, uint32 percentage, bytes calldata data) external;
```

### updateAccountMetadataURI


```solidity
function updateAccountMetadataURI(string calldata metadataURI) external;
```

### updateDelegatedBalance


```solidity
function updateDelegatedBalance(address receiver, uint32 percentage) external;
```

### updateStrategyMetadataURI


```solidity
function updateStrategyMetadataURI(uint32 strategyId, string calldata metadataURI) external;
```

### withdrawETHSlashingFund


```solidity
function withdrawETHSlashingFund(uint256 amount) external;
```

### withdrawSlashingFund


```solidity
function withdrawSlashingFund(address token, uint256 amount) external;
```

## Events
### AccountMetadataURIUpdated

```solidity
event AccountMetadataURIUpdated(address indexed account, string metadataURI);
```

### BAppOptedInByStrategy

```solidity
event BAppOptedInByStrategy(uint32 indexed strategyId, address indexed bApp, bytes data, address[] tokens, uint32[] obligationPercentages);
```

### DelegationCreated

```solidity
event DelegationCreated(address indexed delegator, address indexed receiver, uint32 percentage);
```

### DelegationRemoved

```solidity
event DelegationRemoved(address indexed delegator, address indexed receiver);
```

### DelegationUpdated

```solidity
event DelegationUpdated(address indexed delegator, address indexed receiver, uint32 percentage);
```

### MaxFeeIncrementSet

```solidity
event MaxFeeIncrementSet(uint32 newMaxFeeIncrement);
```

### ObligationCreated

```solidity
event ObligationCreated(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage);
```

### ObligationUpdated

```solidity
event ObligationUpdated(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage);
```

### ObligationUpdateProposed

```solidity
event ObligationUpdateProposed(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage);
```

### StrategyCreated

```solidity
event StrategyCreated(uint32 indexed strategyId, address indexed owner, uint32 fee, string metadataURI);
```

### StrategyDeposit

```solidity
event StrategyDeposit(uint32 indexed strategyId, address indexed account, address token, uint256 amount);
```

### StrategyFeeUpdated

```solidity
event StrategyFeeUpdated(uint32 indexed strategyId, address owner, uint32 newFee, bool isFast);
```

### StrategyFeeUpdateProposed

```solidity
event StrategyFeeUpdateProposed(uint32 indexed strategyId, address owner, uint32 proposedFee);
```

### StrategyMetadataURIUpdated

```solidity
event StrategyMetadataURIUpdated(uint32 indexed strategyId, string metadataURI);
```

### StrategyWithdrawal

```solidity
event StrategyWithdrawal(uint32 indexed strategyId, address indexed account, address token, uint256 amount, bool isFast);
```

### StrategyWithdrawalProposed

```solidity
event StrategyWithdrawalProposed(uint32 indexed strategyId, address indexed account, address token, uint256 amount);
```

### SlashingFundWithdrawn

```solidity
event SlashingFundWithdrawn(address token, uint256 amount);
```

### StrategySlashed

```solidity
event StrategySlashed(uint32 indexed strategyId, address indexed bApp, address token, uint32 percentage, address receiver);
```

## Errors
### BAppAlreadyOptedIn

```solidity
error BAppAlreadyOptedIn();
```

### BAppNotOptedIn

```solidity
error BAppNotOptedIn();
```

### BAppOptInFailed

```solidity
error BAppOptInFailed();
```

### BAppSlashingFailed

```solidity
error BAppSlashingFailed();
```

### DelegationAlreadyExists

```solidity
error DelegationAlreadyExists();
```

### DelegationDoesNotExist

```solidity
error DelegationDoesNotExist();
```

### DelegationExistsWithSameValue

```solidity
error DelegationExistsWithSameValue();
```

### ExceedingMaxShares

```solidity
error ExceedingMaxShares();
```

### ExceedingPercentageUpdate

```solidity
error ExceedingPercentageUpdate();
```

### FeeAlreadySet

```solidity
error FeeAlreadySet();
```

### InsufficientBalance

```solidity
error InsufficientBalance();
```

### InsufficientLiquidity

```solidity
error InsufficientLiquidity();
```

### InvalidAccountGeneration

```solidity
error InvalidAccountGeneration();
```

### InvalidAmount

```solidity
error InvalidAmount();
```

### InvalidBAppOwner

```solidity
error InvalidBAppOwner(address caller, address expectedOwner);
```

### InvalidPercentageIncrement

```solidity
error InvalidPercentageIncrement();
```

### InvalidStrategyFee

```solidity
error InvalidStrategyFee();
```

### InvalidStrategyOwner

```solidity
error InvalidStrategyOwner(address caller, address expectedOwner);
```

### InvalidToken

```solidity
error InvalidToken();
```

### NoPendingFeeUpdate

```solidity
error NoPendingFeeUpdate();
```

### NoPendingObligationUpdate

```solidity
error NoPendingObligationUpdate();
```

### NoPendingWithdrawal

```solidity
error NoPendingWithdrawal();
```

### ObligationAlreadySet

```solidity
error ObligationAlreadySet();
```

### ObligationHasNotBeenCreated

```solidity
error ObligationHasNotBeenCreated();
```

### RequestTimeExpired

```solidity
error RequestTimeExpired();
```

### SlashingDisabled

```solidity
error SlashingDisabled();
```

### TimelockNotElapsed

```solidity
error TimelockNotElapsed();
```

### TokenNotSupportedByBApp

```solidity
error TokenNotSupportedByBApp(address token);
```

### WithdrawTransferFailed

```solidity
error WithdrawTransferFailed();
```

### WithdrawalsDisabled

```solidity
error WithdrawalsDisabled();
```

