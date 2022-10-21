pragma solidity ^0.4.24;


import "./ERC20Basic.sol";
import "./SafeMath.sol";


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;
    address internal owner;
    mapping (address => bool) public frozenAccount;
    mapping (address => bool) public whiteList;
    bool public transferLocked = false;
    event FrozenFunds(address target, bool frozen);
    event SetWhiteList(address target, bool allowed);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (transferLocked) {
          require(whiteList[msg.sender]);
        }
        require(!frozenAccount[msg.sender]);
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
     * @dev set all transfer lock status
     * @param _transferLocked  true or false
     */
    function setTransferLocked(bool _transferLocked) onlyOwner public {
      transferLocked = _transferLocked;
    }

    /**
     * @dev set given address to white list
     * @param _target The target address
     * @param _allowed true or false ( if set true then can transfer token )
     */
    function setWhiteList(address _target, bool _allowed) onlyOwner public {
      whiteList[_target] = _allowed;
      emit SetWhiteList(_target, _allowed);
    }

}

