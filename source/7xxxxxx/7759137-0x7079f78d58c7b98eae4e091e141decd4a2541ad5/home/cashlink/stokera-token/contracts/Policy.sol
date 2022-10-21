pragma solidity ^0.5.3;

import './SignatureManager.sol';

// For policy contracts, it is important that there is some check on msg.sender
// so as to avoid race windows where an attacker can replay a signature
// against the contract directly, thereby potentially producing a denial of service
interface IPolicy {
    // The caller MUST ensure that the value "action" is also part of the input
    // for the given hash value, or there will be no binding between the action
    // and the action parameters.
    function tryAuthorize(string calldata action,
                       bytes32 hash,
                       address sender,
                       bytes calldata sig)
        external
        returns (bool);

    // Asserting version of tryAuthorize
    function authorize(string calldata action,
                       bytes32 hash,
                       address sender,
                       bytes calldata sig)
        external;
}

// Sender- OR signature-based validation
contract SingleAuthorityPolicy is SignatureManager, IPolicy {
    mapping(address => bool) subjectSet;
    address public authority;
    address public newAuthority;

    function initSingleAuthorityPolicy(address _authority) internal {
        authority = _authority;
        newAuthority = address(0);
    }

    modifier onlyAuthority() {
        require(msg.sender == authority, "Called by non-authority");
        _;
    }

    function setAuthority(address _newAuthority)
        onlyAuthority
        external
    {
        newAuthority = _newAuthority;
    }

    function acceptAuthority() external {
        require(newAuthority == msg.sender);
        authority = newAuthority;
        newAuthority = address(0);
    }

    modifier validatesSignature() {
        // This check is important to avoid race conditions where an attacker
        // uses up a signature and causes a DoS by sending it to the policy contract
        // directly.
        require(subjectSet[msg.sender]);
        _;
    }

    function isSubject(address subject) public view returns (bool) {
        return subjectSet[subject];
    }

    function addSubject(address subject) public onlyAuthority {
        require(msg.sender == authority);
        subjectSet[subject] = true;
    }

    function removeSubject(address subject) public onlyAuthority {
        require(msg.sender == authority);
        subjectSet[subject] = false;
    }

    function tryAuthorize(string memory /*action*/,
                       bytes32 hash,
                       address _sender,
                       bytes memory sig)
        public
        validatesSignature
        returns (bool)
    {
        if (_sender == authority) {
            // Fast path
            return true;
        }
        return tryCheckAndUseSignatureImpl(hash, sig, authority);
    }

    function authorize(string calldata action,
                       bytes32 hash,
                       address sender,
                       bytes calldata sig)
        external
        validatesSignature
    {
        bool success = tryAuthorize(action, hash, sender, sig);
        require(success, "Unauthorized: Invalid signature");
    }

    function addSubjectWithSignature(address subject, bytes calldata sig) external {
        bytes32 hash = keccak256(abi.encode(
            "AddSubject",
            address(this),
            subject));
        checkAndUseSignatureImpl(hash, sig, authority);
        subjectSet[subject] = true;
    }

    function removeSubjectWithSignature(address subject, bytes calldata sig) external {
        bytes32 hash = keccak256(abi.encode(
            "RemoveSubject",
            address(this),
            subject));
        checkAndUseSignatureImpl(hash, sig, authority);
        subjectSet[subject] = false;
    }

    function revokeNonce(uint256 nonce) external onlyAuthority {
        revokeNonceImpl(nonce);
    }

    function revokeNonceWithSignature(uint256 nonce, bytes calldata sig) external {
        revokeNonceWithSignatureImpl(nonce, sig, authority);
    }

    function isNonceValid(uint256 nonce) external view returns (bool) {
        return isNonceValidImpl(nonce);
    }

    function isNonceUsed(uint256 nonce) external view returns (bool) {
        return isNonceUsedImpl(nonce);
    }

    function isNonceRevoked(uint256 nonce) external view returns (bool) {
        return isNonceRevokedImpl(nonce);
    }

    function () external payable { revert(); }
}

