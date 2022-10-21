pragma solidity 0.7.2;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Author: Bitnord
// Website: https://bitnord.no
//
//===========================================================================================================
import "IERC20.sol";
//===========================================================================================================
/**
 * StableNOK ERC20 token contract
 * 
 * 
 */
contract StableNOK {

  //-------------------------------------------------------------------------------------------------------
  /**
   * Global contract variables
   * 
   */
  address public admin;
  mapping (address => uint256) private balances;
  mapping (address => uint256) private frozen;
  mapping (address => mapping (address => uint256)) private allowances;
  string  public name;
  string  public symbol;
  uint8   public decimals;
  uint256 public totalSupply;
  bool    public paused = false;
  uint256 public constant MAX_UINT = 2**256 - 1;
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
   * Contract events
   * 
   */
  event Transfer(address indexed _from,   address indexed _to,      uint256 _value);
  event Approval(address indexed _owner,  address indexed _spender, uint256 _value);
  event Paused();
  event Unpaused();
  event AdminPowersTransferred(address  indexed _previousAdmin, address indexed _newAdmin);
  event AdminPowersRenounced(address    indexed _previousAdmin);
  event FundsFrozen(address indexed _account, uint256 _amount);
  event FundsUnFrozen(address indexed _account, uint256 _amount);
  event FrozenFundsBurned(address indexed _account, uint256 _amount);
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Contract constructor
  * 
  */
  constructor() {
    admin = msg.sender;
    name = "Stable NOK";
    symbol = "NOK";
    decimals = 2;
    totalSupply = 1000;
    balances[admin] = totalSupply;
    emit Transfer(address(0), admin, totalSupply);
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * ERC20 transfer function
  * 
  */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(!paused);
    require(_to != address(0));
    require(balances[msg.sender] >= _value);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * ERC20 transferFrom function
  * 
  */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(!paused);
    require(_from != address(0));
    require(_to != address(0));
    require(balances[_from] >= _value);
    require(allowances[_from][msg.sender] >= _value);
    balances[_to] += _value;
    balances[_from] -= _value;
    if(allowances[_from][msg.sender] != MAX_UINT) { // Allow for infinite allowance
      allowances[_from][msg.sender] -= _value;
    }
    emit Transfer(_from, _to, _value);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * ERC20 approve function
  * 
  */
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(!paused);
    require(_spender != address(0));
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * ERC20 allowance function
  * 
  */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowances[_owner][_spender];
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * ERC20 balanceOf function
  * 
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 safeApprove function
  * Added as alternative approval management functions to avoid known front-running attacks.
  * More info: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
  * 
  */
  function safeApprove(address _spender, uint256 _value, uint256 _expectedAllowance) public returns (bool success) {
    require(!paused);
    require(_spender != address(0));
    require(allowances[msg.sender][_spender] == _expectedAllowance);
    allowances[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 increaseApproval function
  * Added as alternative approval management functions to avoid known front-running attacks.
  * More info: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
  * 
  */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
    require(!paused);
    require(_spender != address(0));
    require((allowances[msg.sender][_spender] + _addedValue) >= allowances[msg.sender][_spender]);
    allowances[msg.sender][_spender] += _addedValue;
    emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 decreaseApproval function
  * Added as alternative approval management functions to avoid known front-running attacks.
  * More info: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
  * 
  */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
    require(!paused);
    require(_spender != address(0));
    if(_subtractedValue > allowances[msg.sender][_spender]) {
      allowances[msg.sender][_spender] = 0;
    } else {
      allowances[msg.sender][_spender] = allowances[msg.sender][_spender] - _subtractedValue;
    }
    emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 mint function
  * 
  */
  function mint(address _account, uint256 _amount) public returns (bool success) {
    require(msg.sender == admin);
    totalSupply += _amount;
    balances[_account] += _amount;
    emit Transfer(address(0), _account, _amount);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 burn function
  * 
  */
  function burn(address _account, uint256 _amount) public returns (bool success) {
    require(msg.sender == admin);
    require(balances[_account] >= _amount);
    totalSupply -= _amount;
    balances[_account] -= _amount;
    emit Transfer(_account, address(0), _amount);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 pause function
  * 
  */
  function pause() public returns (bool success) {
    require(msg.sender == admin);
    paused = true;
    emit Paused();
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 unpause function
  * 
  */
  function unpause() public returns (bool success) {
    require(msg.sender == admin);
    paused = false;
    emit Unpaused();
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 transferAdminPowers function
  * 
  */
  function transferAdminPowers(address _newAdmin) public returns (bool success) {
    require(msg.sender == admin);
    require(_newAdmin != address(0));
    admin = _newAdmin;
    emit AdminPowersTransferred(admin, _newAdmin);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 renounceAdminPowers function
  * 
  */
  function renounceAdminPowers() public returns (bool success) {
    require(msg.sender == admin);
    admin = address(0);
    emit AdminPowersRenounced(admin);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 freeze function
  * 
  */
  function freeze(address _account, uint256 _amount) public returns (bool success) {
    require(msg.sender == admin);
    require(balances[_account] >= _amount);
    balances[_account] -=_amount;
    frozen[_account] += _amount;
    emit FundsFrozen(_account, _amount);
    emit Transfer(_account, address(0), _amount);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 unFreeze function
  * 
  */
  function unFreeze(address _account, uint256 _amount) public returns (bool success) {
    require(msg.sender == admin);
    require(frozen[_account] >= _amount);
    frozen[_account] -= _amount;
    balances[_account] += _amount;
    emit FundsUnFrozen(_account, _amount);
    emit Transfer(address(0), _account, _amount);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 burnFrozen function
  * 
  */
  function burnFrozen(address _account, uint256 _amount) public returns (bool success) {
    require(msg.sender == admin);
    require(frozen[_account] >= _amount);
    totalSupply -= _amount;
    frozen[_account] -= _amount;
    emit FrozenFundsBurned(_account, _amount);
    return true;
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 recoverERC20 function
  * Used to recover wrongly sent ERC20 tokens to the contract
  * 
  */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) public returns (bool success) {
    require(msg.sender == admin);
    return IERC20(tokenAddress).transfer(admin, tokenAmount);
  }
  //-------------------------------------------------------------------------------------------------------


  //-------------------------------------------------------------------------------------------------------
  /**
  * Non-standard ERC20 receive function
  * Disallows Ether transactions to the contract address
  * 
  */
  receive() external payable {
    revert();
  }
  //-------------------------------------------------------------------------------------------------------

}
