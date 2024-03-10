//Copyright Octobase.co 2019
pragma solidity ^0.5.1;

import "./signer.sol";

contract SignerFactory
{
    address public factoryOwner;
    address public implementation;
    address[] public signers;
    function signersCount() external view returns (uint256 count) {
        return signers.length;
    }
    mapping(address=>bool) public signerMappings;
    mapping(address=>bool) public successors;

    event ProduceSigner(address signer);

    constructor(address _factoryOwner, address _implementation)
        public
    {
        factoryOwner = _factoryOwner;
        implementation = _implementation;
    }

    modifier onlyOwner() {
        require (msg.sender == factoryOwner, "Only the owner may call this method");
        _;
    }

    function changeOwner(address _newFactoryOwner)
        external
        onlyOwner
    {
        factoryOwner = _newFactoryOwner;
    }

    function produceSigner(address _owner)
        external
        returns (address signer)
    {
        SignerProxy proxy = new SignerProxy(implementation);
        address payable signerAddress = address(proxy);
        Signer wrapper = Signer(signerAddress);
        wrapper.claim(_owner);
        signers.push(signerAddress);
        signerMappings[signerAddress] = true;
        emit ProduceSigner(signerAddress);
        return signerAddress;
    }

    function setSuccessor(address _successor, bool _isSuccessor)
        external
        onlyOwner
        returns (StatusCodes.Status _status)
    {
        successors[_successor] = _isSuccessor;
        return StatusCodes.Status.Success;
    }

    function OctobaseType()
        external
        pure
        returns (uint16 octobaseType)
    {
        return 3;
    }

    function OctobaseTypeVersion()
        external
        pure
        returns (uint32 octobaseTypeVersion)
    {
        return 1;
    }
}
