# IBasedAppWhitelisted
[Git Source](https://github.com/ssvlabs/based-applications/blob/f462573124548b82b6a002d4ef069bdfacf5c637/src/middleware/interfaces/IBasedAppWhitelisted.sol)


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

