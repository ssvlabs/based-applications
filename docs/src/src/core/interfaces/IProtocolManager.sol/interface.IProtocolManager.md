# IProtocolManager
[Git Source](https://github.com/ssvlabs/based-applications/blob/f462573124548b82b6a002d4ef069bdfacf5c637/src/core/interfaces/IProtocolManager.sol)


## Functions
### updateFeeExpireTime


```solidity
function updateFeeExpireTime(uint32 value) external;
```

### updateFeeTimelockPeriod


```solidity
function updateFeeTimelockPeriod(uint32 value) external;
```

### updateMaxFeeIncrement


```solidity
function updateMaxFeeIncrement(uint32 value) external;
```

### updateMaxShares


```solidity
function updateMaxShares(uint256 value) external;
```

### updateObligationExpireTime


```solidity
function updateObligationExpireTime(uint32 value) external;
```

### updateObligationTimelockPeriod


```solidity
function updateObligationTimelockPeriod(uint32 value) external;
```

### updateTokenUpdateTimelockPeriod


```solidity
function updateTokenUpdateTimelockPeriod(uint32 value) external;
```

### updateWithdrawalExpireTime


```solidity
function updateWithdrawalExpireTime(uint32 value) external;
```

### updateWithdrawalTimelockPeriod


```solidity
function updateWithdrawalTimelockPeriod(uint32 value) external;
```

## Events
### FeeExpireTimeUpdated

```solidity
event FeeExpireTimeUpdated(uint32 feeExpireTime);
```

### FeeTimelockPeriodUpdated

```solidity
event FeeTimelockPeriodUpdated(uint32 feeTimelockPeriod);
```

### ObligationExpireTimeUpdated

```solidity
event ObligationExpireTimeUpdated(uint32 obligationExpireTime);
```

### ObligationTimelockPeriodUpdated

```solidity
event ObligationTimelockPeriodUpdated(uint32 obligationTimelockPeriod);
```

### TokenUpdateTimelockPeriodUpdated

```solidity
event TokenUpdateTimelockPeriodUpdated(uint32 tokenUpdateTimelockPeriod);
```

### StrategyMaxFeeIncrementUpdated

```solidity
event StrategyMaxFeeIncrementUpdated(uint32 maxFeeIncrement);
```

### StrategyMaxSharesUpdated

```solidity
event StrategyMaxSharesUpdated(uint256 maxShares);
```

### WithdrawalExpireTimeUpdated

```solidity
event WithdrawalExpireTimeUpdated(uint32 withdrawalExpireTime);
```

### WithdrawalTimelockPeriodUpdated

```solidity
event WithdrawalTimelockPeriodUpdated(uint32 withdrawalTimelockPeriod);
```

### DisabledFeaturesUpdated

```solidity
event DisabledFeaturesUpdated(uint32 disabledFeatures);
```

