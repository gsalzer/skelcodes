pragma solidity ^0.7.0;

interface ICommune {

	function numberOfCommunes() external view returns (uint256);
	function isCommuneMember(uint256 commune, address account) external view returns (bool);
	function feeRate() external view returns (uint256);
	function treasuryAddress() external view returns (address);
	function controller() external view returns (address);

	function createCommune(string memory _uri, address asset, bool allowJoining, bool allowRemoving, bool allowOutsideContribution) external returns(uint256 _id);
	function contribute(uint256 amount, uint256 commune) external;
	function joinCommune(uint256 commune) external;
	function addCommuneMember(address account, uint256 commune) external;
	function leaveCommune(uint256 commune) external;
	function removeCommuneMember(address account, uint256 commune) external;
	function balanceOf(address account, uint256 commune) external view returns (uint256);
	function balanceOfBatch(address[] memory accounts, uint256[] memory ids) external view returns (uint256[] memory);
	function withdraw(address account, address to, uint256 commune, uint256 amount) external;
	function withdrawBatch(address account, address to, uint256[] memory communes, uint256[] memory amounts) external;

	function updateCommuneController(address account, uint256 commune) external;
	function updateCommuneURI(string memory _uri, uint256 commune) external;
	function updateController(address account) external;
	function updateFee(uint256 rate) external;
	function setTreasuryAddress(address newTreasury) external;



	event AddCommuneMember(address indexed account, uint256 indexed commune);
    event RemoveCommuneMember(address indexed account, uint256 indexed commune);
    event Withdraw(address indexed operator, address indexed account, address to, uint256 indexed commune, uint256 amount);
    event WithdrawBatch(address indexed operator, address indexed account, address indexed to, uint256[] communes, uint256[] amounts);
    event URI(string value, uint256 indexed commune);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event Contribute(address indexed account, uint256 indexed commune, uint256 amount);
    event UpdateCommuneController(address indexed account, uint256 indexed commune);
    event UpdateController(address indexed account);
    event UpdateFee(uint256 basisPoints);
    event UpdateTreasuryAddress(address indexed account);
}
