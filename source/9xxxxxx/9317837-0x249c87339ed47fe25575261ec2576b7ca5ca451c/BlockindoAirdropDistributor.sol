pragma solidity >=0.4.20 <0.7.0;

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BlockindoAirdropDistributor{
    using SafeMath for uint256;
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;
    
    address contractOwner;
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner);
        _;
    }
    
    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }
    
    constructor() public{
        contractOwner = msg.sender;
        _addMinter(msg.sender);
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }

    function renounceMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
    
    function checkAllowance(address _tokenContract, address _tokenOwner) public view returns(uint256){
        return IERC20(_tokenContract).allowance(_tokenOwner, address(this));
    }
    
    function claimAllowance(address _tokenContract, address _tokenOwner) onlyMinter public returns(bool){
        uint256 getBalance = IERC20(_tokenContract).allowance(_tokenOwner, address(this));
        return IERC20(_tokenContract).transferFrom(_tokenOwner, address(this), getBalance);
    }
    
    function sendToken(address _tokenContract, address _walletDest, uint256 _amountT) onlyMinter public returns (bool) {
        address dest = _walletDest;
        uint amountToken = _amountT;
        return IERC20(_tokenContract).transfer(dest, amountToken);
    }
    
    function multiSendToken(address _tokenContract, address[] memory _walletDest, uint256 _amountT) onlyMinter public {
        for(uint ia = 0; ia < _walletDest.length; ia++){
            address dest = _walletDest[ia];
            uint amountToken = _amountT;
            IERC20(_tokenContract).transfer(dest, amountToken);
        }
    }
}
