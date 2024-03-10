pragma solidity ^0.4.23;

import "./IERC20Withdraw.sol";
import "./IERC721Withdraw.sol";

contract CutieAccessControl {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // @dev Address with full contract privileges
    address ownerAddress;

    // @dev Next owner address
    address pendingOwnerAddress;

    // @dev Addresses with configuration privileges
    mapping (address => bool) operatorAddress;

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Access denied");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwnerAddress, "Access denied");
        _;
    }

    modifier onlyOperator() {
        require(operatorAddress[msg.sender] || msg.sender == ownerAddress, "Access denied");
        _;
    }

    constructor () internal {
        ownerAddress = msg.sender;
    }

    function getOwner() external view returns (address) {
        return ownerAddress;
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        pendingOwnerAddress = _newOwner;
    }

    function getPendingOwner() external view returns (address) {
        return pendingOwnerAddress;
    }

    function claimOwnership() external onlyPendingOwner {
        emit OwnershipTransferred(ownerAddress, pendingOwnerAddress);
        ownerAddress = pendingOwnerAddress;
        pendingOwnerAddress = address(0);
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr];
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0));
        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _operator) public onlyOwner {
        delete(operatorAddress[_operator]);
    }

    // @dev The balance transfer from CutieCore contract to project owners
    function withdraw(address _receiver) external onlyOwner {
        if (address(this).balance > 0) {
            _receiver.transfer(address(this).balance);
        }
    }

    // @dev Allow to withdraw ERC20 tokens from contract itself
    function withdrawERC20(IERC20Withdraw _tokenContract) external onlyOwner {
        uint256 balance = _tokenContract.balanceOf(address(this));
        if (balance > 0) {
            _tokenContract.transfer(msg.sender, balance);
        }
    }

    // @dev Allow to withdraw ERC721 tokens from contract itself
    function approveERC721(IERC721Withdraw _tokenContract) external onlyOwner {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }

}

