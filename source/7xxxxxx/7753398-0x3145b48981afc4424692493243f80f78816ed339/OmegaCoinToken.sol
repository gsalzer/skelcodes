import "./StandardToken.sol";

pragma solidity >=0.4.0 <0.6.0;

contract OmegaCoinToken is StandardToken {

  uint8 public constant decimals = 18;
  address public owner;
  
  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  function setMinter(address _minterAddress, uint256 _value) public isOwner {
    require(_minterAddress != address(0));
    minters[_minterAddress] = _value;
  }
  
  function minterLeft(address _minterAddress) view public returns (uint256 rest) {
      return minters[_minterAddress];
  }
  
  function dematerialize(uint256 _value) public {
      if (minters[msg.sender] >= _value && _value > 0) {
          balances[msg.sender] += _value;
          minters[msg.sender] -= _value;
          totalSupply += _value;
          emit Transfer(address(0), msg.sender, _value);
      }
  }
  
  function materialize(uint256 _value) public {
    if (minters[msg.sender] >= _value && balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      totalSupply -= _value;
      emit Transfer(msg.sender, address(0), _value);
    }
  }

  mapping (address => uint256) minters;
}

