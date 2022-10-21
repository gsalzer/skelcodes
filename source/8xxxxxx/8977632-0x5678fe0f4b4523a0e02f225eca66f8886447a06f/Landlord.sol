/**
 *Submitted for verification at Etherscan.io on 2019-09-09
 * BEB dapp for www.betbeb.com
*/
pragma solidity^0.4.24;  
interface tokenTransfer {
    function transfer(address receiver, uint amount);
    function transferFrom(address _from, address _to, uint256 _value);
    function balanceOf(address receiver) returns(uint256);
}

contract Ownable {
  address public owner;
 
    function Ownable () public {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    /**
     * @param  newOwner address
     */
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

contract Landlord is Ownable{
    struct user{
        uint256 amount;
        uint256 PlayerOf;
        uint256 LandlordOpen;
        uint256 bz;
    }
tokenTransfer public bebTokenTransfer; //代币 
    string LandlordName;
    uint256 LandlordAmount;
    uint256 LandlordTime;
    address LandlordAddress;
    uint256 BETMIN;
    uint256 BETMAX;
    mapping(address=>user)public users;
    event bomus(address to,uint256 amountBouns,string lx);
    function Landlord(address _tokenAddress){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
     }
     function BetLandlord(uint256 _value,uint256 _amount) public{
         require(tx.origin == msg.sender);
         user storage _user=users[msg.sender];
         uint256 amount=_amount* 10 ** 18;//下注金额
         uint256 _time=now;//现在时间戳
         uint256 Player=_value;//玩家出石头或者剪刀或者布1=石头，2=剪刀，3=布
         require(amount>=BETMIN && amount<=BETMAX);//下注金额必须大于等于下限，小于等于上限
         require(LandlordAmount>=amount);//下注金额必须大于等于地主余额
         require(amount>0);//下注金额必须大于0
         bebTokenTransfer.transferFrom(msg.sender,address(this),amount);
         uint256 _amoun=amount*96/100;//需要赔付的金额
         uint256 _amountt=amount*98/100;//需要赔付的金额
         uint256 random2 = random(block.difficulty+_time+amount*91/100);
         if(random2==1){//判断如果地址是1=石头
             if(Player==1){
                 _user.PlayerOf=Player;//记录玩家出拳
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=2;
                 //如果玩家也是1石，那么就是和，资金100%原路退回
                 bebTokenTransfer.transfer(msg.sender,amount);
             }
             if(Player==2){
                 _user.PlayerOf=Player;//记录玩家出拳
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=1;
                 //如果玩家也是2剪刀，那么玩家输了
                 LandlordAmount+=_amountt;//地主余额增加
             }
             if(Player==3){
                 _user.PlayerOf=Player;//记录玩家出拳
                 _user.amount=_amoun;
                 _user.LandlordOpen=random2;
                 _user.bz=0;
                 //如果玩家也是3布，那么玩家赢了
                 LandlordAmount-=_amountt;//地址余额减少
                 //赔付给玩家196%的金额
                 bebTokenTransfer.transfer(msg.sender,amount+_amoun);
             }
         }
         if(random2==2){//地主如果是2=剪刀
             if(Player==1){
                 _user.PlayerOf=Player;//记录玩家出拳
                 _user.amount=_amount;
                 _user.LandlordOpen=random2;
                 _user.bz=0;
                 LandlordAmount-=_amountt;//地址余额减少
                 bebTokenTransfer.transfer(msg.sender,amount+_amoun);
             }
             if(Player==2){
                 _user.PlayerOf=Player;//记录玩家出拳
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=2;
                 bebTokenTransfer.transfer(msg.sender,amount);
             }
             if(Player==3){
                 _user.PlayerOf=Player;
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=1;
                 LandlordAmount+=_amountt;
             }
         }
         if(random2==3){//如果地主是3=布
             if(Player==1){
                 _user.PlayerOf=Player;//记录玩家出拳
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=1;
                 LandlordAmount+=_amountt;//地主余额增加
             }
             if(Player==2){
                 _user.PlayerOf=Player;//记录玩家出拳
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=0;
                 LandlordAmount-=_amountt;//地址余额减少
                 bebTokenTransfer.transfer(msg.sender,amount+_amoun);
             }
             if(Player==3){
                 _user.PlayerOf=Player;//记录玩家出拳
                 _user.amount=amount;
                 _user.LandlordOpen=random2;
                 _user.bz=2;
                 bebTokenTransfer.transfer(msg.sender,amount);
             }
         }
     }
     function setdizhu(uint256 _BETMIN,uint256 _BETMAX,string _name)onlyOwner{
         BETMIN=_BETMIN* 10 ** 18;
         BETMAX=_BETMAX* 10 ** 18;
         LandlordName=_name;
     }
     function QiangDiZhu(string name,uint256 amount,uint256 BETMAXs) public{
         require(tx.origin == msg.sender);
         uint256 _amount=amount* 10 ** 18;
         uint256 _BETMAX=BETMAXs* 10 ** 18;
         uint256 _time=now-LandlordTime;
         require(_amount>BETMAX && _BETMAX>BETMIN,"Must be greater than the maximum amount");//抢地主最低BETMAX
         require(LandlordAmount<BETMAX || _time >86400 || LandlordTime==0,"We can't rob landlords now");//当前地主金额少于BETMAX或者做地主时间超过24小时即可抢地主
         bebTokenTransfer.transferFrom(msg.sender,address(this),_amount);//转入BEB
         if(LandlordAmount>0){
         bebTokenTransfer.transfer(LandlordAddress,LandlordAmount);//原路退回BEB
         }
         BETMAX=_BETMAX;//最大下注金额
         LandlordAmount=_amount;//地主余额重置成新地主余额
         LandlordAddress=msg.sender;//地主地主重置成新地主
         LandlordTime=now;//做地主时间重置成现在
         LandlordName=name;//重置地主昵称
         
     }
     //退地主
     function TuiDiZhu()public{
         require(tx.origin == msg.sender);
         require(LandlordAddress==msg.sender);//必须当前地主
         //msg.sender.transfer(LandlordAmount);//所有余额转账给地主
         bebTokenTransfer.transfer(LandlordAddress,LandlordAmount);//原路退回BEB
         LandlordAmount=0;
         LandlordAddress=0;
         LandlordTime=0;
         LandlordName="空闲";
     }
     //地主充值
     function ChongZhi(uint256 _amount) public{
         require(tx.origin == msg.sender);
         require(LandlordAddress==msg.sender);//必须当前地主
         uint256 amount=_amount* 10 ** 18;
         bebTokenTransfer.transferFrom(msg.sender,address(this),amount);//转入BEB
         LandlordAmount+=amount;
     }
     function withdrawAmount(uint256 amount) onlyOwner {
        uint256 _amount=amount* 10 ** 18;
        require(getTokenBalance()>=_amount,"Insufficient contract balance");
        bebTokenTransfer.transfer(owner,_amount);//原路退回BEB
    }
    function getTokenBalance() public view returns(uint256){
         return bebTokenTransfer.balanceOf(address(this));
    }
     function getRandom()public view returns(uint256,uint256,uint256,uint256,uint256,uint256){
        user storage _user=users[msg.sender];
        //返回前端LandlordOpen地主出拳结果，玩家出拳结果，amount输赢金额
        return (_user.LandlordOpen,_user.PlayerOf,_user.amount,_user.bz,BETMIN,BETMAX);
    }
    //查询地主信息，昵称、地址、余额
    function LandlordNames()public view returns(string,address,uint256){
        return (LandlordName,LandlordAddress,LandlordAmount);
    }
     //生成随机数
     function random(uint256 randomyType)  internal returns(uint256 num){
        uint256 random = uint256(keccak256(randomyType,now));
         uint256 randomNum = random%4;
         if(randomNum<1){
             randomNum=1;
         }
         if(randomNum>3){
            randomNum=3; 
         }
         
         return randomNum;
    }
    function ()payable{
        
    }
}
