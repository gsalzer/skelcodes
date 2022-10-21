pragma solidity >=0.4.21 <0.7.0;

import "./TessaToken.sol";

contract Tessa_0001_DH1 is TessaToken {
    string public name = "TESSA[#0001] : David Hockney [1]";
    string public symbol = "TSA";
    uint8 public decimals = 0;

    constructor(uint256 supply_, bool state, address addr_) public {
        totalSupply_ = supply_;
        balances[msg.sender] = totalSupply_;
        issuer_ = msg.sender;
        state_ = state;
        tManager_ = TessaManager(addr_);
    }
}

