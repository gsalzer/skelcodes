/**
 *Submitted for verification at Etherscan.io on 2017-09-27
*/

pragma solidity ^0.4.8;
contract Token{
    // token总量，默认会为public变量生成一个getter函数接口，名称为totalSupply().
    uint256 public totalSupply;

    /// 获取账户_owner拥有token的数量 
    function balanceOf(address _owner) constant returns (uint256 balance);

    //从消息发送者账户中往_to账户转数量为_value的token
    function transfer(address _to, uint256 _value) returns (bool success);


    //发生转账时必须要触发的事件 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

}

contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        //默认totalSupply 不会超过最大值 (2^256 - 1).
        //如果随着时间的推移将会有新的token生成，则可以用下面这句避免溢出的异常
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        //require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//从消息发送者账户中减去token数量_value
        balances[_to] += _value;//往接收账户增加token数量_value
        Transfer(msg.sender, _to, _value);//触发转币交易事件
        return true;
    }


  
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    mapping (address => uint256) balances;
}

contract CJZVIP is StandardToken { 

    /* Public variables of the token */
    string public name;                   //名称: eg Simon Bucks
    uint8 public decimals;               //最多的小数位数，How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;               //token简称:

    function CJZVIP() {
        balances[msg.sender] = 30000000000000000000000000; // 初始token数量给予消息发送者
        totalSupply = 30000000000000000000000000;         // 设置初始总量
        name = "CJZVIP";                   // token名称
        decimals = 18;           // 小数位数
        symbol = "CZ";             // token简称
    }

    /* Approves and then calls the receiving contract */
    
 

}
