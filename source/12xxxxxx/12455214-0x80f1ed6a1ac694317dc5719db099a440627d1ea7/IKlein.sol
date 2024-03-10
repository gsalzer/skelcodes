// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.5.17;

interface IKlein {

  function getHolderEditions(address _holder) external view returns (uint256[] memory);

  function specificTransferFrom(address _from, address _to, uint _edition) external returns (bool success);

  function specificTransfer(address _to, uint _edition) external returns (bool success);

  /**************************************************************************
    * ERC20 Interface
    *************************************************************************/

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}
