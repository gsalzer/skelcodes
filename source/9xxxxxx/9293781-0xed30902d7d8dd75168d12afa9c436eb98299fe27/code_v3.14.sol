// Copyright (C) 2020 Benjamin M J D Wang

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.5.0;
import "gov_interface_v2.sol"; //Import governance contract interface.
import "proposal_tokens_v3.sol"; //proposal tokens data structure and transfer functions.
contract onchain_gov_BMJDW2020 is IOnchain_gov, proposal_tokens, onchain_gov_events{ 

	ERC20 public ERC20Interface;

	function calculate_price(uint _side, uint _now) public view returns (uint p) { //Function could also be internal if users can calculate price themselves easily. 
		uint[4] memory price_data = proposal[pa_proposal_id].next_init_price_data;

		p = wmul(price_data[_side], wpow(price_data[2], mul(price_data[3], sub(_now, current_tranche_start))/WAD)); //(WAD)
		//p = wmul(_p1, rpow(_e, mul(_f, sub(_now, _start))/ WAD));

		/**
		p = WAD
		p1 = WAD
		e = WAD
		f = int
		now = int
		start = int
		*/
	}

	
	function submit_proposal(uint _amount, uint _next_init_tranche_size, uint[4] calldata _next_init_price_data, uint _next_reject_spread_threshold, uint _next_minimum_sell_volume, uint40 _prop_period, uint40 _next_min_prop_period, uint40 _reset_time_period) external {
		 
		uint param = wdiv(_amount, mul(_next_min_prop_period, _prop_period)); //_next_min_prop_period is purely an anti-spam prevention to stop spammers submitting proposals with very small amounts. Assume WAD since _next_min_prop_period * _prop_period may result in large number. 

		require(param > top_param, "param < top_param");
		require(_prop_period > proposal[pa_proposal_id].next_min_prop_period, "prop_period < minimum"); //check that voting period is greater than the next_min_prop_period of the last accepted proposal.

		top_param = param; //Sets current top param to that of the resently submitted proposal. 

		ERC20Interface.transferFrom(msg.sender, address(this), _amount / 100);//Takes proposer's deposit in dai. This must throw an error and revert if the user does not have enough funds available. 

		ERC20Interface.transfer(proposal[top_proposal_id].beneficiary, proposal[top_proposal_id].amount / 100); ////Pays back the deposit to the old top proposer in dai.

		uint id = ++nonce; //Implicit conversion to uint256
		top_proposal_id = uint40(id); //set top proposal id and is used as id for recording data.

		//Store all new proposal data:
		proposal[id].beneficiary = msg.sender;
		proposal[id].amount = _amount;
		proposal[id].next_init_tranche_size = _next_init_tranche_size;
		proposal[id].next_init_price_data = _next_init_price_data;
		proposal[id].next_reject_spread_threshold = _next_reject_spread_threshold;
		proposal[id].next_minimum_sell_volume = _next_minimum_sell_volume;
		proposal[id].prop_period = _prop_period;
		proposal[id].next_min_prop_period = _next_min_prop_period;
		proposal[id].reset_time_period = _reset_time_period;

		emit NewSubmission(uint40(id), msg.sender, _amount, _next_init_tranche_size, _next_init_price_data, _next_reject_spread_threshold, _next_minimum_sell_volume, _prop_period, _next_min_prop_period, _reset_time_period);
	}


	function init_proposal(uint40 _id) external { //'sell' and 'buy' indicate sell and buy side from the user perspective in the context of governance tokens even though it is in reference to dai.
		require (running_proposal_id == 0, "Proposal still running."); //Makes sure previous proposal has finished.
		/**
		When proposal has ended and was accepted:
		pa_proposal_id = running_proposal_id
		running_proposal_id = 0

		When proposal has ended and was rejected:
		pa_proposal_id remains the same.
		running_proposal_id = 0

		When initialised:
		running_proposal_id = top_proposal_id
		top_proposal_id = 1;
		proposal status = 1;
		*/

		require (_id == top_proposal_id, "Wrong id."); //Require correct proposal to be chosen.
		require (_id != 0, "_id != 0"); //Cannot initialise the genesis proposal.
		running_proposal_id = _id; //Update running proposal id.
		top_proposal_id = 0; //Set top proposal to the genesis proposal. This is because some top_proposa_id is necessary in the submission function above for the first submission after each proposal.
		proposal[_id].status = 1; //Set proposal status to 'ongoing'.
		uint init_sell_size = proposal[pa_proposal_id].next_init_tranche_size; //Init sell tranche size.

		 proposal[_id].side[1].current_tranche_size = init_sell_size;

		uint minimum_sell_volume = proposal[pa_proposal_id].next_minimum_sell_volume;

		uint dai_out = add(wmul(990000000000000000, proposal[_id].amount), minimum_sell_volume);

		uint net_balance = net_dai_balance;

		uint init_buy_size;

		//Make sure that the contract is always running a positive net dai balance:

		if (dai_out > net_balance){
			init_buy_size = wmul(wdiv(init_sell_size, minimum_sell_volume), sub(dai_out, net_balance));
		}
		else{
			init_buy_size = init_sell_size;
		}

		proposal[_id].side[0].current_tranche_size = init_buy_size;
		current_tranche_start = uint40(now);
		proposal[_id].proposal_start = uint40(now);
		top_param = 0; //reset top param.

		emit InitProposal (_id, init_buy_size, init_sell_size);
	}

	function reset() external{
		require (uint40(now) - proposal[pa_proposal_id].proposal_start > proposal[pa_proposal_id].reset_time_period, "Reset time not elapsed."); //Tests amount of time since last proposal passed.

		uint id = ++nonce;
		//Set proposal data:
		proposal[id].beneficiary = msg.sender;
		proposal[id].next_min_prop_period = proposal[pa_proposal_id].next_min_prop_period;
		proposal[id].next_init_tranche_size = proposal[pa_proposal_id].next_init_tranche_size;
		proposal[id].next_init_price_data = proposal[pa_proposal_id].next_init_price_data;
		proposal[id].next_reject_spread_threshold = proposal[pa_proposal_id].next_reject_spread_threshold;
		uint next_minimum_sell_volume = proposal[pa_proposal_id].next_minimum_sell_volume;
		proposal[id].next_minimum_sell_volume = next_minimum_sell_volume;
		proposal[id].reset_time_period = proposal[pa_proposal_id].reset_time_period;

		require (running_proposal_id == 0, "Proposal still running."); //Makes sure previous proposal has finished.
		running_proposal_id = uint40(id); //Update running proposal id.
		top_proposal_id = 0; //Set top proposal to the genesis proposal. This is because some top_proposal_id is necessary in the submission function above for the first submission after each proposal.
		proposal[id].status = 4; //Set proposal status to 'ongoing reset proposal'.
		proposal[id].side[0].current_tranche_size = next_minimum_sell_volume;
		proposal[id].side[1].current_tranche_size = next_minimum_sell_volume;
		//Set as size of tranche as minimum sell volume.

		current_tranche_start = uint40(now);
		proposal[id].proposal_start = uint40(now);
		top_param = 0; //reset top param.

		emit Reset(id);


	}


	function all_trades_common(uint _id, uint _side, uint _tranche_size) internal view returns (uint current_tranche_t) {
		require (_id == running_proposal_id, "Wrong id."); //User can only trade on currently running proposal.
		require (proposal[_id].side[_side].current_tranche_size == _tranche_size, "Wrong tranche size."); //Make sure the user's selected tranche size is the current tranche size. Without this they may choose arbitrary tranches and then loose tokens.
		require (proposal[_id].side[_side].tranche[_tranche_size].price == 0, "Tranche already closed."); //Check tranche is still open.
		current_tranche_t = proposal[_id].side[_side].current_tranche_total;
	}

	function buy_sell_common(uint _id, uint _input_amount, uint _side, uint _tranche_size, uint _current_dai_price) internal {
		uint current_tranche_t = all_trades_common(_id, _side, _tranche_size);

		require (wmul(add(_input_amount, current_tranche_t), _current_dai_price) < _tranche_size, "Try closing tranche."); //Makes sure users cannot send tokens beyond or even up to the current tranche size since this is for the tranche close function. 

		proposal[_id].side[_side].tranche[_tranche_size].balance[msg.sender] = add(proposal[_id].side[_side].tranche[_tranche_size].balance[msg.sender], _input_amount); //Record proposal balance.

		proposal[_id].side[_side].tranche[_tranche_size].recent_trade_time = sub(now, current_tranche_start); //Set time of most recent trade so 2nd to last trade time can be recorded. Offset by current_tranche_start to account for zero initial value.

		proposal[_id].side[_side].current_tranche_total = add(current_tranche_t, _input_amount); //Update current_tranche_total.

		emit NewTrancheTotal (_side, current_tranche_t + _input_amount);
	}

	function buy(uint _id, uint _input_dai_amount, uint _tranche_size) external {
		//Set correct amount of dai 
		buy_sell_common(_id, _input_dai_amount, 0, _tranche_size, WAD); //For buying _dai_amount = _input_dai_amount. Dai price = 1.0.

		ERC20Interface.transferFrom(msg.sender, address(this), _input_dai_amount); //Take dai from user using call to dai contract. User must approve contract address and amount before transaction.
	}

	function sell(uint _id, uint _input_token_amount, uint _tranche_size) external {
		//Set correct amount of dai

		buy_sell_common(_id, _input_token_amount, 1, _tranche_size, calculate_price(1, now)); //For selling, the current dai amount must be used based on current price.

		burn(_input_token_amount); //Remove user governance tokens. SafeMath should revert with insufficient funds.
	}

	function close_buy_sell_common_1(uint _id, uint _side, uint _tranche_size) internal returns(uint price, uint final_trade_price, uint current_tranche_t) {
		current_tranche_t = all_trades_common(_id, _side, _tranche_size);

		price = calculate_price(_side, add(proposal[_id].side[_side].tranche[_tranche_size].recent_trade_time, current_tranche_start)); //(WAD) Sets price for all traders.
		final_trade_price = calculate_price(_side, now);

		proposal[_id].side[_side].tranche[_tranche_size].price = price; //(WAD) Sets price for all traders.

		proposal[_id].side[_side].tranche[_tranche_size].final_trade_price = final_trade_price; //(WAD) Sets price for only the final trader.

		proposal[_id].side[_side].tranche[_tranche_size].final_trade_address = msg.sender; //Record address of final trade.

		proposal[_id].side[_side].current_tranche_total = 0; //Reset current_tranche_total to zero.
	}


	function close_buy_sell_common_2(uint _id, uint _balance_amount, uint _side, uint _tranche_size, uint _input_dai_amount, uint _current_tranche_t_dai, uint _this_tranche_tokens_total) internal {
		require (add(_input_dai_amount, _current_tranche_t_dai) >= _tranche_size, "Not enough to close."); //Check that the user has provided enough dai or equivalent to close the tranche.

		proposal[_id].side[_side].tranche[_tranche_size].final_trade_amount = _balance_amount; //Record final trade amount.
			
		if (proposal[_id].side[(_side+1)%2].tranche[proposal[_id].side[(_side+1)%2].current_tranche_size].price != 0){ //Check whether tranche for other side has closed.

			current_tranche_start = uint40(now); //Reset timer for next tranche.

			proposal[_id].side[_side].total_tokens_traded = add(proposal[_id].side[_side].total_tokens_traded, _this_tranche_tokens_total);
			proposal[_id].side[(_side+1)%2].total_tokens_traded = add(proposal[_id].side[(_side+1)%2].total_tokens_traded, lct_tokens_traded); //Sets total tokens traded on each side now that tranches on both sides have closed (using lct_tokens_traded which was recorded when the other side closed.)

			proposal[_id].side[_side].total_dai_traded = add(proposal[_id].side[_side].total_dai_traded, _tranche_size); 
			proposal[_id].side[(_side+1)%2].total_dai_traded = add(proposal[_id].side[(_side+1)%2].total_dai_traded, proposal[_id].side[(_side+1)%2].current_tranche_size); //Add total dai traded in tranche to total_dai_traded.
			//Add total dai traded in tranche to total_dai_traded.
			if (proposal[_id].side[1].total_dai_traded >= proposal[pa_proposal_id].next_minimum_sell_volume) { //if sell volume has reached the minimum and reset has not already happened: then reset the tranche sizes on both sides to the same value.
				uint new_size = mul(_tranche_size, 2);
				proposal[_id].side[0].current_tranche_size = new_size;
				proposal[_id].side[1].current_tranche_size = new_size;
				  //Set both tranche sizes to the same size.
			}
			else {
				proposal[_id].side[_side].current_tranche_size = mul(_tranche_size, 2); 
				proposal[_id].side[(_side+1)%2].current_tranche_size = mul(proposal[_id].side[(_side+1)%2].current_tranche_size, 2); //Double the current tranche sizes.
			}
		}
		else{
			lct_tokens_traded = _this_tranche_tokens_total; //Records last closed tranche tokens traded total for when both tranches close.
		}
	emit TrancheClose (_side, _tranche_size, _this_tranche_tokens_total); //Users must check when both sides have closed and then calculate total traded themselves by summing the TrancheClose data. 
	}

	function close_tranche_buy(uint _id, uint _input_dai_amount, uint _tranche_size) external {
		(uint price, uint final_trade_price, uint current_tranche_t) = close_buy_sell_common_1(_id, 0, _tranche_size);

		uint dai_amount_left = sub(_tranche_size, current_tranche_t); //Calculates new amount of dai for user to give.

		uint this_tranche_tokens_total = add(wmul(current_tranche_t,price), wmul(dai_amount_left, final_trade_price)); //Update total_tokens_traded

		close_buy_sell_common_2(_id, dai_amount_left, 0, _tranche_size, _input_dai_amount, current_tranche_t, this_tranche_tokens_total);

		ERC20Interface.transferFrom(msg.sender, address(this), dai_amount_left); //Take dai from user using call to dai contract. User must approve contract address and amount before transaction.

	}
	function close_tranche_sell(uint _id, uint _input_token_amount, uint _tranche_size) external {
		(uint price, uint final_trade_price, uint current_tranche_t) = close_buy_sell_common_1(_id, 1, _tranche_size);

		uint dai_amount_left = sub(_tranche_size, wmul(current_tranche_t, price)); //Calculates dai_amount_left in tranche which is based on the price the other sellers will pay, not the current price.
		uint token_equiv_left = wdiv(dai_amount_left, final_trade_price); //Calculate amount of tokens to give user based on dai amount left.
		uint equiv_input_dai_amount = wmul(_input_token_amount, final_trade_price); //Equivalent amount of dai at current prices based on the user amount of tokens.

		uint this_tranche_tokens_total = add(current_tranche_t, token_equiv_left); //Update total_tokens_traded

		close_buy_sell_common_2(_id, token_equiv_left, 1, _tranche_size, equiv_input_dai_amount, wmul(current_tranche_t, price), this_tranche_tokens_total);

		burn(token_equiv_left); //Remove user governance tokens. SafeMath should revert with insufficient funds.
	}


	function accept_prop() external {
		uint id = running_proposal_id;
		require (proposal[id].side[1].total_dai_traded >= proposal[pa_proposal_id].next_minimum_sell_volume, "dai sold < minimum"); //Check that minimum sell volume has been reached.

		//Collect state data into memory for calculating prices:
		uint current_total_dai_sold = proposal[id].side[0].total_dai_traded;
		uint previous_total_dai_bought = proposal[pa_proposal_id].side[1].total_dai_traded;
		uint current_total_tokens_bought = proposal[id].side[0].total_tokens_traded;

		uint proposal_amount = proposal[id].amount;
		uint accept_current_p_amount;
	    uint accept_previous_p_amount;

		//Calculate where attacker's capital will be spent for accept case and reject case:
		if (current_total_dai_sold < add(previous_total_dai_bought, proposal_amount)){
			accept_current_p_amount = proposal_amount;
			//accept_previous_p_amount = 0 by default.
		}
		else{
			//accept_current_p_amount = 0 by default.
			accept_previous_p_amount = proposal_amount;
		}

		//Attacker aims to attack at weakest point. The assumed ratio of z_a_p to y_a_p determines where attack is spending capital i.e. where they are attacking. So the attacker will aim to spend the most where the amount of dai is lowest, since this will have the greatest effect on price. Or in other words we want to know the minimum of the minimum prices. 

		uint accept_price = wmul(wdiv(sub(current_total_dai_sold, accept_current_p_amount), current_total_tokens_bought), wdiv(proposal[pa_proposal_id].side[1].total_tokens_traded, add(accept_previous_p_amount, previous_total_dai_bought))); //Minimum non-manipulated price.

		if (accept_price > WAD){ //If proposal accepted: (change to require later)
			proposal[id].status = 2;
			ERC20Interface.transfer(proposal[id].beneficiary, proposal[id].amount);
			pa_proposal_id = running_proposal_id;
			running_proposal_id = 0;

			_supply = sub(add(_supply, proposal[id].side[0].total_tokens_traded), proposal[id].side[1].total_tokens_traded);

			net_dai_balance = sub(add(net_dai_balance, current_total_dai_sold), add(wmul(990000000000000000, proposal_amount), proposal[id].side[1].total_dai_traded)); //Update net_dai_balance
		}

		emit AcceptAttempt (accept_price, wdiv(current_total_dai_sold, current_total_tokens_bought), wdiv(proposal[id].side[1].total_dai_traded, proposal[id].side[1].total_tokens_traded));
	}


	function reject_prop_spread() external {
		uint id = running_proposal_id;
		require (proposal[id].status == 1, "Prop status is incorrect."); //Make sure it is not a reset proposal.
		uint recent_buy_price = proposal[id].side[0].tranche[proposal[id].side[0].current_tranche_size].price; //Price of current tranche.
		uint recent_sell_price = proposal[id].side[1].tranche[proposal[id].side[1].current_tranche_size].price;

		if (recent_buy_price == 0) { //Checks whether current tranche has closed. If not then latest price is calculated.
			recent_buy_price = calculate_price(0, now);
		}
		if (recent_sell_price == 0) {
			recent_sell_price = calculate_price(1, now);
		}

		uint spread = wmul(recent_buy_price, recent_sell_price); //Spread based on current tranche using auction prices that have not finished when necessary. You cannot manipulate spread to be larger so naive price is used.
		if (spread > proposal[pa_proposal_id].next_reject_spread_threshold){
			proposal[id].status = 3;
			running_proposal_id = 0;
		}
		emit RejectSpreadAttempt(spread);
	}


	function reject_prop_time() external {
		uint id = running_proposal_id;
		require (proposal[id].status == 1, "Prop status is incorrect."); //Make sure it is not a reset proposal.
		require (now - proposal[id].proposal_start > proposal[id].prop_period, "Still has time.");
		proposal[id].status = 3;
		running_proposal_id = 0;

		emit TimeRejected();
	}

	function accept_reset() external {
		uint id = running_proposal_id;
		uint current_total_dai_bought = proposal[id].side[1].total_dai_traded;
		uint current_total_tokens_bought = proposal[id].side[0].total_tokens_traded;
		uint current_total_tokens_sold = proposal[id].side[1].total_tokens_traded;
		require (current_total_dai_bought >= proposal[pa_proposal_id].next_minimum_sell_volume, "dai sold < minimum"); //Check that minimum sell volume has been reached.
		require (proposal[id].status == 4, "Not reset proposal."); //Check that this is a reset proposal rather than just any standard proposal.
		proposal[id].status = 2; //Proposal accepted
		pa_proposal_id = running_proposal_id;
		running_proposal_id = 0;

		_supply = sub(add(_supply, current_total_tokens_bought), current_total_tokens_sold); //Update supply.

		//Net_dai_balance remains the same since equal dai is traded on both sides and proposal.amount = 0.

		emit ResetAccepted(wdiv(proposal[id].side[0].total_dai_traded, current_total_tokens_bought), wdiv(current_total_dai_bought, current_total_tokens_sold));
	}


	function redeem_refund_common(uint _id, uint _tranche_size, uint _side, uint8 _status) internal returns (uint amount){
		require (proposal[_id].status == _status, "incorrect status");
		amount = proposal[_id].side[_side].tranche[_tranche_size].balance[msg.sender];
		proposal[_id].side[_side].tranche[_tranche_size].balance[msg.sender] = 0; //Set balance to zero.
	}

	function redeem_common(uint _id, uint _tranche_size, uint _side) internal returns (uint amount) {
		require (proposal[_id].side[0].tranche[_tranche_size].price != 0 && proposal[_id].side[1].tranche[_tranche_size].price != 0, "Other side never finished."); //Make sure that both sides of the tranche finished.
		amount = wmul(redeem_refund_common(_id, _tranche_size, _side, 2), proposal[_id].side[_side].tranche[_tranche_size].price); //Set 'amount' to balance multiplied by price since user just gives the amount of tokens that they are sending in the prop function.
	}

	function buy_redeem(uint _id, uint _tranche_size) external {

		mint(redeem_common(_id, _tranche_size, 0)); //User paid with dai so they get back tokens.
	}

	function sell_redeem(uint _id, uint _tranche_size) external {

		ERC20Interface.transfer(msg.sender, redeem_common(_id, _tranche_size, 1)); //User paid with tokens so they get back dai.
	}

	function buy_refund_reject(uint _id, uint _tranche_size) external {

		ERC20Interface.transfer(msg.sender, redeem_refund_common(_id, _tranche_size, 0, 3)); //User paid with dai so they get back dai.
	}

	function sell_refund_reject(uint _id, uint _tranche_size) external {

		mint(redeem_refund_common(_id, _tranche_size, 1, 3)); //User paid with tokens so they get back tokens.
	}

	function buy_refund_accept(uint _id, uint _tranche_size) external {
		require (proposal[_id].side[0].tranche[_tranche_size].price == 0 || proposal[_id].side[1].tranche[_tranche_size].price == 0, "Try redeem"); //One of tranches is unfinished.

		ERC20Interface.transfer(msg.sender, redeem_refund_common(_id, _tranche_size, 0, 2)); //User paid with dai so they get back dai.
	}

	function sell_refund_accept(uint _id, uint _tranche_size) external {
		require (proposal[_id].side[0].tranche[_tranche_size].price == 0 || proposal[_id].side[1].tranche[_tranche_size].price == 0, "Try redeem"); //One of tranches is unfinished.

		mint(redeem_refund_common(_id, _tranche_size, 1, 2));//User paid with tokens so they get back tokens.
	}

	//Functions for redeeming final trades:

	function final_redeem_refund_common(uint _id, uint _tranche_size, uint _side, uint8 _status) internal returns (uint amount){
		require (proposal[_id].status == _status, "Incorrect status");
		require (proposal[_id].side[_side].tranche[_tranche_size].final_trade_address == msg.sender, "Wasn't you.");
		amount = proposal[_id].side[_side].tranche[_tranche_size].final_trade_amount;
		proposal[_id].side[_side].tranche[_tranche_size].final_trade_amount = 0; //Set balance to zero.
	}

	function final_redeem_common(uint _id, uint _tranche_size, uint _side) internal returns (uint amount) {
		require (proposal[_id].side[0].tranche[_tranche_size].price != 0 && proposal[_id].side[1].tranche[_tranche_size].price != 0, "Try refund."); //Make sure that both sides of the tranche finished.
		amount = wmul(final_redeem_refund_common(_id, _tranche_size, _side, 2), proposal[_id].side[_side].tranche[_tranche_size].final_trade_price); //Set 'amount' to balance multiplied by price since user just gives the amount of tokens that they are sending in the prop function.
	}


	function final_buy_redeem(uint _id, uint _tranche_size) external {

		mint(final_redeem_common(_id, _tranche_size, 0)); //User paid with dai so they get back tokens.
	}

	function final_sell_redeem(uint _id, uint _tranche_size) external {

		ERC20Interface.transfer(msg.sender, final_redeem_common(_id, _tranche_size, 1)); //User paid with tokens so they get back dai.
	}

	function final_buy_refund_reject(uint _id, uint _tranche_size) external {

		ERC20Interface.transfer(msg.sender, final_redeem_refund_common(_id, _tranche_size, 0, 3)); //User paid with dai so they get back dai.
	}

	function final_sell_refund_reject(uint _id, uint _tranche_size) external {

		mint(final_redeem_refund_common(_id, _tranche_size, 1, 3)); //User paid with tokens so they get back tokens.
	}

	constructor(uint _init_price, ERC20 _ERC20Interface) public { //(WAD) _init_price is defined as dai_amount/token_amount. _supply is defined in the TokenBase constructor.
		ERC20Interface = _ERC20Interface; //fakeDai contract. Use checksum version of address.

		//Genesis proposal which will be used by first proposal. 
		proposal[0].status = 2;
		proposal[0].beneficiary = address(this); //Because the submission of first proposal would break the erc20 transfer function if address(0) is used, therefore, we use this address. 
		proposal[0].amount = 0; //For first proposal submission, 0/100 will be returned to contract address.
		proposal[0].prop_period = 1;
		proposal[0].next_min_prop_period = 1;
		proposal[0].next_init_tranche_size = wmul(_supply, _init_price)/100;
		proposal[0].next_init_price_data = [wdiv(WAD, wmul(40*WAD, _init_price)), wdiv(_init_price, 2*WAD) , 1003858241594480000, 10**17]; //Price here is defined as [amount received by user after proposal]/[amount given by user before]. 
		//Price should double every 30 mins. Buy price starts above sell price at max potential price - vice versa for sell price. p = wmul(_p1, rpow(_e, mul(_f, sub(_now, _start))/ WAD)). e = 2**(1/180). Value of f defines 10 seconds as 1 int.
		proposal[0].next_reject_spread_threshold = 7 * WAD;
		proposal[0].next_minimum_sell_volume = wmul(_supply, _init_price)/100; //(10 ** -6) dai minimum sell volume.
		proposal[0].reset_time_period = 10;
		proposal[0].proposal_start = uint40(now);

		//Genesis trade values:

		proposal[0].side[0].total_dai_traded = wmul(_supply, _init_price); //0.001 dai initial market cap. (10 ** -6) dai initial price. 
		proposal[0].side[1].total_dai_traded = wmul(_supply, _init_price);
		proposal[0].side[0].total_tokens_traded = _supply;
		proposal[0].side[1].total_tokens_traded = _supply;
	} //price = total_dai_traded/_supply
}

