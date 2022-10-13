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

  event ContentAdded(string ipns, string uuid, uint duration, uint pos);
  event ContentTimePaused(string ipns, string uuid, uint duration);
  event ContentTimeRecovery(string ipns, string uuid, uint duration, uint pos);
  event ContentRemoved(string ipns, string uuid);

  function hot50() public view returns (Article[50] memory, uint) {
    Article[50] memory ret;
    uint len =0;
    for (uint i=0;i<queue.length;i++) {
      if (queue[i].when > 0 && (queue[i].when + queue[i].duration < block.timestamp)) {
        //已经过期的不再进入hot50
        continue;
      }
      if (len < 50) {
        ret[len++] = queue[i]; 
      } else {
        len++;
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

    //第0步，为了节约gas费合约不检查Uuid的重复插入，同一个uuid视作同一个文章，但是阅读端可能会检查uuid的重复性，同一个uuid只显示一次

    uint ret = 0;

    //第一步：根据 unit price 插入合适的位置
    uint thisValue = msg.value / duration;
    bool inserted = false;
    for (uint i=0;i<queue.length; i++) {
      uint thatValue = queue[i].value / queue[i].duration; //当单位价格低于1聪时，出价高者不一定排在前面因为结果去zheng
      if (thisValue >= thatValue) {
        queue.push(Article('','',0,0,0));
        for (uint j=queue.length - 2;j>=i;j--) {
          queue[j+1] = queue[j];
          if (j==i) break;//for safe
        }
        ret = i;
        queue[i] = Article(ipns, uuid, msg.value, block.timestamp, duration);
        inserted = true;
        break;
      }
    }
    if (!inserted) {
      queue.push(Article(ipns, uuid, msg.value, block.timestamp, duration));
      ret = queue.length -1;
    }

    //第二步，对于边界文章，如果还没有过期，就时间静止
    if (queue.length > 50) {
      if (queue[50].when + queue[50].duration > block.timestamp) {
        queue[50].duration = queue[50].when + queue[50].duration - block.timestamp;
        queue[50].when = 0; // 0 是时间静止标记
        emit ContentTimePaused(queue[50].ipns, queue[50].uuid, queue[50].duration);
      }
    }

    //第三步：移除已经过期的文章，只移除前50内的文章因为50以后属于时间静止的状态
    uint totalRemoved=0;
    for (uint8 i=0;i<50;i++) {
      if (i >= queue.length) {
        break;
      }
      if (queue[i].when + queue[i].duration <= block.timestamp) {
        for (uint j=i+1;j<queue.length;j++) {
          queue[j-1] = queue[j];
        }
        if (i<ret) {
          ret--;
        }
        totalRemoved++;
        emit ContentRemoved(queue[i].ipns, queue[i].uuid);
      }
    }
    for (uint i=0;i<totalRemoved;i++) {
      queue.pop();
    }

    //第四步：对于进入前50的时间静止的文章，时间恢复运行
    for (uint8 i=0;i<50;i++) {
      if (i >= queue.length) {
        break;
      }
      if (queue[i].when == 0) {
        queue[i].when = block.timestamp;
        emit ContentTimeRecovery(queue[i].ipns, queue[i].uuid, queue[i].duration, i);
      }
    }

    emit ContentAdded(ipns, uuid, duration, ret);

    //第五步 接受捐赠
    payable(owner()).transfer(msg.value);

  }

}
