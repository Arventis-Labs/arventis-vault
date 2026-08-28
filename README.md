# Arventis Vault (ERC-4626)

A low-level, highly gas-optimized, and audit-grade ERC-4626 Tokenized Vault implementation built with inline Yul/Assembly and rigorous invariant testing.

Developed by **Arventis Labs** (Hesam Qorbani & Ali Elahi).

---

## 🛠 Features & Architecture

* **Inline Yul / Assembly Math:** Pure EVM assembly operations in `VaultMath.sol` for exact deposit/mint/withdraw/redeem conversions, defense against rounding inflation attacks, and maximum gas efficiency.
* **Property-Based Invariants:** Over 11,000+ stateful fuzzing calls generated via Foundry to mathematically prove vault solvency under extreme edge cases.
* **Automated Static Analysis:** Fully integrated Slither security analyzer in the CI/CD pipeline.
* **Strict Code Quality:** Enforced `forge fmt` formatting and automated testing workflow on every push/PR.

---

## ⚡ Quickstart

### Prerequisites
* [Foundry](https://getfoundry.sh/)

### Build
```bash
forge build