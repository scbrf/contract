const { PRIVATEKEY, PROJECT_ID } = process.env;
const HDWalletProvider = require("@truffle/hdwallet-provider");
module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 9545,
      network_id: "*",
    },
    goerli: {
      provider: () =>
        new HDWalletProvider(
          PRIVATEKEY,
          `https://goerli.infura.io/v3/${PROJECT_ID}`
        ),
      network_id: 5,
      gasPrice: 68000000000,
    },
  },

  // Set default mocha options here, use special reporters, etc.
  mocha: {
    // timeout: 100000
  },
  plugins: ["truffle-contract-size"],
  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.17", // Fetch exact version from solc-bin (default: truffle's version)
    },
  },
};
