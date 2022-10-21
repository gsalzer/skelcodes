pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface iDD2 is IERC721Enumerable {
    function _duckHouseStakingCallback(uint256 id, bool staked) external;
    function _duckHouseStakingCallback() external;
    function checkLockedAddress(address) external returns(bool);
}
