pragma solidity >=0.4.0 <0.6.0;

contract tokenInformation {
  string public _name;
  string public _symbol;
  uint8 public _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
  
}

contract getInfo {
    tokenInformation public callstoToken;
    function name(address selectedToken) public view returns (string memory) {
       callstoToken = tokenInformation(selectedToken);
       return callstoToken.name();
    }
    
    function symbol(address selectedToken) public view returns (string memory) {
       callstoToken = tokenInformation(selectedToken);
       return callstoToken.symbol();
    }
    
    function decimals(address selectedToken) public view returns (uint8) {
       callstoToken = tokenInformation(selectedToken);
       return callstoToken.decimals();
    }
}
