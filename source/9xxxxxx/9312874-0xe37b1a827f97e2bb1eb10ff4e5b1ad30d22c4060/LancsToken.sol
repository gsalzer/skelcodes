pragma solidity ^0.4.24;

import "./ERC223.sol";
import "./SafeMath.sol";

// Contract Name
contract LancsToken is ERC223Token {
    using SafeMath for uint256;
    string public name = "LancsToken";
    string public symbol = "LANC";
    uint public decimals = 4; // 1.1234 LANC
    uint public totalSupply = 1000000000 * (10**decimals);
    address private treasury = 0x38A4000dF95775667D0C7985e6E8b4fc216cBa3f;
    //ICO Price; 4dec, 1etc=50000LANC
    uint256 private priceDiv = 2000000000;

    event Purchase(address indexed purchaser, uint256 amount);

    constructor() public {
        balances[msg.sender] = 850000000 * (10**decimals);
        balances[0x0] = 150000000 * (10**decimals);
    }

    function() public payable {
        bytes memory empty;
        if (msg.value == 0) {revert("Transaction has no value");}
        uint256 purchasedAmount = msg.value.div(priceDiv);
        if (purchasedAmount == 0) {revert("Not enough ETC sent");}
        if (purchasedAmount > balances[0x0]) {revert("Too much ETC sent");}

        treasury.transfer(msg.value);
        balances[0x0] = balances[0x0].sub(purchasedAmount);
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount);

        emit Transfer(0x0, msg.sender, purchasedAmount);
        emit ERC223Transfer(0x0, msg.sender, purchasedAmount, empty);
        emit Purchase(msg.sender, purchasedAmount);
    }

}
