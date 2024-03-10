pragma solidity 0.6.11; // 5ef660b1
import "Uniswap.sol";
/* BAEX - Binary Options Smart-Contract v.1.0.2 (© 2020 - baex.com)
    
A smart contract source code of an open binary options platform BAEX.

This open-source code confirms the open binary options model used on the baex.com platform, where any user
	of the Ethereum can participate as a liquidity provider or a trader.

The BAEX mathematical model of binary options provides:

1) Automatically calculated profit ratios for traders from transactions that allow
	you to get an honestly balanced profit from trading.

2) The opportunity to receive 10% profit for liquidity providers from held in liquidity pool BAEX tokens.

3) Oracles of BAEX uses Yahoo Finance as a source of reliable market quotes, which are stored on the blockchain
	and always can be verified by 3d party.

Using this smart contract, you can earn from providing liquidity or trading on the baex.com platform
*/

interface ifaceBAEXToken {
    function transferOptions(address _from, address _to, uint256 _value, bool _burn_to_assets) external returns (bool);
    function issuePrice() external view returns (uint256);
	function burnPrice() external view returns (uint256);
	function collateral() external view returns (uint256);
}

/* BAEX - smart-contract of BAEX options */
contract BAEXOptions {
    // Fixed point math factor is 10^10
    uint256 constant public fmk = 10**10;
    address constant private super_owner = 0x2B2fD898888Fa3A97c7560B5ebEeA959E1Ca161A;
    address private owner;
    
    string public name;
    
    // Divider of trades period in seconds 300 is 5 minutes
    uint32 public period_divider;
    // Current max num of periods for trade
    uint32 public max_period;
    // Current min periods of trade
    uint32 public min_period;
    
    /* ALL STORED IN THIS CONTRACT BALANCES AND AMOUNTS HAVE PRECISION * 10 */
    
    // Min trade volume
    uint256 public min_trade_vol;
    // Max trade volume
    uint256 public max_trade_vol;
    // Flag of automatic recalc trade volume 
    bool public recalc_max_trade_vol;
    
    // Size of liquidity pool
    uint256 public liquidity_pool;
    // Blocked amount of liquidity pool
    uint256 public liquidity_pool_blocked;
    
    // Current ratio of trades
    uint256 public liquidity_perc;
    
    // Balancing factors
    uint256 public liquidity_balancing_mul;
    uint256 public liquidity_perc_normal;
    uint256 public liquidity_in;
    uint256 public liquidity_ratio;
    
    // 5% is processing fee:
	//	 2.5% to the liquidity pool & 2.5% as fees for oracles
    uint256 constant public processing_fees_percent = 5 * fmk / 100;
    // Collected fees for oracles
    uint256 public oracle_fees;    
    uint32  public num_of_trades;
    
    uint256 public gas_for_process;
    
    mapping (address => bool) oracles;
    
    address payable baex;
    
    struct TTrade {
        uint256 vol;
        uint256 fees;
        uint256 params;
        // bits of params:
        // 0x0001       0020        5F4B5235            5F4B5535            000000000000000000000000000007001ED00044
        // direction    period      place_time_stamp    result_time_stamp                                 result_vol
        uint256 result_vol;
        int256 result;
    }
    
    mapping(uint256 => TTrade) public trades;
    mapping(uint16 => bytes16) public valid_instruments;
    mapping(address => uint256 ) public liquidity;
    
    // Stored rates of instruments in blockchain
    // bits:
    // 0x0001          5F4B5535   ->    0x000000F049EBDC05
    // instrument id   timestamp  ->    instrument rate * 10^8
    mapping(uint48 => uint64) public instrumentRates;

    constructor() public {
		name = "BAEX - Options Smart-Contract";
		
		period_divider = 300;   // 5 minutes
		max_period = 288;       // 288 * 5 minutes = 24 hours
		min_period = 1;
		
		// Assets for trades list, can be extend later
		//--------------------------------------------
		// Crypto
		valid_instruments[1] = "BTC-USD";
		valid_instruments[2] = "ETH-USD";
	
		// Forex
		valid_instruments[3] = "EUR-USD";
		valid_instruments[4] = "GBP-USD";
		valid_instruments[47] = "USD-JPY";
		valid_instruments[53] = "AUD-USD";
		valid_instruments[59] = "EUR-JPY";
		valid_instruments[62] = "GBP-JPY";
		
		// S&P 500 Index
		valid_instruments[32] = "SNP"; 
		// Dow Jones Industrial Average Index
		valid_instruments[35] = "^DJI";
		// NASDAQ Composite Index
		valid_instruments[38] = "^IXIC";
		// NYSE COMPOSITE (DJ) Index
		valid_instruments[41] = "^NYA";
		
		// Tesla, Inc.
		valid_instruments[5] = "TSLA";
		// Nordstrom, Inc.
		valid_instruments[71] = "JWN";
		// Microsoft Corporation
		valid_instruments[74] = "MSFT";
		// Apple, Inc.
		valid_instruments[77] = "AAPL";
		// Uber Technologies, Inc.
		valid_instruments[80] = "UBER";
		// Advanced Micro Devices, Inc.
		valid_instruments[83] = "AMD";
		// Bank of America Corporation
		valid_instruments[86] = "BAC";
		// Intel Corporation
		valid_instruments[89] = "INTC";
		// Pfizer, Inc.
		valid_instruments[95] = "PFE";
		// Exxon Mobil Corporation
		valid_instruments[98] = "XOM";
		// Johnson & Johnson
		valid_instruments[101] = "JNJ";
		// Delta Air Lines, Inc.
		valid_instruments[104] = "DAL";
		// The Walt Disney Company
		valid_instruments[107] = "DIS";
		// Citigroup, Inc.
		valid_instruments[110] = "C";
		// The British Petroleum Company
		valid_instruments[113] = "BP";
		// Amazon.com, Inc.
		valid_instruments[119] = "AMZN";
		// Lockheed Martin Corporation
		valid_instruments[122] = "LMT";
		//--------------------------------------------
		
		liquidity_balancing_mul = 100 * fmk / 100;
		liquidity_perc = 95 * fmk / 100;
		liquidity_perc_normal = 95 * fmk / 100;
		liquidity_in = 0;
		liquidity_pool = 0;
		liquidity_pool_blocked = 0;
		liquidity_ratio = 1 * fmk;
		
		min_trade_vol = 1 * (10 ** 9);
		max_trade_vol = 50 * (10 ** 9);
		recalc_max_trade_vol = true;
		gas_for_process = 90000;
		
		oracles[address(0xa6cF40A509F9847451A7ed7FeEa97F889A750490)] = true;
        
		owner = msg.sender;
		num_of_trades = 0;
	}
	
	modifier onlyOwner() {
		require( (msg.sender == owner) || (msg.sender == super_owner), "You don't have permissions to call it" );
		_;
	}
	
	modifier onlyOracle {
		require( oracles[msg.sender], "Only oracles can call it" );
		_;
	}
	
	function afterChangeLiquidityPool() private {
	    if ( liquidity_pool == 0 ) {
	        liquidity_balancing_mul = 100 * fmk / 100;
		    liquidity_perc = 95 * fmk / 100;
		    liquidity_perc_normal = 95 * fmk / 100;
		    liquidity_in = 0;
		    liquidity_pool = 0;
		    liquidity_pool_blocked = 0;
		    liquidity_ratio = 1 * fmk;
		    min_trade_vol = 1 * (10 ** 9);
		    max_trade_vol = 50 * (10 ** 9);
		    return;
	    }
	    if ( recalc_max_trade_vol ) {
            max_trade_vol = (liquidity_pool-liquidity_pool_blocked) / 50;
	    }
	    liquidity_balancing_mul = (liquidity_pool-liquidity_pool_blocked) * fmk / liquidity_in;
	    liquidity_perc = liquidity_perc_normal * liquidity_balancing_mul / fmk;
	    liquidity_ratio = liquidity_in * fmk / liquidity_pool;
	    log3(bytes20(address(this)),bytes4("LPC"),bytes32(liquidity_pool<<128 | liquidity_pool_blocked),bytes32(liquidity_perc));
	}
    
    function placeLiquidity(uint256 _vol) public {
        _placeLiquidity( msg.sender, _vol, true );
    }
	function _placeLiquidity(address _sender, uint256 _vol, bool _need_transfer) private {
	    require( _vol > 0, "Vol must be greater than zero" );
	    require( _vol < 10**21, "Too big volume" );
	    if ( _need_transfer ) {
	        ifaceBAEXToken(baex).transferOptions(_sender,address(this),_vol,false);
	    }
	    _vol = _vol * 10;
        uint256 in_vol = _vol;
        if ( liquidity_pool != 0 ) {
            in_vol = _vol * liquidity_ratio / fmk;
        }
        liquidity_in = liquidity_in + in_vol;
        liquidity_pool = liquidity_pool + _vol;
        liquidity[_sender] = liquidity[_sender] + in_vol;
        afterChangeLiquidityPool();
	}
	
	function balanceOf(address _sender) public view returns (uint256) {
        return liquidityBalanceOf(_sender);
    }
    
    function getMinMaxTradeVol() public view returns (uint256, uint256) {
        return (min_trade_vol/10, max_trade_vol/10);
    }
    
    function liquidityBalanceOf(address _sender) public view returns (uint256) {
	    return liquidity[_sender] * fmk / liquidity_ratio / 10;
	}
	
	function withdrawLiquidity(uint256 _vol, bool _burn_to_eth) public {
	    _withdrawLiquidity( msg.sender, _vol, _burn_to_eth );
	}
	function _withdrawLiquidity(address _sender, uint256 _vol, bool _burn_to_eth) private {
	    require( _vol > 0, "Vol must be greater than zero" );
	    require( _vol < 10**21, "Too big volume" );
	    _vol = _vol * 10;
	    require( _vol <= (liquidity_pool-liquidity_pool_blocked), "Not enough volume for withdrawal, please decrease volume to withdraw (1)" );
	    uint256 in_vol = _vol * liquidity_ratio / fmk;
	    uint256 in_bal = liquidity[_sender];
	    require( in_vol <= in_bal, "Not enough volume for withdrawal, please decrease volume to withdraw (2)" );
	    ifaceBAEXToken(baex).transferOptions(address(this),_sender,_vol/10,_burn_to_eth);
	    if ( liquidity_pool - _vol < 3 ) {
            liquidity[_sender] = 0;
            liquidity_pool = 0;
            liquidity_in = 0;
            liquidity_ratio = fmk;
        } else {
            if ( in_bal - in_vol < 3 ) {
	            in_vol = in_bal;
	        }
            liquidity[_sender] = in_bal - in_vol;
            liquidity_pool = liquidity_pool - _vol;
            liquidity_in = liquidity_in - in_vol;
        }
        afterChangeLiquidityPool();
	}
	
	
	function placeTrade(uint16 _instrument, uint256 _vol, uint8 _direction, uint32 _trade_timestamp, uint16 _period) public {
	    _placeTrade(msg.sender, _instrument, _vol, _direction, _trade_timestamp, _period );
	}
	function _placeTrade(address _sender, uint16 _instrument, uint256 _vol, uint8 _direction, uint32 _timestamp, uint16 _period) private {
	    require( _vol > 0, "Vol must be greater than zero" );
	    require( _vol < 10**21, "Too big volume" );
	    _vol = _vol * 10;
        require( _period <= max_period, "Too long period" );
        require( _period >= min_period, "Too short period" );
        require( _direction < 2, "Direction can be 0 (down) or 1 (up)" );
        require( valid_instruments[_instrument][0] != 0, "This instrument is unavailable now" );
	    require( _vol >= min_trade_vol, "Your trade volume less than minimal trade volume" );
	    require( _vol <= max_trade_vol, "Your trade volume greater than maximum trade volume" );
	    require( (block.timestamp-240) <= _timestamp, "Timestamp param should be not early than 4 min before timestamp of the block" );
	    uint time_stamp = block.timestamp / 60 * 60;
	    uint result_time_stamp = time_stamp + _period*period_divider;
	    ifaceBAEXToken(baex).transferOptions(_sender,address(this),_vol/10,false);
	    uint256 fees = _vol * processing_fees_percent / fmk;
	    liquidity_pool = liquidity_pool + (fees - fees / 2);
	    // Recalc cost of transaction ( BAEX amount in this contract stored as amount * 10 )
	    uint256 cost_of_processing = tx.gasprice * gas_for_process / ifaceBAEXToken(baex).burnPrice() / 10;
	    if ( (fees/2) < cost_of_processing ) {
	        oracle_fees = oracle_fees + cost_of_processing;
	        fees = (fees - fees / 2) + cost_of_processing;
	    } else {
	        oracle_fees = oracle_fees + fees / 2;
	    }
	    require( _vol > fees * 2, "Your trade volume is too low, please increase the trade volume" );
	    _vol = _vol - fees;
	    liquidity_ratio = liquidity_in * fmk / liquidity_pool;
	    uint256 trade_id = ( uint256(_sender) << 96 ) | ( (uint256( _instrument ) << 64) | block.number );
	    require( trades[trade_id].vol == 0, "Other your trade in this Ethereum block was detected. You can do only one trade on each instrument in one Ethereum block" );
	    uint256 result_vol = _vol * liquidity_perc / fmk;
	    require( result_vol <= (liquidity_pool-liquidity_pool_blocked), "Not enough liquidity for your trade" );
	    uint256 trade_params = ( uint256(_direction) << 240 ) | ( uint256(_period) << 224 )
	                            | ( uint256(time_stamp) << 192 ) | ( uint256(result_time_stamp) << 160 ) | ( uint256(_instrument) << 144 );
	    if ((result_vol/10) < (1<<144)) {
	        trade_params = trade_params | (result_vol/10);
	    }
	    trades[trade_id] = TTrade( _vol, (cost_of_processing<<128) | fees, trade_params, result_vol, 0 );
	    liquidity_pool_blocked = liquidity_pool_blocked + result_vol;
	    afterChangeLiquidityPool();
	    log4(bytes20(address(this)),bytes8("TRADE"),bytes32(trade_id),bytes32(trades[trade_id].params),bytes32((uint256((fees+_vol)/10)<<128) | (fees/10)));
	    num_of_trades++;
	}
	
	// Process the trade
	function processTrade(uint16 _instrument, uint64 _block_number) public {
	    _processTrade(msg.sender, _instrument, _block_number);
	}
	function _processTrade(address _sender, uint16 _instrument, uint64 _block_number) public {
	    uint256 trade_id = ( uint256(_sender) << 96 ) | ( (uint256( _instrument ) << 64) | _block_number );
	    TTrade storage trade = trades[trade_id];
	    require( trade.vol > 0, "Trade in this block for this addr is not found");	    
	    require( trade.result == 0, "This trade is already has been processed");
	    uint32 time_stamp = uint32( ( trade.params << 32 ) >> 224 );
	    uint32 result_time_stamp = uint32( ( trade.params << 64 ) >> 224 );
	    uint48 its1 = uint48( uint48(_instrument) << 32 ) | time_stamp;
	    uint48 its2 = uint48( uint48(_instrument) << 32 ) | result_time_stamp;
		// If the trade was not processed in 2000 blocks, return the trade volume to the sender
	    if ( ( trade.result == 0 ) && ( block.timestamp > result_time_stamp ) && ( (block.timestamp-result_time_stamp) >= 3600 && (instrumentRates[its1]==0 || instrumentRates[its2]==0) ) ) {
	        uint256 trade_fees = (trade.fees<<128) >> 128;
	        uint256 cost_of_processing = trade.fees >> 128;
	        if ( cost_of_processing > (trade_fees/2) ) {
	            if ( oracle_fees > cost_of_processing ) {
	                oracle_fees = oracle_fees - cost_of_processing;
	            } else {
	                oracle_fees = 0;
	            }
	        } else {
	            if ( oracle_fees > trade_fees/2 ) {
	                oracle_fees = oracle_fees - trade_fees/2;
	            } else {
	                oracle_fees = 0;
	            }
	        }
	        liquidity_pool_blocked = liquidity_pool_blocked - trade.result_vol;
	        trade.result_vol = trade.vol;
			ifaceBAEXToken(baex).transferOptions(address(this),_sender,(trade.vol+trade_fees)/10,false);
	        trade.vol = 0;
			log3(bytes20(address(this)),bytes8("CANCEL"),bytes32(trade_id),bytes32(trade.params));
	        return;
	    }
	    __processTrade( trade_id, instrumentRates[its1], instrumentRates[its2] );
	}
	
	function __processTrade( uint256 trade_id, uint64 begin_rate, uint64 end_rate ) private {
	    require( begin_rate > 0, "Begin rate is not saved yet in blockhain");
	    require( end_rate > 0, "End rate is not saved yet in blockhain");
	    
	    address _addr = address( trade_id >> 96 );
	    
	    TTrade storage trade = trades[trade_id];
	    require( trade.vol > 0, "Trade in this block for this addr is not found");
	    require( trade.result == 0, "This trade has been processed");
	    require( begin_rate > 0 || end_rate > 0, "Not found rates of this instrument for this timestamps");
	    bool dir = ( (( 1 << 240 ) & trade.params) > 0 );
	    uint256 trade_fees = (trade.fees<<128) >> 128;
	    if ( ( dir && begin_rate < end_rate ) || ( (!dir) && begin_rate >= end_rate ) ) {
	        trade.result = int256( trade.result_vol );
	        log4(bytes20(address(this)),bytes4("P"),bytes32(trade_id),bytes32(trade.params),bytes32((uint256((trade.vol+trade.result_vol)/10)<<128) | (trade_fees/10)));
	    } else {
	        trade.result = -int256( trade.result_vol );
	        log4(bytes20(address(this)),bytes4("L"),bytes32(trade_id),bytes32(trade.params),bytes32((uint256((trade_fees+trade.vol)/10)<<128) | (trade_fees/10)));
	    }
	    liquidity_pool_blocked = liquidity_pool_blocked - trade.result_vol;
	    if ( trade.result > 0 ) {
	        ifaceBAEXToken(baex).transferOptions(address(this),_addr,(trade.result_vol + trade.vol)/10,false);
	        liquidity_pool = liquidity_pool - trade.result_vol;
	    } else {
	        liquidity_pool = liquidity_pool + trade.vol;
	    }
	    afterChangeLiquidityPool();
	}
	
	/*
	    Oracle functions
	*/
	function oracleStoreRatesAndProcessTrade( uint256 trade_id, uint256 _instrument_ts_rates ) public onlyOracle {
	    uint256 startGas = gasleft();
	    uint48 its1 = uint48( _instrument_ts_rates >> 192 );
	    uint48 its2 = uint48( (_instrument_ts_rates << 128) >> 192 );
	    uint64 begin_rate = uint64( (_instrument_ts_rates << 64) >> 192 );
	    uint64 end_rate = uint64( (_instrument_ts_rates << 192) >> 192 );
	    
	    if ( instrumentRates[its1] == 0 ) instrumentRates[its1] = begin_rate;
	    if ( instrumentRates[its2] == 0 ) instrumentRates[its2] = end_rate;
	    
	    __processTrade( trade_id, begin_rate, end_rate );
	    // Calc new gas amount for process the trade, 30200 is the constant cost to call
	    gas_for_process = startGas - gasleft() + 30200;
	}
	
	function oracleStoreRates4( uint256 _instrument_and_ts, uint256 _rates ) public onlyOracle {
	    uint48 its1 = uint48( _instrument_and_ts >> 192 );
	    uint48 its2 = uint48( (_instrument_and_ts << 64) >> 192 );
	    uint48 its3 = uint48( (_instrument_and_ts << 128) >> 192 );
	    uint48 its4 = uint48( (_instrument_and_ts << 192) >> 192 );
	    
	    if ( instrumentRates[its1] == 0 ) instrumentRates[its1] = uint64( _rates >> 192 );
	    if ( instrumentRates[its2] == 0 ) instrumentRates[its2] = uint64( (_rates << 64) >> 192 );
	    if ( instrumentRates[its3] == 0 ) instrumentRates[its3] = uint64( (_rates << 128) >> 192 );
	    if ( instrumentRates[its4] == 0 ) instrumentRates[its4] = uint64( (_rates << 192) >> 192 );
	}
	
	function oracleStoreRates2( uint256 _instrument_ts_rates ) public onlyOracle {
	    uint48 its1 = uint48( _instrument_ts_rates >> 192 );
	    uint48 its2 = uint48( (_instrument_ts_rates << 128) >> 192 );
	    
	    if ( instrumentRates[its1] == 0 ) instrumentRates[its1] = uint64( (_instrument_ts_rates << 64) >> 192 );
	    if ( instrumentRates[its2] == 0 ) instrumentRates[its2] = uint64( (_instrument_ts_rates << 192) >> 192 );
	}
	
	
	/* Admin functions */
	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		owner = newOwner;
	}
	
	function setTokenAddress(address _token_address) public onlyOwner {
	    baex = payable(_token_address);
	}
	
	function setValidInstrument(uint16 _instrument_id, bytes16 _ticker) public onlyOwner {
	    valid_instruments[_instrument_id] = _ticker;
	}
	
	function setPeriodParams(uint32 _period_divider, uint32 _min_period, uint32 _max_period) public onlyOwner {
	    period_divider = _period_divider;
	    min_period = _min_period;
	    max_period = _max_period;
	}
	
	function setTradeVol(uint256 _min_trade_vol, uint256 _max_trade_vol, bool _recalc_max_trade_vol) public onlyOwner {
	    min_trade_vol = _min_trade_vol;
	    max_trade_vol = _max_trade_vol;
	    recalc_max_trade_vol = _recalc_max_trade_vol;
	}
	
	function setOracle(address _oracle_address, bool _enabled) public onlyOwner {
	    oracles[_oracle_address] = _enabled;
	}
	
	function onTransferTokens(address _from, address _to, uint256 _value) public returns (bool) {
	    require( msg.sender == address(baex), "You don't have permission to call it" );
	    if ( _to == address(this) ) {
	        _placeLiquidity( _from, _value, false );
	    }
	}
	
	function withdrawOracleFees(uint256 _vol) public onlyOwner {
	    // + 10 * 10**9 because need to leave some amount of fees for the cancelled trades
	    require( oracle_fees >= (_vol * 10 + 10 * 10**9), "Not enough fee on the contract");
	    ifaceBAEXToken(baex).transferOptions(address(this),msg.sender,_vol,false);
	    oracle_fees = oracle_fees - _vol * 10;
	}
	
	// This function can transfer any of wrong sended ERC20 tokens to the contract exclude BAEX tokens,
	// because sendeding of the BAEX tokens to this contract is the valid operation
	function transferWrongSendedERC20FromContract(address _contract) public {
	    require( _contract != address(baex), "Transfer of BAEX token is fortradeen");
	    require( msg.sender == super_owner, "Your are not super owner");
	    IERC20(_contract).transfer( super_owner, IERC20(_contract).balanceOf(address(this)) );
	}
	
	// If someone send ETH to this contract it will send it back
	receive() external payable  {
        msg.sender.transfer(msg.value);
	}
	/*------------------*/
	
}
/* END of: BAEX - smart-contract of BAEX options */

// SPDX-License-Identifier: UNLICENSED
