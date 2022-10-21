pragma solidity 0.5.7;

import "./Pausable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract MoneyMarketInterface {
  function getSupplyBalance(address account, address asset) public view returns (uint);
  function supply(address asset, uint amount) public returns (uint);
  function withdraw(address asset, uint requestedAmount) public returns (uint);
}

contract LoanEscrow is Pausable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // configurable to any ERC20 (i.e. xCHF)
  IERC20 public dai = IERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);  // 0x9Ad61E35f8309aF944136283157FABCc5AD371E5  // 0xB4272071eCAdd69d933AdcD19cA99fe80664fc08
  MoneyMarketInterface public moneyMarket = MoneyMarketInterface(0x3FDA67f7583380E67ef93072294a7fAc882FD7E7);  // 0x6732c278C58FC90542cce498981844A073D693d7

  event Deposited(address indexed from, uint256 daiAmount);
  event InterestWithdrawn(address indexed to, uint256 daiAmount);
  event Pulled(address indexed to, uint256 daiAmount);

  mapping(address => uint256) public deposits;
  mapping(address => uint256) public pulls;
  uint256 public deposited;
  uint256 public pulled;

  modifier onlyBlockimmo() {
    require(msg.sender == blockimmo(), "onlyBlockimmo");
    _;
  }

  function blockimmo() public view returns (address);

  function withdrawInterest() public onlyBlockimmo {
    uint256 amountInterest = moneyMarket.getSupplyBalance(address(this), address(dai)).add(dai.balanceOf(address(this))).add(pulled).sub(deposited);
    require(amountInterest > 0, "no interest");

    uint256 errorCode = (amountInterest > dai.balanceOf(address(this))) ? moneyMarket.withdraw(address(dai), amountInterest.sub(dai.balanceOf(address(this)))) : 0;
    require(errorCode == 0, "withdraw failed");

    dai.safeTransfer(msg.sender, amountInterest);
    emit InterestWithdrawn(msg.sender, amountInterest);
  }

  function withdrawMoneyMarket(uint256 _amountDai) public onlyBlockimmo {
    uint256 errorCode = moneyMarket.withdraw(address(dai), _amountDai);
    require(errorCode == 0, "withdraw failed");
  }

  function deposit(address _from, uint256 _amountDai) internal {
    require(_from != address(0) && _amountDai > 0, "invalid parameter(s)");

    dai.safeTransferFrom(msg.sender, address(this), _amountDai);

    if (!paused()) {
      dai.safeApprove(address(moneyMarket), _amountDai);

      uint256 errorCode = moneyMarket.supply(address(dai), _amountDai);
      require(errorCode == 0, "supply failed");
      require(dai.allowance(address(this), address(moneyMarket)) == 0, "allowance not fully consumed by moneyMarket");
    }

    deposits[_from] = deposits[_from].add(_amountDai);
    deposited = deposited.add(_amountDai);
    emit Deposited(_from, _amountDai);
  }

  function pull(address _to, uint256 _amountDai, bool _refund) internal {
    require(_to != address(0) && _amountDai > 0, "invalid parameter(s)");

    uint256 errorCode = (_amountDai > dai.balanceOf(address(this))) ? moneyMarket.withdraw(address(dai), _amountDai.sub(dai.balanceOf(address(this)))) : 0;
    require(errorCode == 0, "withdraw failed");

    if (_refund) {
      deposits[_to] = deposits[_to].sub(_amountDai);
      deposited = deposited.sub(_amountDai);
    } else {
      pulls[_to] = pulls[_to].add(_amountDai);
      pulled = pulled.add(_amountDai);
    }

    dai.safeTransfer(_to, _amountDai);
    emit Pulled(_to, _amountDai);
  }
}

