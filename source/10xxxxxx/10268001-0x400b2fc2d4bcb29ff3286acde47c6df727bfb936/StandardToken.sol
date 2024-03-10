pragma solidity ^0.4.8;
import "./Token.sol";
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) returns (bool success) {
        //Ĭ��totalSupply ���ᳬ�����ֵ (2^256 - 1).
        //�������ʱ������ƽ������µ�token���ɣ������������������������쳣
        //require(balances[msg.sender] >= _value && balances[_to] + _value >balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;//����Ϣ�������˻��м�ȥtoken����_value
        balances[_to] += _value;//�������˻�����token����_value
        Transfer(msg.sender, _to, _value);//����ת�ҽ����¼�
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >=  _value);
        balances[_to] += _value;//�����˻�����token����_value
        balances[_from] -= _value;//֧���˻�_from��ȥtoken����_value
        allowed[_from][msg.sender] -= _value;//��Ϣ�����߿��Դ��˻�_from��ת������������_value
        Transfer(_from, _to, _value);//����ת�ҽ����¼�
        return true;
    }
    //��ѯ���
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    //��Ȩ�˻�_spender���Դ���Ϣ�������˻�ת������Ϊ_value��token
    function approve(address _spender, uint256 _value) returns (bool success)   
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];//����_spender��_owner��ת����token��
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}
