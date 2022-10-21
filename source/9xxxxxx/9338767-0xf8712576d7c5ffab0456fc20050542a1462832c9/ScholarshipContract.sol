pragma solidity >=0.4.21 <0.6.0;

import "./AlumniStore.sol";
import "./OpenCertsStore.sol";
import "./TokenContract.sol";

contract ScholarshipContract {
    OpenCertsStore openCertsStore;
    AlumniStore alumniStore;
    TokenContract tokenContract;

    address payable owner;

    constructor(address _openCertsStoreAddress, address _alumniStoreAddress, address _tokenContractAddress) public {
        owner = msg.sender;
        openCertsStore = OpenCertsStore(_openCertsStoreAddress);
        alumniStore = AlumniStore(_alumniStoreAddress);
        tokenContract = TokenContract(_tokenContractAddress);
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function() external payable {}

    function changeOwner(address payable _newOwnerAddress) public onlyOwner returns (bool) {
        owner = _newOwnerAddress;
        return true;
    }

    function isCertificateIssued(bytes32 _blockchainCertificateHash) private view returns (address payable _address) {
        if (openCertsStore.isIssued(_blockchainCertificateHash)) {
            return alumniStore.getAlumniAddress(_blockchainCertificateHash);
        } else {
            return 0x0000000000000000000000000000000000000000;
        }
    }

    function unlockScholarship(bytes32 _blockchainCertificateHash) public returns (bool){
        address payable studentAddress = isCertificateIssued(_blockchainCertificateHash);
        if (studentAddress != address(0x0)) {
            tokenContract.transfer(studentAddress,tokenContract.balanceOf(address(this)));
            return true;
        } else {
            return false;
        }
    }

    function refund() public onlyOwner returns (bool) {
        tokenContract.transfer(owner,tokenContract.balanceOf(address(this)));
        return true;
    }

    function selfDestruct() public onlyOwner {
        selfdestruct(owner);
    }
}
