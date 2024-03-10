pragma solidity 0.5.8;

import "./SafeMath.sol";
import "./SafeGuard.sol";
import "./IERC644.sol";


/**
 * @title ERC644 Standard Balances Contract
 * @author chrisfranko
 */
contract ERC644Balances is IERC644, SafeGuard {
    using SafeMath for uint256;

    uint256 public totalSupply;

    event BalanceAdj(address indexed module, address indexed account, uint amount, string polarity);
    event ModuleSet(address indexed module, bool indexed set);

    mapping(address => bool) public modules;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    modifier onlyModule() {
        require(modules[msg.sender], "ERC644Balances: caller is not a module");
        _;
    }

    /**
     * @notice Set allowance of `_spender` in behalf of `_sender` at `_value`
     * @param _sender Owner account
     * @param _spender Spender account
     * @param _value Value to approve
     * @return Operation status
     */
    function setApprove(address _sender, address _spender, uint256 _value) external onlyModule returns (bool) {
        allowed[_sender][_spender] = _value;
        return true;
    }

    /**
     * @notice Decrease allowance of `_spender` in behalf of `_from` at `_value`
     * @param _from Owner account
     * @param _spender Spender account
     * @param _value Value to decrease
     * @return Operation status
     */
    function decApprove(address _from, address _spender, uint _value) external onlyModule returns (bool) {
        allowed[_from][_spender] = allowed[_from][_spender].sub(_value);
        return true;
    }

    /**
    * @notice Increase total supply by `_val`
    * @param _val Value to increase
    * @return Operation status
    */
    function incTotalSupply(uint _val) external onlyModule returns (bool) {
        totalSupply = totalSupply.add(_val);
        return true;
    }

    /**
     * @notice Decrease total supply by `_val`
     * @param _val Value to decrease
     * @return Operation status
     */
    function decTotalSupply(uint _val) external onlyModule returns (bool) {
        totalSupply = totalSupply.sub(_val);
        return true;
    }

    /**
     * @notice Set/Unset `_acct` as an authorized module
     * @param _acct Module address
     * @param _set Module set status
     * @return Operation status
     */
    function setModule(address _acct, bool _set) external onlyOwner returns (bool) {
        modules[_acct] = _set;
        emit ModuleSet(_acct, _set);
        return true;
    }

    /**
     * @notice Get `_acct` balance
     * @param _acct Target account to get balance.
     * @return The account balance
     */
    function getBalance(address _acct) external view returns (uint256) {
        return balances[_acct];
    }

    /**
     * @notice Get allowance of `_spender` in behalf of `_owner`
     * @param _owner Owner account
     * @param _spender Spender account
     * @return Allowance
     */
    function getAllowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @notice Get if `_acct` is an authorized module
     * @param _acct Module address
     * @return Operation status
     */
    function getModule(address _acct) external view returns (bool) {
        return modules[_acct];
    }

    /**
     * @notice Get total supply
     * @return Total supply
     */
    function getTotalSupply() external view returns (uint256) {
        return totalSupply;
    }

    /**
     * @notice Increment `_acct` balance by `_val`
     * @param _acct Target account to increment balance.
     * @param _val Value to increment
     * @return Operation status
     */
    function incBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].add(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "+");
        return true;
    }

    /**
     * @notice Decrement `_acct` balance by `_val`
     * @param _acct Target account to decrement balance.
     * @param _val Value to decrement
     * @return Operation status
     */
    function decBalance(address _acct, uint _val) public onlyModule returns (bool) {
        balances[_acct] = balances[_acct].sub(_val);
        emit BalanceAdj(msg.sender, _acct, _val, "-");
        return true;
    }

    function transferRoot(address _new) external returns (bool) {
        return false;
    }
}


