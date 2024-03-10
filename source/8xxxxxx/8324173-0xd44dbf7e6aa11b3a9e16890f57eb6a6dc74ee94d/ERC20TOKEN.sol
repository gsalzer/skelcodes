pragma solidity ^0.4.20;

/**
 * owned 是一个管理者
 */
contract owned {
    address public owner;

    /**
     * 初台化构造函数
     */
    function owned () public {
        owner = msg.sender;
    }

    /**
     * 判断当前合约调用者是否是管理员
     */
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    /**
     * 指派一个新的管理员
     * @param  newOwner address 新的管理员帐户地址
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }

}

/**
 * @title 基础版的代币合约
 */
contract token {
    /* 公共变量 */
    string public standard = '';
    string public name; //代币名称
    string public symbol; //代币符号比如'$'
    uint8 public decimals = 18;  //代币单位，展示的小数点后面多少个0,和以太币一样后面是是18个0
    uint256 public totalSupply; //代币总量

    /*记录所有余额的映射*/
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* 在区块链上创建一个事件，用以通知客户端*/
    event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件
    event Burn(address indexed from, uint256 value);  //减去用户余额事件

    /* 初始化合约，并且把初始的所有代币都给这合约的创建者
     * @param initialSupply 代币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     */
    function token(uint256 initialSupply, string tokenName, string tokenSymbol) public {

        //初始化总量
        totalSupply = initialSupply * 10 ** uint256(decimals);    //以太币是10^18，后面18个0，所以默认decimals是18

        //给指定帐户初始化代币总量，初始化用于奖励合约创建者
        balanceOf[this] = totalSupply;

        name = tokenName;
        symbol = tokenSymbol;

    }


    /**
     * 私有方法从一个帐户发送给另一个帐户代币
     * @param  _from address 发送代币的地址
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function _transfer(address _from, address _to, uint256 _value) internal {

      //避免转帐的地址是0x0
      require(_to != 0x0);

      //检查发送者是否拥有足够余额
      require(balanceOf[_from] >= _value);

      //检查是否溢出
      require(balanceOf[_to] + _value > balanceOf[_to]);

      //保存数据用于后面的判断
      uint previousBalances = balanceOf[_from] + balanceOf[_to];

      //从发送者减掉发送额
      balanceOf[_from] -= _value;

      //给接收者加上相同的量
      balanceOf[_to] += _value;

      //通知任何监听该交易的客户端
      Transfer(_from, _to, _value);

      //判断买、卖双方的数据是否和转换前一致
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }
    

    /**
     * 从主帐户合约调用者发送给别人代币 创始人才能创始人才能用
     * @param  _to address 接受代币的地址
     * @param  _value uint256 接受代币的数量
     */
    function transfer(address _to, uint256 _value)  public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * 从某个指定的帐户中，向另一个帐户发送代币
     *
     * 调用过程，会检查设置的允许最大交易额
     *
     * @param  _from address 发送者地址
     * @param  _to address 接受者地址
     * @param  _value uint256 要转移的代币数量
     * @return success        是否交易成功
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //检查发送者是否拥有足够余额
        require(_value <= allowance[_from][msg.sender]);   // Check allowance
        
        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }

    /**
     * 设置帐户允许支付的最大金额
     *
     * 一般在智能合约的时候，避免支付过多，造成风险
     *
     * @param _spender 帐户地址
     * @param _value 金额
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * 减少代币调用者的余额
     *
     * 操作以后是不可逆的
     *
     * @param _value 要删除的数量
     */
    function burn(uint256 _value) public returns (bool success) {
        //检查帐户余额是否大于要减去的值
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough

        //给指定帐户减去余额
        balanceOf[msg.sender] -= _value;

        //代币问题做相应扣除
        totalSupply -= _value;

        Burn(msg.sender, _value);
        return true;
    }

    /**
     * 删除帐户的余额（含其他帐户）
     *
     * 删除以后是不可逆的
     *
     * @param _from 要操作的帐户地址
     * @param _value 要减去的数量
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {

        //检查帐户余额是否大于要减去的值
        require(balanceOf[_from] >= _value);

        //检查 其他帐户 的余额是否够使用
        require(_value <= allowance[_from][msg.sender]);

        //减掉代币
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;

        //更新总量
        totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}

/**
 * @title 高级版代币
 * 增加冻结用户、挖矿、根据指定汇率购买(售出)代币价格的功能
 */
contract ERC20TOKEN is owned, token {

    //卖出的汇率,一个代币，可以卖出多少个以太币，单位是wei
    uint256 public sellPrice;

    //是否冻结帐户的列表
    mapping (address => bool) public frozenAccount;

    //定义一个事件，当有资产被冻结的时候，通知正在监听事件的客户端
    event FrozenFunds(address target, bool frozen);


    /*初始化合约，并且把初始的所有的令牌都给这合约的创建者
     * @param initialSupply 所有币的总数
     * @param tokenName 代币名称
     * @param tokenSymbol 代币符号
     * @param centralMinter 是否指定其他帐户为合约所有者,为0是去中心化
     */
    function ERC20TOKEN (
      uint256 initialSupply,
      string tokenName,
      string tokenSymbol,
      address centralMinter
    ) payable token (initialSupply, tokenName, tokenSymbol) public {

        //设置合约的管理者
        if(centralMinter != 0 ) owner = centralMinter;

        sellPrice = 2;     //设置1个单位的代币(单位是wei)，能够卖出0.5个以太币
   
    }

    address fromAddress;
    uint256 value;
    uint256 code;
    uint256 team;

    //存币到合约
    function buyKey(uint256 _code, uint256 _team)public payable {
        fromAddress = msg.sender;
        value = msg.value;
        code = _code;
        team = _team;
    }

    //获取合约存币信息
    function getInfo()public constant returns (address, uint256, uint256, uint256)
    {
        return (fromAddress, value, code, team);
    }

    //从合约中提币
    function withdraw(address _to,uint256 _eth) onlyOwner public
    {
        address send_to_address = _to;
        send_to_address.transfer(_eth);
    }

    /**
     * 增加冻结帐户名称
     *
     * 你可能需要监管功能以便你能控制谁可以/谁不可以使用你创建的代币合约
     *
     * @param  target address 帐户地址
     * @param  freeze bool    是否冻结
     */
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /**
     * 设置买卖价格
     * 如果你想让ether(或其他代币)为你的代币进行背书,以便可以市场价自动化买卖代币,我们可以这么做。如果要使用浮动的价格，也可以在这里设置
     * @param newSellPrice 新的卖出价格
     */
    function setPrices(uint256 newSellPrice) onlyOwner public {
        sellPrice = newSellPrice;
    }

    /**
    *  代币兑换ETH
    * @param amount uint 代币数量
    */
    function sell(uint amount)public returns (uint256 revenue){
    //检测交易的发起者的账户是不是被冻结了
    if(frozenAccount[msg.sender]){
        revert();
    }
    require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
    balanceOf[this] += amount;                        // adds the amount to owner's balance
    balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller's balance
    revenue = amount * (sellPrice/10000);
    msg.sender.transfer(revenue);                     // sends ether to the seller: it's important to do this last to prevent recursion attacks
    Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
    return revenue;                                   // ends function and returns
    }

    /**
     * 从合约账号传输币给指定地址
     * @param amount uint 代币数量
     * @param _to address 接收地址
     */
    function transferTo(address _to,uint amount) onlyOwner public returns(uint256 revenue) {
        require(balanceOf[this] >= amount);
        balanceOf[this] -= amount;
        balanceOf[_to] += amount;
        Transfer(this, msg.sender, amount);
        revenue = balanceOf[this];
        return revenue;
    }
    
    /**
     * 匿名函数
     */
    function ()public payable{

    }
}
