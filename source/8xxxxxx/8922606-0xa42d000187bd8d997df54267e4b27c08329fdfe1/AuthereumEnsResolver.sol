/**
Author: Authereum Labs, Inc.
*/

pragma solidity 0.5.12;


contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /// @dev Throws if the sender is not the owner
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /// @dev Return the ownership status of an address
    /// @param _potentialOwner Address being checked
    /// @return True if the _potentialOwner is the owner
    function isOwner(address _potentialOwner) external view returns (bool) {
        return owner == _potentialOwner;
    }

    /// @dev Lets the owner transfer ownership of the contract to a new owner
    /// @param _newOwner The new owner
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

contract Managed is Owned {

    // The managers
    mapping (address => bool) public managers;

    /// @dev Throws if the sender is not a manager
    modifier onlyManager {
        require(managers[msg.sender] == true, "Must be manager");
        _;
    }

    event ManagerAdded(address indexed _manager);
    event ManagerRevoked(address indexed _manager);

    /// @dev Adds a manager
    /// @param _manager The address of the manager
    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0), "Address must not be null");
        if(managers[_manager] == false) {
            managers[_manager] = true;
            emit ManagerAdded(_manager);
        }
    }

    /// @dev Revokes a manager
    /// @param _manager The address of the manager
    function revokeManager(address _manager) external onlyOwner {
        require(managers[_manager] == true, "Target must be an existing manager");
        delete managers[_manager];
        emit ManagerRevoked(_manager);
    }
}

contract EnsRegistry {

    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed _node, bytes32 indexed _label, address _owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed _node, address _owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed _node, address _resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed _node, uint64 _ttl);

    // Permits modifications only by the owner of the specified node.
    modifier only_owner(bytes32 _node) {
        require(records[_node].owner == msg.sender, "ENSTest: this method needs to be called by the owner of the node");
        _;
    }

    /**
     * Constructs a new ENS registrar.
     */
    constructor() public {
        records[bytes32(0)].owner = msg.sender;
    }

    /**
     * Returns the address that owns the specified node.
     */
    function owner(bytes32 _node) public view returns (address) {
        return records[_node].owner;
    }

    /**
     * Returns the address of the resolver for the specified node.
     */
    function resolver(bytes32 _node) public view returns (address) {
        return records[_node].resolver;
    }

    /**
     * Returns the TTL of a node, and any records associated with it.
     */
    function ttl(bytes32 _node) public view returns (uint64) {
        return records[_node].ttl;
    }

    /**
     * Transfers ownership of a node to a new address. May only be called by the current
     * owner of the node.
     * @param _node The node to transfer ownership of.
     * @param _owner The address of the new owner.
     */
    function setOwner(bytes32 _node, address _owner) public only_owner(_node) {
        emit Transfer(_node, _owner);
        records[_node].owner = _owner;
    }

    /**
     * Transfers ownership of a subnode sha3(node, label) to a new address. May only be
     * called by the owner of the parent node.
     * @param _node The parent node.
     * @param _label The hash of the label specifying the subnode.
     * @param _owner The address of the new owner.
     */
    function setSubnodeOwner(bytes32 _node, bytes32 _label, address _owner) public only_owner(_node) {
        bytes32 subnode = keccak256(abi.encodePacked(_node, _label));
        emit NewOwner(_node, _label, _owner);
        records[subnode].owner = _owner;
    }

    /**
     * Sets the resolver address for the specified node.
     * @param _node The node to update.
     * @param _resolver The address of the resolver.
     */
    function setResolver(bytes32 _node, address _resolver) public only_owner(_node) {
        emit NewResolver(_node, _resolver);
        records[_node].resolver = _resolver;
    }

    /**
     * Sets the TTL for the specified node.
     * @param _node The node to update.
     * @param _ttl The TTL in seconds.
     */
    function setTTL(bytes32 _node, uint64 _ttl) public only_owner(_node) {
        emit NewTTL(_node, _ttl);
        records[_node].ttl = _ttl;
    }
}

contract EnsResolver {
    function setName(bytes32 _node, string calldata _name) external {}
}

contract EnsReverseRegistrar {

    string constant public ensReverseRegistrarVersion = "2019102500";

   // namehash('addr.reverse')
    bytes32 constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    EnsRegistry public ens;
    EnsResolver public defaultResolver;

    /**
     * @dev Constructor
     * @param ensAddr The address of the ENS registry.
     * @param resolverAddr The address of the default reverse resolver.
     */
    constructor(address ensAddr, address resolverAddr) public {
        ens = EnsRegistry(ensAddr);
        defaultResolver = EnsResolver(resolverAddr);
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @return The ENS node hash of the reverse record.
     */
    function claim(address owner) public returns (bytes32) {
        return claimWithResolver(owner, address(0));
    }

    /**
     * @dev Transfers ownership of the reverse ENS record associated with the
     *      calling account.
     * @param owner The address to set as the owner of the reverse record in ENS.
     * @param resolver The address of the resolver to set; 0 to leave unchanged.
     * @return The ENS node hash of the reverse record.
     */
    function claimWithResolver(address owner, address resolver) public returns (bytes32) {
        bytes32 label = sha3HexAddress(msg.sender);
        bytes32 node = keccak256(abi.encodePacked(ADDR_REVERSE_NODE, label));
        address currentOwner = ens.owner(node);

        // Update the resolver if required
        if(resolver != address(0) && resolver != address(ens.resolver(node))) {
            // Transfer the name to us first if it's not already
            if(currentOwner != address(this)) {
                ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, address(this));
                currentOwner = address(this);
            }
            ens.setResolver(node, resolver);
        }

        // Update the owner if required
        if(currentOwner != owner) {
            ens.setSubnodeOwner(ADDR_REVERSE_NODE, label, owner);
        }

        return node;
    }

    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account. First updates the resolver to the default reverse
     * resolver if necessary.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string memory name) public returns (bytes32 node) {
        node = claimWithResolver(address(this), address(defaultResolver));
        defaultResolver.setName(node, name);
        return node;
    }

    /**
     * @dev Returns the node hash for a given account's reverse records.
     * @param addr The address to hash
     * @return The ENS node hash.
     */
    function node(address addr) public returns (bytes32 ret) {
        return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
    }

    /**
     * @dev An optimised function to compute the sha3 of the lower-case
     *      hexadecimal representation of an Ethereum address.
     * @param addr The address to hash
     * @return The SHA3 hash of the lower-case hexadecimal encoding of the
     *         input address.
     */
    function sha3HexAddress(address addr) private returns (bytes32 ret) {
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000
            let i := 40

            for { } gt(i, 0) { } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }
            ret := keccak256(0, 40)
        }
    }
}

contract AuthereumEnsResolverStateV1 {

    EnsRegistry ens;
    address public timelockContract;

    mapping (bytes32 => address) public addrs;
    mapping(bytes32 => string) public names;
    mapping(bytes32 => mapping(string => string)) public texts;
    mapping(bytes32 => bytes) public hashes;
}

contract AuthereumEnsResolverState is AuthereumEnsResolverStateV1 {}

contract AuthereumEnsResolver is Managed, AuthereumEnsResolverState {

    string constant public authereumEnsResolverVersion = "2019111500";

    bytes4 constant private INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant private ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant private NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant private TEXT_INTERFACE_ID = 0x59d1d43c;
    bytes4 constant private CONTENT_HASH_INTERFACE_ID = 0xbc1c58d1;

    event AddrChanged(bytes32 indexed node, address a);
    event NameChanged(bytes32 indexed node, string name);
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key, string value);
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /// @dev Constructor
    /// @param _ensAddr The ENS registrar contract
    /// @param _timelockContract Authereum timelock contract address
    constructor(EnsRegistry _ensAddr, address _timelockContract) public {
        ens = _ensAddr;
        timelockContract = _timelockContract;
    }

    /**
     * Setters
     */

    /// @dev Sets the address associated with an ENS node
    /// @notice May only be called by the owner of that node in the ENS registry
    /// @param _node The node to update
    /// @param _addr The address to set
    function setAddr(bytes32 _node, address _addr) public onlyManager {
        addrs[_node]= _addr;
        emit AddrChanged(_node, _addr);
    }

    /// @dev Sets the name associated with an ENS node, for reverse records
    /// @notice May only be called by the owner of that node in the ENS registry
    /// @param _node The node to update
    /// @param _name The name to set
    function setName(bytes32 _node, string memory _name) public onlyManager {
        names[_node] = _name;
        emit NameChanged(_node, _name);
    }

    /// @dev Sets the text data associated with an ENS node and key
    /// @notice May only be called by the owner of that node in the ENS registry
    /// @param node The node to update
    /// @param key The key to set
    /// @param value The text data value to set
    function setText(bytes32 node, string memory key, string memory value) public onlyManager {
        texts[node][key] = value;
        emit TextChanged(node, key, key, value);
    }

    /// @dev Sets the contenthash associated with an ENS node
    /// @notice May only be called by the owner of that node in the ENS registry
    /// @param node The node to update
    /// @param hash The contenthash to set
    function setContenthash(bytes32 node, bytes memory hash) public onlyManager {
        hashes[node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * Getters
     */

    /// @dev Returns the address associated with an ENS node
    /// @param _node The ENS node to query
    /// @return The associated address
    function addr(bytes32 _node) public view returns (address) {
        return addrs[_node];
    }

    /// @dev Returns the name associated with an ENS node, for reverse records
    /// @notice Defined in EIP181
    /// @param _node The ENS node to query
    /// @return The associated name
    function name(bytes32 _node) public view returns (string memory) {
        return names[_node];
    }

    /// @dev Returns the text data associated with an ENS node and key
    /// @param node The ENS node to query
    /// @param key The text data key to query
    ///@return The associated text data
    function text(bytes32 node, string memory key) public view returns (string memory) {
        return texts[node][key];
    }

    /// @dev Returns the contenthash associated with an ENS node
    /// @param node The ENS node to query
    /// @return The associated contenthash
    function contenthash(bytes32 node) public view returns (bytes memory) {
        return hashes[node];
    }

    /// @dev Returns true if the resolver implements the interface specified by the provided hash
    /// @param _interfaceID The ID of the interface to check for
    /// @return True if the contract implements the requested interface
    function supportsInterface(bytes4 _interfaceID) public pure returns (bool) {
        return _interfaceID == INTERFACE_META_ID ||
        _interfaceID == ADDR_INTERFACE_ID ||
        _interfaceID == NAME_INTERFACE_ID ||
        _interfaceID == TEXT_INTERFACE_ID ||
        _interfaceID == CONTENT_HASH_INTERFACE_ID;
    }
}
