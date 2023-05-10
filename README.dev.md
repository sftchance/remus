# 🐺 Remus in Development

At the core, Remus has been built on top of `pnpm` and `hardhat`. This allows for a more modular and flexible development environment. With clear separation of dependencies, we can easily test and debug contracts in isolation without requiring the user to even have `pnpm` installed.

## Building

- Install `pnpm` globally: `npm install -g pnpm`
- Install dependencies: `pnpm install`
- Build contracts: `pnpm run build`

## Commands

- `pnpm run build` - "Compile contracts and generate typechain typings."
- `pnpm run dev` - "Debug contracts and functions in isolation using Hardhat tests."
- `pnpm run test` - "Run all tests."
