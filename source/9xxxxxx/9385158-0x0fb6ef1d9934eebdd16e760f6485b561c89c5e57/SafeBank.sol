pragma solidity 0.6.0;
//These contracts were made as a study on the new Solidity 0.6.x way of making transfers.

//Makes sure we have all the transactions stored on the blockchain for easy and public auditing:
contract Log {
    //Object representing each log:
    struct Message {
        address sender; //who did it
        uint amount; //how much eth
        uint time; //timestamp
        string operation; //"Deposit" or "Withdraw"
    }
    
    Message[] public history; //list of logs
    Message lastMsg; //the last registered log
    
    //saves a log on the blockchain:
    function register(address sender, uint amount, string memory operation) public {
        history.push(Message(sender, amount, now, operation));
    }
}

//Safely stores user's Ether and allows withdrawals using the new Solidity ^0.6.0 way:
contract SafeBank {
    uint public constant minDeposit = 300 finney; //minimum deposit is 0.3 Ether (not worth it to deposit much less because of network fees)

    mapping (address => uint) public balances; //balance of each user
    Log transferLog; //logs each deposit and each withdraw for auditing
    
    constructor(address _log) public payable {
        transferLog = Log(_log);
    }
    
    //deposits Eth in the contract:
    function deposit() public payable {
        require(msg.value >= minDeposit, "Minimum deposit not met."); //requires at least minDeposit

        balances[msg.sender] += msg.value; //adds Eth to the balance of whoever called this function
        transferLog.register(msg.sender, msg.value, "Deposit"); //logs the deposit
    }
    
    //withdraws Eth from the contract:
    function withdraw(uint amount) public {
        require(amount <= balances[msg.sender], "Insufficient funds"); //requires the user has enough balance

        (bool success,) = msg.sender.call.value(amount)(""); //tries to send Eth to the user using the new Solidity ^0.6.0 way
        if(success) { //if the transfer fails, the whole transaction is reverted
            balances[msg.sender] -= amount; //reduce the user's balance
            transferLog.register(msg.sender, amount, "Withdraw"); //logs the withdrawal
        }
    }
    
    //the new fallback function:
    receive() external payable {
        
    }
}
