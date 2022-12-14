const Onlyfans = artifacts.require("Onlyfans");
const { ethers } = require("ethers");

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
const wallet = new ethers.Wallet(
  "0xc39574f139c922be5dfefebb889a2b85eadb8bfc1df5dd98d5d6ca1a139207a5"
);
const selfMeta = "0x000102030405060708090a0b0c0d0e0e";
const ipns = "0x000102030405060708090a0b0c0d0e0f";
contract("TestOnlyfans", function (accounts) {
  it("subscribe none should be fail", async () => {
    const inst = await Onlyfans.deployed();
    try {
      await inst.subscribe(selfMeta, ipns, 7, {
        from: accounts[1],
      });
    } catch (ex) {
      assert(ex.message.endsWith("has owner."), "should exception");
    }
    let rate = await inst.rate();
    assert(rate == 30, "default rate is 30");
    await inst.setRate(40);
    rate = await inst.rate();
    assert(rate == 40, "should be changable");
    await inst.setRate(0);
    rate = await inst.rate();
    assert(rate == 0, "could be 0");
  });

  it("normal subscribe", async () => {
    const inst = await Onlyfans.deployed();
    const result1 = await inst.registerPlanet(selfMeta, ipns, 1000);
    assert(result1.logs.length == 1, "should have logs");
    const result2 = await inst.subscribe(selfMeta, ipns, 7, {
      from: accounts[1],
      value: 7000,
    });
    assert(result2.logs.length == 1, "should have logs");
  });
});
