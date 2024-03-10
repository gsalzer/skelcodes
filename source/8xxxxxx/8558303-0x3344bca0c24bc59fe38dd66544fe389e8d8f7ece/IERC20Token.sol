pragma solidity >=0.4.24 <0.6.0;
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20Token{
// these functions aren't abstract since the compiler emits automatically generated getter functions as external
function name() public view returns(string memory);
function symbol() public view returns(string memory);
function decimals() public view returns(uint256);
function totalSupply() public view returns (uint256);
function balanceOf(address _owner) public view returns (uint256);
function allowance(address _owner, address _spender) public view returns (uint256);

function transfer(address _to, uint256 _value) public returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
function approve(address _spender, uint256 _value) public returns (bool success);
 event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
