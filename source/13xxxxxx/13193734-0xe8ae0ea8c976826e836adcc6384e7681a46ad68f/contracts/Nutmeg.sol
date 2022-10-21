// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// Use upgradeable library.  These interfaces will work for tokens that
// are non-upgradeable

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import './lib/Governable.sol';
import "./interfaces/IAdapter.sol";
import "./interfaces/INutmeg.sol";
import "./interfaces/INutDistributor.sol";
import "./interfaces/IPriceOracle.sol";

contract Nutmeg is Initializable, Governable, INutmeg {
    using SafeMath for uint;
    using Math for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public nutDistributor;
    address public nut;

    uint private constant INVALID_POSITION_ID = type(uint).max;
    uint private constant NOT_LOCKED = 0;
    uint private constant LOCKED = 1;
    uint private constant TRANCHE_BBB = uint(Tranche.BBB);
    uint private constant TRANCHE_A = uint(Tranche.A);
    uint private constant TRANCHE_AA = uint(Tranche.AA);

    uint private constant MULTIPLIER = 10**18;
    uint private constant NUM_BLOCK_PER_YEAR = 2102400;
    address private constant INVALID_ADAPTER = address(2);

    uint public constant MAX_NUM_POOL = 256;
    uint public constant LIQUIDATION_COMMISSION = 5;
    // This are in fact interest rate per apy
    // but keeping old names for legacy front end
    uint public constant MAX_INTEREST_RATE_PER_BLOCK = 100000; // 1000.00%
    uint public constant MIN_INTEREST_RATE_PER_BLOCK = 500; // 5.00%
    uint public constant VERSION_ID = 1;
    uint public POOL_LOCK;
    uint public EXECUTION_LOCK;
    uint public STAKE_COUNTER;
    uint public POSITION_COUNTER;
    uint public CURR_POSITION_ID;
    address public CURR_SENDER;
    address public CURR_ADAPTER;

    // treasury pool array and map
    address[] public pools; // array of treasury pools
    mapping(address => Pool) public poolMap; // baseToken => pool mapping.

    // stake
    mapping(address => mapping (address => Stake[3])) public stakeMap; // baseToken => sender => tranche.
    mapping(address => uint[]) public lenderStakeMap; // all stakes of a lender. address => stakeId
    mapping(uint => uint) public nutStakedMap; // the number of nut tokens staked in a position

    // adapter
    address[] public adapters;
    mapping(address => bool) public adapterMap;

    // position
    mapping(uint => Position) public positionMap;
    mapping(address => uint[]) public borrowerPositionMap; // all positions of a borrower. address => positionId
    mapping(address => mapping(address => uint)) public minNut4Borrowers; // pool => adapter => uint
    mapping(address => mapping(address => uint)) public mulNut4Borrowers; // pool => adapter => uint

    /// @dev Reentrancy lock guard.
    modifier poolLock() {
        require(POOL_LOCK == NOT_LOCKED, 'pl lck');
        POOL_LOCK = LOCKED;
        _;
        POOL_LOCK = NOT_LOCKED;
    }

    /// @dev Reentrancy lock guard for execution.
    modifier inExecution() {
        require(CURR_POSITION_ID != INVALID_POSITION_ID, 'not exc');
        require(CURR_ADAPTER == msg.sender, 'bad exc adpr');
        require(EXECUTION_LOCK == NOT_LOCKED, 'exc lock');
        EXECUTION_LOCK = LOCKED;
        _;
        EXECUTION_LOCK = NOT_LOCKED;
    }

    /// @dev Accrue interests in a pool
    modifier accrue(address token) {
        accrueInterest(token);
        _;
    }

    /// @dev Initialize the smart contract, using msg.sender as the first governor.
    function initialize(address _governor, address _nutAddr, address _nutDistAddr) external initializer {
        __Governable__init(_governor);
        nut = _nutAddr;
        nutDistributor = _nutDistAddr;
        POOL_LOCK = NOT_LOCKED;
        EXECUTION_LOCK = NOT_LOCKED;
        STAKE_COUNTER = 1;
        POSITION_COUNTER = 1;
        CURR_POSITION_ID = INVALID_POSITION_ID;
        CURR_ADAPTER = INVALID_ADAPTER;
    }

    function setNutDistributor(address addr) external onlyGov {
        nutDistributor = addr;
    }

    function setNut(address addr) external onlyGov {
        nut = addr;
    }

    function setMinNut4Borrowers(address poolAddr, address adapterAddr, uint val) external onlyGov {
        require(adapterMap[adapterAddr], 'setMin no adpr');
        Pool storage pool = poolMap[poolAddr];
        require(pool.isExists, 'setMin no pool');
        minNut4Borrowers[poolAddr][adapterAddr] = val;
    }
    
    function setMulNut4Borrowers(address poolAddr, address adapterAddr, uint val) external onlyGov {
        require(adapterMap[adapterAddr], 'setMul no adpr');
        Pool storage pool = poolMap[poolAddr];
        require(pool.isExists, 'setMul no pool');
        mulNut4Borrowers[poolAddr][adapterAddr] = val;
    }

    /// @notice Get all stake IDs of a lender
    function getStakeIds(address lender) external override view returns (uint[] memory){
        return lenderStakeMap[lender];
    }

    /// @notice Get all position IDs of a borrower
    function getPositionIds(address borrower) external override view returns (uint[] memory){
        return borrowerPositionMap[borrower];
    }

    /// @notice Return current position ID
    function getCurrPositionId() external override view returns (uint) {
        return CURR_POSITION_ID;
    }

    /// @notice Return next position ID
    function getNextPositionId() external override view returns (uint) {
        return POSITION_COUNTER;
    }

    /// @notice Get position information
    function getPosition(uint id) external override view returns (Position memory) {
        return positionMap[id];
    }

    /// @dev get current sender
    function getCurrSender() external override view returns (address) {
        return CURR_SENDER;
    }


    /// @dev Get all treasury pools
    function getPools() external view returns (address[] memory) {
        return pools;
    }

    /// @dev Get a specific pool given address
    function getPool(address addr) external view returns (Pool memory) {
        return poolMap[addr];
    }

    /// @dev Add a new treasury pool.
    /// @param token The underlying base token for the pool, e.g., DAI.
    /// @param interestRate The interest rate per block of Tranche A.
    function addPool(address token, uint interestRate)
        external poolLock onlyGov {
        require(pools.length < MAX_NUM_POOL, 'addPl pl > max');
        require(_isInterestRateValid(interestRate), 'addPl bad ir');
        Pool storage pool = poolMap[token];
        require(!pool.isExists, 'addPl pool exts');
        pool.isExists = true;
        pool.baseToken = token;
        uint irdiv2 = interestRate.div(2);
        pool.interestRates = [irdiv2, interestRate, interestRate.add(irdiv2)];
        pools.push(token);
        emit addPoolEvent(token, interestRate);
        pool.lossMultiplier = [ MULTIPLIER, MULTIPLIER, MULTIPLIER ];
    }

    /// @dev Update interest rate of the pool
    /// @param token The underlying base token for the pool, e.g., DAI.
    /// @param interestRate The interest rate per block of Tranche A. Input 316 for 3.16% APY
    function updateInterestRates(address token, uint interestRate)
        external poolLock onlyGov {
        require(_isInterestRateValid(interestRate), 'upIR bad ir');
        Pool storage pool = poolMap[token];
        uint irdiv2 = interestRate.div(2);
        pool.interestRates = [irdiv2, interestRate, interestRate.add(irdiv2)];
    }

    function _isInterestRateValid(uint interestRate)
        internal pure returns(bool) {
        return (interestRate <= MAX_INTEREST_RATE_PER_BLOCK &&
            interestRate >= MIN_INTEREST_RATE_PER_BLOCK);
    }

    /// @notice Stake to a treasury pool.
    /// @param token The contract address of the base token of the pool.
    /// @param tranche The tranche of the pool, 0 - AA, 1 - A, 2 - BBB.
    /// @param principal The amount of principal
    function stake(address token, uint tranche, uint principal)
        external poolLock accrue(token) {
        require(tranche < 3, 'stk bad trnch');
        require(principal > 0, 'stk bad prpl');
        Pool storage pool = poolMap[token];
        // whether the pool exists or not is checked in accrue
        if (tranche == TRANCHE_BBB) {
            require(principal.add(pool.principals[TRANCHE_BBB]) <= pool.principals[TRANCHE_AA],
                'stk BBB full');
        }

        // 1. check pre-conditions
        Stake storage stk = stakeMap[token][msg.sender][tranche];

        // 2. transfer the principal to the pool.
        IERC20Upgradeable(pool.baseToken).safeTransferFrom(msg.sender, address(this), principal);

        // 3. add or update a stake
        uint sumIpp = pool.sumIpp[tranche];
        uint scaledPrincipal = 0;

        if (stk.status != StakeStatus.Open) { // new stk
            stk.id = stk.status == StakeStatus.Closed ? stk.id : STAKE_COUNTER++;
            stk.status = StakeStatus.Open;
            stk.owner = msg.sender;
            stk.pool = token;
            stk.tranche = tranche;
            stk.sumIppStart = 0;
            stk.earnedInterest = 0;
            stk.lossMultiplierBase = 0;
            stk.lossZeroCounterBase = 0;
        } else { // add liquidity to an existing stk
	          scaledPrincipal = _scaleByLossMultiplier( stk, stk.principal );
            uint interest = scaledPrincipal.mul( sumIpp.sub(stk.sumIppStart)).div(MULTIPLIER);
            stk.earnedInterest = _scaleByLossMultiplier(stk, stk.earnedInterest ).add(interest);
        }
        stk.sumIppStart = sumIpp;
        stk.principal = scaledPrincipal.add(principal);
	      stk.lossZeroCounterBase = pool.lossZeroCounter[tranche];
	      stk.lossMultiplierBase = pool.lossMultiplier[tranche];
        lenderStakeMap[stk.owner].push(stk.id);

        // update pool information
        pool.principals[tranche] = pool.principals[tranche].add(principal);
        _rebalanceLoans(token, 0, 0, 0);
        updateInterestRateAdjustment(token);
        if (INutDistributor(nutDistributor).inNutDistribution()) {
            INutDistributor(nutDistributor).updateVtb(token, stk.owner, principal, 0);
        }

        emit stakeEvent(token, msg.sender, tranche, principal, stk.id);
    }



    /// @notice Unstake from a treasury pool.
    /// @param token The address of the pool.
    /// @param tranche The tranche of the pool, 0 - AA, 1 - A, 2 - BBB.
    /// @param amount The amount of principal that owner want to withdraw
    function unstake(address token, uint tranche, uint amount)
        external poolLock accrue(token) {
        require(tranche < 3, 'unstk bad trnch');
        Pool storage pool = poolMap[token];
        Stake storage stk = stakeMap[token][msg.sender][tranche];
        require(stk.id > 0, 'unstk no dpt');
        require(stk.status == StakeStatus.Open, 'unstk invalid status');
        uint activePrincipal = _scaleByLossMultiplier( stk, stk.principal );
        require(amount > 0 && amount <= activePrincipal, 'unstk bad amt');
        // get the available amount to remove
        uint withdrawAmt = _getWithdrawAmount(poolMap[stk.pool], tranche, amount);
        uint interest = activePrincipal.mul(pool.sumIpp[tranche].sub(stk.sumIppStart)).div(MULTIPLIER);
        uint totalInterest = _scaleByLossMultiplier(
            stk, stk.earnedInterest
        ).add(interest);
        if (totalInterest > pool.interests[tranche]) { // unlikely, but just in case.
            totalInterest = pool.interests[tranche];
        }

        // transfer liquidity to the lender
        uint actualWithdrawAmt = withdrawAmt.add(totalInterest);
        IERC20Upgradeable(pool.baseToken).safeTransfer(msg.sender, actualWithdrawAmt);

        // update stake information
        stk.principal = activePrincipal.sub(withdrawAmt);
        stk.sumIppStart = pool.sumIpp[tranche];
        stk.lossZeroCounterBase = pool.lossZeroCounter[tranche];
        stk.lossMultiplierBase = pool.lossMultiplier[tranche];
        stk.earnedInterest = 0;
        if (stk.principal == 0) {
            stk.status = StakeStatus.Closed;
        }

        // update pool principal and interest information
        pool.principals[tranche] = pool.principals[tranche].sub(withdrawAmt);
        pool.interests[tranche] = pool.interests[tranche].sub(totalInterest);
        _rebalanceLoans(token, 0, 0, 0);
        updateInterestRateAdjustment(token);
        if (INutDistributor(nutDistributor).inNutDistribution() && withdrawAmt > 0) {
            INutDistributor(nutDistributor).updateVtb(token, stk.owner, 0, withdrawAmt);
        }

        emit unstakeEvent(token, msg.sender, tranche, withdrawAmt, stk.id);
    }

    function _scaleByLossMultiplier(Stake memory stk, uint quantity) internal view returns (uint) {
	      Pool storage pool = poolMap[stk.pool];
	      return stk.lossZeroCounterBase < pool.lossZeroCounter[stk.tranche] ? 0 :
	          quantity.mul(
	          pool.lossMultiplier[stk.tranche]
	      ).div(
	          stk.lossMultiplierBase
	      );
    }

    /// @notice Accrue interest for a given pool.
    /// @param token Address of the pool.
    function accrueInterest(address token) internal {
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'accrIr no pool');

        uint totalPrincipal = pool.principals[0].add(pool.principals[1]).add(pool.principals[2]);
        uint currBlock = block.number;
        if (currBlock <= pool.latestAccruedBlock) return;
        if (totalPrincipal > 0 ) {
            uint totalLoans = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);
            uint interestRate = pool.interestRates[TRANCHE_A];
            if (!pool.isIrAdjustPctNegative) {
                interestRate = interestRate.mul(pool.irAdjustPct.add(100)).div(100);
            } else {
                interestRate = interestRate.mul(uint(100).sub(pool.irAdjustPct)).div(100);
            }
            uint rtb = interestRate.mul(currBlock.sub(pool.latestAccruedBlock));

            // update pool sumRtb.
            pool.sumRtb = pool.sumRtb.add(rtb);

            uint totalWeightedPrincipals = pool.principals[0].mul(1).add(
                pool.principals[1].mul(2)
            ).add(pool.principals[2].mul(3));

            // update tranche sumIpp.
            for (uint idx = 0; idx < pool.principals.length; idx++) {
                if (pool.principals[idx] > 0) {
                    uint interest = (totalLoans.mul(pool.principals[idx]).mul(idx+1).mul(rtb)).div(
                        NUM_BLOCK_PER_YEAR.mul(10000).mul(totalWeightedPrincipals)
                    );
                    pool.interests[idx] = pool.interests[idx].add(interest);
                    pool.sumIpp[idx]= pool.sumIpp[idx].add(interest.mul(MULTIPLIER).div(pool.principals[idx]));
                }
            }
        }
        pool.latestAccruedBlock = block.number;
    }

    /// @notice Get pool information
    /// @param token The base token
    function getPoolInfo(address token) external view override returns(uint, uint, uint) {
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'getPolInf no pol');
        return (pool.principals[0].add(pool.principals[1]).add(pool.principals[2]),
                pool.loans[0].add(pool.loans[1]).add(pool.loans[2]),
                pool.totalCollateral);
    }

    /// @notice Get interest a position need to pay
    /// @param token Address of the pool.
    /// @param posId Position ID.
    function getPositionInterest(address token, uint posId) public override view returns(uint) {
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'getPosIR no pool');
        Position storage pos = positionMap[posId];
        require(pos.baseToken == pool.baseToken, 'getPosIR bad match');
        return pos.loanAmt.mul(pool.sumRtb.sub(pos.sumRtbStart)).div(
            NUM_BLOCK_PER_YEAR.mul(10000)
        );
    }

    /// @dev Update the interest rate adjustment of the pool
    /// @param token Address of the pool
    function updateInterestRateAdjustment(address token) internal {
        Pool storage pool = poolMap[token];
        uint totalPrincipal = pool.principals[0].add(pool.principals[1]).add(pool.principals[2]);
        uint totalLoan = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);
        uint urPct = totalPrincipal > 0 ?
            ( totalLoan >= totalPrincipal ? 100 : totalLoan.mul(100).div(totalPrincipal) ) : 0;
        if (urPct >= 90) { // 0% + 50 * (UR - 90%)
            pool.irAdjustPct = urPct.sub(90).mul(50);
            pool.isIrAdjustPctNegative = false;
        } else { // UR - 90%
            pool.irAdjustPct = (uint(90).sub(urPct));
            pool.isIrAdjustPctNegative = true;
        }
     }

    function _getWithdrawAmount(Pool memory pool, uint tranche, uint amount) internal pure returns (uint) {
        uint totalPrincipal = pool.principals[0].add(pool.principals[1]).add(pool.principals[2]);
        uint totalLoans = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);
        uint availPrincipal =  totalPrincipal.sub(totalPrincipal.min(totalLoans));
        return amount.min(availPrincipal.min(pool.principals[tranche]));
    }

    /// @dev Get the collateral ratio of the pool.
    /// @param baseToken Base token of the pool.
    /// @param baseAmt The collateral from the borrower.
    function _getCollateralRatioPct(address baseToken, uint baseAmt) public view returns (uint) {
        Pool storage pool = poolMap[baseToken];
        require(pool.isExists, '_getCollRatPct no pool');

        uint totalPrincipal = pool.principals[0].add(pool.principals[1]).add(pool.principals[2]);
        uint totalLoan = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);

        uint urPct = (totalPrincipal == 0) ? 100 : ((totalLoan.add(baseAmt)).mul(100)).div(totalPrincipal);
        if (urPct > 100) {
            urPct = 100;
        }

        if (urPct > 90) { // 10% + 9 * (UR - 90%)
            return (urPct.sub(90).mul(9)).add(10);
        }
        // 10% - 0.1 * (90% - UR)
        return (urPct.div(10)).add(1);
    }

    /// @notice Get the maximum available borrow amount
    /// @param baseToken Base token of the pool
    /// @param baseAmt The collateral from the borrower
    function getMaxBorrowAmount(address baseToken, uint baseAmt)
        public override view returns (uint) {
        Pool storage pool = poolMap[baseToken];
        uint totalPrincipal = pool.principals[0].add(pool.principals[1]).add(pool.principals[2]);
        uint totalLoan = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);

        uint crPct = _getCollateralRatioPct(baseToken, baseAmt);

        uint maxAmt = baseAmt.mul(100).div(crPct).sub(baseAmt);
        // This will intentionally revert if totalPrincipal <= totalLoan.
        // as this means that the contract is in an unexpected state
        if (maxAmt > totalPrincipal.sub(totalLoan)) {
            maxAmt = totalPrincipal.sub(totalLoan);
        }
        return maxAmt;
    }


    /// @notice Get stakes of a user in a pool
    /// @param token The address of the pool
    /// @param owner The address of the owner
    function getStake(address token, address owner) public view returns (Stake[3] memory) {
        return stakeMap[token][owner];
    }

    /// @dev Add adapter to Nutmeg
    /// @param adapter The address of the adapter
    function addAdapter(address adapter) external poolLock onlyGov {
        adapters.push(adapter);
        adapterMap[adapter] = true;
    }
    /// @dev Remove adapter from Nutmeg
    /// @param adapter The address of the adapter
    function removeAdapter(address adapter) external poolLock onlyGov {
        adapterMap[adapter] = false;
    }

    /// @notice Borrow tokens from the pool. Must only be called by adapter while under execution.
    /// @param baseToken The token to borrow from the pool.
    /// @param collToken The token borrowers got from the 3rd party pool.
    /// @param baseAmt The amount of collateral from borrower.
    /// @param borrowAmt The amount of tokens to borrow, x time leveraged already.
    function borrow(address baseToken, address collToken, uint baseAmt, uint borrowAmt)
        external override accrue(baseToken) inExecution {
        // check pool and position.
        Pool storage pool = poolMap[baseToken];
        // pool existence is checked in accrue
        Position storage pos = positionMap[CURR_POSITION_ID];
        // check borrowAmt
        uint maxBorrowAmt = getMaxBorrowAmount(baseToken, baseAmt);
        require(borrowAmt <= maxBorrowAmt, "brw too bad");
        require(borrowAmt >= baseAmt, "brw brw < coll");

        // transfer base tokens from borrower to contract as the collateral.
        IERC20Upgradeable(pool.baseToken).safeTransferFrom(pos.owner, address(this), baseAmt);

        // transfer borrowed assets to the adapter
        IERC20Upgradeable(pool.baseToken).safeTransfer(msg.sender, borrowAmt);

        // move over nut tokens
        uint nutRequired = minNut4Borrowers[baseToken][pos.adapter].add(
            mulNut4Borrowers[baseToken][pos.adapter].mul(borrowAmt).div(MULTIPLIER)
        );
        if (nutRequired > 0) {
           nutStakedMap[pos.id] = nutRequired;
           IERC20Upgradeable(nut).safeTransferFrom(pos.owner, address(this), nutRequired);
        }

        // update position information
        pos.status = PositionStatus.Open;
        pos.baseToken = pool.baseToken;
        pos.collToken = collToken;
        pos.baseAmt = baseAmt;
        pos.borrowAmt = borrowAmt;
        pos.loanAmt = borrowAmt;
        pos.sumRtbStart = pool.sumRtb;

        borrowerPositionMap[pos.owner].push(pos.id);
        _rebalanceLoans(baseToken, 0, borrowAmt, 0);
        pool.totalCollateral = pool.totalCollateral.add(baseAmt);
        updateInterestRateAdjustment(baseToken);
    }

    function _rebalanceLoans(address addr,
                             uint posLoan, uint addAmt, uint subAmt)
        internal {
        Pool storage pool = poolMap[addr];
        uint totalPrincipal = pool.principals[0].add(pool.principals[1]).add(pool.principals[2]);
        if (totalPrincipal == 0) {
            return;
        }
        subAmt = posLoan < subAmt ? posLoan : subAmt;
        uint totalLoans = pool.loans[0].add(pool.loans[1]).add(pool.loans[2]);
        totalLoans = totalLoans.add(addAmt).sub(subAmt);
        pool.loans[0] =
            totalLoans.mul(pool.principals[0]).div(totalPrincipal);
        pool.loans[1] =
            totalLoans.mul(pool.principals[1]).div(totalPrincipal);
        // handling rounding numbers
        pool.loans[2] =
            totalLoans.sub(pool.loans[0].add(pool.loans[1])); 

        if (pool.loans[2] > pool.principals[2]) {
            pool.loans[1] = pool.loans[1].add(pool.loans[2]).sub(
                pool.principals[2]
            );
            pool.loans[2] = pool.principals[2];
        }
        if (pool.loans[1] > pool.principals[1]) {
            pool.loans[0] = pool.loans[0].add(pool.loans[1]).sub(
                pool.principals[1]
            );
            pool.loans[1] = pool.principals[1];
        }
    }

    /// @notice Repay tokens to the pool and close the position. Must only be called while under execution.
    /// @param baseToken The token to borrow from the pool.
    /// @param repayAmt The amount of base token repaid from adapter.
    function repay(address baseToken, uint repayAmt)
        external override accrue(baseToken) inExecution {

        Position storage pos = positionMap[CURR_POSITION_ID];
        Pool storage pool = poolMap[pos.baseToken];
        // pool existence is checked in accrue
        require(adapterMap[pos.adapter] && msg.sender == pos.adapter, 'repay: no such adapter');

        uint totalLoan = pos.loanAmt; // owe to lenders
        uint interest = getPositionInterest(pool.baseToken, pos.id); // already paid to lenders
        uint totalRepayAmt = repayAmt.add(pos.baseAmt).sub(interest); // total amount used for repayment
        uint change = totalRepayAmt > totalLoan ? totalRepayAmt.sub(totalLoan) : 0; // profit of the borrower


        // transfer total redeemed amount from adapter to the pool
        IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, address(this), repayAmt);
        if (totalRepayAmt < totalLoan) {
            pos.repayDeficit = totalLoan.sub(totalRepayAmt);
        }
        _rebalanceLoans(baseToken, pos.loanAmt, 0, repayAmt);
        // update position information
        pos.status = PositionStatus.Closed;
        pos.loanAmt = repayAmt < pos.loanAmt ? pos.loanAmt.sub(repayAmt) : 0;

        // update pool information
        pool.totalCollateral = pos.baseAmt < pool.totalCollateral ?
            pool.totalCollateral.sub(pos.baseAmt) : 0;

        // send profit, if any to the borrower.
        IERC20Upgradeable(baseToken).safeTransfer(pos.owner, change);

        // return nut if any
        //
        // in current implementation the if statement will always trigger
        // however, this is in place to deal with any future changes that will
        // allow for partial repays
        //
        // This will create an uncovered branch
        if (pos.status == PositionStatus.Closed) {
            IERC20Upgradeable(nut).safeTransfer(pos.owner, nutStakedMap[pos.id]);
            nutStakedMap[pos.id] = 0;
        }
        updateInterestRateAdjustment(baseToken);
    }

    /// @notice Liquidate a position when conditions are satisfied
    /// @param baseToken The base token of the pool.
    /// @param liquidateAmt The repay amount from adapter.
    function liquidate( address baseToken, uint liquidateAmt)
        external override accrue(baseToken) inExecution {
        Position storage pos = positionMap[CURR_POSITION_ID];
        Pool storage pool = poolMap[baseToken];
        // pool existence is checked in accrue
        require(adapterMap[pos.adapter] && msg.sender == pos.adapter, 'lqt no adpr');
        require(liquidateAmt > 0, 'lqt bad rpy');

        // transfer liquidateAmt of base tokens from adapter to pool.
        IERC20Upgradeable(baseToken).safeTransferFrom(msg.sender, address(this), liquidateAmt);

        uint totalLoan = pos.loanAmt;
        uint interest = getPositionInterest(pool.baseToken, pos.id);
        uint totalRepayAmt = liquidateAmt.add(pos.baseAmt).sub(interest); // total base tokens from liquidated
        uint bonusAmt = LIQUIDATION_COMMISSION.mul(totalRepayAmt).div(100); // bonus for liquidator.

        uint repayAmt = totalRepayAmt.sub(bonusAmt); // amount to pay lenders and the borrower
        uint change = totalLoan < repayAmt ? repayAmt.sub(totalLoan) : 0;

        _rebalanceLoans(baseToken, pos.loanAmt, 0, liquidateAmt);

        // transfer bonus to the liquidator.
        IERC20Upgradeable(baseToken).safeTransfer(CURR_SENDER, bonusAmt);

        // update position information
        pos.status = PositionStatus.Liquidated;
        pos.loanAmt =
           liquidateAmt < pos.loanAmt ? pos.loanAmt.sub(liquidateAmt) : 0;

        // update pool information
        pool.totalCollateral =
            pos.baseAmt < pool.totalCollateral ?
                pool.totalCollateral.sub(pos.baseAmt) : 0;

        // send leftover to position owner
        IERC20Upgradeable(baseToken).safeTransfer(pos.owner, change);

        if (totalRepayAmt < totalLoan) {
            pos.repayDeficit = totalLoan.sub(totalRepayAmt);
        }
        // return all nut tokens as partial liquidations are not possible
        IERC20Upgradeable(nut).safeTransfer(pos.owner, nutStakedMap[pos.id]);
        nutStakedMap[pos.id] = 0;
        updateInterestRateAdjustment(baseToken);
    }

    /// @notice Settle credit event callback
    /// @param baseToken Base token of the pool.
    /// @param collateralLoss Loss to be distributed
    /// @param poolLoss Loss to be distributed
    function distributeCreditLosses( address baseToken, uint collateralLoss, uint poolLoss) external override accrue(baseToken) inExecution {
        Pool storage pool = poolMap[baseToken];
        // pool existence is checked in accrue
        require(collateralLoss <= pool.totalCollateral, 'dstCrd col high');
        pool.totalCollateral = pool.totalCollateral.sub(collateralLoss);

        if (poolLoss == 0) {
            return;
        }
        uint runningLoss = poolLoss;
        for (uint i = 0; i < 3; i++) {
            uint j = 3 - i - 1;
            // The running totals are based on the principal,
            // however, when I calculate the multipliers, I
            // take into account accured interest
            uint tranchePrincipal = pool.principals[j];
            uint trancheValue = pool.principals[j].add(pool.interests[j]);
            // Do not scale pool.sumIpp.  Since I am scaling the
            // principal, this will cause the interest rate
            // calcuations to take into account the losses when
            // a lender position is unstaked.
            if (runningLoss >= tranchePrincipal) {
                pool.principals[j] = 0;
                pool.interests[j] = 0;
                pool.lossZeroCounter[j] = block.number;
                pool.lossMultiplier[j] = MULTIPLIER;
                runningLoss = runningLoss.sub(tranchePrincipal);
            } else {
                uint valueRemaining = tranchePrincipal.sub(runningLoss);
		            pool.principals[j] = pool.principals[j].mul(valueRemaining).div(trancheValue);
		            pool.interests[j] = pool.interests[j].mul(valueRemaining).div(trancheValue);
		            pool.lossMultiplier[j] = valueRemaining.mul(MULTIPLIER).div(trancheValue);
		            break;
	          }
        }
        _rebalanceLoans(baseToken, poolLoss, 0, poolLoss);
        updateInterestRateAdjustment(baseToken);
    }

    /// @notice Add collateral token to position. Must be called during execution.
    /// @param posId Position id
    /// @param collAmt The amount of the collateral token from 3rd party pool.
    function setCollAmt(uint posId, uint collAmt)
        external override inExecution {
        Position storage pos = positionMap[CURR_POSITION_ID];
        require(pos.id == posId, "addCollTk bad pos");

        pos.collAmt = collAmt;
    }

    function getEarnedInterest( address token, address owner, Tranche tranche ) external view returns (uint256) {
        Pool storage pool = poolMap[token];
        require(pool.isExists, 'gtErndIr no pool');
        Stake memory stk = getStake(token, owner)[uint(tranche)];
        return _scaleByLossMultiplier(
            stk,
            stk.earnedInterest.add(
                stk.principal.mul(
                    pool.sumIpp[uint(tranche)].sub(stk.sumIppStart)
                ).div(MULTIPLIER))
        );
    }

    /// -------------------------------------------------------------------
    /// functions to adapter
    function beforeExecution( uint posId, IAdapter adapter ) internal {
        require(POOL_LOCK == NOT_LOCKED, 'pol lck');
        POOL_LOCK = LOCKED;
        address adapterAddr = address(adapter);
        require(adapterMap[adapterAddr], 'no adpr');

        if (posId == 0) {
            // create a new position
            posId = POSITION_COUNTER++;
            positionMap[posId].id = posId;
            positionMap[posId].owner = msg.sender;
            positionMap[posId].adapter = adapterAddr;
        } else {
            require(posId < POSITION_COUNTER, 'no pos');
            require(positionMap[posId].status == PositionStatus.Open, 'only open pos');
            require(positionMap[posId].adapter == adapterAddr, 'bad adpr');
        }

        CURR_POSITION_ID = posId;
        CURR_ADAPTER = adapterAddr;
        CURR_SENDER = msg.sender;
    }

    function afterExecution() internal {
        CURR_POSITION_ID = INVALID_POSITION_ID;
        CURR_ADAPTER = INVALID_ADAPTER;
        POOL_LOCK = NOT_LOCKED;
        CURR_SENDER = address(0);
    }

    function openPosition( IAdapter adapter, address baseToken, address collToken, uint baseAmt, uint borrowAmt ) external {
        beforeExecution(0, adapter);
        adapter.openPosition( baseToken, collToken, baseAmt, borrowAmt );
        afterExecution();
    }

    function closePosition( uint posId, IAdapter adapter ) external returns (uint) {
        require(posId != 0, 'clp 0id');
        beforeExecution(posId, adapter);
        uint redeemAmt = adapter.closePosition();
        afterExecution();
        return redeemAmt;
    }

    function liquidatePosition( uint posId, IAdapter adapter ) external {
        require(posId != 0, 'liqt 0id');
        beforeExecution(posId, adapter);
        adapter.liquidate();
        afterExecution();
    }

    function settleCreditEvent( IAdapter adapter, address baseToken, uint collateralLoss, uint poolLoss ) onlyGov external {
        beforeExecution(0, adapter);
        adapter.settleCreditEvent( baseToken, collateralLoss, poolLoss );
        afterExecution();
    }

    function getMaxUnstakePrincipal(address token, address owner, uint tranche) external view returns (uint) {
        Stake memory stk = stakeMap[token][owner][tranche];
        return _getWithdrawAmount(poolMap[stk.pool], tranche, stk.principal);
    }

    function version() public virtual pure returns (string memory) {
        return "1.0.4.1";
    }
}

