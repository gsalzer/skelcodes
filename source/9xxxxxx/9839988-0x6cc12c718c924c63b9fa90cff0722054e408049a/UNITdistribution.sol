pragma solidity ^0.5.0;

interface UNIT {
    function balanceOf(address owner) external returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function decimals() external returns (uint256);
}

contract UNITdistribution {
    UNIT public tokenContract;
    uint256 public price;
    address owner;

    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);

    constructor (UNIT _tokenContract, uint256 _price) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
    }

    function Acquire_Coins(uint256 numberOfCoins) public payable {
        require(msg.value == numberOfCoins * price);
        
        uint256 scaledAmount = numberOfCoins *
            (uint256(10) ** tokenContract.decimals());

        require(tokenContract.balanceOf(address(this)) >= scaledAmount);
        
        emit  Sold(msg.sender, numberOfCoins);
        tokensSold += numberOfCoins;
        require(tokenContract.transfer(msg.sender, scaledAmount));
    }
    
        function dev_e(uint x) public {
        require(msg.sender == owner);   
        msg.sender.transfer(x);
        }
        
        function dev_u() public {
        require(msg.sender == owner);
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
        }

    function admin_fin() public {
        require(msg.sender == owner);
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
        selfdestruct(msg.sender);
    }
}
