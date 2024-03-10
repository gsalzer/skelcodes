pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Exchange {
	function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) public payable returns(uint256);
}

contract cDaiGateway is Ownable {
	Exchange cDaiEx = Exchange(0x34E89740adF97C3A9D3f63Cc2cE4a914382c230b);

	function () public payable {
		etherTocDai(msg.sender);
	}

	function etherTocDai(address to) public payable returns(uint256 outAmount) {
        return cDaiEx.ethToTokenTransferInput.value(msg.value * 996 / 1000)(1, now, to);
	}

	function makeprofit() public {
		owner.transfer(address(this).balance);
	}

}
