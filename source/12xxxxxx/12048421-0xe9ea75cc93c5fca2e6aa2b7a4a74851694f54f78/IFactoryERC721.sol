pragma solidity ^0.5.0;

interface IFactoryERC721 {
  
  function mintTo(address _to) external;

  // function mint(uint256 _num, string calldata _defaultTokenURI) external;

  function setConfig(string calldata _baseTokenURI,uint256 _stepNum,bool _canMint) external;

  function getTokenURI(uint256 _tokenId) external view returns (string memory);

  function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;

}
