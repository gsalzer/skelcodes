// SPDX-License-Identifier: MIT
// JoeRichardsNFT v1.1
pragma solidity ^0.8.2;

import "./Ownable.sol";

/// @title A preset for our branded releases
/// @author BAD JOE RICHARDS
/// @notice Used for branded releases and drops
/// @dev Inherited by the main NFT
contract JoeRichardsNFT is Ownable {
    
    bool public saleIsActive = false;
    bool public firstMintZero = true;
    bool internal constant twinMinting = true;
    
    uint256 public startingIndexBlock;

    uint256 public constant tokenPrice = 0.0303 ether;
    uint16 public constant MAX_TOKENS_COUNT = 10001; // 16 bit 0 to 65,535
    uint8 public constant maxAgent1Purchase = 20; // 8bit 0-255
    uint8 public proxyRegistrySetting = 2;
    address internal customProxyRegistry;
    
    // @dev when the time comes, everything will freeze to IPFS
    string public baseNFTURI = "https://agent1.xyz/";
    
    mapping (uint256 => string) internal _BJRtokenURIs;
    
    mapping (address => uint) internal zeroAgent1Count;    
    
    
    // @dev Emit to freeze metadata
    event PermanentURI(string _value, uint256 indexed _id);
    
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    } 
    
    function flipFirstMintZero() external onlyOwner {
        firstMintZero = !firstMintZero;
    } 
    
    function setProxySettingAll(uint8 newProxySetting, address newProxyAddress) external onlyOwner {
        proxyRegistrySetting = newProxySetting;
        customProxyRegistry = newProxyAddress;
    }
    
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseNFTURI = _uri;
    }


}
