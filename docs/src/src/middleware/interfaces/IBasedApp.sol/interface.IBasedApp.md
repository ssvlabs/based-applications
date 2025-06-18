# IBasedApp
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/middleware/interfaces/IBasedApp.sol)


## Functions
### optInToBApp


```solidity
function optInToBApp(uint32 strategyId, address[] calldata tokens, uint32[] calldata obligationPercentages, bytes calldata data) external returns (bool);
```

### registerBApp


```solidity
function registerBApp(ICore.TokenConfig[] calldata tokenConfigs, string calldata metadataURI) external;
```

### slash


```solidity
function slash(uint32 strategyId, address token, uint32 percentage, address sender, bytes calldata data)
    external
    returns (bool success, address receiver, bool exit);
```

### updateBAppMetadataURI


```solidity
function updateBAppMetadataURI(string calldata metadataURI) external;
```

### updateBAppTokens


```solidity
function updateBAppTokens(ICore.TokenConfig[] calldata tokenConfigs) external;
```

## Errors
### UnauthorizedCaller

```solidity
error UnauthorizedCaller();
```

