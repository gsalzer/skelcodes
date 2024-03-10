/*! ethbus.sol | (c) 2020 Develop by BelovITLab LLC (smartcontract.ru), author @stupidlovejoy | License: MIT */

pragma solidity 0.5.16;

import "./provableAPI_0.5.sol";

contract Destructible {
    address payable public grand_owner;

    event GrandOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        grand_owner = 0x347C8Aee837a2Cb7A98D3cC6FEb83C6cdcaB5946;
    }

    function transferGrandOwnership(address payable _to) external {
        require(msg.sender == grand_owner, "Access denied (only grand owner)");
        
        grand_owner = _to;
    }

    function destruct() external {
        require(msg.sender == grand_owner, "Access denied (only grand owner)");

        selfdestruct(grand_owner);
    }
}

contract Ownable {
    address payable public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not owner");
        _;
    }

    constructor() public {
        owner = 0x347C8Aee837a2Cb7A98D3cC6FEb83C6cdcaB5946;
    }

    function transferOwnership(address payable to) external onlyOwner {
        require(to != address(0), "Zero address");

        owner = to;
    }
}

contract Rewardable is Ownable {
    struct Payment {
        uint amount; 
        uint members;
    }

    uint public all_members;
    uint public to_repayment;
    uint public last_repayment = block.timestamp;

    Payment[] private repayments;

    mapping(address => bool) public members;
    mapping(address => uint) private rewards;

    event AddMember(address indexed addr, uint time);
    event Repayment(uint amount, uint time);
    event Reward(address indexed addr, uint amount, uint time);

    function _addMember(address payable _addr) internal {
        require(!members[_addr], "Reward: Member already exist");

        members[_addr] = true;
        rewards[_addr] = repayments.length;
        all_members++;

        emit AddMember(_addr, block.timestamp);
    }

    function _reward(address _addr) internal returns(uint sum) {
        require(members[_addr], "Reward: You not a member");
        require(rewards[_addr] < repayments.length, "Reward: Zero amount");

        sum = this.availableRewards(_addr);
        rewards[_addr] = repayments.length;

        emit Reward(_addr, sum, block.timestamp);
    }

    function repayment() internal returns(bool) {
        if(((block.timestamp - last_repayment) / 1 days < 15) || to_repayment == 0 || all_members == 0) return false;

        repayments.push(Payment({
            amount: to_repayment,
            members: all_members
        }));

        emit Repayment(to_repayment, block.timestamp);

        to_repayment = 0;
        last_repayment = block.timestamp;

        return true;
    }

    function availableRewards(address _addr) public view returns(uint sum) {
        require(members[_addr], "Reward: You not a member");

        for(uint i = rewards[_addr]; i < repayments.length; i++) {
            sum += repayments[i].amount / repayments[i].members;
        }
    }
}

contract HappyPool is Destructible, Ownable {
    uint constant PART_PRICE = 2e21;

    address public game;
    uint public close_balance;
    uint public payouts_count;

    mapping(address => uint) public balances;
    address payable[] public members;
    
    constructor(address _game) public {
        game = _game;
    }

    function() payable external {
        
    }

    function addMember(address payable addr, uint value) public {
        require(msg.sender == game, "Only game");

        if(balances[addr] < PART_PRICE && balances[addr] + value >= PART_PRICE && close_balance == 0) {
            members.push(addr);
        }

        balances[addr] += value;
    }

    function close() external onlyOwner {
        require(close_balance == 0, "Already close");
        require(members.length > 0, "Zero members");
        require(address(this).balance > 0, "Zero balance");

        close_balance = address(this).balance;
    }

    function payouts(uint limit) external onlyOwner {
        require(close_balance > 0, "Not close");

        uint value = close_balance / members.length;
        uint i = payouts_count;
        uint m = payouts_count + limit;
        uint l = members.length > m ? m : members.length;
        
        for(; i < l; i++) {
            members[i].transfer(value);
        }
        
        payouts_count = i + 1;
    }
}

contract Ethbus is usingProvable, Rewardable, Destructible {
    struct Build {
        uint price; 
        uint payout_per_day;
        uint life_days;
    }

    struct Player {
        uint balance;
        uint last_payout;
        uint withdraw;
        address upline;
        uint[] builds;
        uint[] builds_time;
    }
    
    uint public rate = 210;

    HappyPool public happyPool;
    
    uint[] public ref_bonuses_percent;

    Build[] public builds;
    mapping(address => Player) public players;
    
    uint public provable_gas_price = 1e9;
    uint public provable_gas_limit = 1e6;
    uint public provable_timeout = 1 days;
    uint public provable_panic_time;
    mapping(bytes32 => bool) private provable_ids;

    event UpRate(address indexed addr, uint old_value, uint new_value, uint time);
    event Donate(address indexed addr, uint amount, uint time);
    event Deposit(address indexed addr, uint value, uint amount, uint time);
    event BuyBuild(address indexed addr, uint build, uint time);
    event SetUpline(address indexed addr, address indexed upline);
    event RefBonus(address indexed addr, address indexed from, uint amount, uint time);
    event Withdraw(address indexed addr, uint value, uint amount, uint time);

    constructor() payable public {

        builds.push(Build({price: 100e18, payout_per_day: 70e18, life_days: 260}));
        builds.push(Build({price: 1000e18, payout_per_day: 800e18, life_days: 260}));
        builds.push(Build({price: 2000e18, payout_per_day: 1800e18, life_days: 260}));
        builds.push(Build({price: 5000e18, payout_per_day: 5000e18, life_days: 200}));
        builds.push(Build({price: 10000e18, payout_per_day: 12000e18, life_days: 200}));
        
        ref_bonuses_percent.push(100);
        ref_bonuses_percent.push(40);
        ref_bonuses_percent.push(30);
        ref_bonuses_percent.push(10);
        ref_bonuses_percent.push(7);
        ref_bonuses_percent.push(5);
        ref_bonuses_percent.push(3);
        ref_bonuses_percent.push(2);
        ref_bonuses_percent.push(2);
        ref_bonuses_percent.push(1);

        happyPool = new HappyPool(address(this));

        provable_setCustomGasPrice(provable_gas_price);
        
        emit UpRate(msg.sender, 0, rate, block.timestamp);

        _upRate(0);
    }

    function __callback(bytes32 id, string memory res) public {
        require(msg.sender == provable_cbAddress(), "Access denied");
        require(provable_ids[id], "Bad ID");

        uint new_value = parseInt(res);

        require(new_value > 0, "Bad value");

        emit UpRate(msg.sender, rate, new_value, block.timestamp);

        rate = new_value;
        delete provable_ids[id];

        repayment();
        _upRate(provable_timeout);
    }

    function _upRate(uint timeout) private {
        if(provable_getPrice("URL") <= address(this).balance) {
            provable_ids[provable_query(timeout, "URL", "json(https://api.pro.coinbase.com/products/ETH-USD/ticker).price", provable_gas_limit)] = true;
            provable_panic_time = block.timestamp + provable_timeout + 1 hours;
        }
    }

    function _payout(address addr) private {
        uint payout = payoutOf(addr);

        if(payout > 0) {
            players[addr].balance += payout;
            players[addr].last_payout = block.timestamp;
        }
    }

    function _upline(address addr, address upline) private {
        if(players[addr].upline == address(0) && addr != upline && (players[upline].balance > 0 || players[upline].withdraw > 0)) {
            players[addr].upline = upline;

            emit SetUpline(addr, upline);
        }
    }

    function _deposit(address addr, uint value) private {
        uint amount = value * (addr == owner ? 10000 : rate);

        players[addr].balance += amount;
        address(happyPool).transfer(value * 3 / 100);

        emit Deposit(addr, value, amount, block.timestamp);
    }
    
    function _buyBuild(address payable addr, uint build) private {
        require(builds[build].price > 0, "Build not found");

        Player storage player = players[addr];

        _payout(addr);
        
        require(player.balance >= builds[build].price, "Insufficient funds");

        player.balance -= builds[build].price;
        to_repayment += builds[build].price * 3 / 100;
        
        address up = player.upline;
        for(uint i = 0; i < ref_bonuses_percent.length; i++) {
            if(up == address(0)) break;

            uint bonus = builds[build].price * ref_bonuses_percent[i] / 1000;
            players[up].balance += bonus;

            emit RefBonus(up, addr, bonus, block.timestamp);

            up = players[up].upline;
        }

        player.builds.push(build);
        player.builds_time.push(block.timestamp);

        happyPool.addMember(addr, builds[build].price);

        emit BuyBuild(addr, build, block.timestamp);
    }

    function donate() payable external {
        emit Donate(msg.sender, msg.value, block.timestamp);
    }

    function deposit() payable external {
        _deposit(msg.sender, msg.value);
    }

    function deposit(address upline) payable external {
        _upline(msg.sender, upline);
        _deposit(msg.sender, msg.value);
    }

    function buyBuild(uint build) external {
        _buyBuild(msg.sender, build);
    }

    function buyBuilds(uint[] calldata items) external {
        require(items.length > 0, "Empty builds");

        for(uint i = 0; i < items.length; i++) {
            _buyBuild(msg.sender, items[i]);
        }
    }

    function depositAndBuyBuild(uint build) payable external {
        _deposit(msg.sender, msg.value);
        _buyBuild(msg.sender, build);
    }
    
    function depositAndBuyBuilds(uint[] calldata items) payable external {
        require(items.length > 0, "Empty builds");

        _deposit(msg.sender, msg.value);

        for(uint i = 0; i < items.length; i++) {
            _buyBuild(msg.sender, items[i]);
        }
    }

    function withdraw(uint value) external {
        require(value > 0, "Small value");

        Player storage player = players[msg.sender];

        _payout(msg.sender);

        require(player.balance >= value, "Insufficient funds");

        player.balance -= value;
        player.withdraw += value;
        
        msg.sender.transfer(value / rate);

        emit Withdraw(msg.sender, value / rate, value, block.timestamp);
    }

    function becomeMember() external {
        _payout(msg.sender);

        require(players[msg.sender].balance >= 2e21, "Insufficient funds");
        
        players[msg.sender].balance -= 2e21;

        _addMember(msg.sender);
    }

    function reward() external {
        players[msg.sender].balance += _reward(msg.sender);
    }

    function upRate(uint _provable_gas_price, uint _provable_gas_limit, uint _provable_timeout) external onlyOwner {
        provable_gas_limit = _provable_gas_limit > 0 ? _provable_gas_limit : provable_gas_limit;

        if(_provable_timeout > 0 && _provable_timeout != provable_timeout && _provable_timeout >= 60 && _provable_timeout <= 1 weeks) {
            provable_timeout = _provable_timeout;
        }

        if(_provable_gas_price > 0 && _provable_gas_price != provable_gas_price) {
            provable_gas_price = _provable_gas_price;
            provable_setCustomGasPrice(provable_gas_price);
        }

        if(block.timestamp > provable_panic_time) {
            _upRate(0);
        }
    }

    function payoutOf(address addr) view public returns(uint value) {
        Player storage player = players[addr];

        for(uint i = 0; i < player.builds.length; i++) {
            uint time_end = player.builds_time[i] + builds[player.builds[i]].life_days * 1 days;
            uint from = player.last_payout > player.builds_time[i] ? player.last_payout : player.builds_time[i];
            uint to = block.timestamp > time_end ? time_end : block.timestamp;

            if(from < to) {
                value += ((to - from) / 1 days) * builds[player.builds[i]].payout_per_day / 100;
            }
        }

        return value;
    }
    
    function balanceOf(address addr) view external returns(uint) {
        return players[addr].balance + payoutOf(addr);
    }
}
