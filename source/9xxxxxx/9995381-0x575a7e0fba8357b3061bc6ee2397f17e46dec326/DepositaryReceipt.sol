pragma solidity ^0.5.16;

contract MakerDAOInsurance {
    function buy() public payable;
    function withdraw() public;
    function balanceOf(address who) external view returns(uint256);
}


contract DepositaryReceipt {
    using SafeMath for *;

    MakerDAOInsurance mutual = MakerDAOInsurance(0x3bc058D0958a543406D70416a810a5Cc023f1F31);

    // --- ERC20 Data ---
    string  public constant name     = "3F Mutual Depositary Receipt SAI";
    string  public constant symbol   = "MDRS";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256)                      public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Approval(address indexed holder, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);


    // --- Token ---
    function transfer(address to, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1))
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(amount);
        require(balanceOf[from] >= amount, "insufficient-balance");
        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        balanceOf[to] = balanceOf[to].add(amount);
        totalSupply = totalSupply.add(amount);
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(balanceOf[from] >= amount, "insufficient-balance");
        balanceOf[from] = balanceOf[from].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(from, address(0), amount);
    }
    
    function cash() public returns(uint256) {
        mutual.withdraw();
        address payable me = address(uint160(address(this)));
        return me.balance;
    }

    function () external payable {
        buy();
    }

    function buy() public payable {
        uint256 before = mutual.balanceOf(address(this));
        mutual.buy.value(msg.value / 2)();
        uint256 later = mutual.balanceOf(address(this));
        _mint(msg.sender, later.sub(before));
    }

    function sell(uint256 amount) external {
        uint256 ethToGo = amount.mul(cash()) / totalSupply;
        _burn(msg.sender, amount);
        address payable recipient = msg.sender;
        (bool scucess, ) = recipient.call.value(ethToGo)("");
        require(scucess);
    }

    function sharePerReceipt() external view returns(uint256) {
        return mutual.balanceOf(address(this)).mul(1e18) / totalSupply;
    }

}

library SafeMath {
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) return 0;
        c = a * b;
        require(c / a == b);
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        require(b <= a);
        c = a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a);
    }

}
