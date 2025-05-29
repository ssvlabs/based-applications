# AccessControlBasedApp
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/middleware/modules/core+roles/AccessControlBasedApp.sol)

**Inherits:**
[BasedAppCore](/src/middleware/modules/core/BasedAppCore.sol/abstract.BasedAppCore.md), AccessControl


## State Variables
### MANAGER_ROLE

```solidity
bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
```


### OWNER_ROLE

```solidity
bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
```


## Functions
### constructor


```solidity
constructor(address _basedAppManager, address owner) AccessControl() BasedAppCore(_basedAppManager);
```

### grantManagerRole


```solidity
function grantManagerRole(address manager) external onlyRole(DEFAULT_ADMIN_ROLE);
```

### revokeManagerRole


```solidity
function revokeManagerRole(address manager) external onlyRole(DEFAULT_ADMIN_ROLE);
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
function registerBApp(ICore.TokenConfig[] calldata tokenConfigs, string calldata metadataURI) external override onlyRole(MANAGER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenConfigs`|`ICore.TokenConfig[]`|array of token addresses and shared risk levels|
|`metadataURI`|`string`|URI of the metadata|


### updateBAppMetadataURI

Updates the metadata URI of a BApp


```solidity
function updateBAppMetadataURI(string calldata metadataURI) external override onlyRole(MANAGER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadataURI`|`string`|new metadata URI|


