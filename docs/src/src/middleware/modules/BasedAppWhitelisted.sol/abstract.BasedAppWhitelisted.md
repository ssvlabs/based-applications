# BasedAppWhitelisted
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/middleware/modules/BasedAppWhitelisted.sol)

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

