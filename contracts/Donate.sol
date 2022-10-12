// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Donate { 
  struct Article {
    string ipns;
    string uuid;
    uint value;
    uint when;
    uint duration;
  }
  uint public DurationLimit = 3600 * 24 *3;
  Article[] queue;

  function donate(string memory ipns, string memory uuid, uint value, uint duration) payable public {
    require(bytes(ipns).length >0, "ipns cannot be empty");
    require(bytes(ipns).length <100, "ipns too long");
    require(bytes(uuid).length >0, "uuid cannot be empty");
    require(bytes(uuid).length <50, "uuid too long");
    require(value > 0, "donate shoule be large than 0");
    require(duration > 0, "duration shoule be large than 0");
    require(msg.value > value, "duration shoule be large than 0");

    uint needPop = 0;
    bool pluged = false;
    for (uint i=0;i<queue.length-needPop; i++) {
      if (queue[i].when + queue[i].duration < block.timestamp) {
        if (!pluged && (value >= queue[i].value)) {
          queue[i] = Article(ipns, uuid, value, block.timestamp, duration);
          pluged = true;
          continue;
        }
        //shift array items forward and remove last
        for (uint j=i+1;i<queue.length;j++) {
          queue[j-1] = queue[j];
        }
        needPop++;
        i--;
      }
    }
    for (uint i=0;i<needPop;i++) {
      queue.pop();
    }
    if (!pluged) {
      queue.push(Article(ipns, uuid, value, block.timestamp, duration));
    }

  }

}
