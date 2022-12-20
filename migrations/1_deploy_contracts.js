var Onlyfans = artifacts.require("Onlyfans");

module.exports = function (deployer) {
  // Deploy the SolidityContract contract as our only task
  deployer.deploy(Onlyfans);
};
