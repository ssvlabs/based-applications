# Release Notes

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
