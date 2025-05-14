# BasedAppsManager
[Git Source](https://github.com/ssvlabs/based-applications/blob/f462573124548b82b6a002d4ef069bdfacf5c637/src/core/modules/BasedAppsManager.sol)

**Inherits:**
[IBasedAppManager](/src/core/interfaces/IBasedAppManager.sol/interface.IBasedAppManager.md)


## Functions
### _onlyRegisteredBApp

Allow the function to be called only by a registered bApp


```solidity
function _onlyRegisteredBApp(CoreStorageLib.Data storage s) private view;
```

### registerBApp

Registers a bApp.

*Allows creating a bApp even with an empty token list.*


```solidity
function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokens`|`address[]`|The list of tokens the bApp accepts; can be empty.|
|`sharedRiskLevels`|`uint32[]`|The shared risk level of the bApp.|
|`metadataURI`|`string`|The metadata URI of the bApp, which is a link (e.g., http://example.com) to a JSON file containing metadata such as the name, description, logo, etc.|


### updateBAppMetadataURI

Function to update the metadata URI of the Based Application


```solidity
function updateBAppMetadataURI(string calldata metadataURI) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadataURI`|`string`|The new metadata URI|


### updateBAppsTokens


```solidity
function updateBAppsTokens(ICore.TokenConfig[] calldata tokenConfigs) external;
```

### _addNewTokens

Function to add tokens to a bApp


```solidity
function _addNewTokens(address bApp, address[] calldata tokens, uint32[] calldata sharedRiskLevels) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bApp`|`address`|The address of the bApp|
|`tokens`|`address[]`|The list of tokens to add|
|`sharedRiskLevels`|`uint32[]`|The shared risk levels of the tokens|


