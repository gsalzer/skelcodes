pragma solidity >=0.4.21 <0.6.0;

import "./AlumniStore.sol";
import "./OpenCertsStore.sol";
import "./TokenContract.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

contract ScholarshipContract_V2 {
    using SafeMath for uint256;
    OpenCertsStore openCertsStore;
    AlumniStore alumniStore;
    TokenContract tokenContract;

    address payable owner;
    uint256 bitDegreeFee = 3; //percent

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
        uint256 toBitDegree = tokenContract.balanceOf(address(this)).mul(bitDegreeFee).div(100);
        uint256 toStudent = tokenContract.balanceOf(address(this)).sub(toBitDegree);
        address payable studentAddress = isCertificateIssued(_blockchainCertificateHash);
        if (studentAddress != address(0x0)) {
            tokenContract.transfer(studentAddress, toStudent);
            tokenContract.transfer(owner, toBitDegree);
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
