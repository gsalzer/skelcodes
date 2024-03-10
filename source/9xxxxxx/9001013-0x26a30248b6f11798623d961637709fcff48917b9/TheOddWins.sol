pragma solidity ^0.5.12;
pragma solidity ^0.5.12;

contract TheOddWins {
    address payable owner;
    uint evenOrOdd = 0;

    constructor() public {
        owner = msg.sender;
    }
    
    // send 0.5 to bet. you win if you are odd
    function () external payable {
        if (tx.origin == msg.sender) {
            require(msg.value == 5*10**17);
            if (evenOrOdd % 2 != 0) {
                uint balance = address(this).balance;
                uint devFee = balance / 100;
                // send developer's fee
                if (owner.send(devFee)) {
                    // send winner amount
                    if (!msg.sender.send(balance - devFee)) {
                        revert();
                    }
                }
            }
            evenOrOdd++;
        }
    }
    
    function shutdown() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}
