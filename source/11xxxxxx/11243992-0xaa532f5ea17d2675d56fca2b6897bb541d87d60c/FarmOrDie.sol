pragma solidity >=0.4.22 <0.8.0;

import "./IFarmOrDie.sol";
import "./SafeMath.sol";


contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract FarmOrDie is Ownable, IFarmOrDie {

    using SafeMath for uint256;

    event LogBurn(uint256 indexed epoch, uint256 totalSupply);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public constant name = "Farm Or Die";
    string public constant symbol = "SKULLS";
    uint256 public constant decimals = 18;

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0); //(2^256) - 1
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 26000 * 10**DECIMALS;

    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = ~uint128(0); //(2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    mapping (address => mapping (address => uint256)) private _allowedFragments;

    function burn(uint256 epoch, uint256 decayrate) external onlyOwner returns (uint256)
    {
        uint256 _remainrate = 100;
        _remainrate = _remainrate.sub(decayrate);


        _totalSupply = _totalSupply.mul(_remainrate);
        _totalSupply = _totalSupply.sub(_totalSupply.mod(100));
        _totalSupply = _totalSupply.div(100);

        
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit LogBurn(epoch, _totalSupply);
        return _totalSupply;
    }

    constructor() public {
        _owner = msg.sender;
        
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[_owner] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        emit Transfer(address(0x0), _owner, _totalSupply);
    }

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address who) public view returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 value) public  validRecipient(to) returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner_, address spender) public view returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function transferFrom(address from, address to, uint256 value) public validRecipient(to) returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function mint(address account, uint256 value) public {
        require(account != address(0));

        uint256 gonValue = value.mul(_gonsPerFragment);

        _totalSupply = _totalSupply.add(gonValue);   
        _gonBalances[account] = _gonBalances[account].add(gonValue);
        emit Transfer(address(0), account, value);
    }
}
