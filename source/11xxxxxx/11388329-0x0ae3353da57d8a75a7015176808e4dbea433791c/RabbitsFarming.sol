pragma solidity 0.5.17;

import "./Ownable.sol";
import "./Rabbits.sol";
import "./MorpheusToken.sol";
import "./SafeMath.sol";

contract RabbitsFarming is Ownable {
    
    using SafeMath for uint256;
    
    // Tokens used in the farming
    Rabbits public rabbits;
    MorpheusToken public morpheus;
    
    constructor(Rabbits _rabbits, MorpheusToken _morpheusToken) public{
        //init Rabbits token address
        setRabbitsToken(_rabbits);
        setMorpheusToken(_morpheusToken);
    }
    
    // Rabbits farming variable
    mapping(uint256 => bool) public canBeFarmed;
    mapping(uint256 => bool) public farmed;
    // Rabbit who is farming
    mapping(uint256 => bool) public onFarming;
    // address who farm the rabbit
    mapping(uint256 => address) private _farmingBy;
    
    // array of spots for Rabbits can be farmed
    uint256[] private _spots;
    
    // Number of MGT Locked on stacking
    uint256 public MGTStackedOnFarming;
    
    // Time for farming
    uint256 public whiteRabbitsFarmingTime = 30 days;
    uint256 public blueRabbitsFarmingTime = 20 days;
    uint256 public redRabbitsFarmingTime = 10 days;
    
    // Amount for farming Values will and can change 
    uint256 public amountForWhiteRabbits = 100000; 
    uint256 public amountForBlueRabbits = 50000;
    uint256 public amountForRedRabbits = 25000;
 
    
    // =========================================================================================
    // Setting Tokens Functions
    // =========================================================================================

    
    // Set the RabbitToken address
    function setRabbitsToken(Rabbits _rabbits) public onlyOwner() {
        rabbits = _rabbits;
    }
    
    // Set the MorpheusToken address
    function setMorpheusToken(MorpheusToken _morpheusToken) public onlyOwner() {
        morpheus = _morpheusToken;
    }
    
    
    // =========================================================================================
    // Setting Farming conditions
    // =========================================================================================


    //functions for setting time needed for farming a rabbit
    function setFarmingTimeWhiteRabbits(uint256 _time) public onlyOwner(){
        whiteRabbitsFarmingTime = _time;
    }
    
    function setFarmingTimeBlueRabbits(uint256 _time) public onlyOwner(){
        blueRabbitsFarmingTime = _time;
    }
    
    function setFarmingTimeRedRabbits(uint256 _time) public onlyOwner(){
        redRabbitsFarmingTime = _time;
    }
    
    //setting amount MGT needed for farming a rabbit
    function setAmountForFarmingWhiteRabbit(uint256 _amount) public onlyOwner(){
        amountForWhiteRabbits = _amount;
    }
    
    function setAmountForFarmingBlueRabbit(uint256 _amount) public onlyOwner(){
        amountForBlueRabbits = _amount;
    }
    
    function setAmountForFarmingRedRabbit(uint256 _amount) public onlyOwner(){
        amountForRedRabbits = _amount;
    }
    
    // =========================================================================================
    // Setting Rabbits ID can be farmed
    // =========================================================================================

    // Create a spot for a rabbit who can be farmed
    function setRabbitIdCanBeFarmed(uint256 _id) public onlyOwner(){
        require(_id>=1 && _id<=160);
        require(farmed[_id] == false,"Already farmed");
        canBeFarmed[_id] = true;
        _spots.push(_id);
    }
    
    // =========================================================================================
    // Farming
    // =========================================================================================

    struct farmingInstance {
        uint256 rabbitId;
        uint256 farmingBeginningTime;
        uint256 amount;
        bool isActive;
    }
    
    // 1 address can only farmed 1 rabbit for a period
    mapping(address => farmingInstance) public farmingInstances;

    // init a farming 
    function farmingRabbit(uint256 _id) public{
        require(canBeFarmed[_id] == true,"This Rabbit can't be farmed");
        require(morpheus.balanceOf(msg.sender) > _rabbitAmount(_id), "Value isn't good");
        delete _spots[_getSpotIndex(_id)];
        canBeFarmed[_id] = false;
        morpheus.transferFrom(msg.sender,address(this),_rabbitAmount(_id).mul(1E18));
        farmingInstances[msg.sender] = farmingInstance(_id,now,_rabbitAmount(_id),true);
        MGTStackedOnFarming = MGTStackedOnFarming.add(_rabbitAmount(_id));
    }
    
    // cancel my farming instance
    function renounceFarming() public {
        require(farmingInstances[msg.sender].isActive == true, "You don't have any farming instance");
        morpheus.transferFrom(address(this),msg.sender,farmingInstances[msg.sender].amount.mul(1E18));
        canBeFarmed[farmingInstances[msg.sender].rabbitId] = false;
        delete farmingInstances[msg.sender];
        _spots.push(farmingInstances[msg.sender].rabbitId);
        MGTStackedOnFarming = MGTStackedOnFarming.sub(_rabbitAmount(farmingInstances[msg.sender].rabbitId));
        
    }
    
    // Claim rabbit at the end of farming
    function claimRabbit() public {
        require(farmingInstances[msg.sender].isActive == true, "You don't have any farming instance");
        require(now.sub(farmingInstances[msg.sender].farmingBeginningTime) >= _rabbitDuration(farmingInstances[msg.sender].rabbitId));
        
        morpheus.transferFrom(address(this),msg.sender,farmingInstances[msg.sender].amount.mul(1E18));
        farmed[farmingInstances[msg.sender].rabbitId] = true;
        rabbits.mintRabbit(msg.sender, farmingInstances[msg.sender].rabbitId);
        delete farmingInstances[msg.sender];
        MGTStackedOnFarming = MGTStackedOnFarming.sub(_rabbitAmount(farmingInstances[msg.sender].rabbitId));
    }
    
    // function allow to now the necessary amount for the Rabbit farming
    function _rabbitAmount(uint256 _id) private view returns(uint256){
        // function will return amount needed to farm rabbit
        uint256 _amount;
        if(_id >= 1 && _id <= 10){
            _amount = amountForWhiteRabbits;
        } else if(_id >= 11 && _id <= 60){
            _amount = amountForBlueRabbits;
        } else if(_id >= 61 && _id <= 160){
            _amount = amountForRedRabbits;
        }
        return _amount;
    }
    
     // function allow to now the necessary time for the Rabbit farming
    function _rabbitDuration(uint256 _id) private view returns(uint256){
        // function will return amount needed to farm rabbit
        uint256 _duration;
        if(_id >= 1 && _id <= 10){
            _duration = whiteRabbitsFarmingTime;
        } else if(_id >= 11 && _id <= 60){
            _duration = blueRabbitsFarmingTime;
        } else if(_id >= 61 && _id <= 160){
            _duration = redRabbitsFarmingTime;
        }
        return _duration;
    }
    
    function _getSpotIndex(uint256 _id) private view returns(uint256){
        uint256 index;
        for( uint256 i = 0 ; i< _spots.length ; i++){
            if(_spots[i] == _id){
                index = i;
                break;
            }
        }
        return index;
    }
    
    // return spots of farming
    function rabbitsSpot() public view returns(uint256[] memory spots){
        return _spots;
    }
    
    // winner of contests will receive rabbits
    function mintRabbitFor(uint256 _id, address _winner ) public onlyOwner(){
        require(farmed[_id]==false);
        farmed[_id] = true;
        rabbits.mintRabbit(_winner,_id);
    }

    
}

