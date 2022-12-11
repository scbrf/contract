// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Onlyfans is Ownable { 
  struct Fan {
    bytes pubkey;
    uint expire;
  }
  struct Planet {
    uint price; //per day
    address owner;
    bytes signature;
    mapping(address=>uint) idxes;
    Fan[] fans;
  }
  mapping(bytes32 => Planet) store;
  uint public rate = 30;

  event PlanetRegistered(bytes32 indexed ipns, address indexed owner, uint price);
  event FanAdded(bytes32 indexed ipns, address indexed fan, uint expire);

  function planet(bytes32 ipns) public view returns (uint, address, bytes memory) {
    return (store[ipns].price, store[ipns].owner, store[ipns].signature);
  }
 
  function planetFans(bytes32 ipns, bool senderOnly) public view returns (Fan[] memory) {
    if (senderOnly) {
      uint senderIdx = store[ipns].idxes[msg.sender];
      if (senderIdx != 0) {
        Fan[] memory ret1 = new Fan[](1);
        ret1[0] = store[ipns].fans[senderIdx];
        return ret1;
      }
      return new Fan[](0);
    }

    uint total = 0;
    for (uint i=0;i<store[ipns].fans.length;i++) {
      if (store[ipns].fans[i].expire >= block.timestamp) {
        total++;
      }
    }

    Fan[] memory result = new Fan[](total);
    uint idx=0;
    for (uint i=0;i<store[ipns].fans.length;i++) {
      if (store[ipns].fans[i].expire >= block.timestamp) {
        result[idx++] = store[ipns].fans[i];
      }
    }

    return result;
  }

  function setRate(uint value) public onlyOwner {
    rate = value;
  }

  /**
    when regist planet, need provide public key of ipns, sign owner + price,
    client should check sign before do subscribe
   */
  function registerPlanet(bytes32 ipns, bytes memory signature, address owner, uint price) public {
    require(store[ipns].owner == address(0x0) || msg.sender == store[ipns].owner, "only allowed by old owner");
    require(price > 0, "price should large than 0");

    store[ipns].price = price;
    store[ipns].owner = owner;
    store[ipns].signature = signature;

    if (store[ipns].fans.length == 0) {
      store[ipns].fans.push(Fan("", 1)); //first element invalid
    }

    emit PlanetRegistered(ipns, owner, price);
  }

  function checkPubKey(bytes memory pubkey, address addr) internal pure  returns (bool){
    return address(uint160(uint256(keccak256(pubkey)))) == addr;
  }

  function subscribe(bytes32 ipns, uint duration, bytes memory pubkey) payable public {
    require(checkPubKey(pubkey, msg.sender), "pubkey mismatch");
    require(store[ipns].owner != address(0x0), "has owner");
    require(msg.value == duration * store[ipns].price, "need exactly equal value!");

    uint idx = store[ipns].idxes[msg.sender];
    if (idx == 0) {
      store[ipns].fans.push(Fan(pubkey, 0));
      idx = store[ipns].fans.length - 1;
      store[ipns].idxes[msg.sender] = idx;
    }
    uint expire = store[ipns].fans[idx].expire > block.timestamp ? store[ipns].fans[idx].expire : block.timestamp;
    store[ipns].fans[idx].expire = expire + duration * 24 * 3600;

    uint fee = msg.value * rate / 100;
    uint left = msg.value - fee;
    if (fee > 0) {
      payable(owner()).transfer(fee);
    }
    payable(store[ipns].owner).transfer(left);
    emit FanAdded(ipns, msg.sender, store[ipns].fans[idx].expire);
  }

}
