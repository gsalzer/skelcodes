// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "../interface/IPermanentStorageV1.sol";
import "../utils/lib_storage/PSStorageV1.sol";

contract PermanentStorageV1 is IPermanentStorageV1 {

    // Constants do not have storage slot.
    bytes32 public constant curveTokenIndexStorageId = 0xf4c750cdce673f6c35898d215e519b86e3846b1f0532fb48b84fe9d80f6de2fc; // keccak256("curveTokenIndex")
    bytes32 public constant nonceStorageId = 0x8a15a97f6259594aa8bc88e85b717672e3bd1edd2a77d009527d64035f1878ed;  // keccak256("nonces")
    bytes32 public constant transactionsStorageId = 0x06b06d69b368c15164608b3fad50feade19592196c279c0bced1c810c096a717;  // keccak256("transactions")
    bytes32 public constant isValidMarketMakerStorageId = 0xd229d32753f9c4fdb887a71e0562ec1c0a209dda65e83ea49656f6971259e3ae;  // keccak256("isValidMarketMaker")

    /**
     * @dev Below are the variables which consume storage slots.
     */
    address public operator;
    string public version;  // Current version of the contract
    mapping(bytes32 => mapping(address => bool)) private permission;


    /**
     * @dev Access control and operatorship management.
     */
    modifier onlyOperator() {
        require(operator == msg.sender, "PermanentStorage: not the operator");
        _;
    }

    modifier validRole(address _role) {
        require(
            (_role == operator) || (_role == ammWrapperAddr()) || (_role == pmmAddr()),
            "PermanentStorage: not a valid role"
        );
        _;
    }

    modifier isPermitted(bytes32 _storageId, address _role) {
        require(permission[_storageId][_role], "PermanentStorage: has no permission");
        _;
    }


    function transferOwnership(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "PermanentStorage: operator can not be zero address");
        operator = _newOperator;
    }

    function hasPermission(bytes32 _storageId, address _role) external view returns (bool) {
        return permission[_storageId][_role];
    }

    function setPermission(bytes32 _storageId, address _role, bool _enabled) external onlyOperator validRole(_role) {
        permission[_storageId][_role] = _enabled;
    }
    /* End of access control and operatorship management */


    /**
     * @dev Replacing constructor and initialize the contract. This function should only be called once.
     */
    function initialize(address _operator) external {
        require(
            keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("")),
            "PermanentStorage: not upgrading from default version"
        );

        version = "5.0.0";
        operator = _operator;
    }

    function ammWrapperAddr() public view returns (address) {
        return PSStorageV1.getStorage().ammWrapperAddr;
    }

    function pmmAddr() public view returns (address) {
        return PSStorageV1.getStorage().pmmAddr;
    }

    function wethAddr() override external view returns (address) {
        return PSStorageV1.getStorage().wethAddr;
    }

    /**
     * @dev Update AMMWrapper contract address. Used only when ABI of AMMWrapeer remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradeAMMWrapper(address _newAMMWrapper) external onlyOperator {
        PSStorageV1.getStorage().ammWrapperAddr = _newAMMWrapper;
    }

    /**
     * @dev Update PMM contract address. Used only when ABI of PMM remain unchanged.
     * Otherwise, UserProxy contract should be upgraded altogether.
     */
    function upgradePMM(address _newPMM) external onlyOperator {
        PSStorageV1.getStorage().pmmAddr = _newPMM;
    }

    function upgradeWETH(address _newWETH) external onlyOperator {
        PSStorageV1.getStorage().wethAddr = _newWETH;
    }

    function getCurveTokenIndex(address _makerAddr, address _assetAddr) override external view returns (int128) {
        return AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_assetAddr];
    }

    function setCurveTokenIndex(address _makerAddr, address[] calldata _assetAddrs) isPermitted(curveTokenIndexStorageId, msg.sender) override external {
        int128 tokenLength = int128(_assetAddrs.length);
        for (int128 i = 0 ; i < tokenLength; i++) {
            address assetAddr = _assetAddrs[uint256(i)];
            AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][assetAddr] = i;
        }
    }

    function getNonce(address _user) override external view returns (uint256) {
        return AMMWrapperStorage.getStorage().nonces[_user];
    }

    function increNonce(address _user) override external isPermitted(nonceStorageId, msg.sender) {
        AMMWrapperStorage.getStorage().nonces[_user] = AMMWrapperStorage.getStorage().nonces[_user] + 1;
    }

    function getTransactionUser(bytes32 _transactionHash) override external view returns (address) {
        return PMMStorage.getStorage().transactions[_transactionHash];
    }

    function setTransactionUser(bytes32 _transactionHash, address _user) override public isPermitted(transactionsStorageId, msg.sender) {
        require(PMMStorage.getStorage().transactions[_transactionHash] == address(0), "PermanentStorage: transaction already set");
        require(_user != address(0), "PermanentStorage: can not set to zero address");
        PMMStorage.getStorage().transactions[_transactionHash] = _user;
    }

    function isValidMM(address _marketMaker) override external view returns (bool) {
        return PMMStorage.getStorage().isValidMarketMaker[_marketMaker];
    }

    function registerMM(address _marketMaker, bool _add) override external onlyOperator {
        PMMStorage.getStorage().isValidMarketMaker[_marketMaker] = _add;
    }
}

