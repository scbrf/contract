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
    mapping(address=>uint) idxes;
    Fan[] fans;
  }
  mapping(string => Planet) store;
  uint public rate = 30;

  event PlanetAdded(string ipns, address owner, uint price);
  event PlanetModified(string ipns, address owner,uint price);
  event FanAdded(string ipns, address fan, uint expire);

  function myfans(string memory ipns) public view returns (Fan[] memory) {
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

  function registerPlanet(string memory ipns, address owner, uint price) public {
    require(store[ipns].owner == address(0x0) || msg.sender == store[ipns].owner, "only allowed by old owner");
    require(price > 0, "price should large than 0");
    store[ipns].price = price;
    store[ipns].owner = owner;
    if (store[ipns].fans.length == 0) {
      store[ipns].fans.push(Fan("", 1)); //first element invalid
    }
    emit PlanetModified(ipns, owner, price);
  }

  function checkPubKey(bytes memory pubkey, address addr) internal pure  returns (bool){
    return address(uint160(uint256(keccak256(pubkey)))) == addr;
  }

  function subscribe(string memory ipns, uint duration, bytes memory pubkey) payable public {
    require(checkPubKey(pubkey, msg.sender), "pubkey mismatch");
    require(store[ipns].owner != address(0x0), "has owner");
    require(msg.value == duration * store[ipns].price, "need exactly equal value!");

    uint idx = store[ipns].idxes[msg.sender];
    if (idx == 0) {
      store[ipns].fans.push(Fan(pubkey, 0));
      idx = store[ipns].fans.length - 1;
    }
    uint expire = store[ipns].fans[idx].expire > block.timestamp ? store[ipns].fans[idx].expire : block.timestamp;
    store[ipns].fans[idx].expire = expire + duration;

    uint fee = msg.value * rate / 100;
    uint left = msg.value - fee;
    if (fee > 0) {
      payable(owner()).transfer(fee);
    }
    payable(store[ipns].owner).transfer(left);
    emit FanAdded(ipns, msg.sender, store[ipns].fans[idx].expire);
  }

}
