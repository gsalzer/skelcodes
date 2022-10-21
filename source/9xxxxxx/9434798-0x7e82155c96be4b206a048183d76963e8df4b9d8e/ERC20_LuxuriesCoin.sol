pragma solidity >=0.4.22 <0.7.0;

/**
 * 带有安全检查的数学操作
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
 
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
 
  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}


/**
 *  ERC20_LuxuriesCoin
 */
contract ERC20_LuxuriesCoin is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals = 6;  
    uint256 public totalSupply;
    address public owner;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;       
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;    
 
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
 
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
 
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);
    
    /**
     * 初始化构造
     */
    constructor(uint256 initialSupply,
                string memory tokenName,
                string memory tokenSymbol,
                address holder) public {
                            name = tokenName;                                            // 代币名称
                            symbol = tokenSymbol;                                       // 代币符号
                            owner = holder;                                            // 所有人地址
                            totalSupply = initialSupply * 10 ** uint256(decimals);    // 供应的份额，份额跟最小的代币单位有关，份额 = 币数 * 10 ** decimals。
                            balanceOf[holder] = totalSupply;                         // 创建者拥有所有的代币
    }
    
    
    /**
     * 代币交易转移
     * 从创建交易者账号发送`_value`个代币到 `_to`账号
     *
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transfer(address _to, uint256 _value) public{
        require(_to != address(0x0));                                                              // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0); 
        require(balanceOf[msg.sender] >= _value);                                       // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);                            // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);      // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                   // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                                     // Notify anyone listening that this transfer took place
    }
 
    /**
     * 账号之间代币交易转移
     * 
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _value 转移数额
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0x0));                                                                            // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0); 
        require(balanceOf[_from] >= _value);                                                          // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);                                          // Check for overflows
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                             // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                                // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    /**
     * 销毁账户中指定个代币
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                                             // Check if the sender has enough
        require(_value > 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);            // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
 
    /** 
     * 设置某个地址（合约）可以交易者名义花费的代币数。
     * 允许发送者`_spender` 花费不多于 `_value` 个代币
     *
     * @param _spender 授权使用的地址
     * @param _value 最多能花多少钱
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        require(_value > 0); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
 
     /** 
     * 冻结
     */
    function freeze(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                                          // Check if the sender has enough
        require(_value > 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);         // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);          // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
 
     /** 
     * 解除冻结 
     */
    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >= _value);                                                     // Check if the sender has enough
        require(_value > 0); 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
    
    /**
     * 销毁合约
     */
    function kill() public {
       if (owner == msg.sender) { // 检查是否为创建者
          selfdestruct(address(uint160(owner))); // 销毁合约
       }
    }
}
