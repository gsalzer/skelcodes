pragma solidity ^0.6.0;
import "./SafeMath.sol";
import "./Vars.sol";



// $$$$$$$$\                                           $$\     $$\                           $$\                     
// $$  _____|                                          $$ |    $$ |                          \__|                    
// $$ |      $$\   $$\  $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$\   $$ |       $$$$$$\   $$$$$$\  $$\  $$$$$$\  $$$$$$$\  
// $$$$$\    \$$\ $$  |$$  __$$\ $$  __$$\ $$  __$$\ \_$$  _|  $$ |      $$  __$$\ $$  __$$\ $$ |$$  __$$\ $$  __$$\ 
// $$  __|    \$$$$  / $$ /  $$ |$$$$$$$$ |$$ |  \__|  $$ |    $$ |      $$$$$$$$ |$$ /  $$ |$$ |$$ /  $$ |$$ |  $$ |
// $$ |       $$  $$<  $$ |  $$ |$$   ____|$$ |        $$ |$$\ $$ |      $$   ____|$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |
// $$$$$$$$\ $$  /\$$\ $$$$$$$  |\$$$$$$$\ $$ |        \$$$$  |$$$$$$$$\ \$$$$$$$\ \$$$$$$$ |$$ |\$$$$$$  |$$ |  $$ |
// \________|\__/  \__|$$  ____/  \_______|\__|         \____/ \________| \_______| \____$$ |\__| \______/ \__|  \__|
//                     $$ |                                                        $$\   $$ |                        
//                     $$ |                                                        \$$$$$$  |                        
//                     \__|                                                         \______/          
//Official Smart Contract

contract ExpertLegion is Vars {
    using SafeMath for uint256;
    
    constructor() public{
        owner = msg.sender;
    }
    
  
    receive() external payable{
        require(!stop);
     
        if(!users[msg.sender].isExist)
            registerUser(msg.sender, msg.value, 0);
        else 
            activateUser(msg.sender, msg.value);
    }
    
   
    function registerUser(address payable _user, uint256 _fee, bytes32 _code) public payable{
        require(_fee >= activationCharges && msg.value >= activationCharges); 
        require(!users[_user].isExist); 
        
       
        isStop();
        
      
        if(!stop){
            if(_code != 0)
                isReferred(_code);
            
            
            storeUserData(_user);
        
            
            distributeToUplines(_fee, _user);
        
            
            emit UserRegistered(_user, users[_user].level, users[_user].id, users[_user].deadline );
        } else{
            revert("game has been stopped");
        }
    }
    
    
    function storeUserData(address payable _user) internal {
        currentUserId++; 
        userList[currentUserId] = _user; 
       
        bytes32 code = generateReferral(_user);
       
        if(occupiedSlots == 3 ** (currentLevel)){ 
            currentLevel++;
            occupiedSlots = 0;
        }
        
        User memory u;
        u.isExist = true;
        u.id = currentUserId;
        u.totalReferrals = 0;
        u.deadline = now.add(activationPeriod);
        u.level = currentLevel;
        u.referralLink = code;
        
        users[_user] = u;
        
        occupiedSlots++;
    }
    
    
    function generateReferral(address _user) internal returns(bytes32){
        bytes32 id = keccak256(abi.encode(_user, currentUserId)); 
        hashedIds[id] = _user;
        return id;
    }
    
    
    function distributeToUplines(uint256 _fee, address _sender) internal { 
        require(address(this).balance >= _fee);
        
        uint256 registerChargeFee = 0.005 ether;
        uint256 ownerFunds;
        
        uint256 amountToDistributeToUplines = _fee.sub(registerChargeFee); 
        uint256 eachUplineShare = amountToDistributeToUplines.div(12);
        
        if(currentLevel == 1){
            
            ownerFunds = _fee;
        } 
        else{
            
            for(uint i = currentLevel-1; i >= 1; i--){
            
                uint256 userAmount = eachUplineShare.div(3 ** i);
            
              
                for(uint id = 1; id<= 3 ** i; id++){
                    address payable _user = userList[id + (i-1)*3]; 
                    bool _eligible = userEligible(_user, _sender);
                
                    if(_eligible){    
                        _user.transfer(userAmount);     
                        emit UserFundsTransfer(_user, userAmount, currentLevel, currentUserId);
                    } else{                         
                        ownerFunds += userAmount;      
                    }
                }
            }
            emit UplineFundsDistributed((currentLevel-1).mul(eachUplineShare), currentLevel, currentUserId);
        
           
            ownerFunds += _fee.sub((currentLevel-1).mul(eachUplineShare));
        }
        
        
        owner.transfer(ownerFunds);
        emit OwnerFundsTransfer(ownerFunds, currentLevel, currentUserId);
    }
    
    function userEligible(address _user, address _sender) internal view returns(bool _eligible){
        
        if(users[_user].deadline > now  && users[_user].level < users[_sender].level ){
            if(users[_user].totalReferrals == 1 && currentLevel <= 3)
                return true;
            else if(users[_user].totalReferrals == 2 && currentLevel <= 6)
                return true;
            else if(users[_user].totalReferrals >= 3)
                return true;
            else 
                return false;
        } 
        
        else{ 
            return false;
        }
    }
    
    
    function isReferred(bytes32 _code) internal{
        require(hashedIds[_code] != address(0));
        users[hashedIds[_code]].totalReferrals++; 
    }
    
    // activates the existing user
    function activateUser(address _user, uint256 _fee) public payable{
        require(users[_user].isExist);
        require(_fee >= activationCharges);
        
        isStop();
        
        
        if(!stop){
            users[_user].deadline = now.add(activationPeriod); 
           
            distributeToUplines(_fee, _user);
            
            emit UserActivated(_user, users[_user].level, users[_user].id, users[_user].deadline );
        } else{
            revert("game has been stopped");
        }
    }
    
    function isStop() internal{
        if(currentLevel == 12 && occupiedSlots == 3**12){
            stop = true;
        }
    }
}
