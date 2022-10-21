pragma solidity ^0.5.0;

interface IERC1155Mintable {
    function mintNonFungibleSingle(uint256 _type, address _to) external;
    function mintNonFungible(uint256 _type, address[] calldata _to) external;
    function mintFungibleSingle(uint256 _id, address _to, uint256 _quantity) external;
    function mintFungible(uint256 _id, address[] calldata _to, uint256[] calldata _quantities) external;
}

