// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Onlyfans is Ownable { 
  struct Planet {
    uint price; //per day
    address owner;
    mapping(address=>uint) subscriptions;
  }
  mapping(bytes32 => Planet) public store;
  mapping(address => bytes32) public metas;
  uint public rate = 30;

  event PlanetRegistered(bytes32 indexed ipns, address indexed owner, uint indexed price);
  event PlanetSubscribed(bytes32 indexed ipns, address indexed fan, uint indexed expire);

  function setRate(uint value) public onlyOwner {
    rate = value;
  }

  function registerPlanet(bytes32 meta, bytes32 ipns, uint price) public {
    require(store[ipns].owner == address(0x0) || msg.sender == store[ipns].owner, "only allowed by old owner");
    require(price > 0, "price should large than 0");

    store[ipns].price = price;
    store[ipns].owner = msg.sender;
    metas[msg.sender] = meta;

    emit PlanetRegistered(ipns, msg.sender, price);
  }

  function subscribe(bytes32 meta, bytes32 ipns, uint duration) payable public {
    require(store[ipns].owner != address(0x0), "has owner");
    require(duration > 0, "duration should large than 0");
    require(msg.value == duration * store[ipns].price, "need exactly equal value!");

    metas[msg.sender] = meta;

    uint expire = store[ipns].subscriptions[msg.sender] > block.timestamp ? store[ipns].subscriptions[msg.sender] : block.timestamp;
    store[ipns].subscriptions[msg.sender] = expire + duration * 24 * 3600;

    uint fee = msg.value * rate / 100;
    uint left = msg.value - fee;
    if (fee > 0) {
      payable(owner()).transfer(fee);
    }
    if (left > 0) {
      payable(store[ipns].owner).transfer(left);
    }
    emit PlanetSubscribed(ipns, msg.sender, store[ipns].subscriptions[msg.sender]);
  }

}
