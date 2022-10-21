pragma solidity 0.5.2;

// from : https://github.com/christianlundkvist/simple-multisig/blob/f63ef72e448ecef85dd61ad5a3727c7dba4e4377/contracts/SimpleMultiSig.sol
// + specify 0.5.2
// + fixed indentation + add storage location
contract SimpleMultiSig {

    // kekkac256("MultiSigTransaction(address destination,uint256 value,bytes data,uint256 nonce,address executor,uint256 gasLimit)")
    bytes32 constant TXTYPE_HASH = 0x3ee892349ae4bbe61dce18f95115b5dc02daf49204cc602458cd4c1f540d56d7;

    bytes32 constant SALT = 0x251543af6a222378665a76fe38dbceae4871a070b7fdaf5c6c30cf758dc33cc0;

    uint public nonce;                 // (only) mutable state
    uint public threshold;             // immutable state
    mapping (address => bool) isOwner; // immutable state
    address[] public ownersArr;        // immutable state

     
    // Note that owners_ must be strictly increasing, in order to prevent duplicates
    constructor(uint threshold_, address[] memory owners_) public {
        require(owners_.length <= 10 && threshold_ <= owners_.length && threshold_ > 0);

        address lastAdd = address(0);
        for (uint i = 0; i < owners_.length; i++) {
            require(owners_[i] > lastAdd);
            isOwner[owners_[i]] = true;
            lastAdd = owners_[i];
        }
        ownersArr = owners_;
        threshold = threshold_;
    }


    // Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    function execute(uint8[] memory sigV, bytes32[] memory sigR, bytes32[] memory sigS, address destination, uint value, bytes memory data, address executor, uint gasLimit) public {
        require(sigR.length == threshold);
        require(sigR.length == sigS.length && sigR.length == sigV.length);
        require(executor == msg.sender || executor == address(0));

        bytes32 txInputHash = keccak256(abi.encodePacked(
            address(this),
            TXTYPE_HASH,
            SALT,
            destination,
            value,
            keccak256(data),
            nonce,
            executor,
            gasLimit
        ));
        bytes32 totalHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", txInputHash));

        address lastAdd = address(0); // cannot have address(0) as an owner
        for (uint i = 0; i < threshold; i++) {
            address recovered = ecrecover(totalHash, sigV[i], sigR[i], sigS[i]);
            require(recovered > lastAdd && isOwner[recovered]);
            lastAdd = recovered;
        }

        // If we make it here all signatures are accounted for.
        // The address.call() syntax is no longer recommended, see:
        // https://github.com/ethereum/solidity/issues/2884
        nonce = nonce + 1;
        bool success = false;
        assembly { success := call(gasLimit, destination, value, add(data, 0x20), mload(data), 0, 0) }
        require(success);
    }

    function () payable external {}
}
