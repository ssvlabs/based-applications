# :construction_worker: :closed_lock_with_key: **Middleware Contracts**

## Modules & Examples for BApp Development

:construction: CAUTION: This repo is currently under **heavy development!** :construction:

&nbsp;

## :book: _Overview_

This folder (`src/middleware/`) contains modules for developers to import and use when creating a BApp (Based Application). Additionally, it includes examples showcasing different implementations of BApps using these modules.

### Modules vs. Examples

- **Modules**: Abstract components that can be imported to create BApps.

- **Examples**: Implementations that demonstrate the usage of these modules in real-world scenarios.

&nbsp;

## :page_with_curl: To Have: Modules

**1) BLS Strategy Module**

Extends the `optIn` function and performs BLS signature verification.

Prevents replay attacks for security purposes.

Ensures unique public keys (potentially using a salt).

Restricts one strategy per owner/BLS, similar to the SSV Based App Manager.

Security Consideration: If BLS data is provided, it must be verified to prevent unauthorized reuse (replay attacks).

No simple verification function—a full module implementation is required.

**2) ECDSA Strategy Module**

Uses ECDSA signature verification.

Lighter alternative to BLS verification.

Can be used to confirm transaction authenticity with lower gas costs.

Also prevents replay attacks and ensures uniqueness where needed.

**3) Strategy Upgrade Module**

Allows a BApp that initially used an EOA (Externally Owned Account) to upgrade to a contract.

Also supports downgrading from a contract to an EOA.

Ensures security in transitions between EOA and contract-based control.

**4) Whitelist Strategy Module**

Implements a whitelist for strategies.

Restricts which strategies can participate in a BApp.

**5) Roles Manager Module**

Instead of relying on an owner, permissions are granted to a whitelisted manager.

Allows only authorized managers to perform specific operations within the BApp.

**6) Capped Strategies Module**

Limits the total capital that can be allocated to a strategy (e.g., maximum 100k SSV).

Hooks into the opt-in to BApp function to enforce deposit limits.

Uses on-chain balance verification to ensure compliance.

Ideal for BApps that want to avoid excessive reward costs.

&nbsp;

## :page_facing_up: To Have: Examples

- **BLS Strategy Example**: Demonstrates how to implement and use the BLS verification module securely.

- **ECDSA Strategy Example**: Showcases a lighter alternative using ECDSA verification.

- **Capped Strategy Example**: Implements a BApp that limits deposits to 100k SSV.

- **Whitelist Manager Example**: Uses whitelist-based permissions instead of owner-based control.
