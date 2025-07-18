# ProtocolStorageLib
[Git Source](https://github.com/ssvlabs/based-applications/blob/f462573124548b82b6a002d4ef069bdfacf5c637/src/core/libraries/ProtocolStorageLib.sol)


## State Variables
### SSV_STORAGE_POSITION

```solidity
uint256 private constant SSV_STORAGE_POSITION = uint256(keccak256("ssv.based-apps.storage.protocol")) - 1;
```


## Functions
### load


```solidity
function load() internal pure returns (Data storage sd);
```

## Structs
### Data
Represents the operational settings and parameters required by the SSV Based Application Platform


```solidity
struct Data {
    uint256 maxShares;
    uint32 feeTimelockPeriod;
    uint32 feeExpireTime;
    uint32 withdrawalTimelockPeriod;
    uint32 withdrawalExpireTime;
    uint32 obligationTimelockPeriod;
    uint32 obligationExpireTime;
    uint32 tokenUpdateTimelockPeriod;
    uint32 maxFeeIncrement;
    uint32 disabledFeatures;
}
```

