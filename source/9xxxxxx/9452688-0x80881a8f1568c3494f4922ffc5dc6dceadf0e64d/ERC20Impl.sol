pragma solidity ^0.4.20;

// 定义ERC-20标准接口
contract ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    function transfer(address to, uint tokens) public returns (bool success);
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// 实现ERC-20标准接口
contract ERC20Impl is ERC20Interface {
    // 存储每个地址的余额（因为是public的所以会自动生成balanceOf方法）
    mapping (address => uint256) public balanceOf;
    // 存储每个地址可操作的地址及其可操作的金额
    mapping (address => mapping (address => uint256)) internal allowed;

    // 初始化属性
    constructor() public {
        name = "幸福币";
        symbol = "KAROS"; 
        decimals = 18;
        totalSupply = 2000000000 * 10 ** uint256(decimals);
        // 初始化该代币的账户会拥有所有的代币
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        // 检验接收者地址是否合法
        require(to != address(0));
        // 检验发送者账户余额是否足够
        require(balanceOf[msg.sender] >= tokens);
        // 检验是否会发生溢出
        require(balanceOf[to] + tokens >= balanceOf[to]);

        // 扣除发送者账户余额
        balanceOf[msg.sender] -= tokens;
        // 增加接收者账户余额
        balanceOf[to] += tokens;

        // 触发相应的事件
        emit Transfer(msg.sender, to, tokens);
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        // 检验地址是否合法
        require(to != address(0) && from != address(0));
        // 检验发送者账户余额是否足够
        require(balanceOf[from] >= tokens);
        // 检验操作的金额是否是被允许的
        require(allowed[from][msg.sender] <= tokens);
        // 检验是否会发生溢出
        require(balanceOf[to] + tokens >= balanceOf[to]);

        // 扣除发送者账户余额
        balanceOf[from] -= tokens;
        // 增加接收者账户余额
        balanceOf[to] += tokens;

        // 触发相应的事件
        emit Transfer(from, to, tokens);   

        success = true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        // 触发相应的事件
        emit Approval(msg.sender, spender, tokens);

        success = true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}
