// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';


contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(UniswapV2Pair).creationCode);
    }

    function createPair(address tokenA, address tokenB, uint fee) external override returns (address pair) {
        require(msg.sender == feeToSetter, 'UniswapV2: NOT_SETTER');
        require(fee <= 50, 'UniswapV2: INVALID_FEE');
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        UniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        UniswapV2Pair(pair).setFee(fee);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setFee(address tokenA, address tokenB, uint fee) external override {
        require(msg.sender == feeToSetter, 'UniswapV2: NOT_SETTER');
        require(fee <= 50, 'UniswapV2: INVALID_FEE');
        address pairAddr = getPair[tokenA][tokenB];
        require(pairAddr != address(0), 'UniswapV2: NO_PAIR');
        UniswapV2Pair pair = UniswapV2Pair(pairAddr);
        pair.setFee(fee);
    }
}

