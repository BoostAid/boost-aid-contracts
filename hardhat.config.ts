import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'dotenv/config';

const config: HardhatUserConfig = {
  solidity: '0.8.18',
  networks: {
    arbitrumSepolia: {
      url: process.env.ALCHEMY_ARB_SEPOLIA_CONNECTION_STR || '',
      accounts: [process.env.OWNER_PRIVATE_KEY || ''],
    },
    shibariumTestnet: {
      url: process.env.PUPPYNET_TESTNET_RPC_URL || '',
      accounts: [process.env.OWNER_PRIVATE_KEY || ''],
    },
  },
  etherscan: {
    apiKey: {
      arbitrumSepolia: process.env.ARBISCAN_API_KEY || '',
      shibariumTestnet: 'empty',
    },
    customChains: [
      {
        network: 'shibariumTestnet',
        chainId: 157,
        urls: {
          apiURL: 'https://puppyscan.shib.io/api',
          browserURL: 'https://puppyscan.shib.io',
        },
      },
    ],
  },
};

export default config;
