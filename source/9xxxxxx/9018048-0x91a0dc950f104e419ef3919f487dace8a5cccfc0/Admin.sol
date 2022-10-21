// File: contracts\interfaces\IAdmin.sol

pragma solidity ^0.4.24;

/**
 * @dev Interface for System Config admin.
 */
contract IAdmin
{
	function isAdmin(address _account) public view returns (bool);
	
	function addAdmin(address _account) public;
	
	function removeAdmin(address _account) public;
	
    function renounceAdmin() public;
}

// File: contracts\Owned.sol

pragma solidity ^0.4.24;

/**
 * @dev Contract used to give other contracts ownership rights and management features.
 * based on:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Owned {
	
    address public owner;
    address public newOwner;
	
	/**
	 * @dev Event raised when ownership was transfered to a different address.
	 * @param _from Current owner address we transfer ownership from
	 * @param _to New owner address that just acquired ownership
	 */
    event OwnershipTransferred(address indexed _from, address indexed _to);
	
	
	
	/**
	 * @dev Constructor
	 */
    constructor() internal {
        owner = msg.sender;
		emit OwnershipTransferred(address(0), owner);
    }
	
    modifier onlyOwner {
        require(msg.sender == owner, "Owner required");
        _;
    }
	
	/**
	 * @dev Transfer ownership function
	 * @param _newOwner New owner address acquiring ownership of contract
	 */
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
	
	/**
	 * @dev New owner pending to accept ownership executes this function to confirm his ownership.
	 */
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Owned: Only user with pending ownership acceptance can accept ownership!");
		
        emit OwnershipTransferred(owner, newOwner);
        
		owner = newOwner;
        newOwner = address(0);
    }
}

// File: contracts\Named.sol

pragma solidity ^0.4.24;


/**
 * @dev Contract used to give a name to implementing contract.
 */
contract Named is Owned
{
	bytes32 public name;
	
	/**
	 * @dev Event raised when name was changed.
	 * @param _owner Contract owner performing the operation.
	 * @param _newName New name given to contract.
	 */
	event NameChanged(address indexed _owner, bytes32 _newName);
    
	
	
	/**
	 * @dev Constructor
	 */
    constructor() internal {
		name = "";
    }
	
    /**
	 * @dev Change contract name, only admin can do it.
	 * @param _newName New name given to contract.
	 */
    function setName(bytes32 _newName) public onlyOwner returns (bool success) {
		if (name != _newName) {
			name = _newName;
			emit NameChanged(msg.sender, _newName);
			return true;
		}
		return false;
    }
}

// File: contracts\Admin.sol

pragma solidity ^0.4.24;




contract Admin is IAdmin
	, Owned
	, Named
{
	/**
	 * @dev Event is raised when a new admin was added.
	 * @param admin Admin address performing the operation.
	 * @param account New admin address added.
	 */
	event AdminAdded(address indexed admin, address indexed account);
	
	/**
	 * @dev Event is raised when admin was removed.
	 * @param admin Admin address performing the operation.
	 * @param account Admin address being removed.
	 */
    event AdminRemoved(address indexed admin, address indexed account);
	
	/**
	 * @dev Event is raised when admin renounces to his admin role.
	 * @param account Admin address renouncing to his admin role.
	 */
	event AdminRenounced(address indexed account);
	
	
	
	mapping(address => bool) public admin;
	
	constructor()
		Owned()
		public
	{
		addAdmin(msg.sender);
		name = "Fiatech admins";
	}
	
	modifier onlyAdmin() {
		require(admin[msg.sender], "Admin required");
		_;
	}
	
	function isAdmin(address _account) public view returns (bool) {
		return admin[_account];
	}
	
	function addAdmin(address _account) public onlyOwner {
		require(_account != address(0));
		require(!admin[_account], "Admin already added");
		admin[_account] = true;
		emit AdminAdded(msg.sender, _account);
	}
	
	function removeAdmin(address _account) public onlyOwner {
		require(_account != address(0));
		require(_account != owner, "Owner can not remove his admin role");
		require(admin[_account], "Remove admin only");
		admin[_account] = false;
		emit AdminRemoved(msg.sender, _account);
	}
	
	function renounceAdmin() public {
		require(msg.sender != owner, "Owner can not renounce to his admin role");
		require(admin[msg.sender], "Renounce admin only");
		admin[msg.sender] = false;
		emit AdminRenounced(msg.sender);
    }
}
