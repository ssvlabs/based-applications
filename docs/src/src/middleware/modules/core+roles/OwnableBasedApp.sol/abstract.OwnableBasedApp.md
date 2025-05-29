# OwnableBasedApp
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/middleware/modules/core+roles/OwnableBasedApp.sol)

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
function registerBApp(ICore.TokenConfig[] calldata tokenConfigs, string calldata metadataURI) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenConfigs`|`ICore.TokenConfig[]`|array of token addresses and shared risk levels|
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


