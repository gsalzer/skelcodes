pragma solidity 0.5.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner`.
     */
    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * See https://eips.ethereum.org/EIPS/eip-20
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public {
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        _burn(from, value);
    }

}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title BlacklistedRole
 * @dev Blacklisted accounts have been dismissed to perform certain actions.
 */
contract BlacklistedRole is Ownable {
    using Roles for Roles.Role;

    event BlacklistedAdded(address indexed account);
    event BlacklistedRemoved(address indexed account);

    Roles.Role private _blacklisteds;

    modifier notBlacklisted(address account) {
        require(!isBlacklisted(account), "BlacklistedRole: caller is Blacklisted");
        _;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisteds.has(account);
    }

    function addBlacklisted(address account) public onlyOwner {
        _blacklisteds.add(account);
        emit BlacklistedAdded(account);
    }

    function removeBlacklisted(address account) public onlyOwner {
        _blacklisteds.remove(account);
        emit BlacklistedRemoved(account);
    }
}

/**
 * @title ApproveAndCall Interface.
 * @dev ApproveAndCall system allows to communicate with smart-contracts.
 */
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external;
}

/**
 * @title The main contract (g.s).
 */
contract asgX is ERC20, BlacklistedRole {

    // name of the token
    string private _name = "asgX";
    // symbol of the token
    string private _symbol = "asgX";
    // decimals of the token
    uint8 private _decimals = 18;

    // initial supply
    uint256 internal constant INITIAL_SUPPLY = 1000000000 * (10 ** 18);

    // Pausable feature
    bool internal _paused;

    // registered contracts (to prevent loss of token via transfer function)
    mapping (address => bool) private _contracts;

    // events
    event Paused(uint256 time);
    event Unpaused(uint256 time);
    event ContractAdded(address contractAddr);
    event ContractRemoved(address contractAddr);

    modifier notPaused {
        require(!paused(), 'Transfers are temporary suspended');
        _;
    }

    /**
      * @dev constructor function that is called once at deployment of the contract.
      * @param recipient Address to receive initial supply.
      */
    constructor(address recipient, address initialOwner) public Ownable(initialOwner) {

        _mint(recipient, INITIAL_SUPPLY);

    }

    /**
      * @dev modified internal transfer function with Pausable and Blacklist features.
      * @param from The address of token holder.
      * @param to The address to transfer to.
      * @param value The amount to be transferred.
      */
    function _transfer(address from, address to, uint256 value) internal notPaused notBlacklisted(from) {

        super._transfer(from, to, value);

    }

    /**
     * @dev modified transfer function that allows to safely send tokens to registered smart contract.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {

        if (_contracts[to]) {
            approveAndCall(to, value, new bytes(0));
        } else {
            super.transfer(to, value);
        }

        return true;

    }

    /**
    * @dev Allows to owner of the contract to suspend any transfer of the token.
    */
    function pause() public onlyOwner {
        require(!paused(), 'Transfers are suspended already');
        _paused = true;
        emit Paused(block.timestamp);
    }

    /**
    * @dev Allows to owner of the contract to revive transfers of the token.
    */
    function unpause() public onlyOwner {
        require(paused(), 'Transfer are not suspended yet');
        _paused = false;
        emit Unpaused(block.timestamp);
    }

    /**
     * @dev Allows to register other smart contracts (to prevent loss of tokens via transfer function).
     * @param addr Address of smart contracts to work with.
     */
    function registerContract(address addr) public onlyOwner {
        require(isContract(addr), 'Address is not a contract');
        _contracts[addr] = true;
        emit ContractAdded(addr);
    }

    /**
     * @dev Allows to unregister registered smart contracts.
     * @param addr Address of smart contracts to work with.
     */
    function unregisterContract(address addr) external onlyOwner {
        require(_contracts[addr]);
        _contracts[addr] = false;
        emit ContractRemoved(addr);
    }

    /**
    * @dev Allows to send tokens (via Approve and TransferFrom) to other smart contract.
    * @param spender Address of smart contracts to work with.
    * @param amount Amount of tokens to send.
    * @param extraData Any extra data.
    */
    function approveAndCall(address spender, uint256 amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    /**
    * @dev Allows to  owner of the contract withdraw needed ERC20 token from this contract (promo or bounties for example).
    * @param ERC20Token Address of ERC20 token.
    * @param recipient Account to receive tokens.
    */
    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        require(amount > 0);
        IERC20(ERC20Token).transfer(recipient, amount);

    }

    /**
     * @return true if transfers of token are suspended.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @return true if the address is registered as contract
     */
    function isRegistered(address addr) public view returns (bool) {
        return _contracts[addr];
    }

    /**
     * @return true if the address is a сontract
     */
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

}
