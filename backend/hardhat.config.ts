import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

task("accounts", "Prints the list of accounts", async (args, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});

// Go to https://infura.io, sign up, create a new API key
// in its dashboard, and replace "KEY" with it
const INFURA_API_KEY = "alcht_NBNXw4ua07Z4U4F4g3DD3S9jvWa5VI";

// Replace this private key with your Sepolia account private key
// To export your private key from Coinbase Wallet, go to
// Settings > Developer Settings > Show private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Beware: NEVER put real Ether into testing accounts
const SEPOLIA_PRIVATE_KEY = "b6418d52a78f42ac4a6f3743ab4ac23fa3bc55ac67e936bb4ca6a7fc1403baff";

// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${INFURA_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY]
    },
    localhost: {
      chainId: 31337,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk", // test test test test test test test test test test test junk
      },
    },
    // hardhat: {
    //   accounts: [
    //     {
    //       balance: "10000000000000000000000",
    //       privateKey:
    //         "0xe87d780e4c31c953a68aef2763df56599c9cfe73df4740fc24c2d0f5acd21bae",
    //     },
    //   ],
    // },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 50,
          },
        },
      },
    ],
  },
  paths: {
    artifacts: '../frontend/app/artifacts',
  },

};
export default config;
