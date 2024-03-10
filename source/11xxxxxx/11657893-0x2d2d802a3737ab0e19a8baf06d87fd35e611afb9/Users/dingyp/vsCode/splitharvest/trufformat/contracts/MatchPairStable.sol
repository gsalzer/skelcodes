// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./uniswapv2/interfaces/IUniswapV2Pair.sol";
import './uniswapv2/libraries/UniswapV2Library.sol';
import './uniswapv2/libraries/TransferHelper.sol';

import "./utils/QueueStableStakesFuns.sol";
import "./utils/MasterCaller.sol";
import "./interfaces/IStakeGatling.sol";
import "./interfaces/IMatchPair.sol";
import "./interfaces/IPriceSafeChecker.sol";




contract MatchPairStable is  IMatchPair, Ownable, MasterCaller{
    using SafeERC20 for IERC20;
    using QueueStableStakesFuns for QueueStableStakes;
    using SafeMath for uint256; 
    
    uint256 profitRateDenominator;
    // round index of pair order
    uint256 public pairRound;
    uint256 public minToken0;
    uint256 public minToken1;

    struct QueuePoolInfo {
        //LP Token : LIFO
        UserStableStake[] lpQueue;
        //from LP to priorityQueue :FIFO
        QueueStableStakes priorityQueue;
        //Single Token  : FIFO
        QueueStableStakes pendingQueue;
        //Queue Total
        uint256 totalPending;
        //index of User index
        mapping(address => uint256[]) userLP;
        mapping(address => uint256[]) userPriority;
        mapping(address => uint256[]) userPending;
    }

    struct UserAmount {
        address user;
        uint256 amount;
    }

    struct RequestWrapper {
        uint256 index;
        address user;
        uint256 amount;
        uint256 rate;
        uint256 rate2;
    }
    
    //LP token Address
    IUniswapV2Pair public lpToken;
    //queue
    QueuePoolInfo queueStake0;
    QueuePoolInfo queueStake1;

    IStakeGatling stakeGatling;

    IPriceSafeChecker priceChecker;
    // LP index array each round
    // index0/1 => round => lpIndex[]
    mapping(uint256 => mapping(uint256 => uint256[])) roundLpIndex;

    event Stake(bool _index0, address _user, uint256 _amount);
    // int256 constant INT256_MAX = int256(~(uint256(1) << 255));
    constructor(address _lpToken) public {
        lpToken =  IUniswapV2Pair(_lpToken);
        createQueue(true, 10e7);
        createQueue(false, 10e7);
    }

   /**  From Library  */
    function createQueue(bool _isFirst, uint256 _size) private {
        QueuePoolInfo storage self = _isFirst? queueStake0 : queueStake1;
        self.priorityQueue.create(_size);
        self.pendingQueue.create(_size);
    }

    function setPriceSafeChecker(address _priceChecker) public onlyOwner() {
        priceChecker = IPriceSafeChecker(_priceChecker);
    }
    function setStakeGatling(address _gatlinAddress) public onlyOwner() {
        stakeGatling = IStakeGatling(_gatlinAddress);
        profitRateDenominator =   stakeGatling.profitRateDenominator();
    }

    function stake(uint256 _index, address _user,uint256 _amount) public override onlyMasterCaller() {
        
        toQueue(_index == 0, _user, _amount);
        updatePool();
    }
    
    function setMinLimit(uint256 _min0, uint256 _mint1 ) public onlyOwner() {
        minToken0 = _min0;
        minToken1 = _mint1;
    }

    function updatePool() private {
        (uint256 pendingA, uint256 pendingB) = ( queueStake0.totalPending, queueStake1.totalPending);

        //todo setting min pairableAmount
        if( pendingA > minToken0 && pendingB > minToken1 ) {
            
            (uint amountA, uint amountB) = getPairAmount( lpToken.token0(), lpToken.token1(), pendingA, pendingB ); 

            TransferHelper.safeTransfer(lpToken.token0(), address(lpToken), amountA);
            TransferHelper.safeTransfer(lpToken.token1(), address(lpToken), amountB);
            
            pairRound = pairRound + 1;
            //mint LP
            uint liquidity = lpToken.mint(address(this));
            // stake via stakeGatling
            TransferHelper.safeTransfer(address(lpToken), address(stakeGatling), liquidity);
            stakeGatling.stake(liquidity); // update Percent

            uint256 presentRate = stakeGatling.presentRate();


            pending2LP(true, amountA,  liquidity, presentRate, pairRound); 
            pending2LP(false,amountB,  liquidity, presentRate, pairRound);
            
        }
    }
    
    function getPairAmount(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired  ) public returns ( uint amountA, uint amountB) {
            
        (uint reserveA, uint reserveB,) = lpToken.getReserves();

        if( address(priceChecker) != address(0) ) {
            priceChecker.checkPrice(reserveA, reserveB);
        }

        uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
        if (amountBOptimal <= amountBDesired) {
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
            assert(amountAOptimal <= amountADesired);
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }
    
    function untakeToken(uint256 _index, address _user,uint256 _amount) 
        public
        override
        onlyMasterCaller()
        returns (uint256 _tokenAmount) 
    {
        //
        bool index0 = _index == 0;
        address tokenCurrent = index0 ? lpToken.token0() : lpToken.token1();
        _tokenAmount = untakePending(index0, _user, _amount);
        
        if(_tokenAmount < _amount) {
            uint256 amountRequerViaLp =  _amount.sub(_tokenAmount);
            //update rate
            stakeGatling.withdraw(0);
            uint256 presentRate = stakeGatling.presentRate();
            stakeGatling.presentRate();
//57

            
            ( UserAmount[] memory originAccountCurrent,
              UserAmount[] memory originAccountPaired, 
              uint256[] memory amountArray) = lpOriginAccountCalc( RequestWrapper(_index, _user, amountRequerViaLp, presentRate, 0 ));
              
             
            if(amountArray[2] > 0) {
                (uint tokenCurrent, uint tokenPaired) = coverageLose(_index, amountArray[0], amountArray[1], amountArray[2]);

                
                // balanceTokenCurrent, balanceTokenPaired . perShare
                uint256 tokenPerShare = tokenPaired.mul(1e36).div(amountArray[1]);

                distributePairedOrigin(index0, tokenPerShare, originAccountPaired );

                _tokenAmount = _tokenAmount.add(tokenCurrent);
            }
        }
        // transfer to Master
        TransferHelper.safeTransfer(tokenCurrent, masterCaller(), _tokenAmount);
    }

    function distributePairedOrigin(bool index0, uint256 tokenPerShare, UserAmount[] memory originAccountPaired ) private {

        uint256 balancePaired = IERC20( index0? lpToken.token1() : lpToken.token0()).balanceOf(address(this));

        uint256 accountLength = originAccountPaired.length;
        
        QueuePoolInfo storage _poolInfo = getQueuePoolInfo(!index0);
        QueueStableStakes storage _priorityQueue = _poolInfo.priorityQueue;
        mapping(address => uint256[])  storage _userPriority = _poolInfo.userPriority;

        for (uint i=0; i < accountLength; i++) {
            UserAmount memory account =  originAccountPaired[i];

            if(account.amount == 0) {

                break;
            }
            uint256 priorityAmount = account.amount.mul(tokenPerShare).div(1e36);
            
            uint256 pid = _priorityQueue.append(UserStableStake( account.user, priorityAmount, 0, 0, 0));
            _userPriority[account.user].push(pid);
            _poolInfo.totalPending = _poolInfo.totalPending.add(priorityAmount);
        }
    }

    function coverageLose(uint256 _index, uint256 amountOriginSumCurrent, uint256 amountOriginSumPaired, uint256 untakeLpAmount) private returns (uint256 tokenCuurent, uint256 tokenPaired) {



        address tokenCurrent = _index == 0 ? lpToken.token0() : lpToken.token1();
        uint256 pairedIndex = (_index+1)%2;
        //burn 
        (tokenCuurent, tokenPaired) = burnLp(_index, untakeLpAmount);





        bool enoughCurrent =  tokenCuurent >= amountOriginSumCurrent;
        bool enoughPaired  =  tokenPaired  >= amountOriginSumPaired;




        if(enoughCurrent == enoughPaired) { //ture ture || false false

        }else {
            bool sellCurrent = enoughCurrent;

            // paired lose
            uint256 amountLoss  = sellCurrent ? amountOriginSumPaired.sub(tokenPaired) : amountOriginSumCurrent.sub(tokenCuurent);
            uint256 amountWin = sellCurrent ? tokenCuurent.sub(amountOriginSumCurrent) : tokenPaired.sub(amountOriginSumPaired);
            uint256 regainRequireAmount = getAmountVinIndexed(sellCurrent ? pairedIndex : _index,  amountLoss);
            
            uint256 sellAmount;
            if(regainRequireAmount >= amountWin) {
                //sell Win
                sellAmount = amountWin;
            }else {
                // half profit
                sellAmount = amountWin.sub(regainRequireAmount).div(2).add(regainRequireAmount);
            }
            //sell
            regainRequireAmount = execSwap(sellCurrent? _index : pairedIndex, sellAmount);

            if(sellCurrent) {
                tokenCuurent = tokenCuurent.sub(sellAmount);
                tokenPaired  = tokenPaired.add(regainRequireAmount);
            }else {
                tokenCuurent = tokenCuurent.add(regainRequireAmount);
                tokenPaired  = tokenPaired.sub(sellAmount);
            }
        }
    }

    function execSwap(uint256 indexIn, uint256 amountIn ) private returns(uint256 amountOunt) {

        if(amountIn > 0) {
            amountOunt = getAmountVoutIndexed( indexIn,  amountIn);


            address sellToken = indexIn == 0? lpToken.token0() : lpToken.token1();
            TransferHelper.safeTransfer(sellToken, address(lpToken), amountIn);
            uint256 zero;
            (uint256 amount0Out, uint256 amount1Out ) = indexIn == 0 ? ( zero , amountOunt ) : (amountOunt, zero);
            lpToken.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }
    }

    //add to quequeEnd
    function toQueue(bool _isFirst, address _user,  uint256 _amount) private {
        QueuePoolInfo storage self =  getQueuePoolInfo(_isFirst); // _isFirst? queueStake0 : queueStake1;

        uint256 pIndex =  self.pendingQueue.append(UserStableStake( _user, _amount, 0, 0, 0));
        self.totalPending = self.totalPending.add(_amount);
        self.userPending[_user].push(pIndex);
        emit Stake(_isFirst, _user, _amount);
    }

    function getQueuePoolInfo(bool _isIndex0) private returns( QueuePoolInfo storage poolInfo ) {
        return _isIndex0 ? queueStake0 : queueStake1;
    }
    // untake from pendingQueue && priorityQueue
    function untakePending(bool _index0, address _user,  uint256 _amount) private returns (uint256 untakeAmount) {
        QueuePoolInfo storage self = _index0? queueStake0 : queueStake1;
        
        uint256[] storage pQueueIndex = self.userPending[_user];

        while(pQueueIndex.length>0) {
            uint256 pIndex = pQueueIndex[pQueueIndex.length.sub(1)];
            UserStableStake storage UserStableStake = self.pendingQueue.indexOf(pIndex);
            uint256 amount = UserStableStake.amount;

            if(untakeAmount.add(amount)>= _amount) {
                UserStableStake.amount = untakeAmount.add(amount).sub(_amount);
                untakeAmount = _amount;    
                break;
            }else{
                untakeAmount = untakeAmount.add(amount);
                UserStableStake.amount = 0;
                pQueueIndex.pop();
            }

        }
        if (untakeAmount < _amount) {
            uint256 untakeProority = untakePriority(_index0, _user, _amount.sub(untakeAmount));
            untakeAmount = untakeAmount.add(untakeProority);
        }

        self.totalPending = self.totalPending.sub(untakeAmount);
    }

    function untakePriority(bool _index0, address _user,  uint256 _amount) private returns(uint256 _untakeAmount) {
        QueuePoolInfo storage self = _index0? queueStake0 : queueStake1;
        uint256[] storage priorityIndex = self.userPriority[_user];
        uint256 untakeAmount;
        while( priorityIndex.length > 0 ) {
            uint256 pIndex = priorityIndex[priorityIndex.length.sub(1)];
            UserStableStake storage UserStableStake = self.priorityQueue.indexOf(pIndex);
            uint256 amount = UserStableStake.amount;
            //self assets only allows
            if(UserStableStake.user != _user ) {
                break;
            }
            if(untakeAmount.add(amount)>= _amount) {
                UserStableStake.amount = untakeAmount.add(amount).sub(_amount);
                return _amount;
            }else{
                untakeAmount = untakeAmount.add(amount);
                UserStableStake.amount = 0;
                priorityIndex.pop();
            }
        }
        return untakeAmount;
    }

    function pending2LP(bool _index0, uint256 _amount, uint256 _liquidity, uint256 _presentRate, uint256 _pairRound) private {
        // lpRate
        uint256 lpPreShare =  _liquidity.mul(1e36).div(_amount);
        uint leftAmount = moveQueue2LP(_index0, true, _amount, lpPreShare, _presentRate, _pairRound);
        //
        if(leftAmount>0) {
            moveQueue2LP(_index0, false, leftAmount, lpPreShare, _presentRate, _pairRound);
        }
        //update totalPending
        QueuePoolInfo storage self = _index0? queueStake0 : queueStake1;
        self.totalPending = self.totalPending.sub(_amount);
    }

    function burnLp(uint256 _index, uint256 _lpAmount) private returns (uint256 tokenCurrent, uint256 tokenPaired) {
        //send LP to address(this);
        // update profitRate
        bool index0 = _index == 0;
        address lpAddress = address(lpToken);
        
        stakeGatling.withdraw(_lpAmount);



        TransferHelper.safeTransfer(lpAddress, lpAddress, _lpAmount);

        (tokenCurrent, tokenPaired) = lpToken.burn(address(this));
        if(_index == 1) {
            (tokenCurrent, tokenPaired) = (tokenPaired, tokenCurrent );
        }

    }

     // LP to Priority
    function lpOriginAccountCalc(RequestWrapper memory request) 
        private
        returns (UserAmount[] memory , UserAmount[] memory , uint256[] memory )
    {

        uint256[] storage userLp =  request.index == 0? queueStake0.userLP[request.user] : queueStake1.userLP[request.user];

        UserAmount[] memory originAccountCurrent = new UserAmount[](userLp.length);
        //how to set length
        UserAmount[] memory originAccountPaired = new UserAmount[](0);
        uint256[] memory amountArray = new uint256[](3);

        uint256 index;
        while(userLp.length>0) {
            if(request.amount == 0) {
                break;
            }
            
            (uint256 cutLp10round, UserAmount memory burnAmount  ) = burnUserLp(request.index, userLp, request.rate, request.amount);
            if(burnAmount.amount ==0) {
                continue;
            }
 //82
            request.amount = request.amount.sub(burnAmount.amount);

            //retrun struts
            originAccountCurrent[index] = burnAmount;
            index++;
            amountArray[0] = amountArray[0].add(burnAmount.amount);
 //69

            (uint256 originPairAmount , UserAmount[] memory paireArray) = untakePairedLP( (cutLp10round % 1e10).mul(10).add(request.index ==0 ? 1:0), cutLp10round.div(1e10)+1, request.rate);

            originAccountPaired = mergeArray(originAccountPaired, paireArray);

            amountArray[1] = amountArray[1].add(originPairAmount);
            amountArray[2] = amountArray[2].add(cutLp10round.div(1e10));

        }

        return (originAccountCurrent, originAccountPaired, amountArray);
     
    }

    function mergeArray(UserAmount[] memory arrayA, UserAmount[] memory arrayB) private returns (UserAmount[] memory) {
            UserAmount[] memory arraySum = new UserAmount[](arrayA.length.add(arrayB.length));
            uint256 index;
            for (uint i=0; i < arrayA.length; i++) {
                arraySum[index] = arrayA[i];
                index++;
            }

            for (uint i=0; i < arrayB.length; i++) {
                arraySum[index] = arrayB[i];
                index++;
            }
            return arraySum;
    }
    //return uint256  = cutLp* 1e10 + round
    function burnUserLp(uint256 index, uint256[] storage userLp, uint256 _presentRate, uint256 requireTokenAmount) 
        private 
        returns (uint256, UserAmount memory)
    {

        UserStableStake[] storage queueStakes =  index == 0? queueStake0.lpQueue : queueStake1.lpQueue;
        uint256 pIndex = userLp[userLp.length.sub(1)];

        UserStableStake storage userStake = queueStakes[pIndex];


        if(userStake.amount ==0) {
            userLp.pop();
            return (0, UserAmount( address(0), 0));
        }
        // inflate profit
        uint256 amount = userStake.amount.mul(_presentRate).div(userStake.perRate); // profit

        address _user = userStake.user;
        uint256 _round = userStake.round;   
        uint256 _lpPerToken = userStake.lpPerToken;
        uint256 originTokenAmount = amount.mul(1e36).div(_lpPerToken);
//79
        UserAmount memory userAmount = UserAmount( _user, 0);
        uint256 cutLp;
        if(originTokenAmount >= requireTokenAmount) {
            uint256 amountLeft =  originTokenAmount.sub(requireTokenAmount);

            if(amountLeft == 0 ) {
                userStake.amount = 0;
                userLp.pop();
                cutLp = amount;
            }else {
                userStake.amount = amountLeft.mul(amount).div(originTokenAmount);
                userStake.perRate = _presentRate;
                cutLp = amount.sub(amountLeft.mul(amount).div(originTokenAmount).add(1));
            }
            userAmount.amount = requireTokenAmount;

        }else {
            userStake.amount = 0; 
            userLp.pop();
            cutLp = amount;
            userAmount.amount = cutLp.mul(1e36).div(_lpPerToken); 
        }

        
        return (cutLp.mul(1e10).add(_round), userAmount);
    }

    function untakePairedLP(uint256 _roundAndIndex, uint256 _amountLp, uint256 _presentRateC )
        private
        returns (uint256 amountOriginSumOther, UserAmount[] memory)
    {
        UserStableStake[] storage queueStakesOther =  _roundAndIndex %10 == 0? queueStake0.lpQueue : queueStake1.lpQueue;        
        uint[] storage pairLpIndex = roundLpIndex[_roundAndIndex %10][_roundAndIndex/10];
        
        // uint256 amountOriginSumOther;
        UserAmount[] memory originAccountOther = new UserAmount[](pairLpIndex.length);



        uint i;
        while(pairLpIndex.length>0) {

            if( _amountLp == 0 ){
                break;
            }
            UserStableStake storage userPair = queueStakesOther[pairLpIndex.length - 1];


            if(userPair.amount == 0) {
                pairLpIndex.pop(); //removeEnd
                continue;
            }
            uint256 amountPairLp = userPair.amount.mul(_presentRateC).div(userPair.perRate); // profit

            if(amountPairLp >= _amountLp) {
                userPair.amount = amountPairLp.sub(_amountLp);
                userPair.perRate = _presentRateC;

                amountOriginSumOther = amountOriginSumOther.add(_amountLp.mul(1e36).div(userPair.lpPerToken));
                originAccountOther[i] = UserAmount( userPair.user, _amountLp.mul(1e36).div(userPair.lpPerToken));
                break;
            }else {

                amountOriginSumOther = amountOriginSumOther.add(userPair.amount.mul(1e36).div(userPair.lpPerToken));

                originAccountOther[i] =  UserAmount( userPair.user, userPair.amount.mul(1e36).div(userPair.lpPerToken));
                userPair.amount = 0;
                _amountLp = _amountLp.sub(amountPairLp);
                pairLpIndex.pop(); //removeEnd
            }

            i++;
        }

        return (amountOriginSumOther, originAccountOther);

    }

    /**
     * @dev _amount , totoal amount to LP 
     * return left Amount to LP , pick from pendingQueue
     */
    function moveQueue2LP(bool _index0, bool isPriority, uint256 _amount , uint256 lpPreShare, uint256 _presentRate, uint256 _pairRound) private returns(uint256 untakeAmount) {
        QueuePoolInfo storage poolinfo = _index0? queueStake0 : queueStake1;
        QueueStableStakes storage queueStakes =  isPriority ? poolinfo.priorityQueue : poolinfo.pendingQueue;
        untakeAmount = _amount;




        // uint256[] memory indexArray  = new uint256[](2);
        // uint256 index = 0;
        while(queueStakes.used>0) { //used == length
            UserStableStake storage userStableStake = queueStakes.first();
            uint256 amount = userStableStake.amount;

            if(amount ==0) { 
                queueStakes.remove();
                continue;
            }
            if(untakeAmount <= amount) {
                if(untakeAmount == amount ) {
                    userStableStake.amount = 0;
                    queueStakes.remove();
                }else {
                    userStableStake.amount = amount.sub(untakeAmount);
                }
                //mark lpQueue index
                poolinfo.userLP[userStableStake.user].push(poolinfo.lpQueue.length);

                roundLpIndex[_index0 ? 0: 1][_pairRound].push(poolinfo.lpQueue.length);

                uint256 lpAmount = untakeAmount.mul(lpPreShare).div(1e36);


                poolinfo.lpQueue.push( UserStableStake( userStableStake.user, lpAmount, _presentRate , lpPreShare, _pairRound));

                untakeAmount = 0; 
                break;
            }else {
                untakeAmount = untakeAmount.sub(amount);
                userStableStake.amount = 0;
                queueStakes.remove();
                //mark lpQueue index
                poolinfo.userLP[userStableStake.user].push(poolinfo.lpQueue.length);
               

                roundLpIndex[_index0 ? 0: 1][_pairRound].push(poolinfo.lpQueue.length);

                uint256 lpAmount = amount.mul(lpPreShare).div(1e36);

                poolinfo.lpQueue.push(UserStableStake( userStableStake.user, lpAmount, _presentRate, lpPreShare , _pairRound));
            }
        }
    }

    function getAmountVinIndexed(uint256 _outIndex, uint256 _amountOut ) private returns(uint256 amountIn) {
        (uint256 _reserveIn, uint256 _reserveOut,) = lpToken.getReserves();
        if(_outIndex == 0) {
            (_reserveIn, _reserveOut) = (_reserveOut, _reserveIn);
        }
        amountIn = getAmountIn(_amountOut, _reserveIn, _reserveOut);
    }

    function getAmountVoutIndexed(uint256 _inIndex, uint256 _amountIn ) private returns(uint256 amountOut) {
        (uint256 _reserveIn, uint256 _reserveOut, ) = lpToken.getReserves();
        if(_inIndex == 1) {
            (_reserveIn, _reserveOut) = (_reserveOut, _reserveIn);
        }
        amountOut = getAmountOut(_amountIn, _reserveIn, _reserveOut);
    }

    function getAmountIn( uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {

        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    /** >>>>>>>  Call functions ,the following list  <<<<<<<<<<< */

    function lPAmount(uint256 _index, address _user) public view returns (uint256) {
        //gatlin profit rate
        uint256 presentRate = stakeGatling.presentRate();

        uint256 totalLPAmount;
        QueuePoolInfo memory self = _index == 0? queueStake0 : queueStake1;
        UserStableStake[] memory lpQueue = self.lpQueue;
        uint256[] memory lps =  _index == 0? queueStake0.userLP[_user] : queueStake1.userLP[_user];
        //lpQueue partion
        for (uint i=0; i< lps.length; i++) {
            
            uint256 amount = lpQueue[lps[i]].amount;
            totalLPAmount = totalLPAmount.add(amount);
        }
        return totalLPAmount;
    }

     function tokenAmount(uint256 _index, address _user) public view returns (uint256) {
        //gatlin profit rate
        uint256 totalLPAmount;
        QueuePoolInfo storage self = _index == 0? queueStake0 : queueStake1;

        uint256[] storage _userPriority = self.userPriority[_user];
        if( _userPriority.length > 0 ) {
            QueueStableStakes storage  _priorityQueue = self.priorityQueue;

            for (uint i=0; i< _userPriority.length; i++) {
                
                uint256 amount = _priorityQueue.indexOfView( _userPriority[i] ).amount;
                totalLPAmount = totalLPAmount.add(amount);
            }
        }

        uint256[] storage _userPending = self.userPending[_user];
        if( _userPending.length > 0 ) {
            QueueStableStakes storage  _pendingQueue = self.pendingQueue;

            for (uint i=0; i< _userPending.length; i++) {
                
                uint256 amount = _pendingQueue.indexOfView( _userPending[i]).amount;
                totalLPAmount = totalLPAmount.add(amount);
            }
        }
        return totalLPAmount;
    }

    function lp2TokenAmount(uint256 _liquidity) public view  returns (uint256 amount0, uint256 amount1) {

        uint256 _totalSupply = lpToken.totalSupply();
        (address _token0, address _token1) = (lpToken.token0(), lpToken.token1());

        uint balance0 = IERC20(_token0).balanceOf(address(lpToken));
        uint balance1 = IERC20(_token1).balanceOf(address(lpToken));

        // //
        // //

        amount0 = _liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = _liquidity.mul(balance1) / _totalSupply;

    }

    function maxAcceptAmount(uint256 _index, uint256 _times, uint256 _inputAmount) public view override returns (uint256) {
        
        QueuePoolInfo storage info =  _index == 0? queueStake0: queueStake1;
        (uint256 amount0, uint256 amount1) = stakeGatling.totalToken();

        uint256 pendingTokenAmount = info.totalPending;
        uint256 lpTokenAmount =  _index == 0 ? amount0 : amount1;

        require(lpTokenAmount.mul(_times) > pendingTokenAmount, "Amount in pool less than PendingAmount");
        uint256 maxAmount = lpTokenAmount.mul(_times).sub(pendingTokenAmount);
        
        return _inputAmount > maxAmount ? maxAmount : _inputAmount ; 
        
    }

    function queueTokenAmount(uint256 _index) public view override  returns (uint256) {
        QueuePoolInfo storage self = _index == 0? queueStake0 : queueStake1;
        return self.totalPending;
    }
    function balanceOfToken0(address _user) external view override returns (uint256) {
        return tokenAmount(0, _user);
    } 
    function balanceOfToken1(address _user) external view override returns (uint256) {
       return tokenAmount(1, _user);
    }
    //LP0 - LP1 Amount
    function balanceOfLP0(address _user) external view override returns (uint256) {
        return lPAmount(0, _user);
    }
    function balanceOfLP1(address _user) external view override  returns (uint256) {
        return lPAmount(1, _user);
    }

    function token(uint256 _index) public view override returns (address) {
        return _index == 0 ? lpToken.token0() : lpToken.token1();
    }

    function token0() public view override returns (address) {
        return lpToken.token0();
    }

    function token1() public view override returns (address) {
        return lpToken.token1();
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        return lpToken.getReserves();
    }

}

