# ISSVBasedApps
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/core/interfaces/ISSVBasedApps.sol)

**Inherits:**
[IStrategyManager](/src/core/interfaces/IStrategyManager.sol/interface.IStrategyManager.md), [IBasedAppManager](/src/core/interfaces/IBasedAppManager.sol/interface.IBasedAppManager.md), [IProtocolManager](/src/core/interfaces/IProtocolManager.sol/interface.IProtocolManager.md), [IViews](/src/core/interfaces/IViews.sol/interface.IViews.md)


## Functions
### getModuleAddress


```solidity
function getModuleAddress(SSVCoreModules moduleId) external view returns (address);
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

### InvalidMaxShares

```solidity
error InvalidMaxShares();
```

### InvalidFeeTimelockPeriod

```solidity
error InvalidFeeTimelockPeriod();
```

### InvalidFeeExpireTime

```solidity
error InvalidFeeExpireTime();
```

### InvalidWithdrawalTimelockPeriod

```solidity
error InvalidWithdrawalTimelockPeriod();
```

### InvalidWithdrawalExpireTime

```solidity
error InvalidWithdrawalExpireTime();
```

### InvalidObligationTimelockPeriod

```solidity
error InvalidObligationTimelockPeriod();
```

### InvalidObligationExpireTime

```solidity
error InvalidObligationExpireTime();
```

### InvalidTokenUpdateTimelockPeriod

```solidity
error InvalidTokenUpdateTimelockPeriod();
```

### InvalidDisabledFeatures

```solidity
error InvalidDisabledFeatures();
```

### TargetModuleDoesNotExist

```solidity
error TargetModuleDoesNotExist(uint8 moduleId);
```

