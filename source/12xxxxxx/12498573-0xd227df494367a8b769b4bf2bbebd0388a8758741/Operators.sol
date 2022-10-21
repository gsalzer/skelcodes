// SPDX-License-Identifier: MIT
// Degen Farm. Collectible NFT game
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./Ownable.sol";

contract Operators is Ownable
{
    mapping (address=>bool) operatorAddress;

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Access denied");
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return owner() == _addr;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || isOwner(_addr);
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "New operator is empty");

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }

    /**
     * @dev Owner can claim any tokens that transferred
     * to this contract address
     */
    function withdrawERC20(IERC20 _tokenContract, address _admin) external onlyOwner
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(_admin, balance);
    }
}

