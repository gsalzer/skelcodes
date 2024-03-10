pragma solidity ^0.5.0 <0.6.0;

import "./C3Emitter.sol";

import "./InteropOwnable.sol";
import "./SafeMath.sol";
import "./C3Events.sol";

import "./ReentrancyGuard.sol";

contract C3Storage is InteropOwnable, C3Events, ReentrancyGuard {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;
  address private _emitter;
  bool private storageInitialized;

  constructor(uint256 initialSupply) public {
    _totalSupply = initialSupply;
    _ownerAddr = msg.sender;
  }

  function balanceOf(address owner) external view returns (uint256) {
    require(storageInitialized);
    return _balances[owner];
  }

  function balanceAdd(address _owner, uint256 value) external onlyInteropOwner nonReentrant returns (bool success) {
    require(storageInitialized);
    if (_balances[_owner] == 0) {
      _balances[_owner] = value;
      return true;
    }
    _balances[_owner] = _balances[_owner].add(value);
    return true;
  }

  function balanceSub(address _owner, uint256 value) external onlyInteropOwner nonReentrant returns (bool success) {
    require(storageInitialized);
    if (_balances[_owner] < value) {
      return false;
    }

    _balances[_owner] = _balances[_owner].sub(value);
    return true;
  }

  function balanceTransfer(address _from, address _to, uint256 value)
    external onlyInteropOwner nonReentrant returns (bool success) {
    require(storageInitialized);
    if (_balances[_from] < value) {
      return false;
    }
    _balances[_from] = _balances[_from].sub(value);
    _balances[_to] = _balances[_to].add(value);
    return true;
  }

  function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
    require(storageInitialized);
    return _allowed[_owner][_spender];
  }

  function approve(address _owner, address _spender, uint256 value) external onlyInteropOwner returns (bool success) {
    require(storageInitialized);
    _allowed[_owner][_spender] = value;

    return true;
  }

  function totalSupply() external view returns (uint256) {
    require(storageInitialized);
    return _totalSupply;
  }

  function totalSupplyAdd(uint256 value) external onlyInteropOwner returns (bool success) {
    require(storageInitialized);
    _totalSupply = _totalSupply.add(value);
    return true;
  }

  function totalSupplySub(uint256 value) external onlyInteropOwner returns (bool success) {
    require(storageInitialized);
    if (value > _totalSupply) {
      return false;
    }

    _totalSupply = _totalSupply.sub(value);
    return true;
  }

  function setEmitterAddress(address emitter) external onlyOwner {
    require(emitter != address(0x0));
    _emitter = emitter;
  }

  function initializeTokens() public onlyOwner {
    require(!storageInitialized && _emitter != address(0x0), "storage was already initialized or emitter was not set");
    _balances[_ownerAddr] = _totalSupply;
    C3Emitter(_emitter).fireTransferEvent(address(0x0), _ownerAddr, _totalSupply);
    storageInitialized = true;
  }
}

