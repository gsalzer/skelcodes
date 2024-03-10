pragma solidity 0.5.7;

import "./SafeMath.sol";
import "./AddrMInterface.sol";

interface TickectInerface{
    function calDeductionADC(uint256 _value,bool isIn_) external returns(uint256 disADC_);
}

interface ERC20 {
  function balanceOf(address) external view returns (uint256);
  function distroy(address _owner,uint256 _value) external;
}

library gameDataSet{
    struct PlyRelationship{
        uint256 parentPID;         //parent PID
        uint256 topPID;
        uint256 sonNumber;
        uint256 bigPotSonPID;    // big pot son ID 
        uint256 totalRecmdplys; // total recommanded players 
        uint256 totalRecmdAmount;     // total Recommended ETH  without  himself
        uint8   nodeLevel;       // this is node level for V1-V6
        //mapping(uint256 => uint256)  sonPIDList;     // son number -> son PID list
        mapping(uint256 => bool)  sonPIDListMap;     //son PID list mapping
        mapping(uint256 => uint256) sonTotalBalance; // PID-> total balance 
       
    }
    
    struct Player{
        //uint256 pID;
        uint256 ticketInCost;     // how many eth can join
        uint256   withdrawAmount;     // how many eth can join
        uint256 startTime;      // join the game time
        uint256 totalSettled;   // rturn  funds
        uint256 staticIncome;
        uint256 lastCalcSITime;      // last Calc staticIncome Time  
        //uint256 lastCalcDITime; //  last Calc dynamicIncome Time
        uint256 dynamicIncome; //  last Calc dynamicIncome
        uint256 stepIncome;
        bool isActive; // 1 mean is 10eth,2 have new one son,3,
        bool isAlreadGetIns;// already get insePoolBalance income;
    }
    
    
    struct Round{
        uint256 rID;            //Round ID
        uint256 rStartTime;      //Round start ID
        uint256 rPlys;           // new round players
        uint256 lastPID;         // last Player ID pID
        uint256 totalInseAmount; // 
        uint256 fritInsePoint;
        uint256 fritInseAmount;
        uint256[] plyInList;
    }
}

contract MainPool{
    using SafeMath for *;
    
    //address manager 
    AddrMInterface addrM ;
    TickectInerface  tickect;
    ERC20  adcERC20;
    
    // pool
    mapping(uint256 => uint256)     public allInBalance;
    mapping(uint256 => uint256)     public mainPoolLockBal; // lock balance do not sub
    mapping(uint256 => uint256)     public mainPoolBalance; // RID -> balance total Main pool balance 
    mapping(uint256 => uint256)     public mainPoolWithdrawBalance; // RID -> balance total Main pool balance 
    mapping(uint256 => uint256)     public alreadyWithDrawBal; // RID -> balance total Main pool balance 
    mapping(uint256 => uint256)     public insePoolBalance; // total insurance pool Banacle 
    
    uint256 public mainPoolSTime ;
    uint256 public totalDistroyADC;
    
    uint256 public constant oneDay = 86400 seconds ;
    
    
    //node level
    mapping(uint8 => uint256)       private nlThdAmount; // node level threshold amount
    mapping(uint8 => uint8)         private nlIncome; // node level threshold amount
    mapping(uint256 => uint256 )    private doubleV6PID; // id -> pID ,is start is 1 ;
    mapping(uint256 => bool )       private isDoubleV6; // PID -> TRUE ,is start is 1 ;
    mapping(uint256 => mapping(uint256 => uint256 )) private plydV6Income; // rid -> pid->balance ,is start is 1 ;
    uint256 totalV6Number;
    
    // Round 
    uint256 public RID;
    mapping(uint256 => gameDataSet.Round) public round; // RID => round Info
    mapping(uint256 => mapping(uint256=>bool)) public luckPID;
    
    // Player
    uint256 lastPID;
    mapping(uint256 => gameDataSet.PlyRelationship) public plyRShip;
    mapping(uint256 => mapping(uint256 => gameDataSet.Player)) public plyr; // rid-> pid-> player
    mapping(address => uint256) public plyrID; // address -> pid-> playerID
    mapping(uint256 => address) private plyrAddr; // pid -> addr-> playerID
    //mapping(uint256 =>mapping(uint256 => uint256)) public plyBalance; // player total can without balance  
    mapping(uint256 =>mapping(uint256 => uint256)) private plyWithdrawBalance; // player total can without balance  
    mapping(uint256 =>mapping(uint256 => uint256)) public playBiggertReward; // player total can without balance 
    mapping(uint256 =>uint256) private playDistroyADC; // PID-ADC balance player total can without balance 
    mapping(address=>bool) private vipPly;
    mapping(uint256=>bool) private vipPlayerID;
    mapping(uint256=>mapping(uint256 => uint256))     public  plyLucklyAmount; //rid-pid-amount
    
    // ambassador 
   mapping(address => bool) public ambassadorList; //addr-true-BOOL
    //uint256[] ambRewardList;// PID list
    mapping(uint256=>bool) private ambRewardMap;
    //mapping(uint256=>uint256) ambRewardIdx;
    mapping(uint256 => mapping(uint256=>uint256)) public ambRewardBalance;
    
    //vip
    address constant vip1Addr = address(0x953ad059b61aA4A23fa48d5eca617D4920E3343e);
    //address constant vip1Addr = address(0xa9A2CbA5d5d16DE370375B42662F3272279B2b89);
    //address constant vip2Addr = address(0x6bE9780954580FCC268944e9D6271B3Dfc886997);
    address constant vip2Addr = address(0xfbcB561D76a622341E6e537a17c5C17af33c4628);
    address constant vip3Addr = address(0x669f366427ea8184FdCDCda6D6201a6bAAf9b156);
    address constant vip4Addr = address(0xBcA44B04e10e04b7FeD7F262cAd70A683D753981);
    address constant vip5Addr = address(0x0D3c20D9102200242398dE26fdF09F29f435421b);
    address constant vip6Addr = address(0xbb3c82CD454911F140B68FE2E67504af9A2b5D16);
    //address constant vip6Addr = address(0xa9A2CbA5d5d16DE370375B42662F3272279B2b89);
   
    address constant vip7Addr = address(0xbE6DFD74AF0848b9cf6C6DFBc8bb24d2920e6aDe);
    address constant vip8Addr = address(0x5b9347799602D0164DF3926c10f237543eaa5b9F);
    address constant vip9Addr = address(0xa2221dE49E4085Be8098d1A8B4538734ce4977C7);
    address constant vip10Addr = address(0xAc1c0B39F3A1450E53BA0dA1bCAB5D9572DCed57);
    address constant vip11Addr = address(0x7721a0C6eb2F2a056C48D107d0a2C4Cff261e98c);
    //address constant vip11Addr = address(0xa9A2CbA5d5d16DE370375B42662F3272279B2b89);

    
    constructor(address addressM_) public{
        
        addrM = AddrMInterface(addressM_);
        tickect = TickectInerface(addrM.getAddr("TICKET"));
        adcERC20 = ERC20(addrM.getAddr("ADC"));
        
        mainPoolSTime = now;
        RID = 1;
        uint256[] memory temparry;
        round[RID] = gameDataSet.Round(RID,now,0,11,0,1,0,temparry);
        lastPID = 11;
        nlThdAmount[1] = 200000000000000000000; //bigger then 200 eth 
        nlThdAmount[2] = 600000000000000000000;
        nlThdAmount[3] = 2000000000000000000000;
        nlThdAmount[4] = 6000000000000000000000;
        nlThdAmount[5] = 12000000000000000000000;
        nlThdAmount[6] = 25000000000000000000000;
        
        nlIncome[1] = 5; // 5% 5/100
        nlIncome[2] = 7;
        nlIncome[3] = 9;
        nlIncome[4] = 11;
        nlIncome[5] = 13;
        nlIncome[6] = 15;
        //initVip();
        initVipPlay();
    }
    
    function initVipPlay() internal{
        vipPly[vip1Addr] = true;
        vipPly[vip2Addr] = true;
        vipPly[vip3Addr] = true;
        vipPly[vip4Addr] = true;
        vipPly[vip5Addr] = true;
        vipPly[vip6Addr] = true;
        vipPly[vip7Addr] = true;
        vipPly[vip8Addr] = true;
        
        vipPly[vip9Addr] = true;
        vipPly[vip10Addr] = true;
        vipPly[vip11Addr] = true;
        
        
        
    }
    
    modifier notContract(address _addr){
        uint size;
        assembly { size := extcodesize(_addr) }
        require(size == 0,"") ;
        _;
    }
    
    function joinGame(address parentAddr) public payable notContract(msg.sender){
        // check ticket
        uint256 tmPid = plyrID[msg.sender];
        if(tmPid ==0){
            require(msg.sender != parentAddr,"parent same as msg sender");
        }
        require(checkTicket(msg.sender,msg.value),"check ticket fail");
        
        // check invite
        uint256 pID =plyrID[msg.sender];
        
        uint256 parentPid_ = plyrID[parentAddr];
        uint256 inBalance = plyr[RID][pID].ticketInCost;
        
        allInBalance[RID] += inBalance;
        
        if(tmPid == 0 && !vipPly[msg.sender]){
            plyRShip[pID].parentPID = parentPid_;
            // topPID
            if(parentPid_ == 0){
                plyRShip[pID].topPID = pID;
            }else{
                plyRShip[pID].topPID = plyRShip[parentPid_].topPID;
            }
        }
        
        /*if(plyr[RID][parentPid_].lastCalcDITime == 0){
            plyr[RID][parentPid_].lastCalcDITime = now;
        }*/
        
        if (RID > 1 && !vipPly[msg.sender] && !vipPlayerID[parentPid_]){
            activeParent(pID,parentPid_,plyr[RID][pID].ticketInCost);
        } 
    
        // the pool  5% for insurance pool
        if(insePoolBalance[RID] >= 50000*10**18){
           mainPoolBalance[RID] += inBalance; 
           mainPoolLockBal[RID] += inBalance;
           mainPoolWithdrawBalance[RID] += inBalance;
        }else{
            uint256 temp = inBalance*95/100;
            insePoolBalance[RID] += inBalance*5/100;
            mainPoolBalance[RID] += temp;
            mainPoolLockBal[RID] += temp;
            mainPoolWithdrawBalance[RID] += temp;
        }
        
        
    
        // find parents calc earn
        calcEarn(pID,inBalance);
        
        //check pool state
        setRoundInfo(pID);
        
    }
    
    function withdraw() public{
        //check ADC 
        uint256 pid = plyrID[msg.sender];
        uint256 bunlers = 0;
        //if(pid > 11){
            require(plyr[RID][pid].isActive,"ply not active");
        //}
        require(mainPoolWithdrawBalance[RID]>0,"pool not withdraw balance");
        if(RID > 1 && !plyr[RID-1][pid].isAlreadGetIns){
            //check last round 
            if(luckPID[RID-1][pid]&& insePoolBalance[RID-1] > 0 ){
                if(pid == round[RID-1].plyInList[round[RID-1].fritInsePoint]){
                    bunlers = round[RID-1].fritInseAmount;
                    insePoolBalance[RID-1] -= bunlers;
                }else{
                    bunlers = plyr[RID-1][pid].ticketInCost*2;
                    if(bunlers > insePoolBalance[RID-1]){
                        insePoolBalance[RID-1] = 0;
                        bunlers = insePoolBalance[RID-1] ;
                    }else{
                        insePoolBalance[RID-1] -= bunlers;
                    }
                    
                }
                
                mainPoolBalance[RID] -= bunlers;
                plyr[RID-1][pid].isAlreadGetIns = true;
                plyLucklyAmount[RID-1][pid] = bunlers;
            }
        }/*else{
            require(plyWithdrawBalance[RID][pid] <= plyBalance[RID][pid],"not enought balance can withdraw");
        }*/
        
        uint256 wdBalance;
        if(plyr[RID][pid].totalSettled>plyWithdrawBalance[RID][pid] ){
            wdBalance = plyr[RID][pid].totalSettled-plyWithdrawBalance[RID][pid] ;
        }
        if(bunlers == 0){
            require(wdBalance > 0,"not enought balance can withdraw");
        }
        
        
        uint256 totalWdBal = wdBalance + bunlers;
        //wdBalance += bunlers;
        if(totalWdBal > mainPoolWithdrawBalance[RID]){
            totalWdBal = mainPoolWithdrawBalance[RID];
        }
        uint256 disAmount  = tickect.calDeductionADC(totalWdBal,false);
        require(adcERC20.balanceOf(msg.sender)>disAmount,"not adc to buy out tikcet");
        adcERC20.distroy(msg.sender,disAmount);
        playDistroyADC[pid] += disAmount;
        totalDistroyADC += disAmount;
        if(totalWdBal >= mainPoolWithdrawBalance[RID]){
            mainPoolWithdrawBalance[RID] = 0;
            plyr[RID][pid].withdrawAmount += mainPoolWithdrawBalance[RID];
            alreadyWithDrawBal[RID] += mainPoolWithdrawBalance[RID];
            msg.sender.transfer(mainPoolWithdrawBalance[RID]);
            
        }else{
            mainPoolWithdrawBalance[RID] -= totalWdBal;
            plyr[RID][pid].withdrawAmount += wdBalance;
            alreadyWithDrawBal[RID] += totalWdBal;
            msg.sender.transfer(totalWdBal);
            
        }
        
        plyWithdrawBalance[RID][pid] += wdBalance;
        
        plyr[RID][pid].staticIncome = 0;
        plyr[RID][pid].dynamicIncome = 0;
        plyr[RID][pid].stepIncome = 0;
        ambRewardBalance[RID][pid] = 0;
        plydV6Income[RID][pid] = 0;
    }
    
    // settlement Static income by web
    function settlementStatic() public {// that is temp balance
        
        //uint256 reward;
        uint256 pid = plyrID[msg.sender];
        uint256 temp = 0;
        gameDataSet.Player storage  rPlyer = plyr[RID][pid];
        //require(pid>11,"is vip");
        require(rPlyer.isActive,"not active");
        require(rPlyer.ticketInCost >0,"not charge");
        require(rPlyer.totalSettled < playBiggertReward[RID][pid],"already to top reward");
        
        
        require(now-rPlyer.lastCalcSITime > oneDay,"not enought one day");
        if(rPlyer.lastCalcSITime == 0){
            temp = calcS_T(rPlyer.startTime,rPlyer.ticketInCost);
        }else if(now - rPlyer.lastCalcSITime > oneDay){
            temp = calcS_T(rPlyer.lastCalcSITime,rPlyer.ticketInCost);
        }
        //temp = temp*50;
        if(rPlyer.totalSettled + temp > playBiggertReward[RID][pid]){
            temp = playBiggertReward[RID][pid] - rPlyer.totalSettled;
        }
        if(temp == 0){
            return ;
        }
       
        if(mainPoolBalance[RID] > temp){
            //plyBalance[RID][pid] += reward;
            rPlyer.staticIncome += temp;
            rPlyer.totalSettled += temp;
            mainPoolBalance[RID] -=temp;
            
            calcDynamic(pid,temp); 
        }else{
           // plyBalance[RID][pid] += mainPoolBalance[RID];
            rPlyer.staticIncome += mainPoolBalance[RID];
            rPlyer.totalSettled += mainPoolBalance[RID];
            mainPoolBalance[RID] =0;
            
            // need start new rand
            startNewRount();
            
        }
        
        
        rPlyer.lastCalcSITime = rPlyer.startTime + ((now - rPlyer.startTime) / oneDay) * oneDay; // remark the last calc income time
        
    }
    
    function calcDynamic(uint256 plyid_,uint256 staticIncome_) internal{
        uint256 parenID = plyRShip[plyid_].parentPID;
        uint256 sonLen = plyRShip[parenID].sonNumber;
        uint256 dIncome = 0;
        
        uint256 temp = staticIncome_;
        //if((sonLen_ == 1 && treeHight_<=2) || (sonLen_ == 2 && treeHight_ <= 4) || (sonLen_ == 3 && treeHight_<= 6) || (sonLen_ == 4 && treeHight_<= 8)){
        for(uint8 i=1; i<= 8;i++){
            //find parent
            temp = staticIncome_;
            if(parenID == 0){
                return;
            }
            //if(!vipPlayerID[parenID]){
            if(plyr[RID][parenID].totalSettled >= playBiggertReward[RID][parenID] || !plyr[RID][parenID].isActive){
                parenID = plyRShip[parenID].parentPID;
                sonLen = plyRShip[parenID].sonNumber;
                continue;
            }//}
            //if(parenID !=0 ){
                /*if(plyr[RID][parenID].ticketInCost == 0 && RID > 1 ){
                    if(!vipPlayerID[parenID] && plyr[RID-1][parenID].ticketInCost <=10*10**18 && plyr[RID-1][parenID].ticketInCost < plyr[RID][plyid_].ticketInCost){
                 
                        if(plyr[RID][plyid_].lastCalcSITime == 0){
                            temp = calcS_T(plyr[RID][plyid_].startTime,plyr[RID-1][parenID].ticketInCost);
                        }else if(now - plyr[RID][plyid_].lastCalcSITime > oneDay){
                            temp = calcS_T(plyr[RID][plyid_].lastCalcSITime,plyr[RID-1][parenID].ticketInCost);
                        }
                    }
                        
                }else{*/
                    if(!vipPlayerID[parenID] && plyr[RID][parenID].ticketInCost <=10*10**18 && plyr[RID][parenID].ticketInCost < plyr[RID][plyid_].ticketInCost){
                    
                        if(plyr[RID][plyid_].lastCalcSITime == 0){
                            temp = calcS_T(plyr[RID][plyid_].startTime,plyr[RID][parenID].ticketInCost);
                        }else if(now - plyr[RID][plyid_].lastCalcSITime > oneDay){
                            temp = calcS_T(plyr[RID][plyid_].lastCalcSITime,plyr[RID][parenID].ticketInCost);
                        }
                    }
               // }
                if(i == 1){
                    dIncome = (temp*20)/100;
                }else if(i>=2 && i<=3){
                    dIncome = (temp*10)/100;
                }else if(i>=4 && i<=8){
                    dIncome = (temp*5)/100;
                }
                if(i==3 ||i==4){
                    if(sonLen<2){
                       dIncome = 0; 
                    }
                }else if(i==5 || i==6){
                    if(sonLen <3){
                        dIncome = 0;
                    } 
                }else if(i==7 || i==8){
                    if(sonLen < 4){
                        dIncome = 0;
                    }
                }
                
                if(dIncome > 0){
                    if(plyr[RID][parenID].totalSettled + dIncome > playBiggertReward[RID][parenID]){
                       dIncome = playBiggertReward[RID][parenID] - plyr[RID][parenID].totalSettled;
                   }
                   
                   if(mainPoolBalance[RID] > dIncome){
                        //plyBalance[RID][parenID] += dIncome;
                        plyr[RID][parenID].dynamicIncome += dIncome;
                        plyr[RID][parenID].totalSettled += dIncome;
                        mainPoolBalance[RID] -= dIncome;
                        
                    }else{
                        //plyBalance[RID][parenID] += mainPoolBalance[RID];
                        plyr[RID][parenID].dynamicIncome += mainPoolBalance[RID];
                        plyr[RID][parenID].totalSettled += mainPoolBalance[RID];
                        mainPoolBalance[RID] =0;
            
                    // need start new rand
                        startNewRount();
                        break;
                    } 
                }
            
            dIncome = 0;
            parenID = plyRShip[parenID].parentPID;
            sonLen = plyRShip[parenID].sonNumber;
            
        }
    }
    
    function setAmbFlag(address ply_) public{
        require(msg.sender == addrM.getAddr("TICKET"),"msg sender not TICKET");
       
        ambassadorList[ply_] = true;
        
    }
    
    //ambassador
    function getPlayerInfo(address ply_,uint256 rid_) public view returns(
        uint256 stIncome_,
        uint256 dtIncome_,
        uint256 stepIncome_,
        uint256 ambIncome_,
        uint256 doubV6Income_,
        uint256 totoalIncome_,
        uint256 withdrawAmount_,
        uint256 ticketIn_,
        uint256 canWithdrawAmount_,
        uint256 startTime_,
        uint256 liveRountAmount_)
    {
            uint256 pid = plyrID[ply_];
            
            stIncome_ = plyr[rid_][pid].staticIncome;
            dtIncome_ = plyr[rid_][pid].dynamicIncome;
            stepIncome_ =  plyr[rid_][pid].stepIncome;
            ambIncome_ = ambRewardBalance[rid_][pid];
            doubV6Income_ = plydV6Income[rid_][pid];
            totoalIncome_ = plyr[rid_][pid].totalSettled;//plyBalance[rid_][pid];
            ticketIn_ = plyr[rid_][pid].ticketInCost;
            withdrawAmount_ = plyr[rid_][pid].withdrawAmount;
            //canWithdrawAmount_ =  rPlyer.staticIncome + rPlyer.stepIncome+ ambRewardBalance[rid_][pid] + plydV6Income[RID][pid] + rPlyer.dynamicIncome;
            if(plyr[rid_][pid].totalSettled > plyr[rid_][pid].withdrawAmount){
                canWithdrawAmount_ = plyr[rid_][pid].totalSettled - plyr[rid_][pid].withdrawAmount;
            }else{
                canWithdrawAmount_ = 0;
            }
            startTime_ = plyr[rid_][pid].startTime;
            //if(playBiggertReward[RID][pid] > plyr[rid_][pid].totalSettled){
            liveRountAmount_ = playBiggertReward[rid_][pid] - plyr[rid_][pid].totalSettled;
            //}
            
    }
    
    function getPlayerRelship(address ply_) public view returns(
        uint256 sonNumber_,
        uint256 allNumber_,
        uint256 curLevel_,
        bool    isamb_,
        uint256 bigPotBalance_,
        uint256 smailPotBalance_,
        bool isDoubleV6_,
        uint256 distroyADC_)
    {
        uint256 pid = plyrID[ply_]; 
        sonNumber_= plyRShip[pid].sonNumber;
        allNumber_= plyRShip[pid].totalRecmdplys;
        curLevel_=plyRShip[pid].nodeLevel;
        
        bigPotBalance_=plyRShip[pid].sonTotalBalance[plyRShip[pid].bigPotSonPID];
        isDoubleV6_ = isDoubleV6[pid];
        distroyADC_ = playDistroyADC[pid];
        smailPotBalance_ = plyRShip[pid].totalRecmdAmount - plyRShip[pid].sonTotalBalance[plyRShip[pid].bigPotSonPID];
        isamb_ = ambRewardMap[pid];
    }
    
   
    
    function getPoolInfo(uint256 rid_) public view returns(
        uint256 totalInBalance_, // all in balanace
        uint256 totalDivBalance_, // Dividend  pool balance
        uint256 totalInsBalance_,//Insurance pool balance
        uint256 totalPlayers_,
        uint256 totalDisADC_)
    {
        totalInBalance_ = allInBalance[rid_];
        totalDivBalance_ = mainPoolBalance[rid_];
        totalInsBalance_ = insePoolBalance[rid_];
        totalPlayers_ = round[rid_].lastPID;
        totalDisADC_ = totalDistroyADC;
    }
    
    function getRID() public view returns(uint256 rid_){
        rid_ = RID;
    }
    
    
    function activeParent(uint256 sonID_,uint256 parentPid_,uint256 value_) internal{
        
        if(!plyr[RID][parentPid_].isActive){
            if(value_ >= 10*10**18 && !plyRShip[parentPid_].sonPIDListMap[sonID_]){
                plyr[RID][parentPid_].isActive = true;
                if(playBiggertReward[RID-1][parentPid_] > plyr[RID-1][parentPid_].totalSettled){
                    playBiggertReward[RID][parentPid_] += (playBiggertReward[RID-1][parentPid_] - plyr[RID-1][parentPid_].totalSettled);
                    plyr[RID][parentPid_].ticketInCost = plyr[RID-1][parentPid_].ticketInCost;
                    plyr[RID][parentPid_].lastCalcSITime = plyr[RID-1][parentPid_].lastCalcSITime;
                }
                
            }
        }
       
    }
    
    function checkTicket(address payable ply_,uint256 value_) internal returns(bool){ 
        
       
       if(vipPly[ply_]){
           initVip(ply_);
       }
       
       uint256 pid =plyrID[ply_];
       uint256 disAmount;
       
        if(pid != 0 ){
           if(plyr[RID][pid].totalSettled >= playBiggertReward[RID][pid]){
                   
               plyr[RID][pid].totalSettled = 0;
               plyr[RID][pid].withdrawAmount = 0;
               plyr[RID][pid].ticketInCost = 0;
               plyr[RID][pid].staticIncome = 0;
               plyr[RID][pid].dynamicIncome = 0;
               plyr[RID][pid].stepIncome = 0;
               playBiggertReward[RID][pid] = 0;
               ambRewardBalance[RID][pid] = 0;
               plydV6Income[RID][pid] = 0;
               plyWithdrawBalance[RID][pid] = 0;
            } 
        }
        
        if (plyr[RID][pid].ticketInCost > 0 ){
            return false;
        }
       
        require(value_ >= 1*10**18,"transfer to smail");
        disAmount = tickect.calDeductionADC(value_,true);
        //require(adcERC20.balanceOf(ply_)>disAmount,"not adc to buy in tikcet");
        adcERC20.distroy(ply_,disAmount);
        totalDistroyADC += disAmount;
        
        
        if(pid == 0){
            lastPID += 1;
            pid = lastPID;
            
            plyrID[ply_] = pid; 
            plyrAddr[pid] = ply_;
            plyr[RID][pid].isActive = true;
            if(ambassadorList[ply_]){
                ambRewardMap[pid] = true;
            }
            
        }
        
        playDistroyADC[pid] += disAmount;
        plyr[RID][pid].startTime = now;
        plyr[RID][pid].ticketInCost = value_;
        if(vipPly[ply_]){
            playBiggertReward[RID][pid] += value_*20000;
            vipPlayerID[pid] = true;
        }else{
           if(value_ >= 31*10**18){
                playBiggertReward[RID][pid] += value_*3;
            }else if(value_ < 31*10**18 && value_ >= 11*10**18){
                playBiggertReward[RID][pid] +=value_*25/10;
            }else{
                playBiggertReward[RID][pid] += value_*2;
            } 
        }
        
        return true;
        
    }
    
    function setRoundInfo(uint256 plyID_) internal{
        
        if(vipPlayerID[plyID_]){
            return;
        }
        round[RID].rPlys += 1;
        round[RID].lastPID = plyID_;
        round[RID].plyInList.push(plyID_);
        
    }
    
    function calcEarn(uint256 plyID_,uint256 value_) internal{
        //check Insurance pool
        
        uint256 aveIncome ;
       // uint256 len = ambRewardList.length;
        //uint256  reward;
        if(totalV6Number > 0){
            aveIncome= (value_*3/100) /totalV6Number;
            uint256 doubpid;
            for(uint256 i = 1; i <= totalV6Number; i++){
                doubpid = doubleV6PID[i];
                if(RID == 1 || (RID >1 && plyr[RID][doubpid].isActive) /*|| vipPlayerID[plyID_]*/){
                    if(plyr[RID][doubpid].totalSettled >= playBiggertReward[RID][doubpid]){
                        continue;
                    }else{
                        if( plyr[RID][doubpid].totalSettled + aveIncome > playBiggertReward[RID][doubpid]){
                            uint256  temp = playBiggertReward[RID][doubpid] - plyr[RID][doubpid].totalSettled;
                            
                            plyr[RID][doubpid].totalSettled +=temp;
                            plydV6Income[RID][doubpid] += temp;
                            mainPoolBalance[RID] -= temp;
                        }else{
                             plydV6Income[RID][doubpid] += aveIncome;
                            //plyBalance[RID][doubpid] += aveIncome;
                            plyr[RID][doubpid].totalSettled += aveIncome; 
                            mainPoolBalance[RID] -= aveIncome;
                        }
                    }
                    
                    
                }
            }
        }
        
        findParentByFor(plyID_,value_);
    }
    
    function findParentByFor(uint256 plyID_,uint256 value_) internal{
            
            uint256 parentPID_ ;
            uint256 pp = plyID_;
            //uint8 dividendAccount = nlIncome[plyRShip[toppid].nodeLevel]; 
            uint256 haveOneV6;
            uint8 parnetNodeLevel;
            uint8 biggestNodeLevel=0;
            uint256[] memory stepPlyerList = new uint256[](120);
            uint256 stepPlyNum;
            
            uint256 ambPid = 0 ;
            
            for(uint8 i=0;i<120;i++){
                parentPID_ = plyRShip[pp].parentPID;
                parnetNodeLevel = plyRShip[parentPID_].nodeLevel;
                if(parentPID_ == 0){
                    break;
                }
                
                if(ambRewardMap[parentPID_] && ambPid == 0&&plyr[RID][parentPID_].isActive){
                    ambPid = parentPID_;
                }
                //if(parentPID_ !=0){
                    //set releaseship
                    setRelationship(pp,parentPID_,value_);
                
                    //double v6
                    if(parnetNodeLevel > 0){
                        if(parnetNodeLevel == 6 && haveOneV6 >=1 && !isDoubleV6[parentPID_]){
                            isDoubleV6[parentPID_] = true;
                            totalV6Number +=1;
                            doubleV6PID[totalV6Number] = parentPID_;
                        }
                        if(parnetNodeLevel == 6 && !isDoubleV6[parentPID_]){
                            haveOneV6++;
                        }
                    
                        //step income calc 
                        if(plyr[RID][parentPID_].isActive){
                            if(parnetNodeLevel > biggestNodeLevel){
                                biggestNodeLevel = parnetNodeLevel;
                                stepPlyerList[stepPlyNum] = parentPID_;
                                stepPlyNum++;
                            }
                        }
                    }
                    //check level
                    if((plyr[RID][parentPID_].ticketInCost >= 11*10**18 && plyRShip[parentPID_].sonNumber >= 5)){
                        for (uint8 j = 1; j <= 6; j++) {
                            if(plyRShip[parentPID_].totalRecmdAmount - plyRShip[parentPID_].sonTotalBalance[plyRShip[parentPID_].bigPotSonPID] > nlThdAmount[j]){
                                plyRShip[parentPID_].nodeLevel = j;
                            }
                        }
                    }
                    
                    pp = parentPID_;
                
                //}
            }
            
            //calc step income
            if(stepPlyNum >0){
                calcStepByList(stepPlyNum,stepPlyerList,biggestNodeLevel,value_);
                
            }
             
            //calc ambReward 
            if(ambPid > 0){
                setAmbRewardBalance(ambPid,value_);
            }
            
            
    }
    
    function calcStepByList(uint256 stepNum_,uint256[] memory stepPlyerList,uint8 biggestNodeLevel,uint256 value_) internal{
                uint8 dividendAccount  = nlIncome[biggestNodeLevel];
                uint8 totalDiv;
                uint8 curDiv;
                uint8 plyNlevel;
                uint256 steppid;
                for(uint8 i=0;i<stepNum_;i++){
                    steppid = stepPlyerList[i];
                    
                    plyNlevel = plyRShip[steppid].nodeLevel;
                    if(totalDiv == 0){
                        curDiv = nlIncome[plyNlevel];
                    }else{
                        if(dividendAccount >nlIncome[plyNlevel] - totalDiv){
                            curDiv = nlIncome[plyNlevel] - totalDiv;
                        }else{
                            curDiv = dividendAccount;
                        }
                    } 
                   
                    calcStepIncome(steppid,value_,curDiv);
                    
                    totalDiv += curDiv;
                    if(dividendAccount > curDiv){
                        dividendAccount -=curDiv;
                    }else{
                        break;
                    }
                }
            
    }
    
    function setAmbRewardBalance(uint256 pid_,uint256 value_) internal{
       
        uint256 ambincom;
        if(plyr[RID][pid_].totalSettled < playBiggertReward[RID][pid_]){
            ambincom = plyr[RID][pid_].totalSettled + (value_*5)/100 > playBiggertReward[RID][pid_]? playBiggertReward[RID][pid_]-plyr[RID][pid_].totalSettled:(value_*5)/100;
            plyr[RID][pid_].totalSettled += ambincom;//(value_*5)/100;
            ambRewardBalance[RID][pid_] += ambincom;// (value_*5)/100;
            mainPoolBalance[RID] -=  ambincom;}//(value_*5)/100;}
             
    }
    
    
    
    function setRelationship(uint256 sonID_,uint256 plyID_,uint256 value_) internal{
    
        gameDataSet.PlyRelationship storage  rship = plyRShip[plyID_];
       
            
        if(!rship.sonPIDListMap[sonID_]){
            rship.sonNumber += 1;
            //rship.sonPIDList[rship.sonNumber] = sonID_;//add son
            rship.sonPIDListMap[sonID_] = true;
        }
        //rship.totalRecmdplys++;
        rship.sonTotalBalance[sonID_] += value_; // add son toto balance value
        rship.totalRecmdAmount += value_;
        
        //check the big one some
        if(rship.sonTotalBalance[sonID_] > rship.sonTotalBalance[rship.bigPotSonPID]){
            rship.bigPotSonPID = sonID_;
        }
        
    }
    
    
    
    
    function calcS_T(uint256 lastTime_,uint256 value_) internal view returns(uint256 _earnAmount){
        
        
            if(now - mainPoolSTime <= (60 * oneDay)){ // 2 month
                
                _earnAmount = (((now -  lastTime_  ) / oneDay ) * value_ * (70))/10000;
            }else if(now - mainPoolSTime <= (120 * oneDay)){ // 4 month
                uint256 oneTime = mainPoolSTime + 60*oneDay;
                if(lastTime_ < oneTime){
                    _earnAmount = (((oneTime - lastTime_)/oneDay) * value_ * 70)/10000 + (((now - oneTime) / oneDay  ) * value_ * (65))/10000;
                }else{
                    _earnAmount = (((now -  lastTime_  ) / oneDay ) * value_ * (65))/10000;
                }
                
            }else{// langer then 6 month
                uint256 oneTime = mainPoolSTime + 60*oneDay;
                uint256 twoTime = mainPoolSTime+ 120*oneDay;
                if(lastTime_ < oneTime){
                    _earnAmount = (((oneTime - lastTime_)/oneDay) * value_ * 70)/10000 + (60  * value_ * 65)/10000 + (((now - twoTime) / oneDay ) * value_ * 50)/10000;
                }else if(lastTime_ < twoTime){
                    _earnAmount = (((twoTime - lastTime_)/oneDay) * value_ * 65)/10000 + (((now - twoTime) / oneDay ) * value_ * (50))/10000;
                }else{
                    _earnAmount = (((now -  lastTime_  ) / oneDay ) * value_ * (50))/10000;
                } 
        
        }   
        
        
        
    }
    
    function calcStepIncome(uint256 pid_,uint256 value_,uint8 dividendAccount_) public{
    
        
            uint256    spIncome = (value_*dividendAccount_)/100;
                if(plyr[RID][pid_].totalSettled >= playBiggertReward[RID][pid_]){
                    return;
                }
                if(plyr[RID][pid_].totalSettled+spIncome>playBiggertReward[RID][pid_]){
                    spIncome = playBiggertReward[RID][pid_]-plyr[RID][pid_].totalSettled;
                }
                //if(mainPoolBalance[RID] > spIncome){
                    plyr[RID][pid_].stepIncome += spIncome;
                    //plyBalance[RID][pid_] += spIncome;
                    plyr[RID][pid_].totalSettled += spIncome;
                    mainPoolBalance[RID] -= spIncome;
                /*}else{
                    
                    plyr[RID][pid_].stepIncome += mainPoolBalance[RID];
                    //plyBalance[RID][pid_] += mainPoolBalance[RID];
                    plyr[RID][pid_].totalSettled += mainPoolBalance[RID];
                    mainPoolBalance[RID] =0;
                }*/
            
        
        
    }
    
    
    function startNewRount() internal {
        
        uint256 tisbalance;
        uint256 pid ;
        uint256 len = round[RID].rPlys;
        uint256 starti ;
        if(len > 100){
            starti = round[RID].rPlys-100;
        }
        for(uint256 i=starti ; i<len; i++){
            pid = round[RID].plyInList[len-i-1];
            luckPID[RID][pid] = true;
            tisbalance += plyr[RID][pid].ticketInCost *2;
            if(tisbalance>=insePoolBalance[RID]){
                //luckPID[RID][pid] = true;
                round[RID].fritInsePoint = len-i-1;
                round[RID].fritInseAmount = insePoolBalance[RID] - (tisbalance-plyr[RID][pid].ticketInCost *2);
                round[RID].totalInseAmount = insePoolBalance[RID];
                break;
            }else{
                
                if(i==len-1){
                    round[RID].fritInsePoint = starti;
                    round[RID].totalInseAmount = tisbalance ;
                }
            }
            
        }
        
        RID++;
        round[RID].rID = RID;
        round[RID].rStartTime = now;
        round[RID].rPlys = 0;
        mainPoolBalance[RID] = insePoolBalance[RID-1];
        mainPoolWithdrawBalance[RID] = insePoolBalance[RID-1];
        
        if(mainPoolLockBal[RID-1] > alreadyWithDrawBal[RID-1]   ){
            mainPoolBalance[RID] += mainPoolLockBal[RID-1]-alreadyWithDrawBal[RID-1];
            mainPoolWithdrawBalance[RID] += mainPoolLockBal[RID-1]-alreadyWithDrawBal[RID-1];
        }
        
        newRoundVIP();
    
    }
    
    function initVip(address ply_) internal{
       
        
        //lastPID = 18;
         
        //1
        if(ply_ == vip1Addr){initVIPInfo(vip1Addr,1,0);}
        if(ply_ == vip2Addr){initVIPInfo(vip2Addr,2,0);}
        if(ply_ == vip3Addr){initVIPInfo(vip3Addr,3,0);}
        if(ply_ == vip4Addr){initVIPInfo(vip4Addr,4,0); }
        if(ply_ == vip5Addr){initVIPInfo(vip5Addr,5,2);}
        
        if(ply_ == vip6Addr){initVIPInfo(vip6Addr,6,2);}
        if(ply_ == vip7Addr){initVIPInfo(vip7Addr,7,2);}
        if(ply_ == vip8Addr){initVIPInfo(vip8Addr,8,3);}
        if(ply_ == vip9Addr){initVIPInfo(vip9Addr,9,3);}
        if(ply_ == vip10Addr){initVIPInfo(vip10Addr,10,4);}
        if(ply_ == vip11Addr){initVIPInfo(vip11Addr,11,4);}
        
    
    }
    
    
    function initVIPInfo(address ply_,uint256 pid_ ,uint256 parentid_) internal{
        
        plyrID[ply_] = pid_;
        //plyr[RID][pid_].pID = pid_;
        plyrAddr[pid_] = ply_;
        plyr[RID][pid_].isActive = true;
        
        
        if(pid_ == 1){
            plyRShip[pid_].parentPID = 0;
            plyRShip[pid_].sonNumber = 3;
            plyRShip[pid_].sonPIDListMap[2] = true;
            plyRShip[pid_].sonPIDListMap[3] = true;
            plyRShip[pid_].sonPIDListMap[4] = true;
            //plyRShip[pid_].sonPIDList[1] = 2;
            //plyRShip[pid_].sonPIDList[2] = 3;
            //plyRShip[pid_].sonPIDList[3] = 4;
        }else if(pid_ == 2){
            plyRShip[pid_].parentPID = 1;
            plyRShip[pid_].sonNumber = 3;
            plyRShip[pid_].sonPIDListMap[5] = true;
            plyRShip[pid_].sonPIDListMap[6] = true;
            plyRShip[pid_].sonPIDListMap[7] = true;
            //plyRShip[pid_].sonPIDList[1] = 5;
            //plyRShip[pid_].sonPIDList[2] = 6;
            //plyRShip[pid_].sonPIDList[3] = 7;
        }else if(pid_ == 3 ){
            plyRShip[pid_].parentPID = 1;
            plyRShip[pid_].sonNumber = 2;
            plyRShip[pid_].sonPIDListMap[8] = true;
            plyRShip[pid_].sonPIDListMap[9] = true;
            //plyRShip[pid_].sonPIDList[1] = 8;
            //plyRShip[pid_].sonPIDList[2] = 9;
        }else if(pid_ == 4){
            plyRShip[pid_].parentPID = 1;
            plyRShip[pid_].sonNumber = 2;
            plyRShip[pid_].sonPIDListMap[10] = true;
            plyRShip[pid_].sonPIDListMap[11] = true;
            //plyRShip[pid_].sonPIDList[1] = 10;
            //plyRShip[pid_].sonPIDList[2] = 11;
        }else if(pid_ >=5 && pid_ <= 11){
           plyRShip[pid_].parentPID = parentid_; 
           ambRewardMap[pid_] = true;
           ambassadorList[ply_] = true;
       
        }
        
        plyRShip[pid_].topPID = 1;
        
    }
    
    function newRoundVIP() internal{
        for(uint8 i=1;i<=11;i++){
            playBiggertReward[RID][i] = playBiggertReward[RID-1][i];
            plyr[RID][i].isActive = true;
            plyr[RID][i].ticketInCost = plyr[RID][i-1].ticketInCost;
            plyr[RID][i].lastCalcSITime = plyr[RID-1][i].lastCalcSITime;
        }   
    }
    
    
    
}
