pragma solidity >= 0.6.4;

import './ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';

contract synSales is Owned {
  using SafeMath for uint256;

  constructor() public {
    SYN = IERC20(0x1695936d6a953df699C38CA21c2140d497C08BD9);
    maxSYN = 2 * 10**6 * 10**18;
    initPrice = 101089 * 10**10;
    maxPriceInc = 2 * 10**15;
    maxETH = maxSYN.mul(initPrice).div(10**18)
              .add(maxSYN.mul(maxPriceInc).div(2 * 10**18));
  }

  event userBuy(
      address account,
      uint256 syn,
      uint256 eth,
      uint256 date
  );
  event userWithdraw(
      address account,
      uint256 syn
  );

  struct buyStruct {
    uint256 syn;
    uint256 date;
    bool withdrawn;
  }

  IERC20 public SYN;
  uint256 public maxSYN;
  uint256 public maxETH;
  uint256 public initPrice;
  uint256 public maxPriceInc;

  mapping(address => uint256) public userNonce;
  mapping(address => mapping(uint256 => buyStruct)) public userBuys;

  uint256 public synSold;
  uint256 public ethPaid;

  function buy(uint256 maxPrice) public payable {
    require(msg.value > 0);
    uint256 eth = msg.value;
    uint256 buyPrice = getBuyPrice(eth);
    require(maxPrice >= buyPrice);
    uint256 syn = eth.mul(1 ether).div(buyPrice);
    uint256 date = block.timestamp.add(1 weeks);
    userBuys[msg.sender][userNonce[msg.sender]].syn = syn;
    userBuys[msg.sender][userNonce[msg.sender]].date = date;

    require(maxSYN >= synSold.add(syn));
    synSold = synSold.add(syn);
    ethPaid = ethPaid.add(eth);

    userNonce[msg.sender] += 1;

    emit userBuy(msg.sender, syn, eth, date);
  }

  function withdraw(uint256[] memory nonces) public returns(uint256) {
    for(uint256 i = 0; i < nonces.length; i++) {
      if(userBuys[msg.sender][nonces[i]].date <= block.timestamp && userBuys[msg.sender][nonces[i]].date != 0){
        if(userBuys[msg.sender][nonces[i]].withdrawn == false){
          userBuys[msg.sender][nonces[i]].withdrawn = true;
          SYN.transfer(msg.sender, userBuys[msg.sender][nonces[i]].syn);
        }
      }
    }
    return(block.timestamp);
  }

  function getBuyPrice(uint256 eth) public view returns(uint256) {
    uint256 p1 = ethPaid.mul(maxPriceInc).div(maxETH);
    uint256 p2 = ethPaid.add(eth).mul(maxPriceInc).div(maxETH);
    return(p1.add(p2).div(2).add(initPrice));
  }

  function tokenremove(IERC20 token, uint256 amount) public onlyOwner() {
    require(token != SYN);
    token.transfer(msg.sender, amount);
  }

  function ethremove() public onlyOwner() {
    address payable owner = msg.sender;
    owner.transfer(address(this).balance);
  }

}

