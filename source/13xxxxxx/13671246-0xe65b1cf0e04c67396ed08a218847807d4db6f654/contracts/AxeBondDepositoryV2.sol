// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./libraries/Ownable.sol";
import "./libraries/SafeMath.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/ERC20.sol";

interface ITreasury {
    function deposit( uint _amount, address _token, uint _profit ) external returns ( bool );
    function valueOfToken( address _token, uint _amount ) external view returns ( uint value_ );
}

interface IBondCalculator {
    function valuation( address _LP, uint _amount ) external view returns ( uint );
    function markdown( address _LP ) external view returns ( uint );
}

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
}

interface IStakingHelper {
    function stake( uint _amount, address _recipient ) external;
}

contract AxeBondDepository is Ownable {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /* ======== EVENTS ======== */
    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    /* ======== STATE VARIABLES ======== */
    address public immutable AXE; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints AXE when receives principle
    address public immutable DAO; // receives profit share from bond

    bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
    address public immutable bondCalculator; // calculates value of LP tokens

    address public staking; // to auto-stake payout
    address public stakingHelper; // to stake and claim if no staking warmup
    bool public useHelper;

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint public lastDecay; // reference block for debt decay


    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTerm; // in seconds
        uint minimumPrice; // vs principle value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint payout; // AXE remaining to be paid
        uint vesting; // Blocks left to vest
        uint lastTimestamp; // Last interaction
        uint pricePaid; // In DAI, for front end viewing
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint buffer; // minimum length (in seconds) between adjustments
        uint lastTimestamp; // block when last adjustment made
    }


    /* ======== INITIALIZATION ======== */

    constructor (
        address _AXE,
        address _principle,
        address _treasury,
        address _DAO,
        address _bondCalculator
    ) {
        require( _AXE != address(0) );
        AXE = _AXE;
        require( _principle != address(0) );
        principle = _principle;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
        // bondCalculator should be address(0) if not LP bond
        bondCalculator = _bondCalculator;
        isLiquidityBond = ( _bondCalculator != address(0) );
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _fee uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(
        uint _controlVariable,
        uint _vestingTerm,
        uint _minimumPrice,
        uint _maxPayout,
        uint _fee,
        uint _maxDebt,
        uint _initialDebt
    ) external onlyOwner() {
        // require( terms.controlVariable == 0, "Bonds must be initialized from 0" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            fee: _fee,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.timestamp;
    }


    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, FEE, DEBT }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyOwner() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 36 * 60 * 60, "Vesting must be longer than 36 hours" );
            terms.vestingTerm = _input;
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.FEE ) { // 2
            require( _input <= 10000, "DAO fee cannot exceed payout" );
            terms.fee = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 3
            terms.maxDebt = _input;
        }
    }

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment (
        bool _addition,
        uint _increment,
        uint _target,
        uint _buffer
    ) external onlyOwner() {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTimestamp: block.timestamp
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     *  @param _helper bool
     */
    function setStaking( address _staking, bool _helper ) external onlyOwner() {
        require( _staking != address(0) );
        if ( _helper ) {
            useHelper = true;
            stakingHelper = _staking;
        } else {
            useHelper = false;
            staking = _staking;
        }
    }




    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint _amount,
        uint _maxPrice,
        address _depositor
    ) external returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );

        decayDebt();
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );

        uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOfToken( principle, _amount );
        uint payout = payoutFor( value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 AXE ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        // profits are calculated
        uint fee = payout.mul( terms.fee ).div( 10000 );
        uint profit = 0;
        if(value > payout.add( fee )) {
            profit = value.sub( payout ).sub( fee );
        } else {
            profit = value.sub( payout );
            fee = 0;
        }

        /**
            principle is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) AXE
         */
        IERC20( principle ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( principle ).approve( address( treasury ), _amount );
        ITreasury( treasury ).deposit( _amount, principle, profit );

        if ( fee != 0 ) { // fee is transferred to dao
            IERC20( AXE ).safeTransfer( DAO, fee );
        }

        // total debt is increased
        totalDebt = totalDebt.add( value );

        // depositor info is stored
        bondInfo[ _depositor ] = Bond({
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm,
            lastTimestamp: block.timestamp,
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */
    function redeem( address _recipient, bool _stake ) external returns ( uint ) {
        Bond memory info = bondInfo[ _recipient ];
        uint percentVested = percentVestedFor( _recipient ); // (blocks since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
            return stakeOrSend( _recipient, _stake, info.payout ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );

            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub( block.timestamp.sub( info.lastTimestamp ) ),
                lastTimestamp: block.timestamp,
                pricePaid: info.pricePaid
            });

            emit BondRedeemed( _recipient, payout, bondInfo[ _recipient ].payout );
            return stakeOrSend( _recipient, _stake, payout );
        }
    }




    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _stake bool
     *  @param _amount uint
     *  @return uint
     */
    function stakeOrSend( address _recipient, bool _stake, uint _amount ) internal returns ( uint ) {
        if ( !_stake ) { // if user does not want to stake
            IERC20( AXE ).transfer( _recipient, _amount ); // send payout
        } else { // if user wants to stake
            if ( useHelper ) { // use if staking warmup is 0
                IERC20( AXE ).approve( stakingHelper, _amount );
                IStakingHelper( stakingHelper ).stake( _amount, _recipient );
            } else {
                IERC20( AXE ).approve( staking, _amount );
                IStaking( staking ).stake( _amount, _recipient );
            }
        }
        return _amount;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint blockCanAdjust = adjustment.lastTimestamp.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= blockCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTimestamp = block.timestamp;
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = block.timestamp;
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( AXE ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );
    }


    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).add( 1e9 ).div( 1e7 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).add( 1e9 ).div( 1e7 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        if( isLiquidityBond ) {
            price_ = bondPrice().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 100 );
        } else {
            price_ = bondPrice().mul( 10 ** IERC20( principle ).decimals() ).div( 100 );
        }
    }


    /**
     *  @notice calculate current ratio of debt to AXE supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {
        uint supply = IERC20( AXE ).totalSupply();
        debtRatio_ = FixedPoint.fraction(
            currentDebt().mul( 1e9 ),
            supply
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice debt ratio in same terms for reserve or liquidity bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns ( uint ) {
        if ( isLiquidityBond ) {
            return debtRatio().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 1e9 );
        } else {
            return debtRatio();
        }
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns ( uint ) {
        return totalDebt.sub( debtDecay() );
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns ( uint decay_ ) {
        uint secondsSinceLast = block.timestamp.sub( lastDecay );
        decay_ = totalDebt.mul( secondsSinceLast ).div( terms.vestingTerm );
        if ( decay_ > totalDebt ) {
            decay_ = totalDebt;
        }
    }


    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor( address _depositor ) public view returns ( uint percentVested_ ) {
        Bond memory bond = bondInfo[ _depositor ];
        uint blocksSinceLast = block.timestamp.sub( bond.lastTimestamp );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = blocksSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of AXE available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }




    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or AXE) to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != AXE );
        require( _token != principle );
        IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}

