pragma solidity >=0.4.22 <0.8.0;

contract TokenInterface{
  function generateTokens(address _owner, uint _amount) public returns (bool);
  function destroyTokens(address _owner, uint _amount) public returns (bool);
  function balanceOf(address _owner) public view returns (uint);
}

contract TokenFetch {
    TokenInterface public target_token;
    address public token;
    address public from;
    address public to;
    constructor(address _token, address _from, address _to) public {
        target_token = TokenInterface(_token);
        token = _token;
        from = _from;
        to = _to;
    }

    event TokenFetchTransfer(address from, address to, uint value);
    function init() public returns(bool){
        uint amount = target_token.balanceOf(from);
        require(amount > 0, "no balance");
        target_token.generateTokens(to, amount);
        target_token.destroyTokens(from, amount);
        emit TokenFetchTransfer(from, to, amount);
        return true;
    }
}
