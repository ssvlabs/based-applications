# IBasedAppWhitelisted
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/middleware/interfaces/IBasedAppWhitelisted.sol)


## Functions
### addWhitelisted


```solidity
function addWhitelisted(uint32 strategyId) external;
```

### removeWhitelisted


```solidity
function removeWhitelisted(uint32 strategyId) external;
```

## Errors
### AlreadyWhitelisted

```solidity
error AlreadyWhitelisted();
```

### NonWhitelistedCaller

```solidity
error NonWhitelistedCaller();
```

### NotWhitelisted

```solidity
error NotWhitelisted();
```

### ZeroID

```solidity
error ZeroID();
```

