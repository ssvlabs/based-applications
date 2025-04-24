# IBasedApp
[Git Source](https://github.com/ssvlabs/based-applications/blob/506ac6ae02f84ad3df44eadfe12c8fc0cb108f44/src/middleware/interfaces/IBasedApp.sol)

**Inherits:**
IERC165


## Functions
### optInToBApp


```solidity
function optInToBApp(uint32 strategyId, address[] calldata tokens, uint32[] calldata obligationPercentages, bytes calldata data) external returns (bool);
```

### registerBApp


```solidity
function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;
```

### slash


```solidity
function slash(uint32 strategyId, address token, uint32 percentage, address sender, bytes calldata data)
    external
    returns (bool success, address receiver, bool exit);
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

