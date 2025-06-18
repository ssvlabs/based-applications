# CoreStorageLib
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/core/libraries/CoreStorageLib.sol)


## State Variables
### SSV_BASED_APPS_STORAGE_POSITION

```solidity
uint256 private constant SSV_BASED_APPS_STORAGE_POSITION = uint256(keccak256("ssv.based-apps.storage.main")) - 1;
```


## Functions
### load


```solidity
function load() internal pure returns (Data storage sd);
```

## Structs
### Data
Represents all operational state required by the SSV Based Application platform.


```solidity
struct Data {
    uint32 _strategyCounter;
    mapping(SSVCoreModules => address) ssvContracts;
    mapping(uint32 strategyId => ICore.Strategy) strategies;
    mapping(address owner => uint32[] strategyId) strategyOwners;
    mapping(address account => mapping(address bApp => uint32 strategyId)) accountBAppStrategy;
    mapping(address delegator => mapping(address account => uint32 percentage)) delegations;
    mapping(address delegator => uint32 totalPercentage) totalDelegatedPercentage;
    mapping(uint32 strategyId => mapping(address token => ICore.Shares shares)) strategyTokenShares;
    mapping(uint32 strategyId => mapping(address bApp => mapping(address token => ICore.Obligation))) obligations;
    mapping(uint32 strategyId => mapping(address account => mapping(address token => ICore.WithdrawalRequest))) withdrawalRequests;
    mapping(uint32 strategyId => mapping(address token => mapping(address bApp => ICore.ObligationRequest))) obligationRequests;
    mapping(uint32 strategyId => ICore.FeeUpdateRequest) feeUpdateRequests;
    mapping(address account => mapping(address token => uint256 amount)) slashingFund;
    mapping(address bApp => bool isRegistered) registeredBApps;
    mapping(address bApp => mapping(address token => ICore.SharedRiskLevel)) bAppTokens;
    mapping(address bApp => ICore.TokenUpdateRequest) tokenUpdateRequests;
}
```

