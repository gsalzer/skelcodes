import "./IERC721Enumerable.sol";

interface IMSOW is IERC721Enumerable {
    
    function mintedTimestampByIndex(uint256 index) external view returns (uint256);
}
