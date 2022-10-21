pragma solidity ^0.6.0;

interface Minereum {
  function Payment (  ) payable external;  
}

contract MinereumLuckyDraw
{
	Minereum public mne;
	RNG public rng;
	uint public stakeHoldersfee = 50;
	uint public percentWin = 80;
	uint public mnefee = 500000000;
	uint public ethfee = 10000000000000000;
	uint public totalSentToStakeHolders = 0;
	uint public totalPaidOut = 0;
	uint public ticketsSold = 0;
	address public owner = 0x0000000000000000000000000000000000000000;	
	uint public maxNumber = 1001;
	uint public systemNumber = 323;
	uint public previousEndPeriod = 1588447830 + 2629743;
	
	address[] public winner;
	uint[] public winnerTickets;
	uint[] public winnerETHAmount;
	uint[] public winnerTimestamp;
	
	address[] public lost;
	uint[] public lostTickets;
	uint[] public lostTimestamp;
	
	event Numbers(address indexed from, uint[] n, string m);
	
	constructor() public
	{
		mne = Minereum(0x7eE48259C4A894065d4a5282f230D00908Fd6D96);
		owner = payable(msg.sender);
		rng = new RNG(1588447830, previousEndPeriod, address(this));
	}
	
	receive() external payable { }
    
	
    function BuyTickets(address _sender, uint256[] memory _max) public payable returns (uint256)
    {
		require(msg.sender == address(mne));
		
		if (block.timestamp > previousEndPeriod)
		{
			//Some sort of security to prevent miners from hacking block.timestamp. Contract Valid for 1 month. 
			//After 1 month a new RNG contract is generated automatically in the first call
			rng = new RNG(previousEndPeriod, (previousEndPeriod + 2629743), address(this));
		}		
        
		bool win = false;
		
		uint[] memory numbers = new uint[](_max[0]);
		
		(numbers, win) = rng.rng(_max[0], systemNumber, maxNumber, _sender);
		
		uint valueStakeHolder = msg.value * stakeHoldersfee / 100;
		
        if (win)
		{
			address payable add = payable(_sender);
			uint contractBalance = address(this).balance;
			emit Numbers(msg.sender, numbers, "You WON!");
			uint winAmount = contractBalance * percentWin / 100;
			uint totalToPay = winAmount - stakeHoldersfee;
			if (!add.send(totalToPay)) revert('Error While Executing Payment.');
			totalPaidOut += totalToPay;
			winner.push(_sender);
			winnerTickets.push(_max[0]);
			winnerETHAmount.push(totalToPay);
			winnerTimestamp.push(block.timestamp);
		}
        else
		{	
			lost.push(_sender);
			lostTickets.push(_max[0]);
			lostTimestamp.push(block.timestamp);
            emit Numbers(msg.sender, numbers, "Your numbers don't match the System Number! Try Again.");
		}
		ticketsSold += _max[0];
		
		uint totalEthfee = ethfee * _max[0];
		uint totalMneFee = mnefee * _max[0];
		if (msg.value < totalEthfee) revert('Not enough ETH.');
		mne.Payment.value(valueStakeHolder)();
		totalSentToStakeHolders += valueStakeHolder;
		
		return totalMneFee;
    }
	
	function transferFundsOut() public
	{
		if (msg.sender == owner)
		{
			address payable add = payable(msg.sender);
			uint contractBalance = address(this).balance;
			if (!add.send(contractBalance)) revert('Error While Executing Payment.');			
		}
		else
		{
			revert();
		}
	}
	
	function updateFees(uint _stakeHoldersfee, uint _mnefee, uint _ethfee) public
	{
		if (msg.sender == owner)
		{
			stakeHoldersfee = _stakeHoldersfee;
			mnefee = _mnefee;
			ethfee = _ethfee;
		}
		else
		{
			revert();
		}
	}
	
	function updateSystemNumber(uint _systemNumber) public
	{
		if (msg.sender == owner)
		{
			systemNumber = _systemNumber;
		}
		else
		{
			revert();
		}
	}
	
	function updateMaxNumber(uint _maxNumber) public
	{
		if (msg.sender == owner)
		{
			maxNumber = _maxNumber;
		}
		else
		{
			revert();
		}
	}
	
	function updateMNEContract(address _mneAddress) public
	{
		if (msg.sender == owner)
		{
			mne = Minereum(_mneAddress);
		}
		else
		{
			revert();
		}
	}
}

contract RNG
{
	address public owner;
	uint public periodStart;
	uint public periodEnd;
	
	constructor(uint _periodStart, uint _periodEnd, address _owner) public
	{
		owner = _owner;
		periodStart = _periodStart;
		periodEnd = _periodEnd;
	}
	
	function rng(uint max, uint systemNumber, uint maxNumber, address _sender) public view returns (uint[] memory, bool)
	{
		require(msg.sender == owner);
		
		//Some sort of security to prevent miners from hacking block.timestamp. Contract Valid for 1 month. 
		//After 1 month a new RNG contract is generated automatically in the first call
		if (!(block.timestamp >= periodStart && block.timestamp <= periodEnd))
			revert('wrong timestamp');		
		
		uint[] memory numbers = new uint[](max);
        uint i = 0;
        bool win = false;
		
		while (i < max)
        {	
            //Random number generation
			numbers[i] = uint256(uint256(keccak256(abi.encodePacked(block.timestamp, _sender, i)))%maxNumber);
            if (numbers[i] == systemNumber)
                win = true;
            i++;
        }
		
		return (numbers, win);
	}
}
