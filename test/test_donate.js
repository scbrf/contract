const Donate = artifacts.require("Donate");

//From: https://medium.com/fluidity/standing-the-time-of-test-b906fcc374a9
advanceTime = (time) => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: "2.0",
        method: "evm_increaseTime",
        params: [time],
        id: new Date().getTime(),
      },
      (err, result) => {
        if (err) {
          return reject(err);
        }
        return resolve(result);
      }
    );
  });
};

advanceBlock = () => {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send(
      {
        jsonrpc: "2.0",
        method: "evm_mine",
        id: new Date().getTime(),
      },
      (err, result) => {
        if (err) {
          return reject(err);
        }
        const newBlockHash = web3.eth.getBlock("latest").hash;

        return resolve(newBlockHash);
      }
    );
  });
};

advanceTimeAndBlock = async (time) => {
  await advanceTime(time);
  await advanceBlock();
  return Promise.resolve(web3.eth.getBlock("latest"));
};

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("TestDonate", function (accounts) {
  it("first donate should be succ", async () => {
    const inst = await Donate.deployed();
    await inst.donate("ipns1", "uuid1", 1, { from: accounts[1], value: 2 });
    var res = await inst.hot50();
    assert.equal(res[1].toNumber(), 1, "should be succ");
    assert.equal(res[0].length, 50, "should be ipns1");
    assert.equal(res[0][0].ipns, "ipns1", "should be ipns1");

    await inst.donate("ipns2", "uuid2", 2, { from: accounts[1], value: 3 });
    res = await inst.hot50();
    assert.equal(res[1].toNumber(), 2, "should be succ");
    assert.equal(res[0][0].ipns, "ipns2", "should be ipns2");

    await inst.donate("ipns3", "uuid3", 2, { from: accounts[1], value: 1 });
    res = await inst.hot50();
    assert.equal(res[1].toNumber(), 3, "should be succ");
    assert.equal(res[0][2].ipns, "ipns3", "should be ipns3");

    await advanceTimeAndBlock(100);
    res = await inst.hot50();
    assert.equal(res[1].toNumber(), 0, "should be 0");

    await inst.donate("ipns4", "uuid4", 2, { from: accounts[1], value: 3 });
    res = await inst.hot50();
    assert.equal(res[1].toNumber(), 1, "should be succ");
    assert.equal(res[0][0].ipns, "ipns4", "should be ipns2");
  });
});
