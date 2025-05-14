# BasedAppWhitelisted
[Git Source](https://github.com/ssvlabs/based-applications/blob/f462573124548b82b6a002d4ef069bdfacf5c637/src/middleware/modules/BasedAppWhitelisted.sol)

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

