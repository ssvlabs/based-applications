# Release Notes

## [v0.2.0] 2024-06-xx
### Description
- fix(strategy-manager): change slashing and obligationUpdate event order
- fix(strategy): revert slashing if strategy not opted in
- feat: add and enforce basic checks for config vars
- Enrich SSVBasedApps interface (#51)
- Remove IERC165 Interface Check (#52)
- feat: check bApp registered during OptIn (#53)
- chore: update docs + add release notes
- chore: sepolia deployment, bump version
- Example ECDSA verifier (#72)
- Fix: Propose Obligation Update storage ref (#74)
- feat: add script for implementation update and solidity 0.8.30

### Contracts
#### New (examples)
- `contract ECDSAVerifier is OwnableBasedApp`

### Interfaces
#### New
- `interface IViews`

#### Modified
- `interface IBasedApp is IERC165` -> `interface IBasedApp`

### Functions
#### Modified
- `function registerBApp(
    address[] calldata tokens, 
    uint32[] calldata sharedRiskLevels, 
    string calldata metadataURI) external`

->
- `function registerBApp(
    ICore.TokenConfig[] calldata tokenConfigs,
    string calldata metadataURI
) external
`


## [v0.1.1 - fix] 2024-06-17
### Description
- Fix to update the storage references when proposing an obligation
- Bump solidity version
- Create module deployment scripts

## [v0.1.1] 2024-06-xx

### Functions
#### Modified
- `function registerBApp(ICore.TokenConfig[] calldata tokenConfigs, string calldata metadataURI) external`
- `function updateDisabledFeatures(uint32 value) external onlyOwner`

### Errors
#### New
- `error InvalidDisabledFeatures();`
- `error InvalidFeeExpireTime();`
- `error InvalidFeeTimelockPeriod();`
- `error InvalidMaxShares();`
- `error InvalidObligationExpireTime();`
- `error InvalidObligationTimelockPeriod();`
- `error InvalidTokenUpdateTimelockPeriod();`
- `error InvalidWithdrawalExpireTime();`
- `error InvalidWithdrawalTimelockPeriod();`

### Events
#### Modified
- `event BAppRegistered(address indexed bApp, ICore.TokenConfig[] tokenConfigs, string metadataURI);`
