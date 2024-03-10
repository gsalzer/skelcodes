pragma solidity ^0.5.1;

// Palmes token

import "./IERC20.sol";

contract ERC20Detailed is IERC20 {

    uint8 private _Tokendecimals; 
    string private _Tokenname; 
    string private _Tokensymbol;

constructor(string memory name, string memory symbol, uint8 decimals) public {

   _Tokendecimals = decimals; 
   _Tokenname = name; 
   _Tokensymbol = symbol;
  
   }

   function name() public view returns(string memory) { return _Tokenname; }

   function symbol() public view returns(string memory) { return _Tokensymbol; }

   function decimals() public view returns(uint8) { return _Tokendecimals; } 
    
}


