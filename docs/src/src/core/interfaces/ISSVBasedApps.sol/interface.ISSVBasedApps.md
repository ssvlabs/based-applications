# ISSVBasedApps
[Git Source](https://github.com/ssvlabs/based-applications/blob/506ac6ae02f84ad3df44eadfe12c8fc0cb108f44/src/core/interfaces/ISSVBasedApps.sol)


## Functions
### getModuleAddress


```solidity
function getModuleAddress(SSVCoreModules moduleId) external view returns (address);
```

### getVersion


```solidity
function getVersion() external pure returns (string memory version);
```

### initialize


```solidity
function initialize(
    address owner_,
    IBasedAppManager ssvBasedAppManger_,
    IStrategyManager ssvStrategyManager_,
    IProtocolManager protocolManager_,
    ProtocolStorageLib.Data memory config
) external;
```

### updateModule


```solidity
function updateModule(SSVCoreModules[] calldata moduleIds, address[] calldata moduleAddresses) external;
```

## Events
### ModuleUpdated

```solidity
event ModuleUpdated(SSVCoreModules indexed moduleId, address moduleAddress);
```

## Errors
### InvalidMaxFeeIncrement

```solidity
error InvalidMaxFeeIncrement();
```

### TargetModuleDoesNotExist

```solidity
error TargetModuleDoesNotExist(uint8 moduleId);
```

