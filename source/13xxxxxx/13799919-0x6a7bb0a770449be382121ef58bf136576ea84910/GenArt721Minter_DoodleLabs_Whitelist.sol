pragma solidity ^0.5.0;

import './IGenArt721CoreV2.sol';
import './SafeMath.sol';

contract GenArt721Minter_DoodleLabs_Whitelist {
    using SafeMath for uint256;

    event AddWhitelist();
    event AddMinterWhitelist(address minterAddress);
    event RemoveMinterWhitelist(address minterAddress);

    IGenArt721CoreV2 genArtCoreContract;
    mapping(address => bool) public minterWhitelist;
    mapping(uint256 => mapping(address => uint256)) public whitelist;

    modifier onlyWhitelisted() {
        require(genArtCoreContract.isWhitelisted(msg.sender), "can only be set by admin");
        _;
    }

    modifier onlyMintWhitelisted() {
        require(minterWhitelist[msg.sender], "only callable by minter");
        _;
    }

    constructor(address _genArtCore, address _minterAddress) public {
        genArtCoreContract = IGenArt721CoreV2(_genArtCore);
        minterWhitelist[_minterAddress] = true;
    }

    function addMinterWhitelist(address _minterAddress) public onlyWhitelisted {
        minterWhitelist[_minterAddress] = true;
        emit AddMinterWhitelist(_minterAddress);
    }

    function removeMinterWhitelist(address _minterAddress) public onlyWhitelisted {
        minterWhitelist[_minterAddress] = false;
        emit RemoveMinterWhitelist(_minterAddress);
    }

    function getWhitelisted(uint256 projectId, address user) external view returns (uint256 amount) {
        return whitelist[projectId][user];
    }

    function addWhitelist(uint256 projectId, address[] memory users, uint256[] memory amounts) public onlyWhitelisted {
        require(users.length == amounts.length, 'users amounts array mismatch');

        for (uint i = 0; i < users.length; i++) {
            whitelist[projectId][users[i]] = amounts[i];
        }
        emit AddWhitelist();
    }

    function decreaseAmount(uint256 projectId, address to) public onlyMintWhitelisted {
        require(whitelist[projectId][to] > 0, "user has nothing to redeem");
        whitelist[projectId][to] = whitelist[projectId][to].sub(1);
    }

}
