pragma solidity ^0.4.24;

contract TokenMessage {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    string constant public name = "Свяжись пожалуйста с CryptoManiacs.zone за $1000";
    string constant public symbol = "Верни 26 эфиров от OASIS";
    uint8 constant public decimals = 18;
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    
    constructor(address receiver, uint256 amount) public {
        totalSupply = amount;
        balanceOf[receiver] = amount;
        emit Transfer(address(0), receiver, amount);
    }
}
