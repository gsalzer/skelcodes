// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface c_or_w_ETH {
  function liquidateBorrow ( address borrower, address cTokenCollateral ) external payable;
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address owner ) external view returns ( uint256 );
  function balanceOfUnderlying ( address owner ) external returns ( uint256 );
  function decimals (  ) external view returns ( uint256 );
  function symbol (  ) external view returns ( string memory );
  function totalSupply( ) external view returns (uint256 supply);
  function transfer ( address dst, uint256 amount ) external returns ( bool );
  function transferFrom ( address src, address dst, uint256 amount ) external returns ( bool );
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

