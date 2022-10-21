pragma solidity >=0.4.21 <0.6.0;

contract Terminator {

    address terminatorOwner;     //合约拥有者
    address callOwner;           //部分方法允许调用者（主合约）

    struct recodeTerminator {
        address userAddress;     //用户地址
        uint256 amountInvest;    //用户留存在合约当中的金额
    }

    uint256 public BlockNumber;                                                           //区块高度
    uint256 public AllTerminatorInvestAmount;                                             //终结者所有用户总投入金额
    uint256 public TerminatorRewardPool;                                                  //当前终结者奖池金额
    uint256 public TerminatorRewardWithdrawPool;                                          //终结者可提现奖池金额
    uint256 public signRecodeTerminator;                                                  //标记插入位置

    recodeTerminator[50] public recodeTerminatorInfo;                                     //终结者记录数组
    mapping(address => uint256 [4]) internal terminatorAllReward;                         //用户总奖励金额和已提取的奖励金额和复投总金额
    mapping(uint256 => address[50]) internal blockAllTerminatorAddress;                   //每个区块有多少终结者
    uint256[] internal signBlockHasTerminator;                                            //产生终结者的区块数组

    //事件
    event AchieveTerminator(uint256 terminatorBlocknumber);  //成为终结者

    //初始化合约
    constructor() public{
        terminatorOwner = msg.sender;
    }

    //添加终结者（主合约调用）
    function addTerminator(address addr, uint256 amount, uint256 blockNumber, uint256 amountPool)
    public
    checkCallOwner(msg.sender)
    {
        require(amount > 0);
        require(amountPool > 0);
        if (blockNumber >= BlockNumber + 240 && BlockNumber != 0) {
            addRecodeToTerminatorArray(BlockNumber);
            signBlockHasTerminator.push(BlockNumber);
        }
        addRecodeTerminator(addr, amount, blockNumber, amountPool);
        BlockNumber = blockNumber;
    }

    //用户提取奖励（主合约调用）
    function modifyTerminatorReward(address addr, uint256 amount)
    public
    checkCallOwner(msg.sender)
    {
        require(amount <= terminatorAllReward[addr][0] - (terminatorAllReward[addr][1] * 100 / 80) - terminatorAllReward[addr][3]);
        terminatorAllReward[addr][1] += amount;
    }
    //用户复投(主合约调用)
    function reInvestTerminatorReward(address addr, uint256 amount)
    public
    checkCallOwner(msg.sender)
    {
        require(amount <= terminatorAllReward[addr][0] - (terminatorAllReward[addr][1] * 100 / 80) - terminatorAllReward[addr][3]);
        terminatorAllReward[addr][3] += amount;
    }

    //添加用户信息记录，等待触发终结者(内部调用)
    function addRecodeTerminator(address addr, uint256 amount, uint256 blockNumber, uint256 amountPool)
    internal
    {
        recodeTerminator memory t = recodeTerminator(addr, amount);
        if (blockNumber == BlockNumber) {
            if (signRecodeTerminator >= 50) {
                AllTerminatorInvestAmount -= recodeTerminatorInfo[signRecodeTerminator % 50].amountInvest;
            }
            recodeTerminatorInfo[signRecodeTerminator % 50] = t;
            signRecodeTerminator++;
            AllTerminatorInvestAmount += amount;
        } else {
            recodeTerminatorInfo[0] = t;
            signRecodeTerminator = 1;
            AllTerminatorInvestAmount = amount;
        }
        TerminatorRewardPool = amountPool;
    }
    //产生终结者，将终结者信息写入并计算奖励（内部调用）
    function addRecodeToTerminatorArray(uint256 blockNumber)
    internal
    {
        for (uint256 i = 0; i < 50; i++) {
            if (i >= signRecodeTerminator) {
                break;
            }
            address userAddress = recodeTerminatorInfo[i].userAddress;
            uint256 reward = (recodeTerminatorInfo[i].amountInvest) * (TerminatorRewardPool) / (AllTerminatorInvestAmount);

            blockAllTerminatorAddress[blockNumber][i] = userAddress;
            terminatorAllReward[userAddress][0] += reward;
            terminatorAllReward[userAddress][2] = reward;
        }
        TerminatorRewardWithdrawPool += TerminatorRewardPool;
        emit AchieveTerminator(blockNumber);
    }

    //添加主合约调用权限(合约拥有者调用)
    function addCallOwner(address addr)
    public
    checkTerminatorOwner(msg.sender)
    {
        callOwner = addr;
    }
    //根据区块高度获取获取所有获得终结者奖励地址
    function getAllTerminatorAddress(uint256 blockNumber)
    view public
    returns (address[50] memory)
    {
        return blockAllTerminatorAddress[blockNumber];
    }
    //获取最近一次获得终结者区块高度和奖励的所有用户地址和上一次获奖数量
    function getLatestTerminatorInfo()
    view public
    returns (uint256 blockNumber, address[50] memory addressArray, uint256[50] memory amountArray)
    {
        uint256 index = signBlockHasTerminator.length;

        address[50] memory rewardAddress;
        uint256[50] memory rewardAmount;
        if (index <= 0) {
            return (0, rewardAddress, rewardAmount);
        } else {
            uint256 blocks = signBlockHasTerminator[index - 1];
            rewardAddress = blockAllTerminatorAddress[blocks];
            for (uint256 i = 0; i < 50; i++) {
                if (rewardAddress[i] == address(0)) {
                    break;
                }
                rewardAmount[i] = terminatorAllReward[rewardAddress[i]][2];
            }
            return (blocks, rewardAddress, rewardAmount);
        }
    }
    //获取可提现奖励金额
    function getTerminatorRewardAmount(address addr)
    view public
    returns (uint256)
    {
        return terminatorAllReward[addr][0] - (terminatorAllReward[addr][1] * 100 / 80) - terminatorAllReward[addr][3];
    }
    //获取用户所有奖励金额和已提现金额和上一次获奖金额和复投金额
    function getUserTerminatorRewardInfo(address addr)
    view public
    returns (uint256[4] memory)
    {
        return terminatorAllReward[addr];
    }
    //获取所有产生终结者的区块数组
    function getAllTerminatorBlockNumber()
    view public
    returns (uint256[] memory){
        return signBlockHasTerminator;
    }
    //获取当次已提走奖池金额（供主合约调用）
    function checkBlockWithdrawAmount(uint256 blockNumber)
    view public
    returns (uint256)
    {
        if (blockNumber >= BlockNumber + 240 && BlockNumber != 0) {
            return (TerminatorRewardPool + TerminatorRewardWithdrawPool);
        } else {
            return (TerminatorRewardWithdrawPool);
        }
    }
    //检查合约拥有者权限
    modifier checkTerminatorOwner(address addr)
    {
        require(addr == terminatorOwner);
        _;
    }
    //检查合约调用者权限（检查是否是主合约调用）
    modifier checkCallOwner(address addr)
    {
        require(addr == callOwner || addr == terminatorOwner);
        _;
    }
}
//备注：
//部署完主合约后，需要调用该合约的addCallOwner方法，传入主合约地址，为主合约调该合约方法添加权限

