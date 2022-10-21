pragma solidity 0.5.16;

import './library.sol';

contract FrogStats is Ownable {
    using SafeMath for uint256;

    IERC20 public frog = IERC20(0x4fEe21439F2b95b72da2F9f901b3956f27fE91D5);
    address public devPool = address(0x96eD0b21d024b82A430386A3A1477324f25f0143);
    address public rewardPool = address(0xC81acf050fa511FBA998b394a6087c569d3D103A);

    mapping (address => bool) public minters;
    mapping (uint256 => uint256) public iiStats;
    mapping (address => uint256) public aiStats;
    mapping (address => mapping(uint256 => uint256)) public aiiStats;
    mapping (address => mapping(address => uint256)) public aaiStats;
    mapping (uint256 => mapping(address => uint256)) public iaiStats;
    mapping (uint256 => mapping(address => address)) public iaaStats;
 
    constructor() public {
    }

    function incrIIStats(uint256 k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        iiStats[k] = iiStats[k].add(v);
        return iiStats[k];
    }
    function decrIIStats(uint256 k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        if(iiStats[k] < v){
            v = iiStats[k];
        }
        iiStats[k] = iiStats[k].sub(v);
        return iiStats[k];
    }
    function incrAIStats(address k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        aiStats[k] = aiStats[k].add(v);
        return aiStats[k];
    }
    function decrAIStats(address k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        if(aiStats[k] < v){
            v = aiStats[k];
        }
        aiStats[k] = aiStats[k].sub(v);
        return aiStats[k];
    }
    function incrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        aiiStats[addr][k] = aiiStats[addr][k].add(v);
        return aiiStats[addr][k];
    }
    function decrAIIStats(address addr, uint256 k, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        if(aiiStats[addr][k] < v){
            v = aiiStats[addr][k];
        }
        aiiStats[addr][k] = aiiStats[addr][k].sub(v);
        return aiiStats[addr][k];
    }
    function incrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        aaiStats[addr0][addr1] = aaiStats[addr0][addr1].add(v);
        return aaiStats[addr0][addr1];
    }
    function decrAAIStats(address addr0, address addr1, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        if(aaiStats[addr0][addr1] < v){
            v = aaiStats[addr0][addr1];
        }
        aaiStats[addr0][addr1] = aaiStats[addr0][addr1].sub(v);
        return aaiStats[addr0][addr1];
    }

    function incrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        iaiStats[k][addr1] = iaiStats[k][addr1].add(v);
        return iaiStats[k][addr1];
    }
    function decrIAIStats(uint256 k, address addr1, uint256 v) external returns (uint256){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        if(iaiStats[k][addr1] < v){
            v = iaiStats[k][addr1];
        }
        iaiStats[k][addr1] = iaiStats[k][addr1].sub(v);
        return iaiStats[k][addr1];
    }

    function setIAAStats(uint256 k, address addr1, address addr2) external returns (address){
        require(minters[msg.sender], "Frog-Token: You are not the minter");
        iaaStats[k][addr1] = addr2;
        return iaaStats[k][addr1];
    }

    function getIIStats(uint256 k) external view returns (uint256) {
        return iiStats[k];
    }
    function getAIStats(address addr) external view returns (uint256) {
        return aiStats[addr];
    }
    function getAAIStats(address addr0, address addr1) external view returns (uint256) {
        return aaiStats[addr0][addr1];
    }
    function getAIIStats(address addr, uint256 k) external view returns (uint256) {
        return aiiStats[addr][k];
    }
    function getIAIStats(uint256 k, address addr) external view returns (uint256) {
        return iaiStats[k][addr];
    }
    function getIAAStats(uint256 k, address addr) external view returns (address) {
        return iaaStats[k][addr];
    }
    /** 
     * Add minter
     * @param _minter minter
     */
    function addMinter(address _minter) external onlyFactoryOrOwner {
        minters[_minter] = true;
    }
    
    /** 
     * Remove minter
     * @param _minter minter
     */
    function removeMinter(address _minter) external onlyFactoryOrOwner {
        minters[_minter] = false;
    }
}
