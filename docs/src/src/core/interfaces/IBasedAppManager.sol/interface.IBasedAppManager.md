# IBasedAppManager
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/core/interfaces/IBasedAppManager.sol)


## Functions
### registerBApp


```solidity
function registerBApp(ICore.TokenConfig[] calldata tokenConfigs, string calldata metadataURI) external;
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
event BAppRegistered(address indexed bApp, ICore.TokenConfig[] tokenConfigs, string metadataURI);
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

