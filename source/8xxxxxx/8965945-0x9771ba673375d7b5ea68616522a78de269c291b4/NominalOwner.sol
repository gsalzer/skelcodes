pragma solidity >=0.4.22 <0.7.0;

contract OwnedInterface {
    address public newOwner;
    function acceptOwnership() public;
}

contract NominalOwner{
    function acceptOwnership(address _ownedContractAddress) public {
        OwnedInterface ownedContract = OwnedInterface(_ownedContractAddress);
        if(address(this) == ownedContract.newOwner())
        {
            ownedContract.acceptOwnership();
        }
    }
}
