# Account Abstraction (ERC-4337 + zkSync Native AA) - Foundry Project

This project is a hands-on implementation of account abstraction in Foundry across:
- Ethereum (ERC-4337 flow via EntryPoint)
- zkSync Era (native account abstraction flow)

Current status:
- Ethereum ERC-4337 implementation is complete at local/dev level.
- zkSync native AA implementation is complete at local/dev level.
- Both flows are tested locally.

Public-network note:
- Ethereum testnet/mainnet execution is currently deferred in this setup.
- zkSync Sepolia/live deployment flow is also not yet finalized in this repo.

## What Is Implemented So Far

### Ethereum (ERC-4337)

- `src/ethereum/MinimalAccount.sol`
  - Owner-controlled smart account.
  - `execute` function callable by owner or EntryPoint.
  - `validateUserOp` signature validation using ECDSA.
  - Prefund logic for missing account funds.

- `test/ethereum/MinimalAccount.t.sol`
  - Owner can execute calls.
  - Non-owner cannot execute calls directly.
  - UserOp signature recovery is correct.
  - `validateUserOp` returns success for valid signature.
  - EntryPoint can process operation and execute token mint on behalf of account.

### zkSync (Native AA)

- `src/zksync/ZkMinimalAccount.sol`
  - Implements zkSync `IAccount`.
  - Bootloader-gated validation path.
  - Owner/bootloader execution path.
  - Signature validation via zkSync transaction hash (`MemoryTransactionHelper.encodeHash`).

- `test/zksync/ZkMinimalAccount.t.sol`
  - Owner can execute account commands.
  - `validateTransaction` returns `ACCOUNT_VALIDATION_SUCCESS_MAGIC` for valid signed tx.

### Scripts

- `script/Helper.s.sol`: network config helper (Ethereum + zkSync constants).
- `script/DeployMinimal.s.sol`: deploys `MinimalAccount`.
- `script/SendPackedUserOp.s.sol`: builds/signs packed UserOperation for ERC-4337 flow.

## Project Structure

```text
Account Abstraction/
├── src/ethereum/MinimalAccount.sol
├── src/zksync/ZkMinimalAccount.sol
├── script/Helper.s.sol
├── script/DeployMinimal.s.sol
├── script/SendPackedUserOp.s.sol
├── test/ethereum/MinimalAccount.t.sol
├── test/zksync/ZkMinimalAccount.t.sol
└── foundry.toml
```

## Dependencies

- `eth-infinitism/account-abstraction` `v0.9.0`
- `OpenZeppelin Contracts` `v5.5.0`
- `forge-std` `v1.15.0`

## Important Note (Local Library Patch)

This repo currently includes a local patch in vendored dependency code:
- `lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol`

Reason:
- `forge test --zksync` with `solc 0.8.30` fails with a stack/codegen error in `_encodeHashEIP712Transaction` from upstream code.

What was changed:
- Pre-hashed dynamic fields and used packed encoding in that hashing path to avoid the compiler issue while preserving hash semantics for fixed-size fields.

Before (upstream-style snippet):
```solidity
function _encodeHashEIP712Transaction(Transaction memory _transaction) private view returns (bytes32) {
    bytes32 structHash = keccak256(
        abi.encode(
            EIP712_TRANSACTION_TYPE_HASH,
            _transaction.txType,
            _transaction.from,
            _transaction.to,
            _transaction.gasLimit,
            _transaction.gasPerPubdataByteLimit,
            _transaction.maxFeePerGas,
            _transaction.maxPriorityFeePerGas,
            _transaction.paymaster,
            _transaction.nonce,
            _transaction.value,
            keccak256(_transaction.data),
            keccak256(abi.encodePacked(_transaction.factoryDeps)),
            keccak256(_transaction.paymasterInput)
        )
    );
}
```

After (local workaround in this repo):
```solidity
function _encodeHashEIP712Transaction(Transaction memory _transaction) private view returns (bytes32) {
    bytes32 dataHash = keccak256(_transaction.data);
    bytes32 factoryDepsHash = keccak256(abi.encodePacked(_transaction.factoryDeps));
    bytes32 paymasterInputHash = keccak256(_transaction.paymasterInput);
    bytes32 structHash = keccak256(
        abi.encodePacked(
            EIP712_TRANSACTION_TYPE_HASH,
            _transaction.txType,
            _transaction.from,
            _transaction.to,
            _transaction.gasLimit,
            _transaction.gasPerPubdataByteLimit,
            _transaction.maxFeePerGas,
            _transaction.maxPriorityFeePerGas,
            _transaction.paymaster,
            _transaction.nonce,
            _transaction.value,
            dataHash,
            factoryDepsHash,
            paymasterInputHash
        )
    );
}
```

Scope:
- This is a temporary compatibility workaround for this toolchain combination.
- Prefer removing this patch after upstream/toolchain provides a clean fix.

## Run Locally

```bash
forge build
forge test -vvv
forge test --zksync -vvv
```

## Why This Project

The goal is to deeply understand account abstraction by implementing the flow end-to-end:
- account contract auth model
- ERC-4337 UserOperation construction and signing
- EntryPoint validation + execution path
- zkSync native transaction validation/execution path
- gas funding behavior in practice

## Roadmap

1. Add deployment scripts for zkSync Sepolia and run end-to-end deployment checks.
2. Expand zkSync tests to cover `executeTransactionFromOutside`, paymaster flow, and failure paths.
3. Add CI matrix for both EVM and `--zksync` test runs.
4. Compare Ethereum ERC-4337 vs zkSync native AA behavior and DX in a dedicated write-up.

## Status

Ethereum ERC-4337 and zkSync native AA milestones are complete from a contract + local test perspective.  
Live public-network deployment/execution is currently deferred.  
Current focus is productionizing the deployment flow and improving test coverage for edge cases.
