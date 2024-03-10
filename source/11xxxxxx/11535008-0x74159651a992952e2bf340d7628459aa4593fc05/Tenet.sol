// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./TenetToken.sol";
import "./TenetMine.sol";
// Tenet is the master of TEN. He can make TEN and he is a fair guy.
contract Tenet is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;             
        uint256 rewardTokenDebt;    
        uint256 rewardTenDebt;      
        uint256 lastBlockNumber;    
        uint256 freezeBlocks;      
        uint256 freezeTen;         
    }
    // Info of each pool.
    struct PoolSettingInfo{
        address lpToken;            
        address tokenAddr;          
        address projectAddr;        
        uint256 tokenAmount;       
        uint256 startBlock;        
        uint256 endBlock;          
        uint256 tokenPerBlock;      
        uint256 tokenBonusEndBlock; 
        uint256 tokenBonusMultipler;
    }
    struct PoolInfo {
        uint256 lastRewardBlock;  
        uint256 lpTokenTotalAmount;
        uint256 accTokenPerShare; 
        uint256 accTenPerShare; 
        uint256 userCount;
        uint256 amount;     
        uint256 rewardTenDebt; 
        uint256 mineTokenAmount;
    }

    struct TenPoolInfo {
        uint256 lastRewardBlock;
        uint256 accTenPerShare; 
        uint256 allocPoint;
        uint256 lpTokenTotalAmount;
    }

    TenetToken public ten;
    TenetMine public tenMineCalc;
    IERC20 public lpTokenTen;
    address public devaddr;
    uint256 public devaddrAmount;
    uint256 public modifyAllocPointPeriod;
    uint256 public lastModifyAllocPointBlock;
    uint256 public totalAllocPoint;
    uint256 public devWithdrawStartBlock;
    uint256 public addpoolfee;
    uint256 public bonusAllocPointBlock;
    uint256 public minProjectUserCount;

    uint256 public updateBlock;
    uint256 public constant MINLPTOKEN_AMOUNT = 10000000000;
    uint256 public constant PERSHARERATE = 1000000000000;
    PoolInfo[] public poolInfo;
    PoolSettingInfo[] public poolSettingInfo;
    TenPoolInfo public tenProjectPool;
    TenPoolInfo public tenUserPool;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping (address => UserInfo) public userInfoUserPool;
    mapping (address => bool) public tenMintRightAddr;

    event AddPool(address indexed user, uint256 indexed pid, uint256 tokenAmount,uint256 lpTenAmount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount,uint256 penddingToken,uint256 penddingTen,uint256 freezeTen,uint256 freezeBlocks);
    event DepositFrom(address indexed user, uint256 indexed pid, uint256 amount,address from,uint256 penddingToken,uint256 penddingTen,uint256 freezeTen,uint256 freezeBlocks);
    event MineLPToken(address indexed user, uint256 indexed pid, uint256 penddingToken,uint256 penddingTen,uint256 freezeTen,uint256 freezeBlocks);    
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount,uint256 penddingToken,uint256 penddingTen,uint256 freezeTen,uint256 freezeBlocks);

    event DepositLPTen(address indexed user, uint256 indexed pid, uint256 amount,uint256 penddingTen,uint256 freezeTen,uint256 freezeBlocks);
    event WithdrawLPTen(address indexed user, uint256 indexed pid, uint256 amount,uint256 penddingTen,uint256 freezeTen,uint256 freezeBlocks);    
    event MineLPTen(address indexed user, uint256 penddingTen,uint256 freezeTen,uint256 freezeBlocks);    
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event DevWithdraw(address indexed user, uint256 amount);

    constructor(
        TenetToken _ten,
        TenetMine _tenMineCalc,
        IERC20 _lpTen,        
        address _devaddr,
        uint256 _allocPointProject,
        uint256 _allocPointUser,
        uint256 _devWithdrawStartBlock,
        uint256 _modifyAllocPointPeriod,
        uint256 _bonusAllocPointBlock,
        uint256 _minProjectUserCount
    ) public {
        ten = _ten;
        tenMineCalc = _tenMineCalc;
        devaddr = _devaddr;
        lpTokenTen = _lpTen;
        tenProjectPool.allocPoint = _allocPointProject;
        tenUserPool.allocPoint = _allocPointUser;
        totalAllocPoint = _allocPointProject + _allocPointUser;
        devaddrAmount = 0;
        devWithdrawStartBlock = _devWithdrawStartBlock;
        addpoolfee = 0;
        updateBlock = 0;
        modifyAllocPointPeriod = _modifyAllocPointPeriod;
        lastModifyAllocPointBlock = tenMineCalc.startBlock();
        bonusAllocPointBlock = _bonusAllocPointBlock;
        minProjectUserCount = _minProjectUserCount;
    }
    modifier onlyMinter() {
        require(tenMintRightAddr[msg.sender] == true, "onlyMinter: caller is no right to mint");
        _;
    }
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    function set_tenMintRightAddr(address _addr,bool isHaveRight) public onlyOwner {
        tenMintRightAddr[_addr] = isHaveRight;
    }
    function tenMint(address _toAddr,uint256 _amount) public onlyMinter {
        ten.mint(_toAddr,_amount);
        devaddrAmount = devaddrAmount.add(_amount.div(10));
    }    
    function set_tenetToken(TenetToken _ten) public onlyOwner {
        ten = _ten;
    }
    function set_tenNewOwner(address _tenNewOwner) public onlyOwner {
        ten.transferOwnership(_tenNewOwner);
    }    
    function set_tenetLPToken(IERC20 _lpTokenTen) public onlyOwner {
        lpTokenTen = _lpTokenTen;
    }
    function set_tenetMine(TenetMine _tenMineCalc) public onlyOwner {
        tenMineCalc = _tenMineCalc;
    }
    function set_updateContract(uint256 _updateBlock) public onlyOwner {
        updateBlock = _updateBlock;
    }
    function set_addPoolFee(uint256 _addpoolfee) public onlyOwner {
        addpoolfee = _addpoolfee;
    }
    function set_devWithdrawStartBlock(uint256 _devWithdrawStartBlock) public onlyOwner {
        devWithdrawStartBlock = _devWithdrawStartBlock;
    }   
    function set_allocPoint(uint256 _allocPointProject,uint256 _allocPointUser,uint256 _modifyAllocPointPeriod) public onlyOwner {
        _minePoolTen(tenProjectPool);
        _minePoolTen(tenUserPool);
        tenProjectPool.allocPoint = _allocPointProject;
        tenUserPool.allocPoint = _allocPointUser;
        modifyAllocPointPeriod = _modifyAllocPointPeriod;
        totalAllocPoint = _allocPointProject + _allocPointUser;        
    }
    function set_bonusAllocPointBlock(uint256 _bonusAllocPointBlock) public onlyOwner {
        bonusAllocPointBlock = _bonusAllocPointBlock;
    }  
    function set_minProjectUserCount(uint256 _minProjectUserCount) public onlyOwner {
        minProjectUserCount = _minProjectUserCount;
    } 
    function add(address _lpToken,
            address _tokenAddr,
            uint256 _tokenAmount,
            uint256 _startBlock,
            uint256 _endBlockOffset,
            uint256 _tokenPerBlock,
            uint256 _tokenBonusEndBlockOffset,
            uint256 _tokenBonusMultipler,
            uint256 _lpTenAmount) public {
        if(_startBlock == 0){
            _startBlock = block.number;
        }
        require(block.number <= _startBlock, "add: startBlock invalid");
        require(_endBlockOffset >= _tokenBonusEndBlockOffset, "add: bonusEndBlockOffset invalid");
        require(tenMineCalc.getMultiplier(_startBlock,_startBlock + _endBlockOffset,_startBlock + _endBlockOffset,_startBlock + _tokenBonusEndBlockOffset,_tokenBonusMultipler).mul(_tokenPerBlock) <= _tokenAmount, "add: token amount invalid");
        if(updateBlock > 0){
            require(block.number <= updateBlock, "add: updateBlock invalid");
        }
        IERC20(_tokenAddr).transferFrom(msg.sender,address(this), _tokenAmount);
        if(addpoolfee > 0){
            ten.transferFrom(msg.sender,address(this), addpoolfee);
            ten.burn(address(this),addpoolfee);
        }
        uint256 pid = poolInfo.length;
        poolSettingInfo.push(PoolSettingInfo({
                lpToken: _lpToken,
                tokenAddr: _tokenAddr,
                projectAddr: msg.sender,
                tokenAmount:_tokenAmount,
                startBlock: _startBlock,
                endBlock: _startBlock + _endBlockOffset,
                tokenPerBlock: _tokenPerBlock,
                tokenBonusEndBlock: _startBlock + _tokenBonusEndBlockOffset,
                tokenBonusMultipler: _tokenBonusMultipler
            }));
        poolInfo.push(PoolInfo({
            lastRewardBlock: block.number > _startBlock ? block.number : _startBlock,
            accTokenPerShare: 0,
            accTenPerShare: 0,
            lpTokenTotalAmount: 0,
            userCount: 0,
            amount: 0,
            rewardTenDebt: 0,
            mineTokenAmount: 0
        }));
        if(_lpTenAmount>MINLPTOKEN_AMOUNT){
            depositTenByProject(pid,_lpTenAmount);
        }
        emit AddPool(msg.sender, pid, _tokenAmount,_lpTenAmount);
    }
    function updateAllocPoint() public {
        if(lastModifyAllocPointBlock.add(modifyAllocPointPeriod) <= block.number){
            uint256 totalLPTokenAmount = tenProjectPool.lpTokenTotalAmount.mul(bonusAllocPointBlock.add(1e4)).div(1e4).add(tenUserPool.lpTokenTotalAmount);
            if(totalLPTokenAmount > MINLPTOKEN_AMOUNT)
            {
                tenProjectPool.allocPoint = tenProjectPool.allocPoint.add(tenProjectPool.lpTokenTotalAmount.mul(1e4).mul(bonusAllocPointBlock.add(1e4)).div(1e4).div(totalLPTokenAmount)).div(2);
                tenUserPool.allocPoint = tenUserPool.allocPoint.add(tenUserPool.lpTokenTotalAmount.mul(1e4).div(totalLPTokenAmount)).div(2);
                totalAllocPoint = tenProjectPool.allocPoint + tenUserPool.allocPoint;
                lastModifyAllocPointBlock = block.number;
            }
        }     
    }
    // Update reward variables of the given pool to be up-to-date.
    function _minePoolTen(TenPoolInfo storage tenPool) internal {
        if (block.number <= tenPool.lastRewardBlock) {
            return;
        }
        if (tenPool.lpTokenTotalAmount <= MINLPTOKEN_AMOUNT) {
            tenPool.lastRewardBlock = block.number;
            return;
        }
        if(updateBlock > 0){
            if(block.number >= updateBlock){
                tenPool.lastRewardBlock = block.number;
                return;                
            }
        }
        uint256 tenReward = tenMineCalc.calcMineTenReward(tenPool.lastRewardBlock, block.number);
        tenReward = tenReward.mul(tenPool.allocPoint).div(totalAllocPoint);
        devaddrAmount = devaddrAmount.add(tenReward.div(10));
        ten.mint(address(this), tenReward);
        tenPool.accTenPerShare = tenPool.accTenPerShare.add(tenReward.mul(PERSHARERATE).div(tenPool.lpTokenTotalAmount));
        tenPool.lastRewardBlock = block.number;
        updateAllocPoint();
    }
    function _withdrawProjectTenPool(PoolInfo storage pool) internal returns (uint256 pending){
        if (pool.amount > MINLPTOKEN_AMOUNT) {
            pending = pool.amount.mul(tenProjectPool.accTenPerShare).div(PERSHARERATE).sub(pool.rewardTenDebt);
            if(pending > 0){
                if(pool.userCount == 0){
                    ten.burn(address(this),pending);
                    pending = 0;
                }
                else{
                    if(pool.userCount<minProjectUserCount){
                        uint256 newPending = pending.mul(bonusAllocPointBlock.mul(pool.userCount).div(minProjectUserCount).add(1e4)).div(bonusAllocPointBlock.add(1e4));
                        ten.burn(address(this),pending.sub(newPending));
                        pending = newPending;
                    }                    
                    pool.accTenPerShare = pool.accTenPerShare.add(pending.mul(PERSHARERATE).div(pool.lpTokenTotalAmount));
                }
            }
        }
    }
    function _updateProjectTenPoolAmount(PoolInfo storage pool,uint256 _amount,uint256 amountType) internal{
        if(amountType == 1){
            lpTokenTen.safeTransferFrom(msg.sender, address(this), _amount);
            tenProjectPool.lpTokenTotalAmount = tenProjectPool.lpTokenTotalAmount.add(_amount);
            pool.amount = pool.amount.add(_amount);
        }else if(amountType == 2){
            pool.amount = pool.amount.sub(_amount);
            if(pool.amount <= MINLPTOKEN_AMOUNT){
                pool.amount = 0;
            }
            lpTokenTen.safeTransfer(address(msg.sender), _amount);
            tenProjectPool.lpTokenTotalAmount = tenProjectPool.lpTokenTotalAmount.sub(_amount);
        }
        pool.rewardTenDebt = pool.amount.mul(tenProjectPool.accTenPerShare).div(PERSHARERATE);
    }
    function depositTenByProject(uint256 _pid,uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        PoolSettingInfo storage poolSetting = poolSettingInfo[_pid];
        require(poolSetting.projectAddr == msg.sender, "depositTenByProject: not good");
        _minePoolTen(tenProjectPool);
        _withdrawProjectTenPool(pool);
        _updateProjectTenPoolAmount(pool,_amount,1);
        emit DepositLPTen(msg.sender, 1, _amount,0,0,0);
    }

    function withdrawTenByProject(uint256 _pid,uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        PoolSettingInfo storage poolSetting = poolSettingInfo[_pid];
        require(poolSetting.projectAddr == msg.sender, "withdrawTenByProject: not good");
        require(pool.amount >= _amount, "withdrawTenByProject: not good");
        _minePoolTen(tenProjectPool);
        _withdrawProjectTenPool(pool);
        _updateProjectTenPoolAmount(pool,_amount,2);
        emit WithdrawLPTen(msg.sender, 1, _amount,0,0,0);
    }

    function _updatePoolUserInfo(uint256 accTenPerShare,UserInfo storage user,uint256 _freezeBlocks,uint256 _freezeTen,uint256 _amount,uint256 _amountType) internal {
        if(_amountType == 1){
            user.amount = user.amount.add(_amount);
        }else if(_amountType == 2){
            user.amount = user.amount.sub(_amount);
            if(user.amount<=MINLPTOKEN_AMOUNT){
                user.amount = 0;
            }          
        }
        user.rewardTenDebt = user.amount.mul(accTenPerShare).div(PERSHARERATE);
        user.lastBlockNumber = block.number;
        user.freezeBlocks = _freezeBlocks;
        user.freezeTen = _freezeTen;
    }
    function _calcFreezeTen(UserInfo storage user,uint256 accTenPerShare) internal view returns (uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen){
        pendingTen = user.amount.mul(accTenPerShare).div(PERSHARERATE).sub(user.rewardTenDebt);
        uint256 blockNow = block.number.sub(user.lastBlockNumber);
        uint256 periodBlockNumer = tenMineCalc.subBlockNumerPeriod();
        freezeBlocks = blockNow.add(user.freezeBlocks);
        if(freezeBlocks <= periodBlockNumer){
            freezeTen = pendingTen.add(user.freezeTen);
            pendingTen = 0;
        }else{
            if(pendingTen == 0){
                freezeBlocks = 0;
                freezeTen = 0;
                pendingTen = user.freezeTen;
            }else{
                freezeTen = pendingTen.add(user.freezeTen).mul(periodBlockNumer).div(freezeBlocks);
                pendingTen = pendingTen.add(user.freezeTen).sub(freezeTen);
                freezeBlocks = periodBlockNumer;
            }            
        }        
    }
    function _withdrawUserTenPool(address userAddr,UserInfo storage user) internal returns (uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen){
        (pendingTen,freezeBlocks,freezeTen) = _calcFreezeTen(user,tenUserPool.accTenPerShare);
        safeTenTransfer(userAddr, pendingTen);
    }   
    function depositTenByUser(uint256 _amount) public {
        UserInfo storage user = userInfoUserPool[msg.sender];
        _minePoolTen(tenUserPool);
        (uint256 pending,uint256 freezeBlocks,uint256 freezeTen) = _withdrawUserTenPool(msg.sender,user);
        lpTokenTen.safeTransferFrom(address(msg.sender), address(this), _amount);
        _updatePoolUserInfo(tenUserPool.accTenPerShare,user,freezeBlocks,freezeTen,_amount,1);
        tenUserPool.lpTokenTotalAmount = tenUserPool.lpTokenTotalAmount.add(_amount);        
        emit DepositLPTen(msg.sender, 2, _amount,pending,freezeTen,freezeBlocks);
    }

    function withdrawTenByUser(uint256 _amount) public {
        UserInfo storage user = userInfoUserPool[msg.sender];
        require(user.amount >= _amount, "withdrawTenByUser: not good");
        _minePoolTen(tenUserPool);
        (uint256 pending,uint256 freezeBlocks,uint256 freezeTen) = _withdrawUserTenPool(msg.sender,user);
        _updatePoolUserInfo(tenUserPool.accTenPerShare,user,freezeBlocks,freezeTen,_amount,2);
        tenUserPool.lpTokenTotalAmount = tenUserPool.lpTokenTotalAmount.sub(_amount);          
        lpTokenTen.safeTransfer(address(msg.sender), _amount);
        emit WithdrawLPTen(msg.sender, 2, _amount,pending,freezeTen,freezeBlocks);
    }

    function mineLPTen() public {
        _minePoolTen(tenUserPool);
        UserInfo storage user = userInfoUserPool[msg.sender];
        (uint256 pending,uint256 freezeBlocks,uint256 freezeTen) = _withdrawUserTenPool(msg.sender,user);
        _updatePoolUserInfo(tenUserPool.accTenPerShare,user,freezeBlocks,freezeTen,0,0);
        emit MineLPTen(msg.sender,pending,freezeTen,freezeBlocks);
    }
    function depositTenByUserFrom(address _from,uint256 _amount) public {
        UserInfo storage user = userInfoUserPool[_from];
        _minePoolTen(tenUserPool);
        (uint256 pending,uint256 freezeBlocks,uint256 freezeTen) = _withdrawUserTenPool(_from,user);
        lpTokenTen.safeTransferFrom(address(msg.sender), address(this), _amount);
        _updatePoolUserInfo(tenUserPool.accTenPerShare,user,freezeBlocks,freezeTen,_amount,1);
        tenUserPool.lpTokenTotalAmount = tenUserPool.lpTokenTotalAmount.add(_amount);        
        emit DepositLPTen(_from, 2, _amount,pending,freezeTen,freezeBlocks);
    } 
    function _minePoolToken(PoolInfo storage pool,PoolSettingInfo storage poolSetting) internal {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lpTokenTotalAmount > MINLPTOKEN_AMOUNT) {
            uint256 multiplier = tenMineCalc.getMultiplier(pool.lastRewardBlock, block.number,poolSetting.endBlock,poolSetting.tokenBonusEndBlock,poolSetting.tokenBonusMultipler);
            if(multiplier > 0){
                uint256 tokenReward = multiplier.mul(poolSetting.tokenPerBlock);
                pool.mineTokenAmount = pool.mineTokenAmount.add(tokenReward);
                pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(PERSHARERATE).div(pool.lpTokenTotalAmount));
            }
        }
        if(pool.lastRewardBlock < poolSetting.endBlock){
            if(block.number >= poolSetting.endBlock){
                if(poolSetting.tokenAmount.sub(pool.mineTokenAmount) > MINLPTOKEN_AMOUNT){
                    IERC20(poolSetting.tokenAddr).transfer(poolSetting.projectAddr,poolSetting.tokenAmount.sub(pool.mineTokenAmount));
                }
            }
        }
        pool.lastRewardBlock = block.number;
        _minePoolTen(tenProjectPool);
        _withdrawProjectTenPool(pool);
        _updateProjectTenPoolAmount(pool,0,0);
    }
    function _withdrawTokenPool(address userAddr,PoolInfo storage pool,UserInfo storage user,PoolSettingInfo storage poolSetting) 
            internal returns (uint256 pendingToken,uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen){
        if (user.amount > MINLPTOKEN_AMOUNT) {
            pendingToken = user.amount.mul(pool.accTokenPerShare).div(PERSHARERATE).sub(user.rewardTokenDebt);
            IERC20(poolSetting.tokenAddr).transfer(userAddr, pendingToken);
            (pendingTen,freezeBlocks,freezeTen) = _calcFreezeTen(user,pool.accTenPerShare);
            safeTenTransfer(userAddr, pendingTen);
        }
    }
    function _updateTokenPoolUser(uint256 accTokenPerShare,uint256 accTenPerShare,UserInfo storage user,uint256 _freezeBlocks,uint256 _freezeTen,uint256 _amount,uint256 _amountType) 
            internal {
        _updatePoolUserInfo(accTenPerShare,user,_freezeBlocks,_freezeTen,_amount,_amountType);
        user.rewardTokenDebt = user.amount.mul(accTokenPerShare).div(PERSHARERATE);
    }
    function depositLPToken(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        PoolSettingInfo storage poolSetting = poolSettingInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _minePoolToken(pool,poolSetting);
        (uint256 pendingToken,uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen) = _withdrawTokenPool(msg.sender,pool,user,poolSetting);
        if (user.amount <= MINLPTOKEN_AMOUNT) {
            pool.userCount = pool.userCount.add(1);
        }
        IERC20(poolSetting.lpToken).safeTransferFrom(address(msg.sender), address(this), _amount);
        pool.lpTokenTotalAmount = pool.lpTokenTotalAmount.add(_amount);
        _updateTokenPoolUser(pool.accTokenPerShare,pool.accTenPerShare,user,freezeBlocks,freezeTen,_amount,1);
        emit Deposit(msg.sender, _pid, _amount,pendingToken,pendingTen,freezeTen,freezeBlocks);
    }

    function withdrawLPToken(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolSettingInfo storage poolSetting = poolSettingInfo[_pid];
        require(user.amount >= _amount, "withdrawLPToken: not good");
        _minePoolToken(pool,poolSetting);
        (uint256 pendingToken,uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen) = _withdrawTokenPool(msg.sender,pool,user,poolSetting);
        _updateTokenPoolUser(pool.accTokenPerShare,pool.accTenPerShare,user,freezeBlocks,freezeTen,_amount,2);
        IERC20(poolSetting.lpToken).safeTransfer(address(msg.sender), _amount);
        pool.lpTokenTotalAmount = pool.lpTokenTotalAmount.sub(_amount);
        if(user.amount <= MINLPTOKEN_AMOUNT){
            pool.userCount = pool.userCount.sub(1);
        }        
        emit Withdraw(msg.sender, _pid, _amount,pendingToken,pendingTen,freezeTen,freezeBlocks);
    }

    function mineLPToken(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolSettingInfo storage poolSetting = poolSettingInfo[_pid];
        _minePoolToken(pool,poolSetting);
        (uint256 pendingToken,uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen) = _withdrawTokenPool(msg.sender,pool,user,poolSetting);
        _updateTokenPoolUser(pool.accTokenPerShare,pool.accTenPerShare,user,freezeBlocks,freezeTen,0,0);
        emit MineLPToken(msg.sender, _pid, pendingToken,pendingTen,freezeTen,freezeBlocks);
    }

    function depositLPTokenFrom(address _from,uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_from];
        PoolSettingInfo storage poolSetting = poolSettingInfo[_pid];
        _minePoolToken(pool,poolSetting);
        (uint256 pendingToken,uint256 pendingTen,uint256 freezeBlocks,uint256 freezeTen) = _withdrawTokenPool(_from,pool,user,poolSetting);
        if (user.amount <= MINLPTOKEN_AMOUNT) {
            pool.userCount = pool.userCount.add(1);
        }
        IERC20(poolSetting.lpToken).safeTransferFrom(msg.sender, address(this), _amount);
        pool.lpTokenTotalAmount = pool.lpTokenTotalAmount.add(_amount);
        _updateTokenPoolUser(pool.accTokenPerShare,pool.accTenPerShare,user,freezeBlocks,freezeTen,_amount,1);
        emit DepositFrom(_from, _pid, _amount,msg.sender,pendingToken,pendingTen,freezeTen,freezeBlocks);
    }
 
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function devWithdraw(uint256 _amount) public {
        require(block.number >= devWithdrawStartBlock, "devWithdraw: start Block invalid");
        require(msg.sender == devaddr, "devWithdraw: devaddr invalid");
        require(devaddrAmount >= _amount, "devWithdraw: amount invalid");        
        ten.mint(devaddr,_amount);
        devaddrAmount = devaddrAmount.sub(_amount);
        emit DevWithdraw(msg.sender, _amount);
    }    

    function safeTenTransfer(address _to, uint256 _amount) internal {
        if(_amount > MINLPTOKEN_AMOUNT){
            uint256 bal = ten.balanceOf(address(this));
            if (_amount > bal) {
                ten.transfer(_to, bal);
            } else {
                ten.transfer(_to, _amount);
            }
        }
    }        
}

