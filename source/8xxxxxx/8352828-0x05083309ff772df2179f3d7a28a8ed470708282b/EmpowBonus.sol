pragma solidity ^0.5.10;

contract EmpowBonus {
    
    event Bonus(address indexed _address, uint32 indexed dapp_id, uint256 _time, uint256 _amount);
    
    struct BonusHistory {
        address user;
        uint32 dapp_id;
        uint256 time;
        uint256 amount;
    }
    
    mapping (address => uint256) public countBonus;
    mapping (address => mapping (uint256 => BonusHistory)) public bonusHistories;
    
    address payable owner;
    
    modifier onlyOwner () {
        require(msg.sender == owner, "owner require");
        _;
    }
    
    constructor ()
        public
    {
        owner = msg.sender;
    }
    
    function bonus (uint32 _dapp_id)
        public
        payable
        returns(bool)
    {
        require(msg.value > 0);
        
        countBonus[msg.sender]++;
        
        uint256 currentTime = block.timestamp;
        
        emit Bonus(msg.sender, _dapp_id, currentTime, msg.value);
        saveHistory(msg.sender, _dapp_id, currentTime, msg.value);
        
        return true;
    }
    
    function saveHistory (address _address, uint32 _dapp_id, uint256 _time, uint256 _amount)
        private
        returns(bool)
    {
        bonusHistories[msg.sender][countBonus[_address]].user = _address;
        bonusHistories[msg.sender][countBonus[_address]].dapp_id = _dapp_id;
        bonusHistories[msg.sender][countBonus[_address]].time = _time;
        bonusHistories[msg.sender][countBonus[_address]].amount = _amount;
        return true;
    }
    
}
