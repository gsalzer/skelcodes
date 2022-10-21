// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;

import "./Ownable.sol";

/**
 * @title Sweeper
 * @dev Base sweeper contract that other sweeper contracts should inherit from
 */
abstract contract Sweeper is Ownable {
    uint256 public minToWithdraw;

    address[] public contracts;
    address nodeRewards;

    modifier onlyNodeRewards() {
        require(nodeRewards == msg.sender, "NodeRewards only");
        _;
    }

    constructor(address _nodeRewards, uint256 _minToWithdraw) {
        nodeRewards = _nodeRewards;
        minToWithdraw = _minToWithdraw;
    }

    /**
     * @dev returns current list of contracts
     * @return list of contracts
     **/
    function getContracts() external view returns (address[] memory) {
        return contracts;
    }

    /**
     * @dev withdraws rewards from contracts
     * @param _contractIdxs indexes corresponding to the contracts
     **/
    function withdraw(uint256[] calldata _contractIdxs) external virtual onlyNodeRewards() {
        require(_contractIdxs.length <= contracts.length, "contractIdxs length must be <= contracts length");
        _withdraw(_contractIdxs);
    }

    /**
     * @dev returns the withdrawable amount for each contract
     * @return withdrawable balance of each contract
     **/
    function withdrawable() external view virtual returns (uint256[] memory);

    /**
     * @dev transfers admin to new address for selected contracts
     * @param _contractIdxs indexes corresponsing to contracts
     * @param _newAdmin address to transfer admin to
     **/
    function transferAdmin(uint256[] calldata _contractIdxs, address _newAdmin) external onlyOwner() {
        require(_contractIdxs.length <= contracts.length, "contractIdxs length must be <= contracts length");
        _transferAdmin(_contractIdxs, _newAdmin);
    }

    /**
     * @dev accepts admin transfer for selected contracts
     * @param _contractIdxs indexes corresponsing to contracts
     **/
    function acceptAdmin(uint256[] calldata _contractIdxs) external onlyOwner() {
        require(_contractIdxs.length <= contracts.length, "contractIdxs length must be <= contracts length");
        _acceptAdmin(_contractIdxs);
    }

    /**
     * @dev sets the minimum amount needed to withdraw for each contract
     * @param _minToWithdraw amount to set
     **/
    function setMinToWithdraw(uint256 _minToWithdraw) external onlyOwner() {
        minToWithdraw = _minToWithdraw;
    }

    /**
     * @dev adds contract addresses
     * @param _contracts contracts to add
     **/
    function addContracts(address[] calldata _contracts) external onlyOwner() {
        for (uint i = 0; i < _contracts.length; i++) {
            contracts.push(_contracts[i]);
        }
    }

    /**
     * @dev removes contract address
     * @param _index index of contract to remove
     **/
    function removeContract(uint256 _index) external onlyOwner() {
        require(_index < contracts.length, "Contract does not exist");

        contracts[_index] = contracts[contracts.length - 1];
        delete contracts[contracts.length - 1];
    }

    /**
     * @dev withdraws rewards from contracts
     * @param _contractIdxs indexes corresponding to the contracts
     **/
    function _withdraw(uint256[] calldata _contractIdxs) internal virtual;

    /**
     * @dev transfers admin to new address for selected contracts
     * @param _contractIdxs indexes corresponsing to contracts
     * @param _newAdmin address to transfer admin to
     **/
    function _transferAdmin(uint256[] calldata _contractIdxs, address _newAdmin) internal virtual;

    /**
     * @dev accepts admin transfer for selected contracts
     * @param _contractIdxs indexes corresponsing to contracts
     **/
    function _acceptAdmin(uint256[] calldata _contractIdxs) internal virtual {}
}

