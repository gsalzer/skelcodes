pragma solidity ^0.4.19;//告诉编译器solidity版本号
//SafeMath库，用来防止加减乘除运算中出现数据溢出
library SafeMath {
    //乘法
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       //任何数乘0，结果都是0，
       //很像一句废话，但可以防止下面除0运算出现。
        if (a == 0) {
          return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);//逆向检查，如果c溢
//出将终止执行，也就是括号里为假，程序终止。
        return c;
    }
    //除法
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;//由于整数除以整数不会溢出，不需要做逆向检查。
        return c;
    }
    //减法
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);//如果b>a，b-a是负数，溢出
        return a - b;
    }
    //加法
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);//如果a加上b结果更小了，说明溢出了  
        //有人可能会问，为啥不检查c=>b呢？
       //因为如果c<a，则说明a+b结果溢出，也就是b+a会溢出，也就是b越加a越小，即c<b。
        return c;   
    }
}
//所有权合约，用来判断操作币的人是否合法，以及转移所有权
contract Owned {
    address public owner;//全局变量
    address public newOwner;//全局变量
    modifier onlyOwner { require(msg.sender == owner); _; }//修饰函数用的，在函数运行前检查调用者是否为所有者
    event OwnerUpdate(address _prevOwner, address _newOwner);//事件，更新所有者

    function Owned() public {//构造函数，与合约同名，第一次构造合约的时候调用一次，就只有这一次哦
        owner = msg.sender;//初始化所有者
    }

    function transferOwnership(address _newOwner) public onlyOwner {//更新所有者函数，onlyOwner使得只有原所有者可以调用该函数
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {//确认所有权，在原所有者出让所有权后，新所有者发起事件，将新所有权写入区块链
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

// ERC20 Interface，定义ERC20代币规范的函数和事件接口
contract ERC20 {
   //总发行量查询函数
    function totalSupply() public view returns (uint _totalSupply);
   //账户余额查询函数
    function balanceOf(address _owner) public view returns (uint balance);
   //代币转移函数1，发送者调用发币
    function transfer(address _to, uint _value) public returns (bool success);
    //代币转移函数2，接收者调用收币，或者转移给第三方，类似于比特币中消费UTXO
    function transferFrom(address _from, address _to, uint _value) public returns (bool success);
    //批准代币转移函数，配合transferFrom使用，类似于比特币中构造UTXO
    function approve(address _spender, uint _value) public returns (bool success);
    //可消费余额查询函数
    function allowance(address _owner, address _spender) public view returns (uint remaining);
  //代币转移事件
    event Transfer(address indexed _from, address indexed _to, uint _value);
    //代币转移批准事件
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// ERC20Token，定义ERC20代币的函数内容
contract ERC20Token is ERC20 {
    using SafeMath for uint256;//使用SafeMath库
    mapping(address => uint256) balances;//记录账户余额的表，地址为索引，余额为值
    mapping (address => mapping (address => uint256)) allowed;//记录转移可用余额的表，索引是转移的输入地址和输出地址，余额为值，类似于比特币里的未消费输出UTXO。
    uint256 public totalToken; //代币总量
//代币转移函数，_to目标地址，_value代币数量，公有函数哦，谁调用就转谁的币，函数将返回转移是否成功
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {//转移者必须有足够的币吧，而且格外检查数量不是负数，防止有人没钱装大佬，设计合约真的是要格外小心啊
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
//调用函数者将其控制的币（别人调用approve函数得来）转移（可以给自己，也可以给第三个人）
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    //总发行量查询
    function totalSupply() public view returns (uint256) {
        return totalToken;
    }
    //账户余额查询
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
//调用函数者将其_value币给_spender控制，_spender通过调用transferFrom可将币转给自己，也可以转给别人
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
//查询_owner给_spender的可用余额
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

//OTCBTC合约，定义OTB的基本信息和燃烧OTB的方法
contract OTCBTC is ERC20Token, Owned {

    string  public constant name = "Starlink";
    string  public constant symbol = "SLC";
    uint256 public constant decimals = 18;
    uint256 public tokenDestroyed;
    event Burn(address indexed _from, uint256 _tokenDestroyed, uint256 _timestamp);

//在构造函数中定义代币初始发行量
    function OTCBTC() public {
        totalToken = 100000005;
        balances[msg.sender] = totalToken;
    }
//转移代币
    function transferAnyERC20Token(address _tokenAddress, address _recipient, uint256 _amount) public onlyOwner returns (bool success) {
        return ERC20(_tokenAddress).transfer(_recipient, _amount);
    }
//燃烧代币
    function burn (uint256 _burntAmount) public returns (bool success) {
        require(balances[msg.sender] >= _burntAmount && _burntAmount > 0);
        balances[msg.sender] = balances[msg.sender].sub(_burntAmount);
        totalToken = totalToken.sub(_burntAmount);
        tokenDestroyed = tokenDestroyed.add(_burntAmount);
        require (tokenDestroyed <= 100000005);
  //燃烧就是转移到0地址      Transfer(address(this), 0x0, _burntAmount);
        Burn(msg.sender, _burntAmount, block.timestamp);
        return true;
    }

}
