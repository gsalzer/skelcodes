// File: @onchain-id/solidity/contracts/IERC734.sol

pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC734 (Key Holder) standard as defined in the EIP.
 */
interface IERC734 {
    /**
     * @dev Definition of the structure of a Key.
     *
     * Specification: Keys are cryptographic public keys, or contract addresses associated with this identity.
     * The structure should be as follows:
     *   - key: A public key owned by this identity
     *      - purposes: uint256[] Array of the key purposes, like 1 = MANAGEMENT, 2 = EXECUTION
     *      - keyType: The type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
     *      - key: bytes32 The public key. // Its the Keccak256 hash of the key
     */
    struct Key {
        uint256[] purposes;
        uint256 keyType;
        bytes32 key;
    }

    /**
     * @dev Emitted when an execution request was approved.
     *
     * Specification: MUST be triggered when approve was successfully called.
     */
    event Approved(uint256 indexed executionId, bool approved);

    /**
     * @dev Emitted when an execute operation was approved and successfully performed.
     *
     * Specification: MUST be triggered when approve was called and the execution was successfully approved.
     */
    event Executed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when an execution request was performed via `execute`.
     *
     * Specification: MUST be triggered when execute was successfully called.
     */
    event ExecutionRequested(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    /**
     * @dev Emitted when a key was added to the Identity.
     *
     * Specification: MUST be triggered when addKey was successfully called.
     */
    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when a key was removed from the Identity.
     *
     * Specification: MUST be triggered when removeKey was successfully called.
     */
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);

    /**
     * @dev Emitted when the list of required keys to perform an action was updated.
     *
     * Specification: MUST be triggered when changeKeysRequired was successfully called.
     */
    event KeysRequiredChanged(uint256 purpose, uint256 number);


    /**
     * @dev Adds a _key to the identity. The _purpose specifies the purpose of the key.
     *
     * Triggers Event: `KeyAdded`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) external returns (bool success);

    /**
    * @dev Approves an execution or claim addition.
    *
    * Triggers Event: `Approved`, `Executed`
    *
    * Specification:
    * This SHOULD require n of m approvals of keys purpose 1, if the _to of the execution is the identity contract itself, to successfully approve an execution.
    * And COULD require n of m approvals of keys purpose 2, if the _to of the execution is another contract, to successfully approve an execution.
    */
    function approve(uint256 _id, bool _approve) external returns (bool success);

    /**
     * @dev Passes an execution instruction to an ERC725 identity.
     *
     * Triggers Event: `ExecutionRequested`, `Executed`
     *
     * Specification:
     * SHOULD require approve to be called with one or more keys of purpose 1 or 2 to approve this execution.
     * Execute COULD be used as the only accessor for `addKey` and `removeKey`.
     */
    function execute(address _to, uint256 _value, bytes calldata _data) external payable returns (uint256 executionId);

    /**
     * @dev Returns the full key data, if present in the identity.
     */
    function getKey(bytes32 _key) external view returns (uint256[] memory purposes, uint256 keyType, bytes32 key);

    /**
     * @dev Returns the list of purposes associated with a key.
     */
    function getKeyPurposes(bytes32 _key) external view returns(uint256[] memory _purposes);

    /**
     * @dev Returns an array of public key bytes32 held by this identity.
     */
    function getKeysByPurpose(uint256 _purpose) external view returns (bytes32[] memory keys);

    /**
     * @dev Returns TRUE if a key is present and has the given purpose. If the key is not present it returns FALSE.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) external view returns (bool exists);

    /**
     * @dev Removes _purpose for _key from the identity.
     *
     * Triggers Event: `KeyRemoved`
     *
     * Specification: MUST only be done by keys of purpose 1, or the identity itself. If it's the identity itself, the approval process will determine its approval.
     */
    function removeKey(bytes32 _key, uint256 _purpose) external returns (bool success);
}

// File: @onchain-id/solidity/contracts/IERC735.sol

pragma solidity ^0.6.2;

/**
 * @dev Interface of the ERC735 (Claim Holder) standard as defined in the EIP.
 */
interface IERC735 {

    /**
     * @dev Emitted when a claim request was performed.
     *
     * Specification: Is not clear
     */
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was added.
     *
     * Specification: MUST be triggered when a claim was successfully added.
     */
    event ClaimAdded(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was removed.
     *
     * Specification: MUST be triggered when removeClaim was successfully called.
     */
    event ClaimRemoved(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Emitted when a claim was changed.
     *
     * Specification: MUST be triggered when changeClaim was successfully called.
     */
    event ClaimChanged(bytes32 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);

    /**
     * @dev Definition of the structure of a Claim.
     *
     * Specification: Claims are information an issuer has about the identity holder.
     * The structure should be as follows:
     *   - claim: A claim published for the Identity.
     *      - topic: A uint256 number which represents the topic of the claim. (e.g. 1 biometric, 2 residence (ToBeDefined: number schemes, sub topics based on number ranges??))
     *      - scheme : The scheme with which this claim SHOULD be verified or how it should be processed. Its a uint256 for different schemes. E.g. could 3 mean contract verification, where the data will be call data, and the issuer a contract address to call (ToBeDefined). Those can also mean different key types e.g. 1 = ECDSA, 2 = RSA, etc. (ToBeDefined)
     *      - issuer: The issuers identity contract address, or the address used to sign the above signature. If an identity contract, it should hold the key with which the above message was signed, if the key is not present anymore, the claim SHOULD be treated as invalid. The issuer can also be a contract address itself, at which the claim can be verified using the call data.
     *      - signature: Signature which is the proof that the claim issuer issued a claim of topic for this identity. it MUST be a signed message of the following structure: `keccak256(abi.encode(identityHolder_address, topic, data))`
     *      - data: The hash of the claim data, sitting in another location, a bit-mask, call data, or actual data based on the claim scheme.
     *      - uri: The location of the claim, this can be HTTP links, swarm hashes, IPFS hashes, and such.
     */
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer;
        bytes signature;
        bytes data;
        string uri;
    }

    /**
     * @dev Get a claim by its ID.
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function getClaim(bytes32 _claimId) external view returns(uint256 topic, uint256 scheme, address issuer, bytes memory signature, bytes memory data, string memory uri);

    /**
     * @dev Returns an array of claim IDs by topic.
     */
    function getClaimIdsByTopic(uint256 _topic) external view returns(bytes32[] memory claimIds);

    /**
     * @dev Add or update a claim.
     *
     * Triggers Event: `ClaimRequested`, `ClaimAdded`, `ClaimChanged`
     *
     * Specification: Requests the ADDITION or the CHANGE of a claim from an issuer.
     * Claims can requested to be added by anybody, including the claim holder itself (self issued).
     *
     * _signature is a signed message of the following structure: `keccak256(abi.encode(address identityHolder_address, uint256 topic, bytes data))`.
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address + uint256 topic))`.
     *
     * This COULD implement an approval process for pending claims, or add them right away.
     * MUST return a claimRequestId (use claim ID) that COULD be sent to the approve function.
     */
    function addClaim(uint256 _topic, uint256 _scheme, address issuer, bytes calldata _signature, bytes calldata _data, string calldata _uri) external returns (bytes32 claimRequestId);

    /**
     * @dev Removes a claim.
     *
     * Triggers Event: `ClaimRemoved`
     *
     * Claim IDs are generated using `keccak256(abi.encode(address issuer_address, uint256 topic))`.
     */
    function removeClaim(bytes32 _claimId) external returns (bool success);
}

// File: @onchain-id/solidity/contracts/IIdentity.sol

pragma solidity ^0.6.2;



interface IIdentity is IERC734, IERC735 {}

// File: @onchain-id/solidity/contracts/IClaimIssuer.sol

pragma solidity ^0.6.2;


interface IClaimIssuer is IIdentity {
    function revokeClaim(bytes32 _claimId, address _identity) external returns(bool);
    function getRecoveredAddress(bytes calldata sig, bytes32 dataHash) external pure returns (address);
    function isClaimRevoked(bytes calldata _sig) external view returns (bool);
    function isClaimValid(IIdentity _identity, uint256 claimTopic, bytes calldata sig, bytes calldata data) external view returns (bool);
}

// File: contracts/registry/ITrustedIssuersRegistry.sol

pragma solidity ^0.6.0;


interface ITrustedIssuersRegistry {
    // EVENTS
    event TrustedIssuerAdded(uint indexed index, IClaimIssuer indexed trustedIssuer, uint[] claimTopics);
    event TrustedIssuerRemoved(uint indexed index, IClaimIssuer indexed trustedIssuer);
    event TrustedIssuerUpdated(uint indexed index, IClaimIssuer indexed oldTrustedIssuer, IClaimIssuer indexed newTrustedIssuer, uint[] claimTopics);

    // READ OPERATIONS
    function getTrustedIssuer(uint index) external view returns (IClaimIssuer);
    function getTrustedIssuerClaimTopics(uint index) external view returns(uint[] memory);
    function getTrustedIssuers() external view returns (uint[] memory);
    function hasClaimTopic(address issuer, uint claimTopic) external view returns(bool);
    function isTrustedIssuer(address issuer) external view returns(bool);

    // WRITE OPERATIONS
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint index, uint[] calldata claimTopics) external;
    function removeTrustedIssuer(uint index) external;
    function updateIssuerContract(uint index, IClaimIssuer _newTrustedIssuer, uint[] calldata claimTopics) external;
}

// File: openzeppelin-solidity/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.6.0;

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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/registry/TrustedIssuersRegistry.sol

pragma solidity ^0.6.0;




contract TrustedIssuersRegistry is ITrustedIssuersRegistry, Ownable {
    // Mapping between a trusted issuer index and its corresponding identity contract address.
    mapping(uint => IClaimIssuer) public trustedIssuers;
    mapping(uint => mapping(uint => uint)) public trustedIssuerClaimTopics;
    mapping(uint => uint) public trustedIssuerClaimCount;
    mapping(address => bool) public trustedIssuer;
    // Array stores the trusted issuer indexes
    uint[] public indexes;

    /**
     * @notice Adds the identity contract of a trusted claim issuer corresponding
     * to the index provided.
     * Requires the index to be greater than zero.
     * Requires that an identity contract doesnt already exist corresponding to the index.
     * Only owner can
     *
     * @param _trustedIssuer The identity contract address of the trusted claim issuer.
     * @param index The desired index of the claim issuer
     * @param claimTopics list of authorized claim topics for each trusted claim issuer
     */
    function addTrustedIssuer(IClaimIssuer _trustedIssuer, uint index, uint[] memory claimTopics) public override onlyOwner {
        require(index > 0);
        uint claimTopicsLength = claimTopics.length;
        require(claimTopicsLength > 0);
        require(address(trustedIssuers[index]) == address(0), "A trustedIssuer already exists by this name");
        require(address(_trustedIssuer) != address(0));
        uint length = indexes.length;
        for (uint i = 0; i < length; i++) {
            require(_trustedIssuer != trustedIssuers[indexes[i]], "Issuer address already exists in another index");
        }
        trustedIssuers[index] = _trustedIssuer;
        indexes.push(index);
        uint i;
        for (i = 0; i < claimTopicsLength; i++) {
            trustedIssuerClaimTopics[index][i] = claimTopics[i];
        }
        trustedIssuerClaimCount[index] = i;
        trustedIssuer[address(trustedIssuers[index])] = true;

        emit TrustedIssuerAdded(index, _trustedIssuer, claimTopics);
    }



    /**
     * @notice Removes the identity contract of a trusted claim issuer corresponding
     * to the index provided.
     * Requires the index to be greater than zero.
     * Requires that an identity contract exists corresponding to the index.
     * Only owner can call.
     *
     * @param index The desired index of the claim issuer to be removed.
     */
    function removeTrustedIssuer(uint index) public override onlyOwner {
        require(index > 0);
        require(address(trustedIssuers[index]) != address(0), "No such issuer exists");
        delete trustedIssuer[address(trustedIssuers[index])];
        delete trustedIssuers[index];

        uint length = indexes.length;
        for (uint i = 0; i < length; i++) {
            if (indexes[i] == index) {
                delete indexes[i];
                indexes[i] = indexes[length - 1];
                delete indexes[length - 1];
                indexes.pop();
                break;
            }
        }
        uint claimTopicCount = trustedIssuerClaimCount[index];
        for (uint i = 0; i < claimTopicCount; i++) {
            if (trustedIssuerClaimTopics[index][i] != 0) {
                delete trustedIssuerClaimTopics[index][i];
            }
        }
        delete trustedIssuerClaimCount[index];

        emit TrustedIssuerRemoved(index, trustedIssuers[index]);
    }

    /**
     * @notice Function for getting all the trusted claim issuer indexes stored.
     *
     * @return array of indexes of all the trusted claim issuer indexes stored.
     */
    function getTrustedIssuers() public override view returns (uint[] memory) {
        return indexes;
    }

    function isTrustedIssuer(address issuer) public override view returns (bool) {
        return trustedIssuer[issuer];
    }
    /**
     * @notice Function for getting the trusted claim issuer's
     * identity contract address corresponding to the index provided.
     * Requires the provided index to have an identity contract stored.
     * Only owner can call.
     *
     * @param index The index corresponding to which identity contract address is required.
     *
     * @return Address of the identity contract address of the trusted claim issuer.
     */
    function getTrustedIssuer(uint index) public override view returns (IClaimIssuer) {
        require(index > 0);
        require(address(trustedIssuers[index]) != address(0), "No such issuer exists");

        return trustedIssuers[index];
    }

    /**
    * @notice Function for getting all the claim topic of trusted claim issuer
    * Requires the provided index to have an identity contract stored and claim topic.
    * Only owner can call.
    *
    * @param index The index corresponding to which identity contract address is required.
    *
    * @return The claim topics corresponding to the trusted issuers.
    */
    function getTrustedIssuerClaimTopics(uint index) public override view returns (uint[] memory) {
        require(index > 0);
        require(address(trustedIssuers[index]) != address(0), "No such issuer exists");
        uint length = trustedIssuerClaimCount[index];
        uint[] memory claimTopics = new uint[](length);
        for (uint i = 0; i < length; i++) {
            claimTopics[i] = trustedIssuerClaimTopics[index][i];
        }

        return claimTopics;
    }

    /**
    * @notice Function for checking the trusted claim issuer's
    * has corresponding claim topic
    *
    * @return true if the issuer is trusted for this claim topic.
    */
    function hasClaimTopic(address issuer, uint claimTopic) public override view returns (bool) {
        require(claimTopic > 0);

        for (uint i = 0; i < indexes.length; i++) {
            if (address(trustedIssuers[indexes[i]]) == issuer) {
                uint claimTopicCount = trustedIssuerClaimCount[indexes[i]];
                for (uint j = 0; j < claimTopicCount; j++) {
                    if (trustedIssuerClaimTopics[indexes[i]][j] == claimTopic) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * @notice Updates the identity contract of a trusted claim issuer corresponding
     * to the index provided.
     * Requires the index to be greater than zero.
     * Requires that an identity contract already exists corresponding to the provided index.
     * Only owner can call.
     *
     * @param index The desired index of the claim issuer to be updated.
     * @param _newTrustedIssuer The new identity contract address of the trusted claim issuer.
     * @param claimTopics list of authorized claim topics for each trusted claim issuer
     */
    function updateIssuerContract(uint index, IClaimIssuer _newTrustedIssuer, uint[] memory claimTopics) public override onlyOwner {
        require(index > 0);
        require(address(trustedIssuers[index]) != address(0), "No such issuer exists");
        uint length = indexes.length;
        uint claimTopicsLength = claimTopics.length;
        require(claimTopicsLength > 0);
        for (uint i = 0; i < length; i++) {
            require(trustedIssuers[indexes[i]] != _newTrustedIssuer, "Address already exists");
        }
        uint i;
        for (i = 0; i < claimTopicsLength; i++) {
            trustedIssuerClaimTopics[index][i] = claimTopics[i];
        }
        trustedIssuerClaimCount[index] = i;
        trustedIssuers[index] = _newTrustedIssuer;

        emit TrustedIssuerUpdated(index, trustedIssuers[index], _newTrustedIssuer, claimTopics);
    }
}
