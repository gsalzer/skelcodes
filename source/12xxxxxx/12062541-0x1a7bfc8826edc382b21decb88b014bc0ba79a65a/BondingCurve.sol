// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import { IERC20 } from "./IERC20.sol";
import { BondingCurveFactory } from "./BondingCurveFactory.sol";

library AddressUtils {
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
}

interface ICurve {
  function isCurve() external returns (bool);
}

contract BondingCurve is IERC20 {
  using AddressUtils for address;
  using SafeMath for uint256;

  // keccak256("ERC20.decimals")
  bytes32 private constant DECIMALS_SLOT = 0x9af4a8efdef7082fbe0a356fe9ce920abbe3461c19ff1888bb79ec1fbee0a564;
  // keccak256("curve.parameters")
  bytes32 private constant PARAMETERS_SLOT = 0x9bb186d4e76241ac6fcfb26f9c0c67a7a4288892aa856bb2ef40fc277c0bbbe2;
  // keccak256(keccak256("curve.parameters"))
  bytes32 private constant PARAMETERS_SLOT_HASH = 0x22e3a4713640ec908fad4277bc5c59c3802aee5469f8a18fa0b552bf09d2299b;

  // bytes4(keccak256("integral(uint256,uint256)")
  bytes4 private constant INTEGRAL_ABI = 0xc3882fef;
  // bytes4(keccak256("valueOf(uint256)")
  bytes4 private constant VALUE_OF_ABI = 0xcadf338f;

  BondingCurveFactory public factory;

  uint256 public supplied = 0;
  address public founder;         // the address of the founder
  IERC20 public tokenToSell;      // the token to offer
  IERC20 public token;            // the token to receive
  address public curve;
  bool public initialized;        // if token transfer is ready

  uint256 public start;           // start time for sale
  uint256 public end;             // deadline for sale. After the sale is completed, it will be set to 0 to indicate that contract has ended.
  bool public redeemInTime;
  uint256 public maximumBalance;  // the maximum number of tokens an account can hold, 0 means no limit.

  // ERC20 params

  uint256 public override totalSupply;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  bool private rentrancyLock;
  bool public founderExit;

  event Buy(address indexed user, uint256 amount, uint256 prict);
  event Sell(address indexed user, uint256 amount, uint256 prict);

  /**
   * @dev Constructor for the bonding curve
   * @param _tokenToSell The address for the token to sell
   * @param _token The address for the trading token
   * @param _start The start time of token sale
   * @param _end The end time of token sale
   * @param _redeemInTime Whether the user can redeem immediately after the sale, instead of waiting for the end time.
   * @param _maximumBalance the maximum number of tokens an account can hold
   * @param _totalSupply The amount of to raise
   * @param _founder The address for the token creator founder
   * @param _curve curve lib
   * @param _params The params list for curve
   */
  constructor(IERC20 _tokenToSell, IERC20 _token, uint256 _start, uint256 _end, bool _redeemInTime, uint256 _maximumBalance, uint256 _totalSupply, address _founder, address _curve, uint256[] memory _params) {
    require(_founder != address(0), "Founder's address must not be address(0)");
    require(_start < _end);
    require(address(_tokenToSell).isContract());
    require(address(_token).isContract());
    require(ICurve(_curve).isCurve());

    tokenToSell = _tokenToSell;
    token = _token;
    curve = _curve;
    totalSupply = _totalSupply;
    founder = _founder;

    end = _end;
    start = _start;
    redeemInTime = _redeemInTime;
    maximumBalance = _maximumBalance;

    uint256 l = _params.length;
    uint256 d = _tokenToSell.decimals();
    assembly {
      sstore(PARAMETERS_SLOT, l)
      sstore(DECIMALS_SLOT, d)
    }
    for (uint256 i = 0; i < l; i++) {
      uint256 v = _params[i];
      assembly {
        sstore(add(PARAMETERS_SLOT_HASH, i), v)
      }
    }
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   */
  modifier nonReentrant() {
    require(!rentrancyLock);
    rentrancyLock = true;
    _;
    rentrancyLock = false;
  }

  /**
   * @dev Modifier for checking the token sale is ended
   */
  modifier afterEnded() {
    bool ended = block.timestamp > end || (redeemInTime && supplied >= totalSupply);
    require(ended, "the token sale has not ended");
    _;
  }

  /**
   * @dev Modifier for checking the token sale is active
   */
  modifier active() {
    require(initialized, "the contract has not initialized");
    require(block.timestamp > start, "the token sale hasn't started");
    require(block.timestamp < end, "the token sale has ended");
    require(supplied < totalSupply, "the token sale has ended");
    _;
  }

  /**
   * @dev Initialize checks whether the token has received
   */
  function initialize(BondingCurveFactory _factory) external {
    require(tokenToSell.balanceOf(address(this)) == totalSupply, "token has not received");
    factory = _factory;
    initialized = true;
  }

  function parameters() external view returns (uint256[] memory params) {
    uint256 l;
    assembly {
      l := sload(PARAMETERS_SLOT)
    }
    params = new uint256[](l);
    for (uint256 i = 0; i < l; i++) {
      uint256 v;
      assembly {
        v := sload(add(PARAMETERS_SLOT_HASH, i))
      }
      params[i] = v;
    }
  }

  function priceNow() external view returns (uint256) {
    return priceAt(supplied);
  }

  function costFor(uint256 amount) external view returns (uint256) {
    return totalPriceBetween(supplied, supplied.add(amount));
  }

  function returnFor(uint256 amount) external view returns (uint256) {
    return totalPriceBetween(supplied.sub(amount), supplied);
  }

  function priceAt(uint256 position) public view returns (uint256 price) {
    (bool success, bytes memory data) = address(this).staticcall(abi.encodePacked(VALUE_OF_ABI, position));
    require(success);
    require(data.length == 32);
    assembly {
      price := mload(add(data, 32))
    }
  }

  function totalPriceBetween(uint256 left, uint256 right) public view returns (uint256 price) {
    (bool success, bytes memory result) = address(this).staticcall(abi.encodePacked(INTEGRAL_ABI, left, right));
    require(success);
    require(result.length == 32);
    assembly {
      price := mload(add(result, 32))
    }
  }

  /**
   * @dev Buy token with bonding curve 
   * @param amount The amount of token to mint
   */
  function buy(uint256 amount) external nonReentrant active  {
    uint256 newSupplied = supplied.add(amount);
    if (newSupplied > totalSupply) {
      amount = totalSupply - supplied;
      newSupplied = totalSupply;
    }
    uint256 totalCost = totalPriceBetween(supplied, newSupplied);
    _mint(msg.sender, amount);
    bool success = token.transferFrom(msg.sender, address(this), totalCost);
    require(success);

    emit Buy(msg.sender, amount, totalCost);
  }
  
  /**
   * @dev Sell token with bonding curve 
   * @param amount The amount of token to burn
   */
  function sell(uint256 amount) external nonReentrant active {
    uint256 newSupplied = supplied.sub(amount);
    uint256 totalReturn = totalPriceBetween(newSupplied, supplied);
    uint256 afterTax = 99 * totalReturn / 100;
    _burn(msg.sender, amount);
    bool success = token.transfer(msg.sender, afterTax);
    require(success);

    emit Sell(msg.sender, amount, afterTax);
  }

  /**
   * @dev Withdraw function allows the founder to withdraw all funds to their founder address
   */
  function withdrawFund() external afterEnded {
    uint256 tokenReceived = token.balanceOf(address(this));
    uint256 tax = 3 * tokenReceived / 100;
    bool success = token.transfer(factory.feeTo(), tax);
    require(success);
    success = token.transfer(founder, tokenReceived - tax);
    require(success);
  }
  /**
   * @dev Withdraw function allows the founder to withdraw rest to-sell-token.
   */
  function withdrawToken() external afterEnded {
    require(!founderExit);
    bool success = tokenToSell.transfer(founder, totalSupply - supplied);
    require(success);
    founderExit = true;
  }

  /**
   * @dev The function to redeem bToken to the original token
   */
  function redeem() external afterEnded {
    uint256 amountToRedeem = balanceOf(msg.sender);
    _balances[msg.sender] = _balances[msg.sender].sub(amountToRedeem);
    emit Transfer(msg.sender, address(0), amountToRedeem);
    bool success = tokenToSell.transfer(msg.sender, amountToRedeem);
    require(success);
  }

  // ERC20 methods

  /**
   * @dev Returns the name of the token.
   */
  function name() public view override returns (string memory) {
    return string(abi.encodePacked("b", tokenToSell.name()));
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view override returns (string memory) {
    return string(abi.encodePacked("b", tokenToSell.symbol()));
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function decimals() public view override returns (uint256) {
    uint256 d;
    assembly {
      d := sload(DECIMALS_SLOT)
    }
    return d;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(msg.sender != recipient, "Cannot transfer to own account");
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    require(maximumBalance == 0 || _balances[recipient] <= maximumBalance);
    emit Transfer(msg.sender, recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    require(sender != recipient, "Cannot transfer to own account");
    _balances[sender] = _balances[sender].sub(amount);
    _allowed[sender][msg.sender] = _allowed[sender][msg.sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    require(maximumBalance == 0 || _balances[recipient] <= maximumBalance);
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    require(_allowed[msg.sender][spender] == 0 || amount == 0);
    _allowed[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
    return _allowed[owner][spender];
  }

  function _mint(address account, uint256 amount) internal virtual {
    require (account != address(0));
    supplied = supplied.add(amount);
    _balances[account] = _balances[account].add(amount);
    require(maximumBalance == 0 || _balances[account] <= maximumBalance);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require (account != address(0));
    _balances[account] = _balances[account].sub(amount);
    supplied = supplied.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  fallback() external {
    require(msg.sender == address(this));

    (bool success, bytes memory data) = curve.delegatecall(msg.data);
    assembly {
      switch success
        case 0 { revert(add(data, 32), returndatasize()) }
        default { return(add(data, 32), returndatasize()) }
    }
  }
}

