pragma solidity =0.5.16;

import './interfaces/ISphynxFactory.sol';
import './SphynxPair.sol';

contract SphynxFactory is ISphynxFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(SphynxPair).creationCode)); // INIT_CODE_PAIR_HASH

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Sphynx: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Sphynx: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Sphynx: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(SphynxPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ISphynxPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Sphynx: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Sphynx: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
    
    function setSwapFee(address _pair, uint32 _swapFee) external {
        require(msg.sender == feeToSetter, 'Sphynx: FORBIDDEN');
        SphynxPair(_pair).setSwapFee(_swapFee);
    }
}
