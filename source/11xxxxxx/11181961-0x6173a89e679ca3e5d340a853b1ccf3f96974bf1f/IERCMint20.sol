pragma solidity >=0.5.0;
interface IERCMint20 {
    function mint(address to,uint256 amount) external;
	function getStartblock(address user,address swap_addr) external view returns (uint256 lastblocknum);
	function setAddressBlock(address user,address swap_addr,uint256 lastrewardblocknum) external returns (bool success);
	function balanceOf(address owner) external view returns (uint);
}
