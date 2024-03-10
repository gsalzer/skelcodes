// SPDX-License-Identifier: MIT

pragma solidity ^0.6.5;

import "./interface/IPermanentStorage.sol";
import "./utils/lib_storage/PSStorage.sol";

contract PermanentStorage is IPermanentStorage {

    // Constants do not have storage slot.
    bytes32 public constant curveTokenIndexStorageId = 0xf4c750cdce673f6c35898d215e519b86e3846b1f0532fb48b84fe9d80f6de2fc; // keccak256("curveTokenIndex")
    bytes32 public constant transactionSeenStorageId = 0x695d523b8578c6379a2121164fd8de334b9c5b6b36dff5408bd4051a6b1704d0;  // keccak256("transactionSeen")
    bytes32 public constant relayerValidStorageId = 0x2c97779b4deaf24e9d46e02ec2699240a957d92782b51165b93878b09dd66f61;  // keccak256("relayerValid")

    // Below are the variables which consume storage slots.
    address public operator;
    string public version;  // Current version of the contract
    mapping(bytes32 => mapping(address => bool)) private permission;

    // Supported Curve pools
    address public constant CURVE_COMPOUND_POOL = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
    address public constant CURVE_USDT_POOL = 0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C;
    address public constant CURVE_Y_POOL = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
    address public constant CURVE_3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant CURVE_sUSD_POOL = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address public constant CURVE_BUSD_POOL = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;

    // Curve coins
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant cDAI = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address private constant cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant TUSD = 0x0000000000085d4780B73119b644AE5ecd22b376;
    address private constant Y_POOL_yDAI = 0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01;
    address private constant Y_POOL_yUSDC = 0xd6aD7a6750A7593E092a9B218d66C0A814a3436e;
    address private constant Y_POOL_yUSDT = 0x83f798e925BcD4017Eb265844FDDAbb448f1707D;
    address private constant Y_POOL_yTUSD = 0x73a052500105205d34Daf004eAb301916DA8190f;
    address private constant sUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
    address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address private constant BUSD_POOL_yDAI = 0xC2cB1040220768554cf699b0d863A3cd4324ce32;
    address private constant BUSD_POOL_yUSDC = 0x26EA744E5B887E5205727f55dFBE8685e3b21951;
    address private constant BUSD_POOL_yUSDT = 0xE6354ed5bC4b393a5Aad09f21c46E101e692d447;
    address private constant BUSD_POOL_yBUSD = 0x04bC0Ab673d88aE9dbC9DA2380cB6B79C4BCa9aE;

    /************************************************************
    *          Access control and ownership management          *
    *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "PermanentStorage: not the operator");
        _;
    }

    modifier validRole(bool _enabled, address _role) {
        if (_enabled) {
            require(
                (_role == operator) || (_role == ammWrapperAddr()) || (_role == pmmAddr()),
                "PermanentStorage: not a valid role"
            );
        }
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

    /// @dev Set permission for entity to write certain storage.
    function setPermission(bytes32 _storageId, address _role, bool _enabled) external onlyOperator validRole(_enabled, _role) {
        permission[_storageId][_role] = _enabled;
    }


    /************************************************************
    *              Constructor and init functions               *
    *************************************************************/
    /// @dev Replacing constructor and initialize the contract. This function should only be called once.
    function initialize() external {
        require(
            keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("5.0.0")),
            "PermanentStorage: not upgrading from 5.0.0 version"
        );

        version = "5.1.0";
        // register Compound pool
        // underlying_coins, exchange_underlying
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_COMPOUND_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_COMPOUND_POOL][USDC] = 2;
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_COMPOUND_POOL][cDAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_COMPOUND_POOL][cUSDC] = 2;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_COMPOUND_POOL] = true; // support get_dx or get_dx_underlying for quoting

        // register USDT pool
        // underlying_coins, exchange_underlying
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_USDT_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_USDT_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_USDT_POOL][USDT] = 3;
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_USDT_POOL][cDAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_USDT_POOL][cUSDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_USDT_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_USDT_POOL] = true;

        // register Y pool
        // underlying_coins, exchange_underlying
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_Y_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_Y_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_Y_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_Y_POOL][TUSD] = 4;
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_Y_POOL][Y_POOL_yDAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_Y_POOL][Y_POOL_yUSDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_Y_POOL][Y_POOL_yUSDT] = 3;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_Y_POOL][Y_POOL_yTUSD] = 4;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_Y_POOL] = true;

        // register 3 pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_3_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_3_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_3_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_3_POOL] = false; // only support get_dy and get_dy_underlying for exactly the same functionality

        // register sUSD pool
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sUSD_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sUSD_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sUSD_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_sUSD_POOL][sUSD] = 4;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_sUSD_POOL] = false;

        // register BUSD pool
        // underlying_coins, exchange_underlying
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_BUSD_POOL][DAI] = 1;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_BUSD_POOL][USDC] = 2;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_BUSD_POOL][USDT] = 3;
        AMMWrapperStorage.getStorage().curveTokenIndexes[CURVE_BUSD_POOL][BUSD] = 4;
        // coins, exchange
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_BUSD_POOL][BUSD_POOL_yDAI] = 1;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_BUSD_POOL][BUSD_POOL_yUSDC] = 2;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_BUSD_POOL][BUSD_POOL_yUSDT] = 3;
        AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[CURVE_BUSD_POOL][BUSD_POOL_yBUSD] = 4;
        AMMWrapperStorage.getStorage().curveSupportGetDx[CURVE_BUSD_POOL] = true;
    }


    /************************************************************
    *                     Getter functions                      *
    *************************************************************/
    function hasPermission(bytes32 _storageId, address _role) external view returns (bool) {
        return permission[_storageId][_role];
    }

    function ammWrapperAddr() public view returns (address) {
        return PSStorage.getStorage().ammWrapperAddr;
    }

    function pmmAddr() public view returns (address) {
        return PSStorage.getStorage().pmmAddr;
    }

    function wethAddr() override external view returns (address) {
        return PSStorage.getStorage().wethAddr;
    }

    function getCurvePoolInfo(address _makerAddr, address _takerAssetAddr, address _makerAssetAddr) override external view returns (int128 takerAssetIndex, int128 makerAssetIndex, uint16 swapMethod, bool supportGetDx) {
        // underlying_coins
        int128 i = AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_takerAssetAddr];
        int128 j = AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][_makerAssetAddr];
        supportGetDx = AMMWrapperStorage.getStorage().curveSupportGetDx[_makerAddr];

        swapMethod = 0;
        if (i != 0 && j != 0) {
            // in underlying_coins list
            takerAssetIndex = i;
            makerAssetIndex = j;
            // exchange_underlying
            swapMethod = 2;
        } else {
            // in coins list
            int128 iWrapped = AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][_takerAssetAddr];
            int128 jWrapped = AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][_makerAssetAddr];
            if (iWrapped != 0 && jWrapped != 0) {
                takerAssetIndex = iWrapped;
                makerAssetIndex = jWrapped;
                // exchange
                swapMethod = 1;
            } else {
                revert("PermanentStorage: invalid pair");
            }
        }
        return (takerAssetIndex, makerAssetIndex, swapMethod, supportGetDx);
    }

    function isTransactionSeen(bytes32 _transactionHash) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().transactionSeen[_transactionHash];
    }

    function isRelayerValid(address _relayer) override external view returns (bool) {
        return AMMWrapperStorage.getStorage().relayerValid[_relayer];
    }


    /************************************************************
    *           Management functions for Operator               *
    *************************************************************/
    /// @dev Update AMMWrapper contract address.
    function upgradeAMMWrapper(address _newAMMWrapper) external onlyOperator {
        PSStorage.getStorage().ammWrapperAddr = _newAMMWrapper;
    }

    /// @dev Update PMM contract address.
    function upgradePMM(address _newPMM) external onlyOperator {
        PSStorage.getStorage().pmmAddr = _newPMM;
    }

    /// @dev Update WETH contract address.
    function upgradeWETH(address _newWETH) external onlyOperator {
        PSStorage.getStorage().wethAddr = _newWETH;
    }


    /************************************************************
    *                   External functions                      *
    *************************************************************/
    function setCurvePoolInfo(address _makerAddr, address[] calldata _underlyingCoins, address[] calldata _coins, bool _supportGetDx) override external isPermitted(curveTokenIndexStorageId, msg.sender) {
        int128 underlyingCoinsLength = int128(_underlyingCoins.length);
        for (int128 i = 0 ; i < underlyingCoinsLength; i++) {
            address assetAddr = _underlyingCoins[uint256(i)];
            // underlying coins for original DAI, USDC, TUSD
            AMMWrapperStorage.getStorage().curveTokenIndexes[_makerAddr][assetAddr] = i + 1;  // Start the index from 1
        }

        int128 coinsLength = int128(_coins.length);
        for (int128 i = 0 ; i < coinsLength; i++) {
            address assetAddr = _coins[uint256(i)];
            // wrapped coins for cDAI, cUSDC, yDAI, yUSDC, yTUSD, yBUSD
            AMMWrapperStorage.getStorage().curveWrappedTokenIndexes[_makerAddr][assetAddr] = i + 1;  // Start the index from 1
        }

        AMMWrapperStorage.getStorage().curveSupportGetDx[_makerAddr] = _supportGetDx;
    }

    function setTransactionSeen(bytes32 _transactionHash) override external isPermitted(transactionSeenStorageId, msg.sender) {
        AMMWrapperStorage.getStorage().transactionSeen[_transactionHash] = true;
    }

    function setRelayersValid(address[] calldata _relayers, bool[] calldata _isValids) override external isPermitted(relayerValidStorageId, msg.sender) {
        require(_relayers.length == _isValids.length, "PermanentStorage: inputs length mismatch");
        for (uint256 i = 0; i < _relayers.length; i++) {
            AMMWrapperStorage.getStorage().relayerValid[_relayers[i]] = _isValids[i];
        }
    }
}

