import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    arbitrumSepolia: {
      url: process.env.ALCHEMY_ARB_SEPOLIA_CONNECTION_STR || "",
      accounts: [process.env.ARB_WALLET_PRIVATE_KEY || ""]
    }
  },
  etherscan: {
    apiKey: {
      arbitrumSepolia: process.env.ARBISCAN_API_KEY || ""
    }
  }
};

export default config;
