import "./IERC721Enumerable.sol";

interface IFaces is IERC721Enumerable {
    
    function mintedTimestampByIndex(uint256 index) external view returns (uint256);
    function segmentsUnlockedByIndex(uint256 index) external view returns (uint256);
    function tokenNameByIndex(uint256 index) external view returns (string memory);
    function isNameReserved(string memory nameString) external view returns (bool);
}
