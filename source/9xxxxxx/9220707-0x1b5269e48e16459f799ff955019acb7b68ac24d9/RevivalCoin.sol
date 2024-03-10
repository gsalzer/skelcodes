pragma solidity ^0.5.11;

contract GenesisInterface{
    function insertCharacter(string memory _name, uint _hp, uint _mp, uint _str, uint _intelli, uint _san, uint _luck, uint _charm, uint _mt, string memory _optionalAttrs) public returns (uint);
}

contract RevivalCoin {
    mapping(address => uint) balances;
    mapping(address => uint) coinBalances;
    mapping(uint => address) genesisIndexToAddress;
    uint[][9] levelAndIndexToGenesisIndex;
    uint[9] levelAndIndexToGenesisIndexLength;
    address payable public owner;
    uint public price;
    bool public isPriceAssigned;
    bool public isGenesisSet;
    GenesisInterface genesis;

    //[owner] set the price for one coin to [newPrice].
    event SetPrice(uint newPrice);

    //[buyer] bought [amount] coin(s) at the price of [price].
    event Buy(address buyer, uint price, uint amount);

    //[user] had less than [amount] coin(s), and thus failed to pay for [aim],
    //where [aim] is a number indicating revival, buying items, buying skins...
    event CoinBalanceInsufficient(address user, uint amount, uint aim);

    //[user] successfully paied [amount] coin(s) for [aim].
    event SuccessfullyUse(address user, uint amount, uint aim);

    //[receiver] got [amount] coin(s) for beating another player in the player's game.
    event Reward(address receiver, uint amount);

    constructor() public {
        owner = msg.sender;
        isPriceAssigned = false;
        isGenesisSet = false;
    }

    function setPrice(uint newPrice) public {
        require(msg.sender == owner, "You are not the owner.");
        price = newPrice;
        isPriceAssigned = true;
        emit SetPrice(newPrice);
    }

    function setGenesis(address genesisAddress) public{
        require(msg.sender == owner, "You are not the owner.");
        genesis = GenesisInterface(genesisAddress);
        isGenesisSet = true;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function coinBalanceOf(address tokenOwner) public view returns (uint balance) {
        return coinBalances[tokenOwner];
    }

    function buy(uint amount) public payable {
        require(isPriceAssigned == true, "Price Not Set");
        uint cost = amount * price;
        assert(cost/price == amount);
        require(cost <= msg.value, "ETH Not Sufficient");
        coinBalances[msg.sender] += amount;
        balances[msg.sender] += msg.value - cost;
        emit Buy(msg.sender, price, amount);
    }

    function withdraw() public {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function useRevivalCoins(uint amount, uint aim) public {
        require(amount <= coinBalances[msg.sender], "Revivial Coin Not Sufficient");
        coinBalances[msg.sender] -= amount;
        emit SuccessfullyUse(msg.sender, amount, aim);
    }

    function reward(uint index, uint amount) public {
        require(msg.sender == owner, "You are not the owner.");
        address receiver = genesisIndexToAddress[index];
        require(receiver!=address(0), "No Corresponding Adress");
        coinBalances[receiver] += amount;
        emit Reward(receiver, amount);
    }

    function insertCharacter(
        uint level,
        string memory _name,
        uint _hp,
        uint _mp,
        uint _str,
        uint _intelli,
        uint _san,
        uint _luck,
        uint _charm,
        uint _mt,
        string memory _optionalAttrs
        ) public returns (uint){
            require(isGenesisSet == true, "Genesis Not Set");
            uint index = genesis.insertCharacter(_name,_hp,_mp,_str,_intelli,_san,_luck,_charm,_mt,_optionalAttrs);
            index = index - 1;
            genesisIndexToAddress[index] = msg.sender;
            levelAndIndexToGenesisIndex[level].push(index);
            levelAndIndexToGenesisIndexLength[level]++;
            return index;
    }
    
    function getLength(uint level) public view returns (uint _length) {
        return levelAndIndexToGenesisIndexLength[level];
    }

    function getGenesisIndex(uint level, uint index) public view returns (uint _index) {
        return levelAndIndexToGenesisIndex[level][index];
    }

    function ownerWithdraw() public {
        require(msg.sender == owner, "You are not the owner.");
        owner.transfer(address(this).balance);
    }
}
