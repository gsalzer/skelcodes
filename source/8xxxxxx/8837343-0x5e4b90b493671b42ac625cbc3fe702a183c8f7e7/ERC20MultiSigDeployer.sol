pragma solidity ^0.5.0;

import "./ERC20MultiSigWallet.sol";

contract ERC20MultiSigDeployer {

    //Mapping on the form user => multisigAddresses
    mapping (address => address[]) public contractsByUser;

    address[] public contracts;

    function deploy(address[] memory _owners, uint256 _required) public {
        ERC20MultiSigWallet multisigWallet = new ERC20MultiSigWallet(_owners, _required);
        contracts.push(address(multisigWallet));
        for (uint256 i = 0; i < _owners.length; i++) {
            contractsByUser[_owners[i]].push(address(multisigWallet));
        }
    }

    function getContracts(address _user) public view returns(address[] memory) {
        return contractsByUser[_user];
    }

    function getAllContracts() public view returns(address[] memory) {
        return contracts;
    }
}

