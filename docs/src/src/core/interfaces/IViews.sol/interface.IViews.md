# IViews
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/core/interfaces/IViews.sol)


## Functions
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

