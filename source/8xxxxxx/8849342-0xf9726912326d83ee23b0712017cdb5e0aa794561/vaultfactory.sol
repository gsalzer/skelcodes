//Copyright Octobase.co 2019
pragma solidity ^0.5.1;

import "./vault.sol";

contract VaultFactory {
    address public factoryOwner;
    address public implementation;
    address[] public vaults;
    function vaultsCount() external view returns (uint256 count) {
        return vaults.length;
    }
    mapping(address=>bool) public vaultMappings;
    mapping(address=>bool) public successors;

    event ProduceVault(address vault);

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

    function produceVault(address payable _signer)
        external
        returns (address vault)
    {
        VaultProxy proxy = new VaultProxy(implementation, _signer);
        address proxyAddress = address(proxy);
        vaults.push(proxyAddress);
        vaultMappings[proxyAddress] = true;
        emit ProduceVault(proxyAddress);
        return (proxyAddress);
    }

    function setSuccessor(address _successor, bool _isSuccessor)
        external
        onlyOwner
        returns (StatusCodes.Status status)
    {
        successors[_successor] = _isSuccessor;
        return StatusCodes.Status.Success;
    }

    function OctobaseType()
        external
        pure
        returns (uint16 octobaseType)
    {
        return 4;
    }

    function OctobaseTypeVersion()
        external
        pure
        returns (uint32 octobaseTypeVersion)
    {
        return 1;
    }
}
