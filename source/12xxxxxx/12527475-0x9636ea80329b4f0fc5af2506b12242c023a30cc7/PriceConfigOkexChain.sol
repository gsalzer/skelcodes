// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./KineMath.sol";
import "./IERC20.sol";
import "./IExOracle.sol";

contract PriceConfigOkexChain is Ownable {
    using KineMath for uint;

    enum PriceSource {
        CHAINLINK, // Price from chainlink, priceUnit is aggregator decimals, baseUnit depends on underlying
        KAPTAIN,   // Price posted by kaptain
        LP,        // LP baseUnit is 1e18, priceUnit is 1e18
        EXORACLE   // Price from ExOracle, priceUnit is 1e6
    }

    struct KTokenConfig {
        address kToken;
        address underlying;
        bytes32 symbolHash;
        uint baseUnit;      // baseUnit: underlying decimal
        uint priceUnit;     // priceUnit: price decimal
        uint priceMantissa; // priceMantissa = priceUnit * baseUnit
        PriceSource priceSource;
    }

    struct ExOracleConfig {
        address kToken;
        string symbol;
        address source;
    }

    // Chainlink aggregator map, bytes32 => AggregatorV3Interface
    mapping(bytes32 => AggregatorV3Interface) public aggregators;

    // Map used for ExOracle price query, kToken => ExOracleConfig
    mapping(address => ExOracleConfig) public exOracleConfigs;

    IExOracle public exOracleView;

    KTokenConfig[] public kTokenConfigs;

    /// @notice New chainlink aggregator
    event AggregatorUpdated(string symbol, address source);

    /// @notice Configuration added event
    event TokenConfigAdded(address kToken, address underlying, bytes32 symbolHash,
        uint baseUnit, uint priceUnit, uint PriceMantissa, PriceSource priceSource);

    /// @notice Configuration removed event
    event TokenConfigRemoved(address kToken, address underlying, bytes32 symbolHash,
        uint baseUnit, uint priceUnit, uint PriceMantissa, PriceSource priceSource);

    /// @notice ExOracle address update event
    event ExOracleAddressUpdated(address fromAddress, address toAddress);

    /// @notice ExOracle configuraion setting event
    event ExOracleConfigUpdated(address kToken, string symbol, address source);

    function _pushConfig(KTokenConfig memory config) internal {
        require(config.priceMantissa == config.baseUnit.mul(config.priceUnit), "invalid priceMantissa");

        // check baseUnit
        IERC20 underlying = IERC20(config.underlying);
        uint tokenDecimals = uint(underlying.decimals());
        require(10**tokenDecimals == config.baseUnit, "mismatched baseUnit");

        kTokenConfigs.push(config);
        emit TokenConfigAdded(config.kToken, config.underlying, config.symbolHash,
            config.baseUnit, config.priceUnit, config.priceMantissa, config.priceSource);
    }

    // @dev must be called after you add chainlink sourced config
    function setAggregators(string[] calldata symbols, address[] calldata sources) public onlyOwner {
        require(symbols.length == sources.length, "mismatched input");
        for (uint i = 0; i < symbols.length; i++) {
            KTokenConfig memory config = getKConfigBySymbolHash(keccak256(abi.encodePacked(symbols[i])));
            AggregatorV3Interface agg = AggregatorV3Interface(sources[i]);
            aggregators[config.symbolHash] = agg;
            uint priceDecimals = uint(agg.decimals());
            require(10**priceDecimals == config.priceUnit, "mismatched priceUnit");
            emit AggregatorUpdated(symbols[i], sources[i]);
        }
    }

    // @notice set the symbol used to query ExOracle
    function setExOracleConfig(address kToken_, string memory symbol_, address source_) public onlyOwner {
        KTokenConfig memory config = getKConfigByKToken(kToken_);
        require(config.priceSource == PriceSource.EXORACLE, "mismatched priceSource");

        ExOracleConfig memory exOracleConfig = ExOracleConfig({
            kToken: kToken_,
            symbol: symbol_,
            source: source_
        });
        exOracleConfigs[kToken_] = exOracleConfig;

        (uint price, ) = exOracleView.get(symbol_, source_);
        require(price != 0, "unable to get price");

        emit ExOracleConfigUpdated(kToken_, symbol_, source_);
    }

    function _deleteConfigByKToken(address kToken) internal returns(KTokenConfig memory){
        uint index = getKConfigIndexByKToken(kToken);
        KTokenConfig memory configToDelete = kTokenConfigs[index];
        kTokenConfigs[index] = kTokenConfigs[kTokenConfigs.length - 1];

        // If chainlink price source, remove its aggregator
        if (configToDelete.priceSource == PriceSource.CHAINLINK) {
            delete aggregators[configToDelete.symbolHash];
        }
        kTokenConfigs.pop();

        emit TokenConfigRemoved(configToDelete.kToken, configToDelete.underlying,
            configToDelete.symbolHash, configToDelete.baseUnit, configToDelete.priceUnit,
            configToDelete.priceMantissa, configToDelete.priceSource);

        return configToDelete;
    }

    function getKConfigIndexByKToken(address kToken) public view returns (uint){
        for (uint i = 0; i < kTokenConfigs.length; i++) {
            KTokenConfig memory config = kTokenConfigs[i];
            if (config.kToken == kToken) {
                return i;
            }
        }
        return uint(-1);
    }

    function getKConfigIndexByUnderlying(address underlying) public view returns (uint){
        for (uint i = 0; i < kTokenConfigs.length; i++) {
            KTokenConfig memory config = kTokenConfigs[i];
            if (config.underlying == underlying) {
                return i;
            }
        }
        return uint(-1);
    }

    function getKConfigIndexBySymbolHash(bytes32 symbolHash) public view returns (uint){
        for (uint i = 0; i < kTokenConfigs.length; i++) {
            KTokenConfig memory config = kTokenConfigs[i];
            if (config.symbolHash == symbolHash) {
                return i;
            }
        }
        return uint(-1);
    }

    // if not found should revert
    function getKConfigByKToken(address kToken) public view returns (KTokenConfig memory) {
        uint index = getKConfigIndexByKToken(kToken);
        if (index != uint(-1)) {
            return kTokenConfigs[index];
        }
        revert("token config not found");
    }

    function getKConfigBySymbolHash(bytes32 symbolHash) public view returns (KTokenConfig memory) {
        uint index = getKConfigIndexBySymbolHash(symbolHash);
        if (index != uint(-1)) {
            return kTokenConfigs[index];
        }
        revert("token config not found");
    }

    function getKConfigBySymbol(string memory symbol) external view returns (KTokenConfig memory) {
        return getKConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
    }

    function getKConfigByUnderlying(address underlying) public view returns (KTokenConfig memory) {
        uint index = getKConfigIndexByUnderlying(underlying);
        if (index != uint(-1)) {
            return kTokenConfigs[index];
        }
        revert("token config not found");
    }

    function changeExOracleAddress(address newExOracle_) external {
        address oldExOracle = address(exOracleView);
        require(oldExOracle != newExOracle_, "same ExOracle");
        exOracleView = IExOracle(newExOracle_);
        emit ExOracleAddressUpdated(oldExOracle, newExOracle_);
    }
}
