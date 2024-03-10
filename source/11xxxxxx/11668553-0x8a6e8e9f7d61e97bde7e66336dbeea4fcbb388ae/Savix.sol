// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SavixSupply.sol";

contract Savix is IERC20
{
    using SafeMath for uint256;

    address private _owner;
    string private constant NAME = "Savix";
    string private constant SYMBOL = "SVX";
    uint private constant DECIMALS = 9;
    uint private constant MINTIMEWIN = 60;
    uint private constant CONSTINTEREST = 8;
    uint private _constGradient = 0;

    bool private _stakingActive = false;
    uint256 private _stakingSince = 0;

    uint256 private constant MAX_UINT256 = 2**256 - 1;
    uint256 private constant MAX_UINT128 = 2**128 - 1;
    uint256 private constant INITIAL_TOKEN_SUPPLY = 10**5 * 10**DECIMALS;

    // TOTAL_FRAGMENTS is a multiple of INITIAL_TOKEN_SUPPLY so that _fragmentsPerToken is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_FRAGMENTS = MAX_UINT256 - (MAX_UINT256 % INITIAL_TOKEN_SUPPLY);

    uint256 private constant MAX_SUPPLY = MAX_UINT128;  // (2^128) - 1
    
    uint256 private _totalSupply = INITIAL_TOKEN_SUPPLY;
    uint256 private _lastTotalSupply = INITIAL_TOKEN_SUPPLY;
    uint256 private _lastAdjustTime = 0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256[2][] private _supplyMap;

    bool _transferLock = true;

    constructor() public
    {
        _owner = msg.sender;
        
         _totalSupply = INITIAL_TOKEN_SUPPLY;
        _balances[_owner] = TOTAL_FRAGMENTS;

        _supplyMap.push([0, 100000 * 10**DECIMALS]);
        _supplyMap.push([7 * SavixSupply.SECPERDAY, 115000 * 10**DECIMALS]);
        _supplyMap.push([30 * SavixSupply.SECPERDAY, 130000 * 10**DECIMALS]);
        _supplyMap.push([6 * 30 * SavixSupply.SECPERDAY, 160000 * 10**DECIMALS]);
        _supplyMap.push([12 * 30 * SavixSupply.SECPERDAY, 185000 * 10**DECIMALS]);
        _supplyMap.push([18 * 30 * SavixSupply.SECPERDAY, 215000 * 10**DECIMALS]);
        _supplyMap.push([24 * 30 * SavixSupply.SECPERDAY, 240000 * 10**DECIMALS]);
        _supplyMap.push([48 * 30 * SavixSupply.SECPERDAY, 300000 * 10**DECIMALS]);
        
        _constGradient = SafeMath.div(INITIAL_TOKEN_SUPPLY * CONSTINTEREST, 360 * SavixSupply.SECPERDAY * 100);
    }
    
    modifier validRecipient(address to)
    {
        require(to != address(0) && to != address(this));
        _;
    }
    
    modifier onlyOwner 
    {
        require(msg.sender == _owner,"Only owner can call this function.");
        _;
    }

    function isContract(address _addr) private view returns (bool)
    {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function supplyMap() external view returns (uint256[2][] memory) 
    {
        return _supplyMap;
    }

    function initialSupply() external pure returns (uint256) 
    {
        return INITIAL_TOKEN_SUPPLY;
    }

    function finalGradient() external view returns (uint) 
    {
        return _constGradient;
    }

    function lastAdjustTime() external view returns (uint) 
    {
        return _lastAdjustTime;
    }

    function lastTotalSupply() external view returns (uint) 
    {
        return _lastTotalSupply;
    }

    function unlockTransfers() 
      external 
      onlyOwner
    {
        _transferLock = false;
    }

    function startStaking() 
      external 
      onlyOwner
    {
        _stakingActive = true;
        _stakingSince = block.timestamp;

        _constGradient = SafeMath.div(INITIAL_TOKEN_SUPPLY * CONSTINTEREST, 360 * SavixSupply.SECPERDAY *100);
        _totalSupply = _supplyMap[0][1];
        _lastTotalSupply = _totalSupply;
        _lastAdjustTime = 0;

    }
    
    function calculateNewSupply(uint256 calcTime) public returns (uint256)
    {
        SavixSupply.AdjustedSupplyData memory supplyData = SavixSupply.getAdjustedSupply(_supplyMap, calcTime, _lastAdjustTime, _totalSupply, _constGradient);
        if (_totalSupply == supplyData.newSupply)
            return _totalSupply;

        _lastTotalSupply = _totalSupply;
        _totalSupply = supplyData.newSupply;
        _lastAdjustTime = supplyData.adjustTime;
        
        return supplyData.newSupply; 
    }


    function name() external pure returns (string memory) 
    {
        return NAME;
    }

    function symbol() external pure returns (string memory)
    {
        return SYMBOL;
    }

    function decimals() external pure returns (uint8)
    {
        return uint8(DECIMALS);
    }

    function stakingActive() external view returns (bool)
    {
        return _stakingActive;
    }

    function stakingSince() external view returns (uint256)
    {
        return _stakingSince;
    }

    function stakingFrequence() external pure returns (uint)
    {
        return SavixSupply.MINTIMEWIN;
    }

    
    function totalSupply() override external view returns (uint256)
    {
        return _totalSupply;
    }
    
    function dailyInterest() external view returns (uint)
    {
            return SavixSupply.getDailyInterest(block.timestamp - _stakingSince, _lastAdjustTime, _totalSupply, _lastTotalSupply); 
    }

    function balanceOf(address account) override public view returns (uint256)
    {
        return _balances[account].div(TOTAL_FRAGMENTS.div(_totalSupply));
    }

    function _calculateFragments(uint256 value) internal returns (uint256)
    {
        if(_stakingActive == true)
            _totalSupply = calculateNewSupply(block.timestamp - _stakingSince);

        return value.mul(TOTAL_FRAGMENTS.div(_totalSupply));
    }

    function transfer(address to, uint256 value) override
        external
        validRecipient(to)
        returns (bool)
    {
        require(msg.sender == _owner || _transferLock == false || isContract(msg.sender), "Tokens are locked for transfer");
        uint256 rAmount = _calculateFragments(value);
        _balances[msg.sender] = _balances[msg.sender].sub(rAmount,"ERC20: transfer amount exceeds balance");
        _balances[to] = _balances[to].add(rAmount);
        emit Transfer(msg.sender, to, value);       
        return true;
    }

    /**
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 value) 
        override
        external
        returns (bool)
    {
        require(msg.sender == _owner || _transferLock == false || isContract(sender), "Tokens are locked for transfer");
        uint256 rAmount = _calculateFragments(value);
        _balances[sender] = _balances[sender].sub(rAmount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(rAmount);
        emit Transfer(sender, recipient, value);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(value,"ERC20: transfer amount exceeds allowance");
        return true;
    }

    function allowance(address owner, address spender) override external view returns (uint256)
    {
        return _allowances[owner][spender];
    }

    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool)
    {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool)
    {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
        return true;
    }

    
    function approve(address spender, uint256 value) override external returns (bool) 
    {
        _allowances[msg.sender][spender] = 0;
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal 
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        // In order to exclude front-running attacks:
        // To change the approve amount you first have to reduce the addresses`
        // allowance to zero by calling `approve(_spender, 0)` if it is not
        // already 0 to mitigate the race condition described here:
        // https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((value == 0 || _allowances[msg.sender][spender] == 0), "possible front-running attack");
        
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // use same logic to adjust balances as in function transfer
    // only distribute from owner wallet (ecosystem fund)
    // gas friendly way to do airdrops or giveaways
    function distributeTokens(address[] memory addresses, uint256 value)
        external
        onlyOwner
    {
        uint256 rAmount = _calculateFragments(value);
        _balances[_owner] = _balances[_owner].sub(rAmount * addresses.length,"ERC20: distribution total amount exceeds balance");
        for (uint i = 0; i < addresses.length; i++)
        {
            _balances[addresses[i]] = _balances[addresses[i]].add(rAmount);
            emit Transfer(_owner, addresses[i], value);       
        }
    }

    // use same logic to adjust balances as in function transfer
    // only distribute from owner wallet (ecosystem fund)
    // gas friendly way to do airdrops or giveaways
    function distributeTokensFlexSum(address[] memory addresses, uint256[] memory values)
        external
        onlyOwner
    {
        // there has to be exacly 1 value per address
        require(addresses.length == values.length); // Overflow check

        uint256 valuesum = 0;
        for (uint i = 0; i < values.length; i++)
            valuesum += values[i];

        _balances[_owner] = _balances[_owner].sub( _calculateFragments(valuesum),"ERC20: distribution total amount exceeds balance");

        for (uint i = 0; i < addresses.length; i++)
        {
            _balances[addresses[i]] = _balances[addresses[i]].add(_calculateFragments(values[i]));
            emit Transfer(_owner, addresses[i], values[i]);       
        }
    }
    
    function getOwner() 
      external
      view 
    returns(address)
    {
        return _owner;
    }
}

