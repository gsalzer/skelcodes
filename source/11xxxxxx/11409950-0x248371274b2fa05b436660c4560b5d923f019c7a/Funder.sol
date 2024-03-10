pragma solidity >=0.4.23;

interface TokenLike {
    function transferFrom(address,address,uint) external returns (bool);
    function transfer(address,uint) external returns (bool);
}

contract Funder {
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "fun/not-authorized");
        _;
    }

    mapping (address => mapping (address => uint256)) public  allowance;
    bytes32                                           public  symbol = "fGAZ";
    uint256                                           public  decimals = 18; // standard token precision. override to customize
    bytes32                                           public  name = "fund_gaz";     // Optional token name
    mapping (address => uint256)                      public  bud;        // Whitelisted contracts, set by an auth

    TokenLike                                         public  pro;         //众筹资产
    TokenLike                                         public  gaz;         //平台币
    uint256                                           public  one = 10**18;        
    uint256                                           public  step;        //最低加价幅度
    uint256                                           public  balanc;      //拍卖余额
    uint256                                           public  depi;        //拍卖轮次
    uint256                                           public  ltim;        //释放启动时间
    uint256                                           public  Tima;        //拍卖时长
    uint256                                           public  low;         //拍卖最低出价
    uint256                                           public  timb;        //每轮拍卖启动时间
    uint256                                           public  live;        //暂停拍卖标示
    mapping(uint => uint)                             public  pta;         //价格序号
    mapping(uint => mapping(uint => uint))            public  psn;         //价格序号对应的价格
    mapping(uint => uint)                             public  Tem;         //每轮拍卖锁仓时间
    mapping(uint => uint)                             public  total;       //每轮拍卖总量
    mapping(uint => uint)                             public  sp;          //每轮拍卖起价
    mapping(address => uint)                          public  balanceOf;   //众筹总余额
    mapping(uint => mapping(address => uint))         public  balancetl;   //每轮众筹总余额
    mapping(uint => mapping(uint => uint))            public  order;       //每轮每价位众筹者编号
    mapping(uint => mapping(uint => mapping(uint => address)))        public  maid;  //每轮每价位众筹者编号对应的地址
    mapping(uint => mapping(uint => mapping(uint => uint)))           public  waid;  //每轮每价位众筹者编号对应的数量
    
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Auction(address indexed ust,uint indexed pri,uint wad);
    event Withdraw(address indexed src, uint wad);

    constructor(address _gaz,address _pro) public {
        wards[msg.sender] = 1;
        gaz = TokenLike(_gaz);
        pro = TokenLike(_pro);
    }
    // --- Math ---
    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function sub(uint x, int y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
   
    function star() external auth  returns (bool){
        ltim = now;
        return true;
    }     
    function step(uint256 _step) external auth  returns (bool){
        require(Tima < now - timb,"fund/Auction-not-closed");
        step = _step;
        return true;
    }   
    function settima(uint256 _tima) external auth  returns (bool){
        Tima = _tima;
        return true;
    }
    function approve(address guy) external returns (bool) {
        return approve(guy, uint(-1));
    } 
    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(bud[dst] == 1 || bud[msg.sender] == 1, "fund/-not-white");
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "fund/insufficient-approval");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        require(balanceOf[src] >= wad, "fund/insufficient-balance");
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function deposit(uint256 wad ,uint256 _low, uint256 _tea) public  auth returns (bool){
        require(wad > 0,"fund/not");
        require(Tima < now - timb,"fund/Auction-not-closed");
        require(gaz.transferFrom(msg.sender, address(this), wad),"fund/ds-transfer-not");
        balanc=add(balanc, wad);
        depi=add(depi,uint256(1));
        low = _low;
        timb = now;
        Tem[depi] = _tea;
        total[depi] = balanc;
        sp[depi] = _low;
        return true;
    }
    function exitpro(uint256 wad ,address usr) public  auth returns (bool){
        require(pro.transfer(usr, wad),"fund/ds-transfer-not");
        return true;
    }
    function auction(uint256 wad,uint256 pri) public  returns (bool){
        require(live == 1,"fund/Auction-pause");
        require((balanc == 0 &&  pri > low) || (balanc > 0 &&  pri >= low),"fund/Offer-too-low");
        require(wad > 0 && pri % step == 0,"fund/The minimum markup does not meet the requirements");
        require(Tima > now - timb,"fund/Auction-closed");
        uint256 bof=balanceOf[msg.sender];
        balancetl[depi][msg.sender] =add(balancetl[depi][msg.sender],wad);
        balanceOf[msg.sender]=add(balanceOf[msg.sender],wad);
        if (order[depi][pri] == 0) {
            pta[depi] += 1;
            psn[depi][pta[depi]]=pri;}
        order[depi][pri]=add(order[depi][pri],uint256(1));
        uint256 ord = order[depi][pri];
        maid[depi][pri][ord]= msg.sender;
        waid[depi][pri][ord]= wad;
        uint256 data = mul(wad,pri)/one;
        uint256 wad1;
        address usr;
        require(pro.transferFrom(msg.sender, address(this) , data),"fund/ds-transfer-not"); 
        
        //如果众筹数量小于本轮众筹余额，就从余额中扣除
        if (wad <= balanc) {
            balanc=sub(balanc,wad);
        
         //如果众筹数量大于本轮众筹余额，部分从余额中扣除，剩余数量来自于最低出价者中的最后出价者   
        }else if  (wad > balanc ){
            if  (balanc > 0) {
                 wad1 = sub(wad,balanc);
                 balanc = 0;
                 
        // 如果本轮众筹余额为零，数量来自于最低出价者中的最后出价者        
           }else if  ( balanc == 0) { 
                 wad1 = wad;
           } do {
                 while (order[depi][low] <= 0) low=add(low,step); 
                 uint256 i= order[depi][low];
                 uint256 wad2 = waid[depi][low][i];
                 usr  = maid[depi][low][i];
                 if (wad1 <= wad2) {
                     balancetl[depi][usr]=sub(balancetl[depi][usr],wad1);
                     balanceOf[usr]=sub(balanceOf[usr],wad1);
                     waid[depi][low][i] =sub(waid[depi][low][i],wad1);
                     require(pro.transfer(usr, mul(wad1,low)/one),"fund/ds-transfer-not"); 
                     wad1 = 0;
                     
         //如果最低出价者中的最后出价者数量不足，则不足部分由最低出价者中倒数第二个出价者扣除            
                }else if (wad1 > wad2) {
                     if (wad2>0) {
                     balancetl[depi][usr]=sub(balancetl[depi][usr],wad2);
                     balanceOf[usr]=sub(balanceOf[usr],wad2);
                     require(pro.transfer(usr, mul(wad2,low)/one),"fund/ds-transfer-not"); 
                     uint256 id = order[depi][low];
                     waid[depi][low][id] = 0;
                     wad1=sub(wad1,wad2);
                     }order[depi][low] =sub(order[depi][low],uint256(1));
                     
          //如果最低出价者中倒数第二个出价者余额仍然不足，则重复本轮扣除方式
          //如果最低出价者是该价位的最后一个出价者，则最低出价改为高一个价位
          //如果最低出价者是该价位的最后一个出价者，则最低出价改为高一个价位
          //如果高一个价位没有出价者，则继续高一个价位，直到一个新的出价者
          //新的最低出价者有可能是他自己，这样相当于扣除自己刚刚拍卖的数量

                }
            } while (wad1 >0);
        }
        bof = sub(balanceOf[msg.sender],bof);
        emit Auction(msg.sender,pri,bof);
        return true;
    }
    function withdraw(uint wad) external returns (bool) {
        require(balanceOf[msg.sender] >= wad, "fund/insufficient-balance");
        require(ltim != 0, "fund/Release has not been activated yet");
   
        //提现后的余额必须大于锁仓中的余额
        require(wad <= callfree(),"fund/insufficient-lock") ;
        balanceOf[msg.sender] = sub(balanceOf[msg.sender],wad);
        require(gaz.transfer(msg.sender, wad), "fund/failed-transfer");
        emit Withdraw(msg.sender, wad);
        return true;
     }
    function callfree() public view returns (uint256) {
        require(ltim != 0, "fund/Release has not been activated yet");
        uint256 dend;
        uint256 pend;
        uint256 lock; 
        if (Tima > now-timb) 
        dend = 1;
        pend = balancetl[depi][msg.sender];
        //计算每一轮拍卖被锁的数量之和  
        for (uint i = 1; i <=sub(depi,dend); i++) {
            if (balancetl[i][msg.sender]>0) {
               uint256  lte = sub(Tem[i], sub(now,ltim));
               if (lte > 0 )
               {   uint256 unc = mul(lte,balancetl[i][msg.sender])/Tem[i];
                   lock =add(lock,unc);
                }
            }
        }   
        return sub(sub(balanceOf[msg.sender],lock),pend);
     }
    function highest(uint256 _depi) public view returns(uint256){
         uint256 hig;
         for (uint i = 1; i <=pta[depi]; i++) {
              uint256 pri = psn[_depi][i];
              hig = max(hig,pri);
            }
         return  hig;
    }
    function gross(uint256 _depi, uint256 _pri) public view returns(uint256){
         uint256 or = order[_depi][ _pri];
         uint256 grs;
         for (uint i = 1; i <=or; i++) {
              uint256 gr = waid[_depi][_pri][i];
              grs = add(grs,gr);
            }
         return  grs;
    }
    function check(uint256 _depi, uint256 _pri) public view returns(uint256){
         uint256 cmax;
         for (uint i = low; i <_pri; i=i+step) {
              uint256 gro = gross(_depi, i);
              cmax = add(cmax,gro);
            }
         return  cmax ;
    }
    function kiss(address a) external  auth returns (bool){
        require(a != address(0), "fund/no-contract-0");
        bud[a] = 1;
        return true;
    }

    function diss(address a) external  auth returns (bool){
         bud[a] = 0;
         return true;
    }
    function setlive() external  auth returns (bool){
        if (live == 1) live = 0;
        else if (live == 0) live = 1;
        return true;
     } 
}
