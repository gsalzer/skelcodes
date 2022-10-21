pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeMath.sol";


contract ERC20 is IERC20 {

uint256 public override totalSupply;
mapping (address => uint256) balances;
mapping (address => mapping (address => uint256)) allowed;
using SafeMath for uint256;


function transfer(address _to, uint256 _value) public override returns (bool success) {
if (balances[msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {

balances[msg.sender] = balances[msg.sender] .sub(_value);
balances[_to]        = balances[_to]        .add(_value);

emit Transfer(msg.sender, _to, _value);

return true;
} else { return false; }
}

function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to].add(_value) > balances[_to]) {

balances[_to]              = balances[_to]              .add(_value);
balances[_from]            = balances[_from]            .sub(_value);
allowed[_from][msg.sender] = allowed[_from][msg.sender] .sub(_value);

emit Transfer(_from, _to, _value);

return true;
} else { return false; }
}


function balanceOf(address _owner) external view override returns (uint256 balance) {
return balances[_owner];
}

function approve(address _spender, uint256 _value) public override returns (bool success) {

allowed[msg.sender][_spender] = _value;
emit Approval(msg.sender, _spender, _value);

return true;
}

function allowance(address _owner, address _spender) external view override returns (uint256 remaining) {
return allowed[_owner][_spender];
}

}

