pragma solidity ^0.5.0;

contract onchain_gov_events{
    event NewSubmission (uint40 indexed id, address beneficiary, uint amount,  uint next_init_tranche_size, uint[4] next_init_price_data, uint next_reject_spread_threshold, uint next_minimum_sell_volume, uint40 prop_period, uint40 next_min_prop_period, uint40 reset_time_period);
    event InitProposal (uint40 id, uint init_buy_tranche, uint init_sell_tranche);
    event Reset(uint id);
    
	event NewTrancheTotal (uint side, uint current_tranche_t); //Measured in terms of given token.
	event TrancheClose (uint side, uint current_tranche_size, uint this_tranche_tokens_total); //Indicates tranche that closed and whether both or just one side have now closed.
	event AcceptAttempt (uint accept_price, uint average_buy_dai_price, uint average_sell_dai_price); // 
	event RejectSpreadAttempt(uint spread);
	event TimeRejected();

	event ResetAccepted(uint average_buy_dai_price, uint average_sell_dai_price);


}

interface IOnchain_gov{

	function proposal_token_balanceOf(uint40 _id, uint _side, uint _tranche, address _account) external view returns (uint);

	function proposal_token_allowance(uint40 _id, uint _side, uint _tranche, address _from, address _guy) external view returns (uint);

	function proposal_token_transfer(uint40 _id, uint _side, uint _tranche, address _to, uint _amount) external returns (bool);

	function proposal_transfer_from(uint40 _id, uint _side, uint _tranche,address _from, address _to, uint _amount) external returns (bool);

    function proposal_token_approve(uint40 _id, uint _side, uint _tranche, address _guy, uint _amount) external returns (bool);


    function calculate_price(uint _side, uint _now) external view returns (uint p);

	function submit_proposal(uint _amount, uint _next_init_tranche_size, uint[4] calldata _next_init_price_data, uint _next_reject_spread_threshold, uint _next_minimum_sell_volume, uint40 _prop_period, uint40 _next_min_prop_period, uint40 _reset_time_period) external;

	function init_proposal(uint40 _id) external;

	function reset() external;

	function buy(uint _id, uint _input_dai_amount, uint _tranche_size) external;

	function sell(uint _id, uint _input_token_amount, uint _tranche_size) external;

	function close_tranche_buy(uint _id, uint _input_dai_amount, uint _tranche_size) external;

	function close_tranche_sell(uint _id, uint _input_token_amount, uint _tranche_size) external;  

	function accept_prop() external;

	function reject_prop_spread() external;

	function reject_prop_time() external;

	function accept_reset() external;

	function buy_redeem(uint _id, uint _tranche_size) external;

	function sell_redeem(uint _id, uint _tranche_size) external;

	function buy_refund_reject(uint _id, uint _tranche_size) external;

	function sell_refund_reject(uint _id, uint _tranche_size) external;

	function buy_refund_accept(uint _id, uint _tranche_size) external;

	function sell_refund_accept(uint _id, uint _tranche_size) external;

	function final_buy_redeem(uint _id, uint _tranche_size) external;

	function final_sell_redeem(uint _id, uint _tranche_size) external;

	function final_buy_refund_reject(uint _id, uint _tranche_size) external;

	function final_sell_refund_reject(uint _id, uint _tranche_size) external;
}

//27 functions
