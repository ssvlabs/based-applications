# BasedAppCore
[Git Source](https://github.com/ssvlabs/based-applications/blob/506ac6ae02f84ad3df44eadfe12c8fc0cb108f44/src/middleware/modules/core/BasedAppCore.sol)

**Inherits:**
[IBasedApp](/src/middleware/interfaces/IBasedApp.sol/interface.IBasedApp.md)


## State Variables
### SSV_BASED_APPS_NETWORK
Address of the SSV Based App Manager contract


```solidity
address public immutable SSV_BASED_APPS_NETWORK;
```


## Functions
### onlySSVBasedAppManager

*Allows only the SSV Based App Manager to call the function*


```solidity
modifier onlySSVBasedAppManager();
```

### constructor

constructor for the BasedAppCore contract,
initializes the contract with the SSVBasedApps address and the owner and disables the initializers.


```solidity
constructor(address _ssvBasedAppsNetwork);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_ssvBasedAppsNetwork`|`address`|address of the SSVBasedApps contract|


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
function registerBApp(address[] calldata tokens, uint32[] calldata sharedRiskLevels, string calldata metadataURI) external virtual;
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
function updateBAppMetadataURI(string calldata metadataURI) external virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`metadataURI`|`string`|new metadata URI|


### updateBAppTokens

Updates the tokens of a BApp


```solidity
function updateBAppTokens(ICore.TokenConfig[] calldata tokenConfigs) external virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenConfigs`|`ICore.TokenConfig[]`|new list of tokens and their shared risk levels|


### withdrawSlashingFund


```solidity
function withdrawSlashingFund(address token, uint256 amount) external virtual;
```

### withdrawETHSlashingFund


```solidity
function withdrawETHSlashingFund(uint256 amount) external virtual;
```

### optInToBApp

Allows a Strategy to Opt-in to a BApp, it can be called only by the SSV Based App Manager


```solidity
function optInToBApp(uint32, address[] calldata, uint32[] calldata, bytes calldata) external virtual onlySSVBasedAppManager returns (bool success);
```

### slash

*--- CORE LOGIC (TO BE IMPLEMENTED) ---*

*--- RETURN TRUE IF SUCCESS, FALSE OTHERWISE ---*


```solidity
function slash(uint32, address, uint32, address, bytes calldata) external virtual onlySSVBasedAppManager returns (bool, address, bool);
```

### supportsInterface

Checks if the contract supports the interface

*--- CORE LOGIC (TO BE IMPLEMENTED) ---*

*--- RETURN TRUE IF SUCCESS, FALSE OTHERWISE ---*

*--- RETURN RECEIVER ADDRESS FOR THE SLASHED FUNDS ---*


```solidity
function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|interface id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|true if the contract supports the interface|


### receive


```solidity
receive() external payable virtual;
```

