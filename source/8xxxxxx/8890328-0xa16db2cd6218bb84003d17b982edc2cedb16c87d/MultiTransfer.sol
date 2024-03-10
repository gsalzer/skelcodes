// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
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
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/MultiTransfer.sol

pragma solidity ^0.5.0;



/**
 * @title An amazing project called mulit_transfer
 * @dev This contract is the base of our project
 */
contract MultiTransfer is Ownable{

    address public tokenAddress;
    uint256 public minThreshold;
    address public collector;
    mapping(address => bool) public whitelists;

    constructor (address _tokenAddress,
                 address _collector,
                 uint256 _minThreshold) public {
        require(_tokenAddress != address(0) && _collector != address(0) && _minThreshold > 0, "invalid params");
        tokenAddress = _tokenAddress;
        collector = _collector;
        minThreshold = _minThreshold;
        whitelists[msg.sender] = true;
        whitelists[collector] = true;
    }

    function() external payable {}

    function transferToken(address _from, uint256 _amount) internal {
        require(_from != address(0) && _amount >= minThreshold , "invalid from or amount");
        IERC20(tokenAddress).transferFrom(_from, collector, _amount);
    }

    function multiTransferToken(address[] memory _froms, uint256[] memory _amounts) public {
        require(_froms.length == _amounts.length, "invalid transfer token counts");
        for(uint256 i = 0; i<_froms.length; i++ ){
            transferToken(_froms[i], _amounts[i]);
        }
    }

    function multiTransferETH(address[] memory _receives, uint256[] memory _amounts) public {
        require(whitelists[msg.sender], "invalid sender");
        require(_receives.length == _amounts.length, "invalid transfer eth counts");

        uint256 count = 0;
        uint256 i = 0;

        for(i = 0; i < _amounts.length; i++){
            count += _amounts[i];
        }
        require(address(this).balance >= count, "contract balance not enough");

        for(i = 0; i < _receives.length; i++){
            address payable receiver = address(uint160(_receives[i]));
            receiver.transfer(_amounts[i]);
        }
    }

    function configureThreshold(uint256 _minThreshold) public onlyOwner {
        require(_minThreshold > 0, "invalid threshold");
        minThreshold = _minThreshold;
    }

    function modifyTokenAddress(address _tokenAddress) public onlyOwner{
        require(_tokenAddress != address(0), "invalid token address");
        tokenAddress = _tokenAddress;
    }

    function modifyCollector(address _collector) public onlyOwner {
        require(_collector != address(0), "invalid collector address");
        collector = _collector;
    }

    function modifyWhitelist(address _user, bool _isWhite) public onlyOwner {
        require(_user != address(0), "invalid user");
        whitelists[_user] = _isWhite;
    }

    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) {
            address payable owner = address(uint160(owner()));
            owner.transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }

}
