// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface IERC20{
    function approve( address, uint256)  external returns(bool);

     function allowance(address, address) external view returns (uint256);
    function balanceOf(address)  external view returns(uint256);

    function decimals()  external view returns(uint8);

    function totalSupply() external  view returns(uint256);

    function transferFrom(address,address,uint256) external  returns(bool);

    function transfer(address,uint256) external  returns(bool);
    function mint(address , uint256 ) external ;
    function burn(address , uint256 ) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
