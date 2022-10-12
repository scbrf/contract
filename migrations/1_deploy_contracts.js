var Donate = artifacts.require("Donate");

module.exports = function (deployer) {
  // Deploy the SolidityContract contract as our only task
  deployer.deploy(Donate);
};
