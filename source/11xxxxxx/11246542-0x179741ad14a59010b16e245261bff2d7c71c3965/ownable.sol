// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./erc20.sol";

abstract contract Ownable is Context {
    address payable private _owner;
    address private _manager;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () public {
        _owner = _sender();
        _manager = _sender();
        emit OwnershipTransferred(address(0), _sender());
    }
    function owner() public view returns (address payable) {
        return _owner;
    }
	function manager() public view returns (address) {
        return _manager;
    }
	function setManager(address newManager) external onlyOwner{
		require(newManager != address(0), "Ownable: zero address");
        _manager = newManager;
    }
    modifier onlyOwner() {
        require(_owner == _sender(), "Ownable: caller is not the owner");
        _;
    }
	modifier onlyManager() {
        require(_owner == _sender() || _manager == _sender(), "Ownable: caller is not the owner or manager");
        _;
    }
    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
	function inCaseWrongTokenTransfer(address _tokenAddr,uint _type) onlyOwner external {
		require(_tokenAddr != address(this), "Ownable: invalid address");
        uint qty = IERC20(_tokenAddr).balanceOf(address(this));
		if(_type == 1)
			IERC20(_tokenAddr).transfer(_sender(), qty);
		else
			OLDIERC20(_tokenAddr).transfer(_sender(), qty);
    }
    function inCaseWrongEthTransfer() onlyOwner external{
        (bool result, ) = _sender().call{value:address(this).balance}("");
        require(result, "ETH Transfer Failed");
    }
}
