pragma solidity ^0.5.5;
import "./FWStorage.sol";

contract FWLogic is FWStorage {
     event CollectProfit(address indexed from, uint256 staticAmount, uint256 dynamicAmount);
     event Invest(address indexed from, uint256 amount, uint64 referCode);
     event AppendInvest(address indexed from, uint256 amount);
     event UserWithdraw(address indexed from, uint amount);
     
        //可以接收以太币的特殊函数(payable)
    function() payable external{
        ethMissPool = SafeMath.add(ethMissPool,msg.value);
    }
    function transferOwnership(address newOwner) public isOwner {
		require(newOwner != address(0x0), "Ownable: new owner is the zero address");
		_owner = newOwner;
	}
    /**
     * 投资eth
     * referrNO:6位邀请码
     * 转入ETH到合约储存池
     */
    function invest(uint64 referrNO)public payable{

        require(msg.value >= minInvest, "less than min");
        require (SafeMath.add(msg.value, totalInvestAmount) <= getCapacity(), "more than capacity");
        User storage o_user = addressToUser[msg.sender];
        require(SafeMath.add(msg.value, o_user.investAmount) <= maxInvest, "more than max");

        if (o_user.inviter == address(0x0)){
            //初次投资
            address r_address =  codeToAddress[referrNO];
            require (r_address != address(0x0), "invalid referrNO");
            User  storage r_user = addressToUser[r_address];
            r_user.children.push(msg.sender);
            o_user.birth = now;
            o_user.inviter = r_user.userAddress;
            o_user.userAddress = msg.sender;
            codeToAddress[currentReferCode] = msg.sender;
            o_user.referCode = currentReferCode;
            currentReferCode = currentReferCode + 9;
            investors.push(msg.sender);
            globalNodeNumber = globalNodeNumber + 1;
            r_user.invitersCount = SafeMath.add(r_user.invitersCount , msg.value);
             r_user.achieveTime = now;
             battleWithTop(r_address);
             emit Invest(msg.sender, msg.value, referrNO);
        }else{
            //原来投资过的人
            haveFun();
            address r_address = o_user.inviter;
            User  storage r_user = addressToUser[r_address];
            r_user.invitersCount = SafeMath.add(r_user.invitersCount , msg.value);
            r_user.achieveTime = now;
            battleWithTop(r_address);
            emit AppendInvest(msg.sender, msg.value);
        }
        o_user.investAmount = SafeMath.add(o_user.investAmount, msg.value);
        o_user.allInvestAmount = SafeMath.add(o_user.allInvestAmount, msg.value);
        o_user.rebirth = now;

        
    totalInvestAmount = totalInvestAmount + msg.value;
    address payable payFoundingPool = address(uint160(foundingPool));
    payFoundingPool.transfer(SafeMath.div( msg.value, 100));
    address payable payAppFund = address(uint160(appFund));
    payAppFund.transfer(SafeMath.div( msg.value, 50));
    racePool = SafeMath.add(racePool, SafeMath.div(msg.value, 100));
    }
    function battleWithTop(address _add) public{
         User memory challenger = addressToUser[_add];
         address minAdd = topUsers[8];
         User memory minWinner = addressToUser[minAdd];
         if (challenger.invitersCount <= minWinner.invitersCount){
             return;
         }
        uint hitIndex = 100;
        for (uint h = 0; h < 9; h++){
            address winnerAdd = topUsers[h];
            if (winnerAdd == _add){
                hitIndex = h;
                break;
            }
        }
        if (hitIndex < 9){ 
            //hitted
           
            for (uint g = hitIndex; g > 0; g--){
                address winnerAdd = topUsers[g - 1];
                User memory winner = addressToUser[winnerAdd];
                if (challenger.invitersCount > winner.invitersCount){
                   //change index;
                   topUsers[g] = topUsers[g - 1];
                   topUsers[g - 1] = _add;
                }
            }
        }else {
       
            uint index = 100;
            for (uint i = 0; i < 9; i ++){
                address winnerAdd = topUsers[i];
                User memory winner = addressToUser[winnerAdd];
                if (challenger.invitersCount > winner.invitersCount){
                    index = i;
                    break;
                }
             }
             if (index < 9){
                for (uint j = 8; j > index; j--){
                 topUsers[j] = topUsers[j - 1];
                 }
                 topUsers[index] = _add;
             }
             
             
            }
    }
    function getCapacity() public view returns (uint) {
        uint ages = (SafeMath.div(SafeMath.sub(now , contractBirthDay), oneLoop)) + 1;
        uint capacity =  (11 ** ages) * 10000 / (10 ** ages) - 10000;
        return capacity * 1 ether;
    }
     function happy() public{
         
        User storage _user = addressToUser[msg.sender];
        require(!_user.inserted, "can't withdraw form insert");
        uint payAmount = _user.investAmount;
        require (payAmount > 0, "no amount");
        uint ages = SafeMath.div(SafeMath.sub(now , _user.birth), oneLoop);
        uint residue = ages % (roundOfLoop + 1);
        require (residue == roundOfLoop, "not today");
        address payable needPay = address(uint160(_user.userAddress));
        _user.investAmount = 0;
        uint ring = SafeMath.div(ages, (roundOfLoop + 1));
        if (ring > 3){
            needPay.transfer(SafeMath.mul(SafeMath.div(payAmount,100), 95));
            address payable pool = address(uint160(guaranteePool));
            pool.transfer(SafeMath.mul( SafeMath.div(payAmount,100),5));
        }else if (ring > 2){
            needPay.transfer(SafeMath.mul(SafeMath.div(payAmount,100), 90));
            address payable pool = address(uint160(guaranteePool));
            pool.transfer(SafeMath.mul( SafeMath.div(payAmount,100),10));
        }else if (ring > 1){
            needPay.transfer(SafeMath.mul(SafeMath.div(payAmount,100), 85));
            address payable pool = address(uint160(guaranteePool));
            pool.transfer(SafeMath.mul( SafeMath.div(payAmount,100),15));
        }else {
            needPay.transfer(SafeMath.mul(SafeMath.div(payAmount,100), 80));
            address payable pool = address(uint160(guaranteePool));
            pool.transfer(SafeMath.mul( SafeMath.div(payAmount,100),20));
        }
        emit UserWithdraw(msg.sender, payAmount);
    }
    function haveFun() public {
        
        User storage _user = addressToUser[msg.sender];
        uint sAmount = getLiveStaticProfit(msg.sender);
        uint dAmount = getLiveDynamicProfit(msg.sender);
        _user.gottenStaticProfit = SafeMath.add(_user.gottenStaticProfit, sAmount);
        _user.gottenDynamicProfit = SafeMath.add(_user.gottenDynamicProfit, dAmount);
        _user.rebirth = now;
        msg.sender.transfer(SafeMath.add(sAmount, dAmount));
                 //动态奖励
        if (dAmount > 0){
            address payable safePool = address(uint160(fusePool));
            safePool.transfer(SafeMath.div(dAmount, 5));
        }
        emit CollectProfit(msg.sender, sAmount, dAmount);
    }
    function getLast10Children(address _par)public view returns(address[] memory){
         User memory _user = addressToUser[_par];
         if (_user.children.length >= 10) {
             address[] memory last10 = new address[](10);
             uint j = 0;
             for (uint i = _user.children.length - 10; i < _user.children.length;i++){
                 last10[j] = _user.children[i];
                 j++;
             }
             return last10;
         }else {
             return _user.children;
         }
    }
    function getOneDayStatic(address _address) public view returns(uint){
        if (getLevel(_address) == 1){
             User memory _user = addressToUser[_address];
              return SafeMath.mul(SafeMath.div(_user.investAmount, 1000),13 ); //0.7%
        }else if (getLevel(_address) == 2){
             User memory _user = addressToUser[_address];
            return SafeMath.mul(SafeMath.div(_user.investAmount, 1000),12 ); //0.8%
        }else if (getLevel(_address) == 3){
               User memory _user = addressToUser[_address];
              return SafeMath.mul(SafeMath.div(_user.investAmount, 1000),11 ); //1.0%
        }else if (getLevel(_address) == 4){
              User memory _user = addressToUser[_address];
             return SafeMath.mul(SafeMath.div(_user.investAmount, 1000),11 ); //1.1%
        }
        return 0;
    }
    function getOneDayStaticPure(uint _amount) public pure returns (uint){
      
        if (_amount >= 16 ether){
             return SafeMath.mul(SafeMath.div(_amount, 1000),11 );
        }else if (_amount >= 11 ether){
             return SafeMath.mul(SafeMath.div(_amount, 1000),11 );
        }else if (_amount >= 6 ether){
             return SafeMath.mul(SafeMath.div(_amount, 1000),12 );
        }else if (_amount >= 1 ether){
            return SafeMath.mul(SafeMath.div(_amount, 1000),13);
        }   
            return 0;
    }
    function getOneDayDynamic(address _address) public view returns(uint){
        User memory _user = addressToUser[_address];
       if (getLevel(_address) == 0){
           return 0;
       }else  if (getLevel(_address) == 1){
            return getChildrenDynamic(_user.investAmount, _address, 1, 1, 0);
       }else  if (getLevel(_address) == 2){
           return  getChildrenDynamic(_user.investAmount, _address, 1, 2, 0);
       }else  if (getLevel(_address) == 3){
           return getChildrenDynamic(_user.investAmount, _address, 1, 10, 0);
       }else  if (getLevel(_address) == 4){
           return getChildrenDynamic(_user.investAmount, _address, 1, 59, 0);
       }
    }

    function getLiveStaticProfit(address _address) public view returns(uint){
        User memory _user = addressToUser[_address];
        uint times = now - _user.rebirth;
        uint minu = SafeMath.div(times, 60);
        uint profit =  SafeMath.div(SafeMath.mul(getOneDayStatic(_address), minu), 1440);
        return profit;
        
    }
    function getLiveDynamicProfit(address _address) public view returns(uint){
                User memory _user = addressToUser[_address];
        uint times = now - _user.rebirth;
        uint minu = SafeMath.div(times, 60);
        uint profit =  SafeMath.div(SafeMath.mul(getOneDayDynamic(_address), minu), 1440);
        return profit;
    }
    
    
    function getChildrenDynamic(uint adamAmount, address _par,uint8 generation,uint endGeneration, uint total) public view returns (uint){
         User memory _user = addressToUser[_par];
         address[] memory child = _user.children;
            if (child.length == 0){
                return total;
            }
            uint myTotal = 0;
          for (uint i = 0; i < child.length; i ++){
             User memory _childUser = addressToUser[child[i]];
             uint8 level = getLevel(_childUser.userAddress);
             uint rate = getDynamicRateByLevel(level, generation);
             uint staticReward = 0;
             if (adamAmount <= _childUser.investAmount){
             staticReward = getOneDayStaticPure(adamAmount);
            }else {
                staticReward = getOneDayStatic(_childUser.userAddress);
            }
             if (generation < endGeneration){
               myTotal = getChildrenDynamic(adamAmount, _childUser.userAddress, generation + 1, endGeneration, myTotal);
           }
        myTotal = myTotal + SafeMath.mul(SafeMath.div(staticReward , 100),rate);
    }
        return myTotal + total;
    }
    
    function getDynamicRateByLevel(uint8 _level, uint _generation)public pure returns (uint){
        if (_level == 1){
            if (_generation == 1){
                return 60;
            }
        }else if (_level == 2){
            if (_generation == 1){
            return 70;
        }else if (_generation == 2){
             return 30;
        }
        }else if (_level == 3){
            if (_generation == 1){
              return 80;
            }else if (_generation == 2){
              return 30;
            }else if (_generation == 3){
              return 20;
            }else if (_generation <= 10){
              return 10;
            }

        }else if (_level == 4){
             if (_generation == 1){
                return 100;
            }else if (_generation == 2){
                return 40;
            }else if (_generation == 3){
                return 30;
             }else if (_generation <= 10){
                 return 10;
             }else if (_generation <= 15){
                 return 5;
             }else if (_generation <= 99){
              return 1; 
         }
         }
        return 0;
    }

    function canHappyU(address _add)public view returns(uint){
        User storage _user = addressToUser[_add];
        uint ages = SafeMath.div(SafeMath.sub(now , _user.birth), oneLoop);
        uint residue = ages % (roundOfLoop + 1);
        if (residue == roundOfLoop){
            return 1;
        }else {
            return 2;
        }
        
    }

    function getLevel(address _address) public view returns(uint8){
        User memory _user = addressToUser[_address];
        if (_user.investAmount >= 16 ether){
            return 4;
        }else if (_user.investAmount >= 11 ether){
             return 3;
        }else if (_user.investAmount >= 6 ether){
             return 2;
        }else if (_user.investAmount >= 1 ether){
            return 1;
        }   
            return 0;
    }
    function getTeamScore(address _address)public view returns (uint256){
        return getChildrenTeamScore(_address, 1, 59, 0);
    }

    function getChildrenTeamScore(address _par,uint8 generation,uint endGeneration, uint total) public view returns (uint){

         User memory _user = addressToUser[_par];
         address[] memory child = _user.children;
            if (child.length == 0){
            return total;
        }
        uint myTotal = 0;
        for (uint i = 0; i < child.length; i ++){
             User memory _childUser = addressToUser[child[i]];
             uint amount = _childUser.allInvestAmount;
             if (generation < endGeneration){
               myTotal = getChildrenTeamScore(_childUser.userAddress, generation + 1, endGeneration, myTotal);
             }
        myTotal = myTotal + amount;
      }
        return myTotal + total;
    }
    function sendRace() public isOwner{
//发放竞赛奖励,每月一次
        address[] memory top10 = topUsers;
        uint256[9] memory rate = [uint256(40),20,10,5,5,5,5,5,5];
        uint256 sendedAmount = 0;
        for (uint i = 0; i < 10; i ++){
            address _add = top10[i];
            if (_add != address(0x0)){
                User memory _user = addressToUser[_add];
                if (_user.invitersCount != 0){
                    address payable needPay = address(uint160(_user.userAddress));
                    needPay.transfer(SafeMath.mul(SafeMath.div(racePool, 100), rate[i]));
                    sendedAmount = sendedAmount + SafeMath.mul(SafeMath.div(racePool, 100), rate[i]);
                }
            }
        }
        racePool = SafeMath.sub(racePool, sendedAmount);
    }
    function getTopInfo (uint rank)public view returns(address, uint, uint){
        address _add = topUsers[rank];
         if (_add == address(0x0)){
             return(address(0x0),0,0);
           }else {
         User memory userRank = addressToUser[_add];
         return (userRank.userAddress,userRank.children.length,userRank.invitersCount);
      }
    }
    function resetRace(uint _from, uint _to) public isOwner{
        for (uint i = _from; i < _to; i ++){
            User storage _user = addressToUser[investors[i]];
            _user.invitersCount = 0;
        }
    }
    
  
}
