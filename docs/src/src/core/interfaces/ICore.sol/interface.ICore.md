# ICore
[Git Source](https://github.com/ssvlabs/based-applications/blob/3ee95af731e4fce61ac2b03f418aa4e9fb5f64bd/src/core/interfaces/ICore.sol)


## Structs
### SharedRiskLevel
Represents a SharedRiskLevel


```solidity
struct SharedRiskLevel {
    uint32 currentValue;
    bool isSet;
    uint32 pendingValue;
    uint32 effectTime;
}
```

### Obligation
Represents an Obligation


```solidity
struct Obligation {
    uint32 percentage;
    bool isSet;
}
```

### Strategy
Represents a Strategy


```solidity
struct Strategy {
    address owner;
    uint32 fee;
}
```

### FeeUpdateRequest
Represents a FeeUpdateRequest


```solidity
struct FeeUpdateRequest {
    uint32 percentage;
    uint32 requestTime;
}
```

### WithdrawalRequest
Represents a request for a withdrawal from a participant of a strategy


```solidity
struct WithdrawalRequest {
    uint256 shares;
    uint32 requestTime;
}
```

### ObligationRequest
Represents a change in the obligation in a strategy. Only the owner can submit one.


```solidity
struct ObligationRequest {
    uint32 percentage;
    uint32 requestTime;
}
```

### Shares
Represents the shares system of a strategy


```solidity
struct Shares {
    uint256 totalTokenBalance;
    uint256 totalShareBalance;
    uint256 currentGeneration;
    mapping(address => uint256) accountShareBalance;
    mapping(address => uint256) accountGeneration;
}
```

### TokenUpdateRequest

```solidity
struct TokenUpdateRequest {
    TokenConfig[] tokens;
    uint32 requestTime;
}
```

### TokenConfig

```solidity
struct TokenConfig {
    address token;
    uint32 sharedRiskLevel;
}
```

