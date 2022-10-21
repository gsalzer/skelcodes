pragma solidity >= 0.5.0 < 0.6.0;

import "./provableAPI_0.5.sol";


library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}


contract ERCDICE is usingProvable, Owned {
  using SafeMath for uint;
  constructor() public {
    provable_setProof(proofType_Ledger);
    provable_setCustomGasPrice(5000000000);
  }
  uint256 public GAS_FOR_CALLBACK = 200000;
  uint256 public QUERY_EXECUTION_DELAY = 0;
  uint256 public minrndpay = 1000000000000000;

  event LogNewProvableQuery(string description);

  event startroll(address user, address token, uint256 betamount, bool[6] picks, uint8 count, bytes32 queryId);
  event endroll(address user, address token, uint256 betamount, bytes32 queryId, uint256 payout, bool[6] picks, uint8 outcome);
  event withdrawalevt(address user, address token, uint256 amount, uint256 shares);
  event depositevt(address user, address token, uint256 amount, uint256 shares);

  struct proll {
    address token;
    bool[6] picks;
    uint8 count;
    uint8 outcome;
    address addr;
    uint256 amount;
  }

  mapping(address => uint256) public housebalance;
  mapping(address => mapping(address => uint256)) public backershares; //backershares[addr][token]
  mapping(address => uint256) public backervol;

  mapping(bytes32 => proll) public playerrolls;

  uint256 public max;

  address ETH = 0x0000000000000000000000000000000000000000;

  //PLAYER FUNCTIONS
  function Roll(address token, uint256 amount, bool[6] memory picks) payable public {
    require(amount <= backershares[msg.sender][token]);

    if (minrndpay > msg.value) {
      emit LogNewProvableQuery("you need to pay for gas, bitch");
    }
    else {

      uint8 c;
      for (uint8 i = 0; i < 6; i++) {
        if (picks[i] == true) {
          c = c + 1;
        }
      }

      if (max * amount * 6 / c > backervol[token]) {
        revert();
      }

      bytes32 _queryId =  provable_newRandomDSQuery(
        QUERY_EXECUTION_DELAY,
        NUM_RANDOM_BYTES_REQUESTED,
        GAS_FOR_CALLBACK
      );

      playerrolls[_queryId].addr = msg.sender;
      playerrolls[_queryId].token = token;
      playerrolls[_queryId].amount = amount;
      playerrolls[_queryId].picks = picks;
      playerrolls[_queryId].count = c;

      emit startroll(msg.sender, token, amount, picks, c,  _queryId);
    }
  }

  function deposit(address token, uint256 amount) payable public {
    uint256 amt;
    uint256 shares;
    if (token == ETH) {
      amt = msg.value;
    }
    else {
      IERC20 itoken = IERC20(token);
      itoken.transferFrom(msg.sender, address(this), amount);
      amt = amount;
    }
    if (backervol[token] != 0){
      shares = amt * backervol[token] / housebalance[token];
    }
    else {
      shares = amt;
    }
    backershares[msg.sender][token] = backershares[msg.sender][token].add(shares);
    backervol[token] = backervol[token].add(shares);
    housebalance[token] = housebalance[token].add(amt);
    emit depositevt(msg.sender, token, amt, shares);
  }

  function withdrawal(address token, uint256 shares) public {
    require(backershares[msg.sender][token] >= shares);
    uint256 amount = shares * housebalance[token] / backervol[token];
    backershares[msg.sender][token] = backershares[msg.sender][token].sub(shares);
    backervol[token] = backervol[token].sub(shares);
    housebalance[token] = housebalance[token].sub(amount);
    if (token == ETH) {
      msg.sender.transfer(amount);
    }
    else {
      IERC20 itoken = IERC20(token);
      itoken.transfer(msg.sender, amount);
    }
    emit withdrawalevt(msg.sender, token, amount, shares);
  }

  //VIEW FUNCTIONS
  function viewbackerval(address token, address addr) public view returns(uint256) {
    if(housebalance[token] == 0){
      return(0);
    }
    else {
      uint256 tmp = backershares[addr][token] * housebalance[token] / backervol[token];
      return(tmp);
    }
  }

  //ADMIN ONLY FUNCTIONS
  function setmax(uint256 _max) public onlyOwner() {
    max = _max;
  }
  function setprovablegasprice(uint256 _price) public onlyOwner() {
    provable_setCustomGasPrice(_price);
  }
  function setgasforcallback(uint256 _gas) public onlyOwner() {
    GAS_FOR_CALLBACK = _gas;
  }
  function setminrndpay(uint256 _minrndpay) public onlyOwner() {
    minrndpay = _minrndpay;
  }

  function clearExtraEth() public onlyOwner() {
    address payable _owner = msg.sender;
    uint256 x = address(this).balance.sub(housebalance[ETH]);
    _owner.transfer(x);
  }

  uint256 constant MAX_INT_FROM_BYTE = 256;
  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 7;


  function __callback(
    bytes32 _queryId,
    string memory _result,
    bytes memory _proof
  )
  public
  {
    require(msg.sender == provable_cbAddress());

    if (
      provable_randomDS_proofVerify__returnCode(
        _queryId,
        _result,
        _proof
      ) != 0
    ) {

    } else {


      if(playerrolls[_queryId].outcome == 0){
        uint8 _rnum = uint8(uint256(keccak256(abi.encodePacked(_result))) % 6 + 1);
        address addr = playerrolls[_queryId].addr;
        uint256 amount = playerrolls[_queryId].amount;
        address token = playerrolls[_queryId].token;
        bool[6] memory picks = playerrolls[_queryId].picks;
        uint8 count = playerrolls[_queryId].count;
        playerrolls[_queryId].outcome = _rnum;

        if (amount > backershares[addr][token]) {
          revert();
        }

        uint256 tmp;

        if (picks[_rnum]) {
          tmp = amount.mul(6);
          tmp = tmp.div(count);
          tmp = tmp.mul(99);
          tmp = tmp.div(100);
          tmp = tmp.sub(amount);

          backershares[addr][token] = backershares[addr][token].add(tmp);
          backervol[token] = backervol[token].add(tmp);
        }
        else {
          backershares[addr][token] = backershares[addr][token].sub(amount);
          backervol[token] = backervol[token].sub(amount);
        }
        emit endroll(addr, token, amount, _queryId, tmp, picks, _rnum);
      }

    }
  }
  function() external payable {
    revert();
  }
}

