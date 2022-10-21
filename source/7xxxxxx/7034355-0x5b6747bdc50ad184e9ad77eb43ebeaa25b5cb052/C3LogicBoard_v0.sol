pragma solidity ^0.5.0 <0.6.0;

import "./C3Emitter.sol";
import "./ERC20ControllerInterface.sol";

import "./InteropOwnable.sol";
import "./C3StorageInterface.sol";
import "./SafeMath.sol";

// solium-disable-next-line camelcase
contract C3LogicBoard_V0 is ERC20ControllerInterface, InteropOwnable {
  using SafeMath for uint256;

  C3StorageInterface private _storage;

  C3Emitter private _emitter;

  /**
   * deprecation flag used to disable old logic boards.
   * board owner can use setDeprecationFlag to control this.
   **/
  bool private deprecated = false;

  constructor(address storageImpl) public {
    _storage = C3StorageInterface(storageImpl);

    _ownerAddr = msg.sender;
  }

  function setDeprecationFlag(bool isDeprecated) external onlyOwner {
    deprecated = isDeprecated;
  }

  function setStorage(C3StorageInterface _newStorage) external onlyOwner {
    _storage = _newStorage;
  }

  function balanceOf(
    address /*_requestedBy*/,
    address owner) external view returns (uint256 balance) {
    require(!deprecated);
    return _storage.balanceOf(owner);
  }

  function transfer(
    address _requestedBy,
    address _to, uint256 _value) external onlyInteropOwner returns (bool success) {
    require(!deprecated);
    return _transfer(_requestedBy, _requestedBy, _to, _value);
  }

  function transferFrom(
    address _requestedBy,
    address _from, address _to, uint256 _value) external onlyInteropOwner returns (bool success) {
    require(!deprecated);

    return _transfer(_requestedBy, _from, _to, _value);
  }

  function approve(address _requestedBy, address _spender, uint256 _value)
    external onlyInteropOwner returns (bool success) {
    require(!deprecated);
    require(_storage.balanceOf(_requestedBy) >= _value, "insufficient funds");

    // see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
    require(
      _storage.allowance(_requestedBy, _spender) == 0 || _value == 0,
      "you should reset your previous allowance value for this spender."
    );

    _emitter.fireApprovalEvent(_requestedBy, _spender, _value);
    return _storage.approve(_requestedBy, _spender, _value);
  }

  function allowance(
    address /*_requestedBy*/,
    address _owner, address _spender) external onlyInteropOwner view returns (uint256 remaining) {
    require(!deprecated);
    require(_spender != address(0x0));
    return _storage.allowance(_owner, _spender);
  }

  function totalSupply(address /*requestedBy*/) external view returns (uint256) {
    require(!deprecated);
    return _storage.totalSupply();
  }

  function burn(address requestedBy, uint256 value) external onlyInteropOwner returns (bool success) {
    require(!deprecated);
    return _burn(requestedBy, requestedBy, value);
  }

  function burnFrom(address requestedBy, address from, uint256 value) external onlyInteropOwner returns (bool success) {
    require(!deprecated);
    return _burn(requestedBy, from, value);
  }

  function setEmitterAddress(address emitter) public onlyOwner {
    require(emitter != address(0x0));
    _emitter = C3Emitter(emitter);
  }

  function _burn(address _requestedBy, address _from, uint256 _value) private returns (bool success) {
    require(!deprecated);
    if (_requestedBy == _from) {
    // if transfer requested by owner, check if owner got enough funds
      require(_storage.balanceOf(_from) >= _value, "insufficient funds");
    } else {
      // if transfer was not requested by owner, we must check for both:
      //   1) if owner allowed enough funds to the potential spender (a.k.a. request's sender)
      //   2) and if owner actually got enough funds for the spender
      require(_storage.allowance(_from, _requestedBy) >= _value && _storage.balanceOf(_from) >= _value, "insufficient allowance or funds");
    }

    if (_value != 0) {
      require(_storage.balanceSub(_from, _value));
      require(_storage.totalSupplySub(_value));
    }
    _emitter.fireTransferEvent(_from, address(0x0), _value);

    return true;
  }

  function _transfer(address _requestedBy, address _from, address _to, uint256 _value) private returns (bool success) {
    require(!deprecated);
    //solium-disable operator-whitespace
    require(
      // burn operation requires additional checks and operations,
      // so we're disabling this via _transfer
      _to != address(0x0) &&
      // transfering tokens to logic boards, storage or root token contract
      // is basically is a burn operation. without reducing totalSupply
      // that tokens would be wasted.
      _to != address(this) &&
      _to != address(_storage) &&
      _to != address(_emitter),
      "use burn()/burnFrom() method instead"
    );

    if (_requestedBy == _from) {
    // if transfer requested by owner, check if owner got enough funds
      require(_storage.balanceOf(_from) >= _value, "insufficient funds");
    } else {
      // if transfer was not requested by owner, we must check for both:
      //   1) if owner allowed enough funds to the potential spender (a.k.a. request's sender)
      //   2) and if owner actually got enough funds for the spender
      require(_storage.allowance(_from, _requestedBy) >= _value && _storage.balanceOf(_from) >= _value, "insufficient allowance or funds");
    }

    // transfers with _value = 0 MUST be treated as normal transfers and fire the Transfer event.
    if (_value != 0) {
      require(_storage.balanceTransfer(_from, _to, _value));
    }
    _emitter.fireTransferEvent(_from, _to, _value);

    return true;
  }
}

