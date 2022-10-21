/**
Author: BlockRocket.tech.

*/

pragma solidity ^0.5.12;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

contract AccessWhitelist is WhitelistedRole {
    constructor() public {
        super.addWhitelisted(msg.sender);
    }
}

contract AccessControls {
    AccessWhitelist public accessWhitelist;

    constructor(AccessWhitelist _accessWhitelist) internal {
        accessWhitelist = _accessWhitelist;
    }

    modifier onlyWhitelisted() {
        require(accessWhitelist.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    modifier onlyWhitelistAdmin() {
        require(accessWhitelist.isWhitelistAdmin(msg.sender), "Caller not whitelist admin");
        _;
    }

    function updateAccessWhitelist(AccessWhitelist _accessWhitelist) external onlyWhitelistAdmin {
        accessWhitelist = _accessWhitelist;
    }
}

contract CommissionSplitter is AccessControls {
    using SafeMath for uint256;

    address public platform;
    uint256 public platformSplit;

    address public partner;
    uint256 public partnerSplit;

    constructor(AccessWhitelist _accessWhitelist, address _platform, uint256 _platformSplit, address _partner, uint256 _partnerSplit)
        AccessControls(_accessWhitelist) public {
        require(_platformSplit.add(_partnerSplit) == 100, "Split percentages are not setup correctly");
        platform = _platform;
        platformSplit = _platformSplit;
        partner = _partner;
        partnerSplit = _partnerSplit;
    }

    function () external payable {
        uint256 singleUnitOfValue = msg.value.div(100);

        uint256 amountToSendPlatform = singleUnitOfValue.mul(platformSplit);
        (bool platformSuccess,) = platform.call.value(amountToSendPlatform)("");
        require(platformSuccess, "Failed to send split to platform");

        uint256 amountToSendPartner = singleUnitOfValue.mul(partnerSplit);
        (bool partnerSuccess,) = partner.call.value(amountToSendPartner)("");
        require(partnerSuccess, "Failed to send split to partner");
    }

    function updatePlatform(address _platform) external onlyWhitelisted {
        platform = _platform;
    }

    function updatePartner(address _partner) external onlyWhitelisted {
        partner = _partner;
    }

    function updateSplit(uint256 _platformSplit, uint256 _partnerSplit) external onlyWhitelisted {
        require(_platformSplit.add(_partnerSplit) == 100, "Split percentages are not setup correctly");
        platformSplit = _platformSplit;
        partnerSplit = _partnerSplit;
    }
}
