pragma solidity ^0.4.26;

//验证转账的余额的正确性
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// erc20令牌的接口
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, string memory data) public;
}

// ----------------------------------------------------------------------------
// 设置合同拥有者
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//发行币
contract FucksToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;



    constructor(address _address) public payable {
        symbol = "EPT";
        name = "Express payment token";
        decimals = 8;
        _totalSupply = 13000000000000000;
        balances[_address] = _totalSupply;


        emit Transfer(address(0), _address, _totalSupply);
        //Owned.transferOwnership(_address);//将所有者转让给_address
    }

    // ------------------------------------------------------------------------
    // 总供应
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // 获取地址的用户余额
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    //转账
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    //我的理解是：A给B了1000token支票,A的余额是不扣除的，B可以用transferFrom随时提现的到自己的地址下才能用,B提现到自己账号下面后A的余额才会减少。（A的余额必须充足才可以）
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    //取走approve给自己的token
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    //获取某个拥有者给某个用户的额度
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    //比approve多调用了receiveApproval
    function approveAndCall(address spender, uint tokens, string memory data) public  returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, spender, data);
        return true;
    }

    //不接受eth
    function () external payable {
        revert();
    }


    // 所有者可以转移其他用户的eth
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function transferOwner(address _address) public onlyOwner returns (bool success) {
        Owned.transferOwnership(_address);//将所有者转让给_address
        return true;
    }


}
