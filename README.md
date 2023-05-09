# 🐺🐺 Remus

When Romulus and Remus became adults, they decided to found a city where the wolf had found them. This is my city, a collection of semi-opinionated, lightweight, and build-ready EVM primitives for smart contract development.

```ml
contracts
├─ auth
├─ ├─ extensions
|  |  ├─ ✅ NBadgeAuthConsumer- "Localized consumer of a Network Governors NBadge permission constitutions."
├─ ├─ modules
|  |  ├─ ✅ NBadgeModule - "Extendable framework for creating a plug-and-play registry access module."
|  |  ├─ ✅ NBadgeIdPacked - "Gating by multiple token ids of a single Badge collection."
|  |  ├─ ✅ NBadgeMultiBalance - "Simple gating by a cumulative balance of Badges held."
|  |  ├─ ✅ NBadgeMultiBalancePoints - "Complex gating by a cumulative point-driven system based on Badges held."
|  ├─ ✅ BadgeAccessControl - "Variant of OpenZeppelin AccessControl using ERC1155 Badges."
|  ├─ ✅ NBadgeAuth - "On-chain access control powered by complex uses of ERC1155 Badges."
|  ├─ ✅ NBadgeRegistry - "Public shared-access registry powering Badged credentials with simple inheritance."
├─ lib
|  ├─ ✅ LibColorRGB - "Library for working with RGB colors."
├─ math
|  ├─ ⏳ MathlessCurves - "Shapeless curves for the EVM using Fourier series."
├─ metatx
|  ├─ ✅ BadgingForwarder - "Forwarder contract that mints a Badge upon transaction execution."
```

## Commands

- `pnpm audit`
- `pnpm build`
- `pnpm test`

## Safety

This is experimental software and is provided on an "as is" and "as available" basis.

We do not give any warranties and will not be liable for any loss incurred through any use of this codebase.
