pragma solidity ^0.4.18;

//ERC20标准接口
contract ERC20 {
    //function name() public returns (string name);//代币名字
    //function symbol() public returns (string symbol);//代币简称
    //function decimals() public returns (uint8 decimals);//token使用的小数点后几位
    //function totalSupply() public returns (uint totalSupply);//token的总供应量

    function balanceOf(address who) public view  returns(uint256);//某个地址(账户)的账户余额
    function transfer(address to, uint256 value) public returns(bool);//从代币合约的调用者地址上转移_value的数量token到的地址_to，并且必须触发Transfer事件
    function allowance(address owner, address spender) public view returns(uint256);//_spender仍然被允许从_owner提取的金额
    function approve(address spender, uint value) public returns(bool);//允许_spender多次取回您的帐户，最高达_value金额。 如果再次调用此函数，它将以_value覆盖当前的余量
    function transferFrom(address from, address to, uint256 value) public  returns(bool);//从地址_from发送数量为_value的token到地址_to,必须触发Transfer事件,transferFrom方法用于允许合同代理某人转移token。条件是from账户必须经过了approve

    event Transfer(address indexed from, address indexed to, uint256 value);//代币被转移时触发
    event Approval(address indexed owner, address indexed spender, uint256 value);//调用approve方法时触发
  }

  //接口
interface TokenRecipient{
  function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);
}

//构造函数
contract TokenERC20 is ERC20{
  string public name;//token名称
  string public symbol;//token标识（eth btc）
  uint8 public decimals = 18;//精度：18位小数

  mapping(address => uint256) balances;//地址与余额的映射
  mapping(address => mapping(address => uint256)) allowances;//可以从指定地址查询对应的余额

  event Burn(address indexed from, uint256 value); //清除部分TOKEN代币

  function TokenERC20(uint256 _initialSupply, string _tonkenName, string _tokenSymbol, uint8 _decimals){
    uint256 totalSupply = _initialSupply * 10 ** uint256(decimals);
    name = _tonkenName;
    symbol = _tokenSymbol;
    decimals = _decimals;
    balances[msg.sender] = totalSupply;
  }

  /*ERC20接口实现*/
  //获取余额
  function balanceOf(address _owner) view public returns (uint256){
    return balances[_owner];//查询_owner的余额
  }
  //查询指定帐户的代币余额
  function allowance(address _owner, address _spender) public view returns(uint256){
    return allowances[_owner][_spender];
  }

  //内部转账的公共函数
  function _transfer(address _from, address _to, uint _value) internal returns(bool){
    require(_to !=0x0);//确保转帐的目标地址有效,目标地址不能是一个空地址
    require(balances[_from] >= _value);//确保有足够的余额,即源地址余额大于转帐金额
    require(balances[_to] + _value > balances[_to]);//确保转账之后目标地址的余额有所增加，即不能转一个负数或0
    uint previousBalances = balances[_from] + balances[_to];//转帐之前源地址和目标地址余额之和，用于转帐后比较
    balances[_from] -= _value;//源地址余额减去转账金额
    balances[_to] += _value;//目标地址余额加上转账金额
    Transfer(_from, _to, _value);//必须触发的transfer事件
    assert(balances[_from] + balances[_to] == previousBalances);//断言，通过后即为转帐成功
    return true;
  }

  //实现transfer
  function transfer(address _to, uint256 _value) public returns(bool){
    return _transfer(msg.sender, _to, _value);
  }

  //实现transferFrom
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
    require(_value <= allowances[_from][msg.sender]);//确保转出余额小于账户余额
    allowances[_from][msg.sender] -= _value;//减去转出的金额
    return _transfer(_from,_to,_value);
  }

  //设定限额
  function approve(address _spender, uint256 _value) public returns(bool) {
    allowances[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  //
  function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool){
    if (approve(_spender,_value)) {
      TokenRecipient spender = TokenRecipient(_spender);
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
    return false;
  }

  function burn(uint256 _value) public returns(bool){
    require(balances[msg.sender] >= _value);//确保余额足够
    balances[msg.sender] -= _value;
    //totalSupply -= _value;
    Burn(msg.sender, _value);
  }

  function burnFrom(address _from, uint256 _value) public returns(bool){
    require(balances[_from] >= _value);//确保余额足够
    require(_value <= allowances[_from][msg.sender]);
    balances[_from] -= _value;
    //totalSupply -= _value;
    allowances[_from][msg.sender] -= _value;
    Burn(_from, _value);
    return true;
  }

  function increaseApproval(address _spender, uint _addedvalue) public returns(bool){
      require(allowances[msg.sender][_spender] - _addedvalue > allowances[msg.sender][_spender]);
      allowances[msg.sender][_spender] += _addedvalue;
      Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
      return true;
  }

  function decreaseApproval(address _spender, uint _subtractedvalue) public returns(bool) {
      uint oldValue = allowances[msg.sender][_spender];
      if (oldValue < _subtractedvalue) {
          allowances[msg.sender][_spender] = 0;
      } else {
          allowances[msg.sender][_spender] -= _subtractedvalue;
      }
      Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
      return true;
  }

  function _balances(address addr)  public returns(uint){
    return balances[addr];
  }
}

//对外发布合约
contract FairToken is TokenERC20 {
    function FairToken() TokenERC20(2000000000,"test_watt", "watt", 18) public {

    }
}
