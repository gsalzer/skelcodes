pragma solidity >=0.5.0 <=0.5.15;

import "./Ownable.sol";

contract VerifierList is Ownable {
    struct VerifierDetails {
        address owner;
        string typeOfVerifier;
        string verifierParams; // typically a json of parameters required
        bool isCreated;
    }

    event VerifierAdded(string verifier, string typeOfVerifier);

    event VerifierUpdated(string verifier);

    mapping(string => VerifierDetails) public verifiers;

    string[] public verifierList;

    modifier verifierExists(string memory verifier) {
        require(verifiers[verifier].isCreated, "verifier doesnt exist");
        _;
    }

    modifier verifierDoesNotExists(string memory verifier) {
        require(!verifiers[verifier].isCreated, "verifier already exists");
        _;
    }

    modifier verifierOwnerOnly(string memory verifier) {
        require(verifiers[verifier].owner == msg.sender, "not owner of verifier");
        _;
    }

    function addVerifier(
        string calldata _verifier,
        string calldata _typeOfVerifier,
        string calldata _verifierParams,
        address _owner
    ) external onlyOwner verifierDoesNotExists(_verifier) {
        verifiers[_verifier] = VerifierDetails({owner: _owner, typeOfVerifier: _typeOfVerifier, verifierParams: _verifierParams, isCreated: true});
        verifierList.push(_verifier);
        emit VerifierAdded(_verifier, _typeOfVerifier);
    }

    function updateVerifier(string calldata _verifier, string calldata _verifierParams)
        external
        verifierOwnerOnly(_verifier)
        verifierExists(_verifier)
    {
        verifiers[_verifier].verifierParams = _verifierParams;
        emit VerifierUpdated(_verifier);
    }

    function getVerifierListCount() external view returns (uint256 verifierListCount) {
        return verifierList.length;
    }
}

