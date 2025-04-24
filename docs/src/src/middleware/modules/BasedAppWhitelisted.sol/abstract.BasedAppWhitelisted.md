# BasedAppWhitelisted
[Git Source](https://github.com/ssvlabs/based-applications/blob/506ac6ae02f84ad3df44eadfe12c8fc0cb108f44/src/middleware/modules/BasedAppWhitelisted.sol)

**Inherits:**
[IBasedAppWhitelisted](/src/middleware/interfaces/IBasedAppWhitelisted.sol/interface.IBasedAppWhitelisted.md)


## State Variables
### isWhitelisted

```solidity
mapping(uint32 => bool) public isWhitelisted;
```


## Functions
### addWhitelisted


```solidity
function addWhitelisted(uint32 strategyId) external virtual;
```

### removeWhitelisted


```solidity
function removeWhitelisted(uint32 strategyId) external virtual;
```

