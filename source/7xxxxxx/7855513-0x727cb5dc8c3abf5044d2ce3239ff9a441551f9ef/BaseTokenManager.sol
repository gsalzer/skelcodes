pragma solidity >=0.5.3 < 0.6.0;

import { SafeMath } from "./SafeMath.sol";
import { AdminManaged } from "./AdminManaged.sol";


/// @author Ben, Veronica & Ryan of Linum Labs
/// @author Ryan N.                 RyRy79261
/// @title Basic Linear Token Manager
contract BaseTokenManager is AdminManaged {
    using SafeMath for uint256;

    address internal membershipManager_;
    address internal reserveToken_;
    address internal revenueTarget_;
    address internal proteaAccount_;
    uint256 internal contributionRate_;

    string internal name_;
    string internal symbol_;

    uint256 internal totalSupply_;
    uint256 internal poolBalance_;
    
    
    uint256 internal gradientDenominator_ = 2000; // numerator/denominator DAI/Token
    uint256 internal decimals_ = 18; // For now, assume 10^18 decimal precision

    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) internal balances;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    event Mint(address indexed to, uint256 amount, uint256 totalCost);
    event Burn(address indexed from, uint256 amount, uint256 reward);

    constructor(
        string memory _name,
        string memory _symbol,
        address _reserveToken,
        address _proteaAccount,
        address _publisher,
        uint256 _contributionRate,
        address _membershipManager
    ) 
        public
        AdminManaged(_publisher)
    {
        name_ = _name;
        symbol_ = _symbol;
        reserveToken_ = _reserveToken;
        revenueTarget_ = _publisher;
        proteaAccount_ = _proteaAccount;
        contributionRate_ = _contributionRate;
        membershipManager_ = _membershipManager;
    }

     /// @dev                Gets the balance of the specified address.
    /// @param _spender     :address The account that will receive the funds.
    /// @param _value       :uint256 The value of funds accessed.
    /// @return             :boolean Indicating the action was successful.
    // Rough gas usage 47,234
    function approve(
        address _spender, 
        uint256 _value
    ) 
        external 
        returns (bool) 
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev                Gets the value of the current allowance specifed for that account
    /// @param _owner       :address The account sending the funds.
    /// @param _spender     :address The account that will receive the funds.
    /// @return             An uint256 representing the amount owned by the passed address.
    function allowance(address _owner, address _spender) 
        external 
        view 
        returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
    /// @dev                Gets the balance of the specified address.
    /// @param _owner       :address The address to query the the balance of.
    /// @return             An uint256 representing the amount owned by the passed address.
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    /// @dev                Total number of tokens in existence
    /// @return             A uint256 representing the total supply of tokens in this market
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    /// @dev                Returns the address where community revenue is sent
    /// @return             :address Address of the revenue storing account
    function revenueTarget() external view returns(address) {
        return revenueTarget_;
    }

    /// @dev                Returns the contribution rate for the community on Token purchase
    /// @return             :uint256 The percentage of incoming collateral collected as revenue
    function contributionRate() external view returns(uint256) {
        return contributionRate_;
    }

    /// @dev                Returns the decimals set for the community
    /// @return             :uint256 The decimals set for the community
    function decimals() external view returns(uint256) {
        return decimals_;
    }
}
