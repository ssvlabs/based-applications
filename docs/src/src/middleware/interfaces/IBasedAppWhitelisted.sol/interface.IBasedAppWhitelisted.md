# IBasedAppWhitelisted
[Git Source](https://github.com/ssvlabs/based-applications/blob/506ac6ae02f84ad3df44eadfe12c8fc0cb108f44/src/middleware/interfaces/IBasedAppWhitelisted.sol)


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

