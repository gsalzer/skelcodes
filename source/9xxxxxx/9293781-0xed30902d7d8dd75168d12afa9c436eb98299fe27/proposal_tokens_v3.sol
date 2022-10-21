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
import "base.sol";

contract proposal_tokens is TokenBase(0) {
	//Proposal mappings
	mapping (uint => Proposal) internal proposal; //proposal id is taken from nonce. 

	struct Proposal { //Records all data that is submitted during proposal submission.
		address beneficiary;
		uint amount; //(WAD)
		uint next_init_tranche_size; //(WAD)
		uint[4] next_init_price_data; //Array of data for next proposal [initial buy price (WAD), initial sell price (WAD), base (WAD), exponent factor (int)] 
		uint next_reject_spread_threshold; //(WAD)
		uint next_minimum_sell_volume; //(WAD)

		uint8 status; //0 = not submitted or not ongoing, 1 = ongoing, 2 = accepted, 3 = rejected, 4 = ongoing reset proposal.
		uint40 prop_period; //(int) How long users have to prop before prop rejected.
		uint40 next_min_prop_period; //(int) Minimum prop period for the next proposal.
		uint40 reset_time_period; //(int) Time period necessary for proposal to be reset. 
		uint40 proposal_start; //(int) This is to provide a time limit for the length of proposals.
		mapping (uint => Side) side; //Each side of proposal
	}
	struct Side { //Current tranche data for this interval.
		uint current_tranche_total; //This is in units of given tokens rather than only dai tokens: dai for buying, proposal token for selling. For selling, total equivalent dai tokens is calculated within the function.
		uint total_dai_traded; //Used for calculating acceptance/rejection thresholds.
		uint total_tokens_traded; //Used for calculating acceptance/rejection thresholds.
		uint current_tranche_size; //(WAD) This is maximum amount or equivalent maximum amount of dai tokens the tranche can be.
		mapping (uint => Tranche) tranche; //Data for each tranche that must be recorded. Size of tranche will be the uint tranche id.
	}

	struct Tranche {
		uint price; //(WAD) Final tranche price for each tranche. Price is defined as if the user is selling their respective token types to the proposal so price increases over time to incentivise selling. Buy price is price of dai in proposal tokens where sell price is the price in dai.
		uint final_trade_price;
		uint recent_trade_time;
		uint final_trade_amount;
		address final_trade_address;
		mapping (address => uint) balance; //(WAD)
		mapping (address => mapping (address => uint256)) approvals;
	}
 
	uint40 internal nonce; // Nonce for submitted proposals that have a higher param regardless of whether they are chosen or not. Will also be used for chosen proposals.
	uint40 public top_proposal_id; //Id of current top proposal.
	uint40 public running_proposal_id; //id of the proposal that has been initialised.
	uint40 public pa_proposal_id; //Previously accepted proposal id.
	uint40 current_tranche_start; //(int) 
	uint public top_param; //(WAD)
	uint internal lct_tokens_traded; //Records the total tokens traded for the tranche on the first side to close. This means that this calculation won't need to be repeated when both sides close.
	uint internal net_dai_balance; //The contract's dai balance as if all redemptions and refunds are collected in full, re-calculated at the end of every accepted proposal.


	function proposal_token_balanceOf(uint40 _id, uint _side, uint _tranche, address _account) external view returns (uint) {
        return proposal[_id].side[_side].tranche[_tranche].balance[_account];
    }

	function proposal_token_allowance(uint40 _id, uint _side, uint _tranche, address _from, address _guy) external view returns (uint) {
		return proposal[_id].side[_side].tranche[_tranche].approvals[_from][_guy];
	}

	function proposal_token_transfer(uint40 _id, uint _side, uint _tranche, address _to, uint _amount) external returns (bool) {
		return proposal_transfer_from(_id, _side, _tranche, msg.sender, _to, _amount);
	}

	event ProposalTokenTransfer(address from, address to, uint amount);

	function proposal_transfer_from(uint40 _id, uint _side, uint _tranche,address _from, address _to, uint _amount)
        public
        returns (bool)
    {
        if (_from != msg.sender) {
            proposal[_id].side[_side].tranche[_tranche].approvals[_from][msg.sender] = sub(proposal[_id].side[_side].tranche[_tranche].approvals[_from][msg.sender], _amount); //Revert if funds insufficient. 
        }
        proposal[_id].side[_side].tranche[_tranche].balance[_from] = sub(proposal[_id].side[_side].tranche[_tranche].balance[_from], _amount);
        proposal[_id].side[_side].tranche[_tranche].balance[_to] = add(proposal[_id].side[_side].tranche[_tranche].balance[_to], _amount);

        emit ProposalTokenTransfer(_from, _to, _amount);

        return true;
    }

	event ProposalTokenApproval(address account, address guy, uint amount);

    function proposal_token_approve(uint40 _id, uint _side, uint _tranche, address _guy, uint _amount) external returns (bool) {
        proposal[_id].side[_side].tranche[_tranche].approvals[msg.sender][_guy] = _amount;

        emit ProposalTokenApproval(msg.sender, _guy, _amount);

        return true;
    }
}
