pragma solidity ^0.5.4;

contract Proxy {

  address implementation;

  constructor(address _implementation)
  public {
    implementation = _implementation;
  }

  function()
  external payable {
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let target := sload(0)
      calldatacopy(0, 0, calldatasize())
      let result := delegatecall(gas, target, 0, calldatasize(), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }
}
