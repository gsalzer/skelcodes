pragma solidity >=0.5.3 < 0.6.0;

import { Roles } from "./Roles.sol";
import { SafeMath } from "./SafeMath.sol";
import { AdminManaged } from "./AdminManaged.sol";


/// @author Ryan @ Protea 
/// @title Generic Utility base
contract BaseUtility is AdminManaged{
    using SafeMath for uint256;
    using Roles for Roles.Role;

    Roles.Role internal admins_;

    address internal tokenManager_;
    address internal membershipManager_;

    uint256 internal index_ = 0;

    /// @dev Sets the address of the admin to the msg.sender.
    /// @param _tokenManager        :address
    /// @param _membershipManager   :address
    /// @param _communityCreator    :address
    constructor (
        address _tokenManager, 
        address _membershipManager,
        address _communityCreator
    ) 
        public 
        AdminManaged(_communityCreator)
    {
        tokenManager_ = _tokenManager;
        membershipManager_ = _membershipManager;
    }

    modifier onlyMembershipManager() {
        require(msg.sender == membershipManager_, "Not authorised");
        _;
    }

    modifier onlyToken() {
        require(msg.sender == address(tokenManager_), "Not registered token address");
        _;
    }

    /// @dev    Returns the registered token manager
    /// @return address
    function tokenManager() external view returns(address) {
        return tokenManager_;
    }

    /// @dev    Returns the registered membership manager
    /// @return address
    function membershipManager() external view returns(address) {
        return membershipManager_;
    }

    /// @dev    Returns the current index
    /// @return address
    function index() external view returns(uint256) {
        return index_;
    }
}
