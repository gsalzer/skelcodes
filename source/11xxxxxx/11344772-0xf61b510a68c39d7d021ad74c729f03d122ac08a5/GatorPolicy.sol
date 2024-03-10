pragma solidity 0.4.24;

import "./Gator.sol";

library UInt256Lib {
    
    uint256 private constant MAX_INT256 = (2**255)-1;

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256, "SafeCast: value doesn't fit in an int256");
        return int256(a);
    }
}

contract GatorPolicy is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    event LogRebase(
        uint256 indexed epoch,
        uint256 exchangeRate,
        uint256 cpi,
        int256 requestedSupplyAdjustment,
        uint256 timestampSec
    );

    GatorToken public uFrags;

    // CPI value at the time of launch, as an 18 decimal fixed point number.
    // uint256 private baseCpi;

    uint256 public deviationThreshold;

    // The actual token price, will update only if deviationThreshold crossed
    uint256 public token_price;

    // The rebase lag parameter, used to dampen the applied supply adjustment by 1 / rebaseLag
    // Check setRebaseLag comments for more details.
    // Natural number, no decimal places.
    //uint256 public rebaseLag;

    // More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    // The rebase window begins this many seconds into the minRebaseTimeInterval period.
    // For example if minRebaseTimeInterval is 24hrs, it represents the time of day in seconds.
    //uint256 public rebaseWindowOffsetSec;

    // The length of the time window where a rebase operation is allowed to execute, in seconds.
    //uint256 public rebaseWindowLengthSec;

    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 18;

    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 10**6*10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = ~(uint256(1) << 255) / MAX_RATE;

    // This module orchestrates the rebase execution and downstream notification.
    address public orchestrator;

    modifier onlyOrchestrator() {
        require(msg.sender == orchestrator);
        _;
    }

    function rebase(uint256 wei_token_price) external
    onlyOrchestrator
    {
        //sets the epoch
        epoch = epoch.add(1);
        
        //compute supply delta    
        int256 supplyDelta = computeSupplyDelta(wei_token_price);
        
        if(supplyDelta == 0) {
            //require that 24 hours has passed and then set the current token price without rebasing supply
            require(lastRebaseTimestampSec + 24 hours < now, "24 hours has not passed since the last rebase");

            //set the price and return
            token_price = wei_token_price;
            
            // Snap the rebase time after changes are made
            lastRebaseTimestampSec = now;
        } else {
            
            // This comparison also ensures there is no reentrancy.
            require(lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now , "30 minutes has not passed since last rebase");
            
            //to continue from here, the price must have increased past the old price
            require(supplyDelta != 0,"not a 5% increase");
            
            //this sets the total_supply to max_supply
            if (supplyDelta > 0 && uFrags.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
                supplyDelta = (MAX_SUPPLY.sub(uFrags.totalSupply())).toInt256Safe();
            }
            
            //only repegs up
            uint old_token_price = token_price;
            require(wei_token_price > old_token_price, "new token price is not greater than old");
            
            //split the difference b/w old and new
            uint actual_new_token_price = old_token_price + uint(wei_token_price - old_token_price).div(2);
            int256 actual_rebase_price_delta = computeSupplyDelta(actual_new_token_price);
            
            //update totals
            uFrags.rebase(epoch, actual_rebase_price_delta);
            
            // Snap the rebase time to the start of this window. Ensures 30 minutes passed since last rebase call
            lastRebaseTimestampSec = now;
            
            token_price = actual_new_token_price;
        }
            
    }
        
    function setOrchestrator(address orchestrator_)
        external
        onlyOwner
    {
        require(orchestrator_ != address(0));
        orchestrator = orchestrator_;
    }

    function setTokenPrice(uint256 _token_price)
        external
        onlyOwner
    {   
        //set in wei
        token_price = _token_price;
    }

    function setDeviationThreshold(uint256 deviationThreshold_)
        external
        onlyOwner
    {
        // deviationThreshold = 0.05e18 = 5e16 5%
        deviationThreshold = deviationThreshold_;
    }

    function setRebaseTimingParameters(
        uint256 minRebaseTimeIntervalSec_,
        uint256 rebaseWindowOffsetSec_)
        external
        onlyOwner
    {
        require(minRebaseTimeIntervalSec_ > 0);
        require(rebaseWindowOffsetSec_ < minRebaseTimeIntervalSec_);

        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
    }

    constructor(GatorToken uFrags_, uint256 _token_price)
        public
    {
        
        token_price = _token_price;

        // deviationThreshold = 0.05e18 = 5e16
        deviationThreshold = 5 * 10 ** (DECIMALS-2); // 5%

        minRebaseTimeIntervalSec = 30 minutes;
        lastRebaseTimestampSec = now;
        epoch = 0;

        uFrags = uFrags_;

    }

    function computeSupplyDelta(uint256 new_price)
        public
        view
        returns (int256)
    {
        if (withinDeviationThreshold(new_price, token_price)) {
            return 0;
        }
        if (new_price < token_price) {
            return 0;
        }

        // supplyDelta = totalSupply * (rate - targetRate) / targetRate
        int256 targetRateSigned = token_price.toInt256Safe();

        return uFrags.totalSupply().toInt256Safe()
            .mul(new_price.toInt256Safe().sub(targetRateSigned))
            .div(targetRateSigned);
    }


    function withinDeviationThreshold(uint256 new_price, uint256 old_price)
        public
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = old_price.mul(deviationThreshold).div(10**DECIMALS);
        
        return (new_price >= old_price && new_price.sub(old_price) < absoluteDeviationThreshold)
            || (new_price < old_price && old_price.sub(new_price) < absoluteDeviationThreshold);
    }
}

