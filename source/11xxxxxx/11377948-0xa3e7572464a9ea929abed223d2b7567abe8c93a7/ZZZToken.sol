pragma solidity >=0.4.22 <0.6.0;

import "./SafeMath.sol";
import "./Owned.sol";


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address _tokenOwner) public view returns (uint _balance);
    function allowance(address _tokenOwner, address _spender) public view returns (uint _remaining);
    function transfer(address _to, uint _tokens) public returns (bool _success);
    function approve(address _spender, uint _tokens) public returns (bool _success);
    function transferFrom(address _from, address _to, uint _tokens) public returns (bool _success);

    event Transfer(address indexed _from, address indexed _to, uint _tokens);
    event Approval(address indexed _tokenOwner, address indexed _spender, uint _tokens);
}


contract ZZZToken is Owned, ERC20Interface {
    using SafeMath for uint;

    string public constant symbol = "ZZZ";
    string public constant name = "ZZZ";
    uint8 public constant decimals = 18;
    uint public constant decimalFactor = 10**uint(decimals);
    uint public constant m_totalSupply = 10000 * decimalFactor;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor () public {
        balances[owner] = m_totalSupply;
        emit Transfer(address(0), owner, m_totalSupply);
    }


    function batchTransfer(
        address[] memory _recipients,
        uint _tokens
    )
        public
        onlyOwner
        returns (bool)
    {
        require(_recipients.length > 0);
        _tokens = _tokens * 10**uint(decimals);
        require(_tokens <= balances[msg.sender]);

        for(uint j = 0; j < _recipients.length; j++){

            balances[_recipients[j]] = balances[_recipients[j]].add(_tokens);
            balances[owner] = balances[owner].sub(_tokens);
            emit Transfer(owner, _recipients[j], _tokens);
        }
        return true;
    }


    function totalSupply() public view returns (uint) {
        return m_totalSupply.sub(balances[address(0)]);
    }


    function balanceOf(address _tokenOwner) public view returns (uint _balance) {
        return balances[_tokenOwner];
    }


    function allowance(address _tokenOwner, address _spender) public view returns (uint _remaining) {
        return allowed[_tokenOwner][_spender];
    }


    function transfer(address _to, uint _tokens) public returns (bool _success) {
        require(balances[msg.sender] >= _tokens);

        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }


    function approve(address _spender, uint _tokens) public returns (bool _success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }


    function transferFrom(address _from, address _to, uint _tokens) public returns (bool _success) {
        require(balances[_from] >= _tokens);
        require(allowed[_from][msg.sender] >= _tokens);

        balances[_from] = balances[_from].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_tokens);
        emit Transfer(_from, _to, _tokens);
        return true;
    }

}

