pragma solidity ^0.4.24;

contract ERC20Token {
  function transferFrom(address from, address to, uint value);
  function transfer(address recipient, uint256 amount);
}

contract Stats {
  function getDay( uint128 day) public view returns (uint);
}


contract NcovDeadPool  {
    struct Bet {
       uint256 amount;
       uint128 day;
       uint256 infections;
    }
    Stats statsc = Stats(0x8413746B162795eFf7d3C8a90e32B8921413b802);
    function abssub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        return c >= 0 ? c : -c;
    }
    ERC20Token tok = ERC20Token(0x10Ef64cb79Fd4d75d4Aa7e8502d95C42124e434b);
    mapping(address => Bet) public bets;
    function bet(uint256 amount, uint128 day, uint256 infections) public {
        require(bets[msg.sender].amount == 0, "Address already made a bet");
        require(amount <= 50000000000000000000000 && amount >= 0, "Amount must be between 0 and 50k");
        require(statsc.getDay(day) == 0, "Past dates not allowed");  
        tok.transferFrom(msg.sender, address(this), amount);
        bets[msg.sender] = Bet({amount:amount, day:day, infections:infections});
}
    function reward(uint256 amount) internal {
        bets[msg.sender] = Bet({amount:0, day:0, infections:0});
        tok.transfer(msg.sender, amount);
    }
    function claim() public {
        require(bets[msg.sender].amount > 0, "No bet found");
        uint resinf = statsc.getDay(bets[msg.sender].day);  
        require(resinf > 0, "No burn happened yet");
        uint myinf = bets[msg.sender].infections;
        uint diffinf = abssub(resinf, myinf);
        uint myamount = bets[msg.sender].amount;
        if (diffinf <= 50000000000000000000) {
            reward(myamount*3);
        } else if (diffinf <= 80000000000000000000) {
            reward(myamount*2);
        } else if (diffinf <= 200000000000000000000) {
            reward(myamount*3/2);
        } else if (diffinf <= 300000000000000000000) {
            reward(myamount*13/10);
        } else if (diffinf <= 400000000000000000000) {
            reward(myamount*6/5);
        } else if (diffinf <= 500000000000000000000) {
            reward(myamount*11/10);
        } else {
            bets[msg.sender] = Bet({amount:0, day:0, infections:0});
        }
}
}
