import "./IERC20.sol";

interface ISFT is IERC20 {
    
    function totalAccumulatedSupply() external view returns (uint256);
    
    function accumulated(uint256 tokenIndex) external view returns (uint256);
    function totalAccumulated(uint256 tokenIndex) external view returns (uint256);
    function totalClaimed(uint256 tokenIndex) external view returns (uint256);
}
