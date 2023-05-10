import { HardhatUserConfig } from "hardhat/config";


import "@nomicfoundation/hardhat-toolbox";
import "hardhat-packager";
import "@nomiclabs/hardhat-solhint";
import "hardhat-gas-reporter"
import "hardhat-spdx-license-identifier"
import "hardhat-tracer";

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.17",
        settings: {
            optimizer: {
                enabled: true,
                runs: 2000,
                details: {
                    yul: true,
                    yulDetails: {
                        stackAllocation: true,
                        optimizerSteps: "u"
                    }
                }
            }
        },
    },
    paths: {
        sources: "./src",
    },
    packager: {
        contracts: ["LibColorRGB"],
        includeFactories: false,
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS ? true : false,
        currency: 'USD',
        gasPrice: 40,
        onlyCalledMethods: false,
        showMethodSig: true,
    },
    typechain: {
        outDir: 'src/types',
        target: 'ethers-v5',
    },
    spdxLicenseIdentifier: {
        overwrite: true,
        runOnCompile: true
    }
};

export default config;
