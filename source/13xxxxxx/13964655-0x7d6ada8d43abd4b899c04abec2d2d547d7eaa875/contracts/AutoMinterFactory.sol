// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "./AutoMinterERC721.sol";
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract AutoMinterFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable
{
    address erc721Implementation;
    uint256 public fee;

    event ContractDeployed(string indexed appIdIndex, string appId, address indexed erc721Implementation, address author);
    
    function initialize() public initializer  {
        __Ownable_init_unchained();
        __UUPSUpgradeable_init();
        erc721Implementation = address(new AutoMinterERC721());
    }
    
    /* Create an NFT Collection and pay the fee */
    function create(string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory appId_,
        uint256 mintFee_,
        uint256 size_,
        bool mintSelectionEnabled_,
        bool mintRandomEnabled_) payable public
    {
        require(msg.value >= fee, 'Must pass the correct fee to the contract');
        
        address clone = ClonesUpgradeable.clone(erc721Implementation);

        AutoMinterERC721(clone).initialize(name_,
            symbol_,
            baseURI_,
            owner(),
            msg.sender,
            mintFee_,
            size_,
            mintSelectionEnabled_,
            mintRandomEnabled_
        );
        
        emit ContractDeployed(appId_, appId_, clone, msg.sender);
    }
    
    /* Change the fee charged for creating contracts */
    function changeFee(uint256 newFee) onlyOwner() public {
        fee = newFee;
    }

    /* add an existing contract the the factory collection so it can be tracked */
    function addExistingCollection(address collectionAddress, address owner, string memory appId) onlyOwner() public{
        emit ContractDeployed(appId, appId, collectionAddress, owner);
    }
    
    function version() external pure returns (string memory)
    {
        return "1.0.2";
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner() {}
}
