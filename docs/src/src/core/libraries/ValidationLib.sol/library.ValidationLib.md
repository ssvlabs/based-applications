# ValidationLib
[Git Source](https://github.com/ssvlabs/based-applications/blob/f462573124548b82b6a002d4ef069bdfacf5c637/src/core/libraries/ValidationLib.sol)


## Functions
### validatePercentage


```solidity
function validatePercentage(uint32 percentage) internal pure;
```

### validatePercentageAndNonZero


```solidity
function validatePercentageAndNonZero(uint32 percentage) internal pure;
```

### validateArrayLengths


```solidity
function validateArrayLengths(address[] calldata tokens, uint32[] memory values) internal pure;
```

### validateNonZeroAddress


```solidity
function validateNonZeroAddress(address addr) internal pure;
```

## Errors
### InvalidPercentage

```solidity
error InvalidPercentage();
```

### LengthsNotMatching

```solidity
error LengthsNotMatching();
```

### ZeroAddressNotAllowed

```solidity
error ZeroAddressNotAllowed();
```

