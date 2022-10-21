// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/impl/Data.sol

pragma solidity ^0.5.16;


contract Data {
    address public proxy;
    
    struct Asset {
		uint256 typeid;
        bytes32 name;
        address tokenAddress;
        string partnerIssuer;
    }

    mapping(uint256 => Asset) internal Assets;
    mapping (uint256 => uint256) internal AssetIndex;
	uint256[] internal AssetIds;

    constructor(address _proxy) public {
        require(_proxy != address(0), "zero address is not allowed");
        proxy = _proxy;
    }

    // 验证对model的操作是否来源于Proxy
    modifier onlyAuthorized {
        require(msg.sender == proxy, "Data: must be called by entry contract");
        _;
    }

    function _checkParam(uint256 _typeid, bytes32 _name, address _tokenAddress, string memory _partnerIssuer) internal view {
		require(_typeid != uint256(0), "Data: _typeid null is not allowed");
		require(_name != bytes32(0), "Data: _name null is not allowed");
		require(_tokenAddress != address(0), "Data: _tokenAddress null is not allowed");
		require(Address.isContract(_tokenAddress), "_tokenAddress is a non-contract address");
		require(bytes(_partnerIssuer).length > 0, "Data: _partnerIssuer null is not allowed");
	}

    function _insert(
		uint256 _typeid,
        bytes32 _name,
        address _tokenAddress,
        string memory _partnerIssuer
    ) internal {
        _checkParam(_typeid, _name, _tokenAddress, _partnerIssuer);
        require(
            Assets[_typeid].typeid == uint256(0),
            "Data: current Asset exist"
        );
        Asset memory a = Asset(_typeid, _name, _tokenAddress, _partnerIssuer);
        Assets[_typeid] = a;
        AssetIds.push(_typeid);
		AssetIndex[_typeid] = AssetIds.length;
    }

    function insert(
        uint256 _typeid,
		bytes32 _name,
		address _tokenAddress,
		string calldata _partnerIssuer
    ) external onlyAuthorized {
        _insert(_typeid, _name, _tokenAddress, _partnerIssuer);
    }

    function _update(
        uint256 _typeid,
		bytes32 _name,
		address _tokenAddress,
		string memory _partnerIssuer
    ) internal {
        require(
            _typeid != uint256(0),
            "Data: _typeid 0 is not allowed"
        );
        require(
            Assets[_typeid].typeid != uint256(0),
            "Data: current Asset not exist"
        );

        Asset memory a = Assets[_typeid];
        if (_name != bytes32(0)) {
            a.name = _name;
        }
        if (_tokenAddress != address(0)) {
            a.tokenAddress = _tokenAddress;
        }
        if (bytes(_partnerIssuer).length > 0) {
            a.partnerIssuer = _partnerIssuer;
        }
        Assets[_typeid] = a;
    }

    function update(
        uint256 _typeid,
		bytes32 _name,
		address _tokenAddress,
		string calldata _partnerIssuer
    ) external onlyAuthorized {
		_update(_typeid, _name, _tokenAddress, _partnerIssuer);
    }

    function _search(uint256 _typeid)
        internal
        view
        returns (
            uint256,
			bytes32,
			address,
			string memory
        )
    {
        require(
            _typeid != uint256(0),
            "Data: _typeid 0 is not allowed"
        );
        require(
            Assets[_typeid].typeid != uint256(0),
            "Data: current Asset not exist"
        );

        Asset memory a = Assets[_typeid];
        return (a.typeid, a.name, a.tokenAddress, a.partnerIssuer);
    }

    function search(uint256 _typeid)
        external
        view
		onlyAuthorized
        returns (
            uint256,
			bytes32,
			address,
			string memory
        )
    {
        return _search(_typeid);
    }

    function _delete(uint256 _typeid) internal {
		require(_typeid != uint256(0), "Data: _typeid 0 is not allowed");
        require(Assets[_typeid].typeid != uint256(0), "Data: current Asset not exist");
        uint256 _deleteIndex = AssetIndex[_typeid] - 1;
		uint256 _lastIndex = AssetIds.length - 1;
        if(_deleteIndex != _lastIndex){
			AssetIds[_deleteIndex] = AssetIds[_lastIndex];
			AssetIndex[AssetIds[_lastIndex]] = _deleteIndex + 1;
		}
		AssetIds.pop();
        delete Assets[_typeid];
    }

    function del(uint256 _typeid) external onlyAuthorized {
        _delete(_typeid);
    }

    //return Array of assetId
    function getAssetIds() external view onlyAuthorized returns (uint256[] memory){
        uint256[] memory ret = AssetIds;
        return ret;
    }
}

// File: contracts/third/IToken.sol

pragma solidity ^0.5.16;

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function getCallAddress() external view returns (address);
    function allowance(address owner, address spender) external view returns (uint256);
}

// File: contracts/impl/StorageStateful.sol

pragma solidity ^0.5.16;



contract StorageStateful {
    Data public _storage;
}

// File: contracts/interfaces/ICustodian.sol

pragma solidity ^0.5.16;

interface ICustodian {
    function lock(uint256 _typeid, address _from, uint256 _value, bytes32 _memo) external;
    function unlock(uint256 _typeid, address _to, uint256 _value) external;
    function add(uint256 _typeid, bytes32 _name, address _tokenAddress, string calldata _partnerIssuer) external;
    function remove(uint256 _typeid) external;
    function getAsset(uint256 _typeid) external view returns (uint256, bytes32, address, string memory);
    function getAssetIds() external view returns (uint256[] memory assetIds);
    function getLockedFunds(address _tokenAddress) external view returns (uint256);
    event Locked(uint256 indexed typeid, address indexed from, uint256 value, bytes32 memo);
    event UnLocked(uint256 indexed typeid, address indexed sender, uint256 value);
    event AddedAsset(uint256 indexed typeid, bytes32 indexed name);
    event RemovedAsset(uint256 indexed typeid);
}

// File: contracts/impl/Custodian.sol

pragma solidity ^0.5.16;





contract Custodian is StorageStateful, Ownable, ICustodian {
    event Locked(uint256 indexed typeid, address indexed from, uint256 value, bytes32 memo);
    event UnLocked(uint256 indexed typeid, address indexed sender, uint256 value);
    event AddedAsset(uint256 indexed typeid, bytes32 indexed name);
    event RemovedAsset(uint256 indexed typeid);

    modifier onlyWhitelistedToken(uint256 _typeid) {
        (uint256 typeid,,,) = _storage.search(_typeid);
        require(typeid != uint256(0), "Data: the token is prohibited");
        _;
    }

    function lock(uint256 _typeid, address _from, uint256 _value, bytes32 _memo) external onlyWhitelistedToken(_typeid) onlyOwner {
        (,,address tokenAddress,) = _storage.search(_typeid);
        IToken token = IToken(tokenAddress);
        require(token.transferFrom(_from, address(this), _value), "Token: transfer failed");
        emit Locked(_typeid, _from, _value, _memo);
    }

    function unlock(uint256 _typeid, address _to, uint256 _value) external onlyWhitelistedToken(_typeid) onlyOwner {
        (,,address tokenAddress,) = _storage.search(_typeid);
        IToken token = IToken(tokenAddress);
        require(token.transfer(_to, _value), "Token: transfer failed");
        emit UnLocked(_typeid, _to, _value);
    }

    function add(
        uint256 _typeid,
		bytes32 _name,
		address _tokenAddress,
		string calldata _partnerIssuer
    ) external onlyOwner {
         _storage.insert(_typeid, _name, _tokenAddress, _partnerIssuer);
        emit AddedAsset(_typeid, _name);
    }

    function remove(uint256 _typeid) external onlyOwner {
        _storage.del(_typeid);
        emit RemovedAsset(_typeid);
    }

    function getAsset(uint256 _typeid) external view returns (uint256, bytes32, address, string memory) {
        (uint256 typeid, bytes32 name, address tokenAddress, string memory partnerIssuer) = _storage.search(_typeid);
		return (typeid, name, tokenAddress, partnerIssuer);
    }

    function getAssetIds() external view returns (uint256[] memory assetIds) {
        assetIds = _storage.getAssetIds();
    }

    function getLockedFunds(address _tokenAddress) external view returns (uint256) {
        return IToken(_tokenAddress).balanceOf(address(this));
    }
}
