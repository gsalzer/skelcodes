pragma solidity ^0.4.19;

contract GST {
  function transfer(address _to, uint256 _value) public returns (bool);
  function mint(uint256 value) public;
}

contract Proxy {
  // GST1
  /* address private gastoken = 0x88d60255F917e3eb94eaE199d827DAd837fac4cB; */
  // GST2
  address private gastoken = 0x0000000000b3F879cb30FE243b4Dfee438691c04;
  uint256 amount = 100; // 1 GST per invocation, feel free to change
  address admin;

  function Proxy() {
    admin = msg.sender;
  }

  function () payable public {
    // forward incoming ether
    admin.transfer(msg.value);
    // mint some gastokens
    GST(gastoken).mint(amount);
    // transfer minted gastoken
    GST(gastoken).transfer(admin, amount);
  }
}
