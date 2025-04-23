# Feature Flags in StrategyManager

## Purpose

Introduce a compact, on‑chain mechanism to enable or disable selected features of the `StrategyManager` contract without a full redeploy. By packing multiple boolean toggles into a single `uint32`, the design:

- Minimizes storage footprint and gas cost.
- Provides an upgrade‑friendly switchboard for safety (e.g., emergency pause).
- Centralizes feature management under DAO control.

## Technical Explanation

- **Storage**: A `uint32 disabledFeatures` field in `ProtocolStorageLib.Data`.
- **Bitmask Layout**:
  - Bit 0 (LSB) → Slashing Disabled (`SLASHING_DISABLED = 1 << 0`)
  - Bit 1 → Withdrawals Disabled (`WITHDRAWALS_DISABLED = 1 << 1`)
  - Further bits reserved for future toggles.

- **Checks**: Two internal functions in `StrategyManager`:
  ```solidity
  function checkSlashingAllowed() internal view {
    if (ProtocolStorageLib.load().disabledFeatures & SLASHING_DISABLED != 0)
      revert SlashingDisabled();
  }

  function checkWithdrawalsAllowed() internal view {
    if (ProtocolStorageLib.load().disabledFeatures & WITHDRAWALS_DISABLED != 0)
      revert WithdrawalsDisabled();
  }
  ```
  - Called at the entry points of:
    - `slash(...)`
    - `proposeWithdrawal(...)`
    - `finalizeWithdrawal(...)`
    - `proposeWithdrawalETH(...)`
    - `finalizeWithdrawalETH(...)`

## Authorized Accounts

- Only the **DAO (owner)** can update the entire `disabledFeatures` bitmask via:
  ```solidity
  function updateDisabledFeatures(uint32 disabledFeatures) external onlyOwner;
  ```
- No per-feature granularity: toggles are applied in bulk.

## Current Features That Can Be Enabled/Disabled

| Bit Position | Feature            | Constant              | Description                               |
|:------------:|:-------------------|:----------------------|:------------------------------------------|
| 0            | Slashing           | `SLASHING_DISABLED`   | Stops all calls to `slash(...)`           |
| 1            | Withdrawals        | `WITHDRAWALS_DISABLED`| Stops all withdrawal proposals and finalizations |

## Usage & Examples

1. **Disable slashing only**:
   ```js
   // binary: 0b...01 → 1
   SSVBasedApps.updateDisabledFeatures(1);
   // `slash(...)` now reverts with `SlashingDisabled()`.
   ```
2. **Re-enable slashing, disable withdrawals**:
   ```js
   // binary: 0b...10 → 2
   SSVBasedApps.updateDisabledFeatures(2);
   // `slash(...)` resumes; `proposeWithdrawal(...)` and `finalizeWithdrawal(...)` revert.
   ```
3. **Disable both**:
   ```js
   SSVBasedApps.updateDisabledFeatures(3);
   ```
4. **Full example:**
    ```js
    // bit-definitions
    const SLASHING_DISABLED    = 1 << 0;  // 0b0001
    const WITHDRAWALS_DISABLED = 1 << 1;  // 0b0010

    // Suppose you want to disable only withdrawals:
    let flags = 0;
    flags |= WITHDRAWALS_DISABLED;      // flags === 0b0010

    // Later you decide to also disable slashing:
    flags |= SLASHING_DISABLED;         // flags === 0b0011

    // To re-enable withdrawals but keep slashing disabled:
    flags &= ~WITHDRAWALS_DISABLED;     // flags === 0b0001

    // Finally, send the update on-chain:
    await SSVBasedApps.updateDisabledFeatures(flags);
    ```

## Future Extensions

- Reserve bits 2–31 for other purposes:
  - Feature disabling
  - Emergency pause (global)


---
*This document outlines the bitmask‑driven feature gating mechanism for `StrategyManager`. It ensures rapid reaction to on‑chain emergencies and fine‑grained control over critical operations.*

