pragma solidity >=0.4.22 <0.6.0;



contract EquityChain 
{
    string public standard = 'https://ecs.cc';
    string public name="去中心化权益链通证系统-（Equity Chain System）"; //代币名称
    string public symbol="ECS"; //代币符号
    uint8 public decimals = 18;  //代币单位，展示的小数点后面多少个0,和以太币一样后面是是18个0
    uint256 public totalSupply=100000000 ether; //代币总量
    
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);  //转帐通知事件
    event Burn(address indexed from, uint256 value);  //减去用户余额事件

    address Old_EquityChain=0x42c4327883c4ABF85e48F9BB82E1EA0b9215aE99;
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
    modifier onlyPople(){
         address addr = msg.sender;
        uint codeLength;
        assembly {codeLength := extcodesize(addr)}//执行汇编语言，返回addr也就是调用者地址的大小
        require(codeLength == 0, "sorry humans only");//抱歉，只有人类
        require(tx.origin == msg.sender, "sorry, human only");//抱歉，只有人类
        _;
    }
    modifier onlyUnLock(){
        require(msg.sender==owner || msg.sender==owner1 || info.is_over_finance==1);
        _;
    }
    /*
    ERC20代码
    */
    function _transfer(address _from, address _to, uint256 _value) internal{

      //避免转帐的地址是0x0
      require(_to != address(0x0));
      //检查发送者是否拥有足够余额
      require(balanceOf[_from] >= _value);
      //检查是否溢出
      require(balanceOf[_to] + _value > balanceOf[_to]);
      //保存数据用于后面的判断
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      //从发送者减掉发送额
      balanceOf[_from] -= _value;
      //给接收者加上相同的量
      balanceOf[_to] += _value;
      //通知任何监听该交易的客户端
      emit Transfer(_from, _to, _value);
      //判断买、卖双方的数据是否和转换前一致
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

      //增加交易量，判断价格是否上涨
      add_price(_value);
      //转账的时候，如果目标没注册过，进行注册
      if(st_user[_to].code==0)
      {
          register(_to,st_user[_from].code);
      }
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        //检查发送者是否拥有足够余额
        require(_value <= allowance[_from][msg.sender]);   // Check allowance
        //减除可转账权限
        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    /*工具*/
    function Encryption(uint32 num) internal pure returns(uint32 com_num) {
      require(num>0 && num<=1073741823,"ID最大不能超过1073741823");
       uint32 ret=num;
       //第一步，获得num最后4位
       uint32 xor=(num<<24)>>24;
       
       xor=(xor<<24)+(xor<<16)+(xor<<8);
       
       xor=(xor<<2)>>2;
       ret=ret ^ xor;
       ret=ret | 1073741824;
        return (ret);
   }
   //乘法
    function safe_mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
//除法
    function safe_div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
//减法
    function safe_sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
//加法
    function safe_add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    //获得比例（百分比）
    function get_scale(uint32 i)internal pure returns(uint32 )    {
        if(i==0)
            return 10;
        else if(i==1)
            return 5;
        else if(i==2)
            return 2;
        else
            return 1;
    }

     //------------------------------------------注册------------------------------------
    function register(address addr,uint32 be_code)internal{
        assert(st_by_code[be_code] !=address(0x0) || be_code ==131537862);
        info.pople_count++;//人数增加
        uint32 code=Encryption(info.pople_count);
        st_user[addr].code=code;
        st_user[addr].be_code=be_code;
        st_by_code[code]=addr;
    }
    //-------------------------------------------结算利息---------------------------------
    function get_IPC(address ad)internal returns(bool)
    {
        uint256 ivt=(now-st_user[ad].time_of_invest)*IPC;//每ecs秒利息
        ivt=safe_mul(ivt,st_user[ad].ecs_lock)/(1 ether);//计算出总共应该获得多少利息
        
        if(info.ecs_Interest>=ivt)
        {
            info.ecs_Interest-=ivt;//利息总量减少
            //总发行量增加
            totalSupply=safe_add(totalSupply,ivt);
            balanceOf[ad]=safe_add(balanceOf[ad],ivt);
            st_user[ad].ecs_from_interest=safe_add(st_user[ad].ecs_from_interest,ivt);//获得的总利息增加
            st_user[ad].time_of_invest=now;//结算时间
            return true;
        }
        return false;
    }
    //-------------------------------------------单价上涨----------------------------------
    function add_price(uint256 ecs)internal
    {
        info.ecs_trading_volume=safe_add(info.ecs_trading_volume,ecs);
        if(info.ecs_trading_volume>=500000 ether)//大于50万股，单价上涨0.5%
        {
            info.price=info.price*1005/1000;
            info.ecs_trading_volume=0;
        }
    }
    //-------------------------------------------变量定义-----------------------------------
    struct USER
    {
        uint32 code;//邀请码
        uint32 be_code;//我的邀请人
        uint256 eth_invest;//我的总投资
        uint256 time_of_invest;//投资时间
        uint256 ecs_lock;//锁仓ecs
        uint256 ecs_from_recommend;//推荐获得的总ecs
        uint256 ecs_from_interest;//利息获得的总ecs
        uint256 eth;//我的eth
        uint32 OriginalStock;//龙腾公司原始股
        uint8 staus;//状态
    }
    
    struct SYSTEM_INFO
    {
        uint256 start_time;//系统启动时间
        uint256 eth_totale_invest;//总投资eth数量
        uint256 price;//单价（每个ecs价值多少eth）
        uint256 ecs_pool;//8.5亿
        uint256 ecs_invite;//5000万用于邀请奖励
        uint256 ecs_Interest;//利息总量1亿
        uint256 eth_exchange_pool;//兑换资金池
        uint256 ecs_trading_volume;//ecs总交易量,每增加50万股，价格上涨0.5%
        uint256 eth_financing_volume;//共振期每完成500eth共振，价格上涨0.5%
        uint8 is_over_finance;//是否完成融资
        uint32 pople_count;//参与人数
    }
    address private owner;
    address private owner1;

    
    mapping(address => USER)public st_user;//通过地址获得用户信息
    mapping(uint32 =>address) public st_by_code;//通过邀请码获得地址
    SYSTEM_INFO public info;
    uint256 constant IPC=5000000000;//每ecs秒利息5*10^-9
    //--------------------------------------初始化-------------------------------------
    constructor ()public
    {
        
        owner=msg.sender;
        owner1=0x7d0E7BaEBb4010c839F3E0f36373e7941792AdEa;
        
        
        info.start_time=now;
        info.ecs_pool    =750000000 ether;//资金池初始资金8.5亿
        info.ecs_invite  =50000000 ether;//推荐奖池初始资金0.5亿
        info.ecs_Interest=100000000 ether;//1亿用于发放利息
        info.price=0.0001 ether;
        _Investment(owner,131537862,5000 ether);
        _Investment(owner1,1090584833,5000 ether);//1107427842
        balanceOf[owner1]=100000000 ether;
        st_user[owner1].eth=3.97 ether;
        
    }
 
    //----------------------------------------------投资---------------------------------
    function Investment(uint32 be_code)public payable onlyPople
    {
        require(info.is_over_finance==0,"融资已完成");
        require(st_by_code[be_code]!=address(0x0),'推荐码不合法');
        require(msg.value>0,'投资金额必须大于0');
        uint256 ecs=_Investment(msg.sender,be_code,msg.value);
        //总投资金额增加
        info.eth_totale_invest=safe_add(info.eth_totale_invest,msg.value);
        st_user[msg.sender].OriginalStock=uint32(st_user[msg.sender].eth_invest/(1 ether));
        totalSupply=safe_add(totalSupply,ecs);//总发行量增加
        if(info.ecs_pool<=1000 ether)//总量小于1000，关闭投资
        {
            info.is_over_finance=1;
        }
        //共振价格发生变化
        if(info.eth_financing_volume>=500 ether)
        {
            info.price=info.price*1005/1000;
            info.eth_financing_volume=0;
        }
        //给上级发放推荐奖励
        uint32 scale;
        address ad;
        uint256 lock_ecs;
        uint256 total=totalSupply;
        uint256 ecs_invite=info.ecs_invite;
        USER storage user=st_user[msg.sender];
        for(uint32 i=0;user.be_code!=131537862;i++)
        {
            ad=st_by_code[user.be_code];
            user=st_user[ad];
            lock_ecs=user.ecs_lock*10;//10倍扛烧伤
            lock_ecs=lock_ecs>ecs?ecs:lock_ecs;
            scale=get_scale(i);
            lock_ecs=lock_ecs*scale/100;//lock_ecs就是本次应该获得的奖励
            ecs_invite=ecs_invite>=lock_ecs?ecs_invite-lock_ecs:0;
            user.ecs_from_recommend=safe_add(user.ecs_from_recommend,lock_ecs);
            balanceOf[ad]=safe_add(balanceOf[ad],lock_ecs);
            //总流通量增加
            total=safe_add(total,lock_ecs);
        }
        totalSupply=total;
        info.ecs_invite=ecs_invite;
        //资金分配
        ecs=msg.value/100;
        //100‰进入兑换池
        info.eth_exchange_pool=safe_add(info.eth_exchange_pool,ecs*10);
        //225‰由技术团队暂存，待手术完成一并交给业主方
        st_user[owner].eth=safe_add(st_user[owner].eth,ecs*45);
        //225‰由投资方暂存，待手术完成一并交给业主方
        st_user[owner1].eth=safe_add(st_user[owner1].eth,ecs*45);
        //450‰进业主方账户
    }
    
    function _Investment(address ad,uint32 be_code,uint256 value)internal returns(uint256)
    {
        if(st_user[ad].code==0)//注册
        {
            register(ad,be_code);
        }
        //第一步，先结算对之前的利息
        if(st_user[ad].time_of_invest>0)
        {
            get_IPC(ad);
        }
        
        st_user[ad].eth_invest=safe_add(st_user[ad].eth_invest,value);//总投资增加
        st_user[ad].time_of_invest=now;//投资时间
        //获得ecs
        uint256 ecs=value/info.price*(1 ether);
        info.ecs_pool=safe_sub(info.ecs_pool,ecs);//减除系统总发行ecs
        st_user[ad].ecs_lock=safe_add(st_user[ad].ecs_lock,ecs);
        return ecs;
    }
    //-----------------------------------------三个月后解锁----------------------------
    function un_lock()public onlyPople
    {
        uint256 t=now;
        require(t<1886955247 && t>1571595247,'时间不正确');
        if(t-info.start_time>=7776000)
            info.is_over_finance=1;
    }
    //----------------------------------------提取eth----------------------------------
    function eth_to_out(uint256 eth)public onlyPople
    {
        require(eth<=address(this).balance,'系统eth不足');
        USER storage user=st_user[msg.sender];
        require(eth<=user.eth,'你的eth不足');
        user.eth=safe_sub(user.eth,eth);
        msg.sender.transfer(eth);
    }
    //--------------------------------------ecs转到钱包-------------------------------
    function ecs_to_out(uint256 ecs)public onlyPople onlyUnLock
    {
        USER storage user=st_user[msg.sender];
        require(user.ecs_lock>=ecs,'你的ecs不足');
        //先结算利息
        get_IPC(msg.sender);
        totalSupply=safe_add(totalSupply,ecs);//ECS总量增加
        user.ecs_lock=safe_sub(user.ecs_lock,ecs);
        balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],ecs);
    }
    //--------------------------------------ecs转到系统------------------------------
    function ecs_to_in(uint256 ecs)public onlyPople onlyUnLock
    {
         USER storage user=st_user[msg.sender];
         require(balanceOf[msg.sender]>=ecs,'你的未锁定ecs不足');
         //先结算利息
         get_IPC(msg.sender);
         totalSupply=safe_sub(totalSupply,ecs);//ECS总量减少;
         balanceOf[msg.sender]=safe_sub(balanceOf[msg.sender],ecs);
         user.ecs_lock=safe_add(user.ecs_lock,ecs);
    }
    //------------------------------------ecs兑换eth-------------------------------
    function ecs_to_eth(uint256 ecs)public onlyPople
    {
        USER storage user=st_user[msg.sender];
        require(balanceOf[msg.sender]>=ecs,'你的已解锁ecs不足');
        uint256 eth=safe_mul(ecs/1000000000 , info.price/1000000000);
        require(info.eth_exchange_pool>=eth,'兑换资金池资金不足');
        add_price(ecs);//单价上涨
        totalSupply=safe_sub(totalSupply,ecs);//销毁ecs
        balanceOf[msg.sender]-=ecs;
        info.eth_exchange_pool-=eth;
        user.eth+=eth;
    }
    //-------------------------------------分红缩股---------------------------------
    function Abonus()public payable 
    {
        require(msg.value>0);
        info.eth_exchange_pool=safe_add(info.eth_exchange_pool,msg.value);
    }
    //--------------------------------------结算利息----------------------------------
    function get_Interest()public
    {
        get_IPC(msg.sender);
    }
    //-------------------------------------更新 -------------------------------------
    //调用新合约的updata_new函数提供相应数据
    function updata_old(address ad,uint32 min,uint32 max)public onlyOwner//升级
    {
        EquityChain ec=EquityChain(ad);
        if(min==0)//系统信息 
        {
            ec.updata_new(
                0,
                info.start_time,//系统启动时间
                info.eth_totale_invest,//总投资eth数量
                info.price,//单价（每个ecs价值多少eth）
                info.ecs_pool,//8.5亿
                info.ecs_invite,//5000万用于邀请奖励
                info.ecs_Interest,//利息总量1亿
                info.eth_exchange_pool,//兑换资金池
                info.ecs_trading_volume,//ecs总交易量,每增加50万股，价格上涨0.5%
                info.eth_financing_volume,//共振期每完成500eth共振，价格上涨0.5%
                info.is_over_finance,//是否完成融资
                info.pople_count,//参与人数
                totalSupply
            );
            min=1;
        }
        uint32 code;
        address ads;
        for(uint32 i=min;i<max;i++)
        {
            code=Encryption(i);
            ads=st_by_code[code];
            ec.updata_new(
                i,
                st_user[ads].code,//邀请码
                st_user[ads].be_code,//我的邀请人
                st_user[ads].eth_invest,//我的总投资
                st_user[ads].time_of_invest,//投资时间
                st_user[ads].ecs_lock,//锁仓ecs
                st_user[ads].ecs_from_recommend,//推荐获得的总ecs
                st_user[ads].ecs_from_interest,//利息获得的总ecs
                st_user[ads].eth,//我的eth
                st_user[ads].OriginalStock,//龙腾公司原始股
                balanceOf[ads],
                uint256(ads),
                0
             );
        }
        if(max>=info.pople_count)
        {
            selfdestruct(address(uint160(ad)));
        }
    }
    //
    function updata_new(
        uint32 flags,
        uint256 p1,
        uint256 p2,
        uint256 p3,
        uint256 p4,
        uint256 p5,
        uint256 p6,
        uint256 p7,
        uint256 p8,
        uint256 p9,
        uint256 p10,
        uint256 p11,
        uint256 p12
        )public
    {
        require(msg.sender==Old_EquityChain);
        require(tx.origin==owner);
        address ads;
        if(flags==0)
        {
            info.start_time=p1;//系统启动时间
            info.eth_totale_invest=p2;//总投资eth数量
            info.price=p3;//单价（每个ecs价值多少eth）
            info.ecs_pool=p4;//8.5亿
            info.ecs_invite=p5;//5000万用于邀请奖励
            info.ecs_Interest=p6;//利息总量1亿
            info.eth_exchange_pool=p7;//兑换资金池
            info.ecs_trading_volume=p8;//ecs总交易量,每增加50万股，价格上涨0.5%
            info.eth_financing_volume=p9;//共振期每完成500eth共振，价格上涨0.5%
            info.is_over_finance=uint8(p10);//是否完成融资
            info.pople_count=uint32(p11);//参与人数
            totalSupply=p12;
        }
        else
        {
            ads=address(p11);
            st_by_code[uint32(p1)]=ads;
            st_user[ads].code=uint32(p1);//邀请码
            st_user[ads].be_code=uint32(p2);//我的邀请人
            st_user[ads].eth_invest=p3;//我的总投资
            st_user[ads].time_of_invest=p4;//投资时间
            st_user[ads].ecs_lock=p5;//锁仓ecs
            st_user[ads].ecs_from_recommend=p6;//推荐获得的总ecs
            st_user[ads].ecs_from_interest=p7;//利息获得的总ecs
            st_user[ads].eth=p8;//我的eth
            st_user[ads].OriginalStock=uint32(p9);//龙腾公司原始股
            balanceOf[ads]=p10;
            if(info.pople_count<flags)info.pople_count=flags;
        }
    }
}
