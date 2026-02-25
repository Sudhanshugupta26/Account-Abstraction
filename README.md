# Account Abstraction (ERC-4337) - Foundry Project

This project is a hands-on implementation of a minimal **ERC-4337 smart account** on Ethereum using Foundry.

Current status:
- Ethereum implementation is complete at local/dev level.
- Minimal account contract (`MinimalAccount`) is built and tested.
- Packed UserOperations are generated, signed, and executed via `EntryPoint.handleOps` in local tests.

Public-network note:
- This implementation is not currently executed on Ethereum testnet due to support limitations in this setup.
- Mainnet execution is intentionally deferred because gas costs are a practical barrier at this stage.

Next focus:
- Extend the same flow for **zkSync** account abstraction in a future phase.

## What Is Implemented So Far

- `MinimalAccount.sol`
  - Owner-controlled smart account.
  - `execute` function callable by owner or EntryPoint.
  - `validateUserOp` signature validation using ECDSA.
  - Prefund logic for missing account funds.

- Scripts
  - `Helper.s.sol`: network config + local EntryPoint deployment for Anvil.
  - `DeployMinimal.s.sol`: deploys `MinimalAccount`.
  - `SendPackedUserOp.s.sol`: builds unsigned UserOp, hashes via EntryPoint, signs, and returns packed op.

- Tests (`MinimalAccount.t.sol`)
  - Owner can execute calls.
  - Non-owner cannot execute calls directly.
  - UserOp signature recovery is correct.
  - `validateUserOp` returns success for valid signature.
  - EntryPoint can process operation and execute token mint on behalf of account.

## Project Structure

```text
Account Abstraction/
├── src/ethereum/MinimalAccount.sol
├── script/Helper.s.sol
├── script/DeployMinimal.s.sol
├── script/SendPackedUserOp.s.sol
├── test/ethereum/MinimalAccount.t.sol
└── foundry.toml
```

## Dependencies

- `eth-infinitism/account-abstraction` `v0.9.0`
- `OpenZeppelin Contracts` `v5.5.0`
- `forge-std` `v1.15.0`

## Run Locally

```bash
forge build
forge test -vvv
```

## Why This Project

The goal is to deeply understand account abstraction by implementing the flow end-to-end:
- account contract auth model
- UserOperation construction and signing
- EntryPoint validation + execution path
- gas funding behavior in practice

## Roadmap

1. Add zkSync-native AA implementation.
2. Port UserOperation-style flow where applicable to zkSync tooling/model.
3. Add deployment scripts + tests for zkSync network.
4. Compare Ethereum ERC-4337 vs zkSync AA developer experience and constraints.

## Status

Ethereum milestone is complete from a contract + script + local test perspective.  
Live Ethereum deployment/execution is currently deferred (testnet support constraints and mainnet cost barrier).  
zkSync integration is planned as the next major milestone.
