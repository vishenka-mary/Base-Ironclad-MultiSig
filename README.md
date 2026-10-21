# Base Ironclad MultiSig

A highly resilient, decentralized multi-signature wallet deployed on the Base L2 network. Ironclad MultiSig requires a predefined M-of-N consensus threshold to execute any on-chain transaction, providing enterprise-grade security for DAO treasuries and protocol administration.

## Core Mechanics
* **Threshold Consensus:** Transactions remain in a pending state until the required number of authorized owners mathematically verify and confirm the payload.
* **Immutable Execution:** Once a transaction reaches the consensus threshold, it can be executed trustlessly by any owner, routing the exact `msg.value` and `calldata` to the target address.
* **Dynamic Owner Management:** Includes secure internal mechanisms to add, remove, or replace owners and adjust the required confirmation threshold, strictly requiring a multisig consensus to alter its own security parameters.

## Security Architecture
Built using Solidity `0.8.37`. The protocol strictly isolates state changes from external calls during transaction execution, fully preventing reentrancy attacks while maintaining a clear, auditable trail of all signatures and proposals.
