pragma solidity ^0.4.24;
import "./StandardToken.sol";

contract USDTToken is StandardToken {
    using SafeMath for uint256;

    string public name = "FAKE USDT";
    string public symbol = "USDT";
    uint8 public decimals = 18;

    constructor(address _owner, uint256 _totalSupply) public{
      totalSupply_ = _totalSupply;
      balances[_owner] = _totalSupply;
      emit Transfer(address(0), _owner, _totalSupply);
    }
}

