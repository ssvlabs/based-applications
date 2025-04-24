# OwnableBasedApp
[Git Source](https://github.com/ssvlabs/based-applications/blob/506ac6ae02f84ad3df44eadfe12c8fc0cb108f44/src/middleware/modules/core+roles/OwnableBasedApp.sol)

**Inherits:**
Ownable, [BasedAppCore](/src/middleware/modules/core/BasedAppCore.sol/abstract.BasedAppCore.md)


## Functions
### constructor


```solidity
constructor(address _basedAppManager, address _initOwner) BasedAppCore(_basedAppManager) Ownable(_initOwner);
```

### registerBApp

Registers a BApp calling the SSV SSVBasedApps

*metadata should point to a json that respect template:
{
"name": "SSV Based App",
"website": "https://www.ssvlabs.io/",
"description": "SSV Based App Core",
"logo": "https://link-to-your-logo.png",
"social": "https://x.com/ssv_network"
}*


```solidity
function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokens`|`address[]`|array of token addresses|
|`sharedRiskLevels`|`uint32[]`|array of shared risk levels|
|`metadataURI`|`string`|URI of the metadata|


### updateBAppMetadataURI

Updates the metadata URI of a BApp


```solidity
function updateBAppMetadataURI(string calldata metadataURI) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadataURI`|`string`|new metadata URI|


### supportsInterface

Checks if the contract supports the interface


```solidity
function supportsInterface(bytes4 interfaceId) public pure override(BasedAppCore) returns (bool isSupported);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|interface id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isSupported`|`bool`|if the contract supports the interface|


