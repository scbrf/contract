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
    await inst.donate("ipns1", "uuid1", 100, { from: accounts[1], value: 200 });
    var res = await inst.hot50();
    assert.equal(res[1].toNumber(), 1, "should be succ");
    assert.equal(res[0].length, 50, "should be ipns1");
    assert.equal(res[0][0].ipns, "ipns1", "should be ipns1");

    await inst.donate("ipns2", "uuid2", 100, { from: accounts[1], value: 300 });
    res = await inst.hot50();
    assert.equal(res[1].toNumber(), 2, "should be succ");
    assert.equal(res[0][0].ipns, "ipns2", "should be ipns2");

    await inst.donate("ipns3", "uuid3", 100, { from: accounts[1], value: 100 });
    res = await inst.hot50();
    assert.equal(res[1].toNumber(), 3, "should be succ");
    assert.equal(res[0][2].ipns, "ipns3", "should be ipns3");

    await advanceTimeAndBlock(200);
    res = await inst.hot50();
    assert.equal(res[1].toNumber(), 0, "should be 0");

    await inst.donate("ipns4", "uuid4", 100, { from: accounts[1], value: 300 });
    res = await inst.hot50();
    assert.equal(res[1].toNumber(), 1, "should be succ");
    assert.equal(res[0][0].ipns, "ipns4", "should be ipn4");
  });

  it("test limit", async () => {
    const inst = await Donate.deployed();
    let gotEx = false;
    try {
      await inst.donate("ipns3", "uuid3", 4 * 24 * 3600, {
        from: accounts[1],
        value: 1,
      });
    } catch (ex) {
      assert(ex.message.endsWith("less than limit."), "should exception");
      gotEx = true;
    }
    assert(gotEx, "should got ex");

    gotEx = false;
    try {
      await inst.setLimit(7 * 24 * 3600, { from: accounts[1] });
    } catch (ex) {
      gotEx = true;
    }
    assert(gotEx, "should only be owner");
    await inst.setLimit(7 * 24 * 3600, { from: accounts[0] });

    await inst.donate("ipns3", "uuid3", 4 * 24 * 3600, {
      from: accounts[1],
      value: 1,
    });
  });

  it("test balance", async () => {
    const inst = await Donate.deployed();
    const balance = await web3.eth.getBalance(accounts[0]);
    await inst.donate("ipns3", "uuid3", 2 * 24 * 3600, {
      from: accounts[1],
      value: 100,
    });
    const balance2 = await web3.eth.getBalance(accounts[0]);
    assert(
      web3.utils
        .toBN(balance)
        .add(web3.utils.toBN(100))
        .eq(web3.utils.toBN(balance2)),
      "should have new money"
    );
  });

  it("test time pause", async () => {
    const inst = await Donate.deployed();
    await advanceTimeAndBlock(10 * 24 * 3600); //让之前的都过期
    for (let i = 0; i < 51; i++) {
      //增加51个
      await inst.donate("ipns1", `uuid${i}`, 100 * (i + 1), {
        from: accounts[1],
        value: 2000,
      });
    }
    let res = await inst.hot50();
    assert.equal(res[1].toNumber(), 51, "should be last one");
    await advanceTimeAndBlock(10000);
    res = await inst.hot50();
    assert.equal(res[1].toNumber(), 1, "should be last one");
  });
});
