pragma solidity 0.5.11;

contract EURSToken {
    function transferFrom(address, address, uint256) public returns(bool);
    function transfer(address, uint256) public returns(bool);
}

contract Test {
    
    EURSToken eurs = EURSToken(0xdB25f211AB05b1c97D595516F45794528a807ad8);
    
    uint256 public syndicateBalance;
    
    function userDeposit(address _from, uint256 _value) public {
        address _to = address(this);
        require(eurs.transferFrom(_from, _to, _value));
        syndicateBalance += _value;
    }
    
    function userWithdraw(uint256 _value) public {
        require(eurs.transfer(msg.sender, _value));
        syndicateBalance -= _value;
    }
    
}
