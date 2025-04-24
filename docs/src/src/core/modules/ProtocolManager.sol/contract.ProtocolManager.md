# ProtocolManager
[Git Source](https://github.com/ssvlabs/based-applications/blob/506ac6ae02f84ad3df44eadfe12c8fc0cb108f44/src/core/modules/ProtocolManager.sol)

**Inherits:**
[IProtocolManager](/src/core/interfaces/IProtocolManager.sol/interface.IProtocolManager.md)


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
### updateFeeTimelockPeriod


```solidity
function updateFeeTimelockPeriod(uint32 feeTimelockPeriod) external;
```

### updateFeeExpireTime


```solidity
function updateFeeExpireTime(uint32 feeExpireTime) external;
```

### updateWithdrawalTimelockPeriod


```solidity
function updateWithdrawalTimelockPeriod(uint32 withdrawalTimelockPeriod) external;
```

### updateWithdrawalExpireTime


```solidity
function updateWithdrawalExpireTime(uint32 withdrawalExpireTime) external;
```

### updateObligationTimelockPeriod


```solidity
function updateObligationTimelockPeriod(uint32 obligationTimelockPeriod) external;
```

### updateObligationExpireTime


```solidity
function updateObligationExpireTime(uint32 obligationExpireTime) external;
```

### updateTokenUpdateTimelockPeriod


```solidity
function updateTokenUpdateTimelockPeriod(uint32 tokenUpdateTimelockPeriod) external;
```

### updateMaxShares


```solidity
function updateMaxShares(uint256 maxShares) external;
```

### updateMaxFeeIncrement


```solidity
function updateMaxFeeIncrement(uint32 maxFeeIncrement) external;
```

### updateDisabledFeatures


```solidity
function updateDisabledFeatures(uint32 disabledFeatures) external;
```

