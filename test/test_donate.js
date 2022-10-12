const TestDonate = artifacts.require("TestDonate");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("TestDonate", function (/* accounts */) {
  it("should assert true", async function () {
    await TestDonate.deployed();
    return assert.isTrue(true);
  });
});
