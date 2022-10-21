pragma solidity ^0.5.4;

contract TokenDetails{

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function detail(string memory name, string memory symbol, uint8 decimals)
  internal {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name()
  public view
  returns (string memory) {
    return _name;
  }

  function symbol()
  public view
  returns (string memory) {
    return _symbol;
  }

  function decimals()
  public view
  returns (uint8) {
    return _decimals;
  }
}
