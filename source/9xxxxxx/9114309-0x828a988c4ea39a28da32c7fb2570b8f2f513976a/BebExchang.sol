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

contract BebExchang is Ownable{
    uint256 BEBMIN;//买卖最小数量
    uint256 BEBMAX;//买卖最大数量
    uint256 BEBjiage;//最新价格
    uint256 sellAmount;//卖出总量
    uint256 buyAmount;//买入总量
    uint256 sumAmount;//历史成交总金额
    struct userSell{
        uint256 amount;//总金额
        uint256 value;//数量
        uint256 exbl;//汇率比例
        bool vote;//状态
    }
    struct userBuy{
        uint256 amount;//总金额
        uint256 exbl;//beb-ETH
        uint256 value;//数量
        bool vote;//状态
    }
    mapping(address=>userSell)public userSells;
    mapping(address=>userBuy)public userBuys;
    tokenTransfer public bebTokenTransfer; //代币
    function BebExchang(address _tokenAddress){
         bebTokenTransfer = tokenTransfer(_tokenAddress);
     }
     //卖出订单的参数价格_amount、_value需要乘方后传给合约
     function sellGD(uint256 _amount,uint256 _value)public{
         require(tx.origin == msg.sender);
         userSell storage _user=userSells[msg.sender];
         require(!_user.vote,"Please cancel the order first.");
         require(_amount>0 & _value,"No 0");
         require( _value>=BEBMIN,"Not less than the lower limit of sale！");
         require( _value<=BEBMAX,"No higher than the sale ceiling！");
         uint256 _exbl=1000000000000000000/_amount;//计算汇率
         uint256 _eth=_value/_exbl;
         bebTokenTransfer.transferFrom(msg.sender,address(this),_value);//转入BEB
         _user.amount=_eth;
         _user.value=_value;
         _user.exbl=_exbl;
         _user.vote=true;
     }
     //买入订单的参数价格_amount需要乘方后传给合约
     function BuyGD(uint256 _amount)payable public{
         require(tx.origin == msg.sender);
         userBuy storage _users=userBuys[msg.sender];
         require(!_users.vote,"Please cancel the order first.");
         require(_amount>0,"No 0");
         require( msg.value>0,"Sorry, your credit is running low");
         uint256 _amounts=msg.value;
         uint256 _exbls=1000000000000000000/_amount;//计算汇率
         uint256 bebamount=_amounts*_exbls;
         require( bebamount>=BEBMIN,"Not less than the lower limit of sale！");
         require( bebamount<=BEBMAX,"No higher than the sale ceiling！");
         _users.amount=_amounts;
         _users.exbl=_exbls;
         _users.value=bebamount;
         _users.vote=true;
     }
     //实时卖出BEB，_value需要乘方后传给合约
     function bebToSell(address addr,uint256 _value)public{
         require(tx.origin == msg.sender);
        require(addr != address(0),"Address cannot be empty");
        userBuy storage _user=userBuys[addr];
        require(_user.vote,"The opposite party can't trade without a receipt");
        require(_user.value >= _value,"No more than sellers");
        uint256 _sender=_value/_user.exbl;
        bebTokenTransfer.transferFrom(msg.sender,addr,_value);//转BEB给收购方
        msg.sender.transfer(_sender);
        BEBjiage=_user.exbl;
        _user.amount-=_sender;//递减卖家金额
        _user.value-=_value;//递减卖家BEB数量
        sellAmount+=_value;
        sumAmount+=_sender;
        if(_user.value==0){
            _user.amount=0;
            _user.exbl=0;
            _user.vote=false;
        }
     }
     //实时买入BEB
     function buyToBeb(address addr)payable public{
         require(tx.origin == msg.sender);
        require(addr != address(0),"Address cannot be empty");
        require( msg.value>0,"Sorry, your credit is running low");
        userSell storage _user=userSells[addr];
        require(_user.vote,"The opposite party can't trade without a receipt");
        uint256 amounts=msg.value;
        uint256 buyamount=_user.exbl*amounts;
        require(_user.value >= buyamount,"No more than sellers");
        bebTokenTransfer.transfer(msg.sender,buyamount);//转账给购买方
        BEBjiage=_user.exbl;
        addr.transfer(amounts);//转账ETH给出售方
        _user.amount-=amounts;//递减卖家金额
        _user.value-=buyamount;//递减卖家BEB数量
        buyAmount+=buyamount;
        sumAmount+=amounts;
        if(_user.value==0){
            _user.amount=0;
            _user.exbl=0;
            _user.vote=false;
        }
     }
     //撤卖单
     function BebSellCheDan()public{
         require(tx.origin == msg.sender);
        userSell storage _user=userSells[msg.sender];
        require(_user.vote,"You don't have a ticket！");
        bebTokenTransfer.transfer(msg.sender,_user.value);//退回BEB
        _user.value=0;
        _user.amount=0;
        _user.exbl=0;
        _user.vote=false;
     }
     //撤买单
     function BebBuyCheDan()public{
         require(tx.origin == msg.sender);
        userBuy storage _userS=userBuys[msg.sender];
        require(_userS.vote,"You don't have a ticket！");
        msg.sender.transfer(_userS.amount);//退回eth
        _userS.value=0;
        _userS.amount=0;
        _userS.exbl=0;
        _userS.vote=false; 
     }
     //修改买单价格，价格需要乘方后传入
     function BuyPriceRevision(uint256 _amount)public{
         require(tx.origin == msg.sender);
        userBuy storage _userS=userBuys[msg.sender];
        require(_userS.vote,"You don't have a ticket！");
        uint256 _exbls=1000000000000000000/_amount;//计算汇率
        uint256 _eth=_userS.value/_exbls;
        _userS.amount=_eth;
        _userS.exbl=_exbls;
     }
     //修改买单价格，价格需要乘方后传入
     function SellPriceRevision(uint256 _amount)public{
         require(tx.origin == msg.sender);
        userSell storage _userS=userSells[msg.sender];
        require(_userS.vote,"You don't have a ticket！");
        uint256 _exbls=1000000000000000000/_amount;//计算汇率
        uint256 _eth=_userS.value/_exbls;
        _userS.amount=_eth;
        _userS.exbl=_exbls;
     }
     //管理员更改交易数量的上限和下限
     function setExchangMINorMAX(uint256 _MIN,uint256 _MAX)onlyOwner{
        BEBMIN=_MIN*10**18;
        BEBMAX=_MAX*10**18;
     }
     //我的卖出挂单查询
     function MySell(address _addr)public view returns(uint256,uint256,uint256,bool){
         userSell storage _user=userSells[_addr];
        return (_user.amount,_user.value,_user.exbl,_user.vote);
    }
    //我的买入挂单查询
    function MyBuy(address _addr)public view returns(uint256,uint256,uint256,bool){
         userBuy storage _user=userBuys[_addr];
         
        return (_user.amount,_user.value,_user.exbl,_user.vote);
    }
    function BEBwithdrawAmount(uint256 amount) onlyOwner {
        uint256 _amount=amount* 10 ** 18;
        bebTokenTransfer.transfer(owner,_amount);//原路退回BEB
    }
    function withdrawEther(uint256 amount) onlyOwner{
		//if(msg.sender != owner)throw;
		owner.transfer(amount);
	}
    //交易所交易数量的下限、上限、最新成交价格、卖出总量、买入总量、历史成交金额
    function ExchangMINorMAX()public view returns(uint256,uint256,uint256,uint256,uint256,uint256){
        return (BEBMIN,BEBMAX,BEBjiage,sellAmount,buyAmount,sumAmount);
    }
    function ()payable{
        
    }
}
