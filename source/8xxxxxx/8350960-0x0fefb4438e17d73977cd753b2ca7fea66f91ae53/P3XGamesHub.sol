pragma solidity 0.5.10;

import "./SafeMath.sol";

contract P3XGamesHub {
    
    using SafeMath for uint256;
    
    function()
        external
        payable
    {}
    
    //
    //Players
    //
    
    struct Player {
        uint256 balance;
        uint256 fundingBalance;
    }
    
    mapping(address => Player) public players;
    uint256 public totalPlayerBalances;
    uint256 public totalFundingBalances;
    
    event Withdraw(address indexed player, uint256 amount);
    event Fund(address indexed funder, uint256 amount);
    event WithdrawFunding(address indexed player, uint256 amount);
	
	function fund(address player, uint256 amount)
	    private
	{
	    players[player].fundingBalance = players[player].fundingBalance.add(amount);
	    
	    totalFundingBalances += amount;
	    
	    emit Fund(player, amount);
	}
	
	function playGame(address player, uint256 amount, bytes memory data)
	    private
	{
	    (address gameAddress, bytes memory gameData) = abi.decode(data, (address, bytes));
	    
	    require(games[gameAddress].registered);
	    
	    games[gameAddress].amountGiven += amount;
	    
	    IHubGame(gameAddress).play(player, amount, gameData);
	}
	
	function withdrawBalance()
	    external
	    fetchP3XDividends
	{
	    uint256 amount = players[msg.sender].balance;
	    
	    require(amount > 0);
	    
	    players[msg.sender].balance = 0;
	    
	    totalPlayerBalances -= amount;
	    
        p3xContract.transfer(msg.sender, amount);
        
	    emit Withdraw(msg.sender, amount);
	}
	
	function withdrawBalancePartial(uint256 howMuch)
	    external
	    fetchP3XDividends
	{
	    require(howMuch > 0);
	    
	    players[msg.sender].balance = players[msg.sender].balance.sub(howMuch);
	    
	    totalPlayerBalances -= howMuch;
	   
        p3xContract.transfer(msg.sender, howMuch);
	    
	    emit Withdraw(msg.sender, howMuch);
	}
	
	function withdrawFundingBalance()
	    external
	{
	    uint256 amount = players[msg.sender].fundingBalance;
	    
	    require(amount > 0);
	    
	    players[msg.sender].fundingBalance = 0;
	    
	    totalFundingBalances -= amount;
	   
	    p3xContract.transfer(msg.sender, amount);
	    
	    emit WithdrawFunding(msg.sender, amount);
	}
	
	function withdrawFundingBalancePartial(uint256 howMuch)
	    external
	{
	    require(howMuch > 0);
	    
	    players[msg.sender].fundingBalance = players[msg.sender].fundingBalance.sub(howMuch);
	    
	    totalFundingBalances -= howMuch;
	   
	    p3xContract.transfer(msg.sender, howMuch);
	    
	    emit WithdrawFunding(msg.sender, howMuch);
	}
	
	//
	//Games
	//
	
	struct Game {
        bool registered;
        uint256 amountGiven;
        uint256 amountTaken;
    }
    
    mapping(address => Game) public games;
    uint256 public numberOfGames;
	
	address public manager = address(0x1EB2acB92624DA2e601EEb77e2508b32E49012ef);
	address public newManager = address(0);
    
    event AddGame(address game);
    event RemoveGame(address game);
    
    modifier isRegisteredGame(address gameAddress)
    {
        require(games[gameAddress].registered);
        _;
    }
    
    modifier isUnregisteredGame(address gameAddress)
    {
        require(!games[gameAddress].registered);
        _;
    }

    modifier onlyManager()
    {
        require(msg.sender == manager);
        _;
    }

    function addGame(address gameAddress)
        external
        onlyManager
        isUnregisteredGame(gameAddress)
    {
        games[gameAddress] = Game(true, 0, 0);
        numberOfGames++;
        
        emit AddGame(gameAddress);
    }
    
    function removeGame(address gameAddress)
        external
        onlyManager
        isRegisteredGame(gameAddress)
    {
        games[gameAddress].registered = false;
        numberOfGames--;
        
        emit RemoveGame(gameAddress);
    }
    
    function changeManager(address newManagerAddress)
        external
        onlyManager
    {
        newManager = newManagerAddress;
    }
    
    function becomeManager()
        external
    {
        require(msg.sender == newManager);
        manager = newManager;
        newManager = address(0);
    }
	
	function addPlayerBalance(address playerAddress, uint256 value)
	    external
	    isRegisteredGame(msg.sender)
	{
	    addPlayerBalanceInternal(msg.sender, playerAddress, value);
	}
	
	function addPlayerBalances(address[] calldata playerAddresses, uint256[] calldata values)
	    external
	    isRegisteredGame(msg.sender)
	{
	    for(uint256 i = 0; i < playerAddresses.length; i++) {
	        addPlayerBalanceInternal(msg.sender, playerAddresses[i], values[i]);
	    }
	}
	
	function addPlayerBalanceInternal(address gameAddress, address playerAddress, uint256 value)
	    private
	{
	    players[playerAddress].balance = players[playerAddress].balance.add(value);
	    games[gameAddress].amountTaken += value;
	    
	    totalPlayerBalances += value;
	}
	
	function subPlayerBalance(address playerAddress, uint256 value)
	    external
	    isRegisteredGame(msg.sender)
	{
	    subPlayerBalanceInternal(msg.sender, playerAddress, value);
	}
	
	function subPlayerBalances(address[] calldata playerAddresses, uint256[] calldata values)
	    external
	    isRegisteredGame(msg.sender)
	{
	    for(uint256 i = 0; i < playerAddresses.length; i++) {
	        subPlayerBalanceInternal(msg.sender, playerAddresses[i], values[i]);
	    }
	}
	
	function subPlayerBalanceInternal(address gameAddress, address playerAddress, uint256 value)
	    private
	{
	    players[playerAddress].balance = players[playerAddress].balance.sub(value);
	    games[gameAddress].amountGiven += value;
	    
	    totalPlayerBalances -= value;
	}
	
	//
	// P3X Integration
	//
	
	address constant private P3X_ADDRESS = address(0x058a144951e062FC14f310057D2Fd9ef0Cf5095b);
    IP3X constant private p3xContract = IP3X(P3X_ADDRESS);
    
    modifier onlyP3X()
    {
        require(msg.sender == P3X_ADDRESS);
        _;
    }
	
	modifier fetchP3XDividends()
    {
        if(totalSupply > 0) {
            uint256 dividends = p3xContract.dividendsOf(address(this), true);
            if(dividends > 0) {
                uint256 contractBalance = address(this).balance;
                p3xContract.withdraw();
                uint256 newContractBalance = address(this).balance;
                uint256 actualDividends = newContractBalance.sub(contractBalance);
                totalDividendPoints = totalDividendPoints.add(actualDividends.mul(POINT_MULTIPLIER) / totalSupply);
                totalOutstandingDividends = totalOutstandingDividends.add(actualDividends);
            }
        }
        _;
    }
    
    function tokenFallback(address player, uint256 amount, bytes calldata data)
	    external
	    onlyP3X
	    fetchP3XDividends
	{
	    require(amount > 0);
	    
	    if(data.length == 0) {
	        fund(player, amount);
	    } else {
	        playGame(player, amount, data);
	    }
	}
    
    //
    //Shareholder Setup
	//
	
    struct Shareholder {
        uint256 tokens;
        uint256 outstandingDividends;
        uint256 lastDividendPoints;
    }

    uint256 public totalSupply = 0;
    mapping(address => Shareholder) public shareholders;
    
    uint256 constant private POINT_MULTIPLIER = 10e18;
    uint256 private totalDividendPoints;
    uint256 public totalOutstandingDividends;
    
    event Mint(address indexed player, uint256 indexed amount);
    
    function addShareholderTokens(address playerAddress, uint256 amount)
        external
	    isRegisteredGame(msg.sender)
    {
        updateOutstandingDividends(shareholders[playerAddress]);
        shareholders[playerAddress].tokens = shareholders[playerAddress].tokens.add(amount);
        
        totalSupply += amount;
        
        emit Mint(playerAddress, amount);
    }
    
    function updateOutstandingDividends(Shareholder storage shareholder)
        private
    {
        uint256 dividendPointsDifference = totalDividendPoints.sub(shareholder.lastDividendPoints);
        
        shareholder.lastDividendPoints = totalDividendPoints;
        shareholder.outstandingDividends = shareholder.outstandingDividends
                                            .add(dividendPointsDifference.mul(shareholder.tokens) / POINT_MULTIPLIER);
    }
    
    function withdrawDividends()
        external
    {
        Shareholder storage shareholder = shareholders[msg.sender];
        
        updateOutstandingDividends(shareholder);
        
        uint256 amount = shareholder.outstandingDividends;
        
        require(amount > 0);
        
        shareholder.outstandingDividends = 0;
        totalOutstandingDividends = totalOutstandingDividends.sub(amount);
		
	    msg.sender.transfer(amount);
    }
}

interface IP3X {
    function transfer(address to, uint256 value) external returns(bool);
	function dividendsOf(address customerAddress, bool includeReferralBonus) external view returns(uint256);
    function withdraw() external;
}

interface IHubGame {
    function play(address playerAddress, uint256 value, bytes calldata gameData) external;
}
