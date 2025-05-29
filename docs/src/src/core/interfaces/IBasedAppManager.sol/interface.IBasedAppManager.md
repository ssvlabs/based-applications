# IBasedAppManager
[Git Source](https://github.com/ssvlabs/based-applications/blob/f462573124548b82b6a002d4ef069bdfacf5c637/src/core/interfaces/IBasedAppManager.sol)


## Functions
### registerBApp


```solidity
function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;
```

### updateBAppMetadataURI


```solidity
function updateBAppMetadataURI(string calldata metadataURI) external;
```

### updateBAppsTokens


```solidity
function updateBAppsTokens(ICore.TokenConfig[] calldata tokenConfigs) external;
```

## Events
### BAppMetadataURIUpdated

```solidity
event BAppMetadataURIUpdated(address indexed bApp, string metadataURI);
```

### BAppRegistered

```solidity
event BAppRegistered(address indexed bApp, address[] tokens, uint32[] sharedRiskLevel, string metadataURI);
```

### BAppTokensUpdated

```solidity
event BAppTokensUpdated(address indexed bApp, ICore.TokenConfig[] tokenConfigs);
```

## Errors
### BAppAlreadyRegistered

```solidity
error BAppAlreadyRegistered();
```

### BAppDoesNotSupportInterface

```solidity
error BAppDoesNotSupportInterface();
```

### BAppNotRegistered

```solidity
error BAppNotRegistered();
```

### TokenAlreadyAddedToBApp

```solidity
error TokenAlreadyAddedToBApp(address token);
```

### ZeroAddressNotAllowed

```solidity
error ZeroAddressNotAllowed();
```

