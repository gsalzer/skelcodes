//Copyright Octobase.co 2019
pragma solidity ^0.5.1;

import "./safemath.sol";
import "./statuscodes.sol";


interface ISignerFactory {
    function produceSigner(address _owner)
        external
        returns (address signer);
}

interface IVaultFactory {
    function produceVault(address _signer)
        external
        returns (address vault);
}



contract SmartWalletFactory
{
    using SafeMath for uint256;

    //Events
    event ProduceSmartWallet(address signer, address vault);

    ISignerFactory public signerFactory;
    IVaultFactory public vaultFactory;

    address[] public signers;
    address[] public vaults;
    mapping(address => bool) public signerMappings;
    mapping(address => bool) public vaultMappings;
    uint public registryCount;

    constructor(
            ISignerFactory _signerFactory,
            IVaultFactory _vaultFactory)
        public
    {
        signerFactory = _signerFactory;
        vaultFactory = _vaultFactory;
    }

    function produceSmartWallet(address _owner)
        external
        payable
        returns (StatusCodes.Status status, address signer, address vault)
    {
        address createdSigner = signerFactory.produceSigner(_owner);
        address createdVault = vaultFactory.produceVault(createdSigner);

        if (msg.value > 0) {
            (bool success,) = address(createdVault).call.value(msg.value)("");
            require(success, "Seeding smart wallet failed");
        }

        emit ProduceSmartWallet(createdSigner, createdVault);

        signers.push(createdSigner);
        vaults.push(createdVault);
        registryCount = registryCount.add(1);
        signerMappings[createdSigner] = true;
        vaultMappings[createdVault] = true;

        return (StatusCodes.Status.Success, createdSigner, createdVault);
    }

    function OctobaseType()
        external
        pure
        returns (uint16 octobaseType)
    {
        return 5;
    }

    function OctobaseTypeVersion()
        external
        pure
        returns (uint32 octobaseTypeVersion)
    {
        return 1;
    }
}
