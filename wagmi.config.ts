import { defineConfig } from '@wagmi/cli'

import { actions, hardhat, react } from '@wagmi/cli/plugins'

export default defineConfig({
    out: 'src/hooks.ts',
    contracts: [],
    plugins: [
        actions({
            readContract: true,
        }),
        hardhat({
            commands: {
                clean: 'pnpm clean',
                build: 'pnpm hardhat compile',
                rebuild: 'pnpm hardhat compile',
            },
            project: './'
        }),
        react({
            useContractRead: true,
            useContractFunctionRead: true
        })
    ],
})
