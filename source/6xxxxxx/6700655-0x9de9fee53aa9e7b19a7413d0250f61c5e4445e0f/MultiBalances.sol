pragma solidity ^0.4.24;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

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

contract MultiBalances { 
    function getBalances(address contractAddress, address[] addresses) public view returns (uint256[]){
        IERC20 erc20 = IERC20(contractAddress);
        uint addrLength = addresses.length;
        uint256[]  memory balances = new uint256[](addrLength);
        for(uint i = 0; i<addrLength; i++){
            balances[i] = erc20.balanceOf(addresses[i]);
        }
        return balances;
    } 
}
