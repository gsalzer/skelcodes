pragma solidity ^0.5.0 <0.6.0;

import "./C3StorageInterface.sol";
import "./ERC20ControllerInterface.sol";
import "./C3Emitter.sol";

import "./C3Base.sol";
import "./C3Events.sol";
import "./Ownable.sol";
import "./InteropOwnable.sol";

contract C3 is C3Base, C3Emitter, C3Events, Ownable {
  address private _logicBoardAddress;
  address private _storageAddress;

  string  private _name;
  string  private _symbol;
  uint8   private _decimals;

  constructor(
    string memory pname, string memory psymbol, uint8 pdecimals,
    address _logicBoard, address _storage
  ) public {
    _name = pname;
    _symbol = psymbol;
    _decimals = pdecimals;

    _logicBoardAddress = _logicBoard;
    _storageAddress = _storage;
    _ownerAddr = msg.sender;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public view returns (uint8) {
    return _decimals;
  }

  function upgradeLogicBoard(address _newLogicBoard) public onlyOwner {
    require(_newLogicBoard != address(0x0), "can't set logic board to a null address");
    _logicBoardAddress = _newLogicBoard;
  }

  function totalSupply() public view returns (uint256) {
    return C3StorageInterface(_storageAddress).totalSupply();
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return C3StorageInterface(_storageAddress).balanceOf(_owner);
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    return ERC20ControllerInterface(_logicBoardAddress).transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    return ERC20ControllerInterface(_logicBoardAddress).transferFrom(msg.sender, _from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    return ERC20ControllerInterface(_logicBoardAddress).approve(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return ERC20ControllerInterface(_logicBoardAddress).allowance(msg.sender, _owner, _spender);
  }

  function burn(uint256 value) public returns (bool success) {
    return ERC20ControllerInterface(_logicBoardAddress).burn(msg.sender, value);
  }

  function burnFrom(address from, uint256 value) public returns (bool success) {
    return ERC20ControllerInterface(_logicBoardAddress).burnFrom(msg.sender, from, value);
  }

  modifier internalUsage {
    require(msg.sender == _storageAddress || msg.sender == _logicBoardAddress);
    _;
  }

  function fireTransferEvent(address from, address to, uint256 tokens) public internalUsage {
    emit Transfer(from, to, tokens);
  }

  function fireApprovalEvent(address tokenOwner, address spender, uint tokens) public internalUsage {
    emit Approval(tokenOwner, spender, tokens);
  }

  function logicBoard() internal view returns (address) {
    return _logicBoardAddress;
  }
}

