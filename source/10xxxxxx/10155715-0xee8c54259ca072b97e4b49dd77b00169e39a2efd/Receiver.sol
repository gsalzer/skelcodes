pragma solidity ^0.6.8;


abstract contract ERC20 {
    function balanceOf(address tokenOwner) public view virtual returns (uint balance);
    function transfer(address to, uint tokens) public virtual returns (bool success);
}


contract Receiver {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    /* Owning managing */
    function changeOwner(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    /* ERC20 overrides */
    function transfer(address contractAddress, uint256 amount, address receiver) public returns ( bool ) {
        require(msg.sender == owner);
        return ERC20(contractAddress).transfer(receiver, amount);
    }
    
    function balanceOf(address contractAddress) public view returns (uint256) {
        return ERC20(contractAddress).balanceOf(address(this));
    }
}
