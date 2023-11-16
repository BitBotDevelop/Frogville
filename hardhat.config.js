/** @type import('hardhat/config').HardhatUserConfig */
require('hardhat-abi-exporter');
require('@nomiclabs/hardhat-ethers');
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require('@openzeppelin/hardhat-upgrades');

require('dotenv').config();

const { GOERLO_OP_API_URL, GOERLO_API_URL , PRIVATE_KEY } = process.env;



module.exports = {
  solidity: "0.8.17",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },

  networks: {
    goerli_op : {
      "url": GOERLO_OP_API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      // should set gasPrice, otherwise, ' transaction underpriced' occurs
      gasPrice: 10000000000, 
    },
    goerli: {
      "url": GOERLO_API_URL,
      accounts: [`0x${PRIVATE_KEY}`] 
    }
  },
  abiExporter: {
    path: './data/abi',
    runOnCompile: true,
    clear: true,
    flat: true,
    // only: [':Fission$'],
    spacing: 2,
    pretty: true
  }
};
