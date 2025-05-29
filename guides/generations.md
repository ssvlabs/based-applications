# Generation Versioning in Strategy Shares

## Purpose

When a slashing event fully drains a strategy’s token balance, we need to ensure that any _old_ share‑balances and pending withdrawals become invalidated. The “generation” mechanism provides a simple versioning layer: bumping the `currentGeneration` counter makes all previous per‑account shares stale, preventing them from being redeemed after a full slash.

## Rationale

Without generation/versioning:

1. A user deposits → receives `N` shares.
2. A slash drains the strategy → token balance is zero.
3. If we didn’t invalidate old shares, a user could still call `withdraw`, burn “old” shares, and withdraw zero tokens—potentially confusing or even exploitable in edge flows.

By grouping every deposit/withdraw epoch under a “generation” number:

- **Deposits** record both a share count _and_ the current generation at that time.  
- On a full‑balance slash, we bump `currentGeneration`.  
- Any subsequent withdrawal attempts carry an out‑of‑date generation tag and revert.

This cleanly tears down all outstanding share balances in one on‑chain operation.

## High-Level Flow

1. **Deposit**  
   - If `totalShares == 0` (fresh strategy), `shares = amount`;  
   - Store `accountGeneration[msg.sender] = currentGeneration`;  
   - Add to `accountShareBalance[msg.sender]`.

2. **Slash & Generation bump**  
   - If `strategyTokenShares.totalTokenBalance` goes to zero after slashing:  
     ```solidity
     delete strategyTokenShares.totalTokenBalance;
     delete strategyTokenShares.totalShareBalance;
     strategyTokenShares.currentGeneration += 1;
     ```
   - Now `currentGeneration` > any `accountGeneration[...]` recorded so far.

3. **Withdraw**  
   - On `proposeWithdrawal` and `finalizeWithdrawal`, we check  
     ```solidity
     if (strategyTokenShares.currentGeneration !=
         strategyTokenShares.accountGeneration[msg.sender]
     ) revert InvalidAccountGeneration();
     ```
   - Out‑of‑date generations cannot proceed.

## Technical Explanation

### Storage Layout (excerpt)

```solidity
struct Shares {
    uint256 totalTokenBalance;
    uint256 totalShareBalance;
    uint256 currentGeneration;
    mapping(address => uint256) accountShareBalance;
    mapping(address => uint256) accountGeneration;
}
mapping(uint32 strategyId => mapping(address token => Shares)) public strategyTokenShares;
```

- `currentGeneration` is a global counter per `(strategyId,token)` pair.  
- `accountGeneration[addr]` records which generation that account last deposited in.  
- When generations mismatch, the user’s local `accountShareBalance` is considered invalid.

### Deposit (`_beforeDeposit`)

```solidity
if (strategyTokenShares.currentGeneration
    != strategyTokenShares.accountGeneration[msg.sender]
) {
    // brand-new generation for this account
    strategyTokenShares.accountGeneration[msg.sender]
        = strategyTokenShares.currentGeneration;
    strategyTokenShares.accountShareBalance[msg.sender]
        = computedShares;
} else {
    // same generation: accumulate shares
    strategyTokenShares.accountShareBalance[msg.sender] += computedShares;
}
```

### Full Slash & Bump

```solidity
if (strategyTokenShares.totalTokenBalance == 0) {
    // clear balances
    delete strategyTokenShares.totalTokenBalance;
    delete strategyTokenShares.totalShareBalance;
    // bump to invalidate everyone else
    strategyTokenShares.currentGeneration += 1;
}
```

### Withdrawal Check

```solidity
// in _proposeWithdrawal or finalize:
if (strategyTokenShares.currentGeneration
    != strategyTokenShares.accountGeneration[msg.sender]
) revert InvalidAccountGeneration();
```

## References

- **CoreStorageLib**  
  Defines `strategyTokenShares` and where `Shares` lives:  
  [`src/core/libraries/CoreStorageLib.sol`](src/core/libraries/CoreStorageLib.sol)
- **ERC-20 share math + generation logic**  
  In `StrategyManager._beforeDeposit`, `StrategyManager._proposeWithdrawal`, and the slash handlers:  
  [`src/core/modules/StrategyManager.sol`](src/core/modules/StrategyManager.sol)
- **IStrategyManager.Shares**  
  Describes the struct and intent:  
  [`src/core/interfaces/ICore.sol`](src/core/interfaces/ICore.sol)
