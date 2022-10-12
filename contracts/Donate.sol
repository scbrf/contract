// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Donate is Ownable { 
  struct Article {
    string ipns;
    string uuid;
    uint value;
    uint when;
    uint duration;
  }
  uint public DurationLimit = 3600 * 24 *3;
  Article[] queue;

  function hot50() public view returns (Article[50] memory, uint) {
    Article[50] memory ret;
    uint len =0;
    for (uint i=0;i<queue.length;i++) {
      if (len >= 50) break;
      if (queue[i].when + queue[i].duration < block.timestamp) {
        continue;
      }
      if (len <50) {
        ret[len++] = queue[i]; 
      }
    }
    return (ret, len);
  }

  function setLimit(uint v) public onlyOwner {
    DurationLimit = v;
  }

  function donate(string memory ipns, string memory uuid,  uint duration) payable public {
    require(bytes(ipns).length >0, "ipns cannot be empty");
    require(bytes(ipns).length <100, "ipns too long");
    require(bytes(uuid).length >0, "uuid cannot be empty");
    require(bytes(uuid).length <50, "uuid too long");
    require(msg.value > 0, "donate shoule be large than 0");
    require(duration > 0, "duration shoule be large than 0");
    require(duration < DurationLimit, "duration shoule be less than limit");

    uint needPop = 0;
    bool pluged = false;
    for (uint i=0;i<queue.length-needPop; i++) {
      if (queue[i].when + queue[i].duration < block.timestamp) {//已经过期
        if (!pluged && (msg.value >= queue[i].value)) { //最佳位置
          queue[i] = Article(ipns, uuid, msg.value, block.timestamp, duration);
          pluged = true;
          continue;
        }
        //shift array items forward and remove last
        for (uint j=i+1;j<queue.length;j++) {
          queue[j-1] = queue[j];
        }
        needPop++;
        i--;
      } else if (msg.value > queue[i].value) {//没有过期
        if (!pluged && (msg.value >= queue[i].value)) { //最佳位置
          queue.push(Article('','',0,0,0));
          for (uint j=queue.length - needPop - 2;j>=i;j--) {
            queue[j+1] = queue[j];
            if (j==i) break;//for safe
          }
          queue[i] = Article(ipns, uuid, msg.value, block.timestamp, duration);
          pluged = true;
        }
      }
    }
    for (uint i=0;i<needPop;i++) {
      queue.pop();
    }
    if (!pluged) {
      queue.push(Article(ipns, uuid, msg.value, block.timestamp, duration));
    }

    payable(owner()).transfer(msg.value);

  }

}
