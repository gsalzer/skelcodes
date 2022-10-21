pragma solidity ^0.5.0;

import "./DIA.sol";

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

contract Dispute is Initializable, Ownable {
	using SafeMath for uint;
	// DIA token
	DIAToken private dia_;
	// Event to emit when a dispute is open
	event DisputeOpen(uint256 _id, uint _deadline);
	// Event to emit when a dispute is finalized
	event DisputeClosed(uint256 _id, bool _result);
	// How many blocks should we wait before the dispute can be closed
	uint private DISPUTE_LENGTH;
	// How many token a user should stake on each vote
	uint private VOTE_COST;
	// Disputes
	mapping (uint256=>Disputes) private disputes_;
	// Rewards that each voter can claim
	mapping (address=>uint256) public rewards_;

	struct Disputes {
		// Block number to finalize dispute
		uint deadline;
		// Array of voters
		Voter[] voters;
		// Voters index in the voters array
		mapping(address=>uint) votersIndex;
	}
	// Voters
	struct Voter {
		// store voter address. Required for payout
		address id;
		// Vote. true:keep, false:drop
		bool vote;
	}

	/**
	* @dev Acts as constructor for upgradeable contracts
	* @param _dia Address of DIA token contract.
	*/
	function initialize(DIAToken _dia) public initializer() onlyOwner {
		// ~2 weeks. weeks x days x hours x minute x seconds
		DISPUTE_LENGTH = 2*7*24*60*60;
		VOTE_COST = 10;
		dia_ = _dia;
	}
	
	function updateVotingParameters(DIAToken _dia, uint256 _newDisputeLength, uint256 _newVoteCost) public onlyOwner {
	    dia_ = _dia;
	    VOTE_COST = _newVoteCost;
	    DISPUTE_LENGTH = _newDisputeLength;
	}

	/**
	* @dev Cast vote.
	* @param _id Data source identifier.
	* @param _vote true for drop and false to keep.
	* Voter must increase allowance to this contract to be able to participate in the dispute.
	*/
	function vote(uint256 _id, bool _vote) public {
		// check only new voters
		require (disputes_[_id].votersIndex[msg.sender] == 0, "Address already voted");
		require (disputes_[_id].deadline > 0, "Dispute not available");
		dia_.transferFrom(msg.sender, address(this), VOTE_COST);
		disputes_[_id].voters.push(Voter(msg.sender, _vote));
		disputes_[_id].votersIndex[msg.sender] = disputes_[_id].voters.length;
	}

	/**
	* @dev Start a dispute.
	* @param _id data source identifier.
	*/
	function openDispute(uint256 _id) external {
		require(disputes_[_id].deadline == 0, "Dispute already ongoing");
		disputes_[_id].deadline = now+DISPUTE_LENGTH;
		emit DisputeOpen(_id, disputes_[_id].deadline);
	}

	/**
	* @dev Once the deadline is reached this function should be called to get decision.
	* @param _id data source id.
	*/
	function triggerDecision(uint256 _id) external{
		// Maybe we can get rid of a require
		require(disputes_[_id].deadline > 0, "Dispute not available");
		require(now > disputes_[_id].deadline, "Dispute deadline not reached");
		// prevent method to be called again before its done
		disputes_[_id].deadline = 0;
		uint256 dropVotes = 0;
		uint256 keepVotes = 0;
		uint totalVoters = disputes_[_id].voters.length;
		for (uint i = 0; i<totalVoters; i++){
			if (disputes_[_id].voters[i].vote)
				dropVotes++;
			else
				keepVotes++;
		}
		bool drop = (dropVotes>keepVotes);
		uint payment;
		// use safe math to compute payment
		if (drop)
			payment = ((totalVoters).mul(VOTE_COST)).div(dropVotes);
		else
			payment = ((totalVoters).mul(VOTE_COST)).div(keepVotes);
		for (uint256 i = 0; i < totalVoters; i++){
			if (disputes_[_id].voters[i].vote == drop){
				rewards_[disputes_[_id].voters[i].id] += payment;
			}
			delete disputes_[_id].votersIndex[disputes_[_id].voters[i].id];
		}
		delete disputes_[_id];
		emit DisputeClosed(_id, drop);
	}

	/**
	* @dev Claim rewards
	*/
	function claimRewards() external {
		require(rewards_[msg.sender] > 0, "No balance to withdraw");
		dia_.transfer(msg.sender, rewards_[msg.sender]);
		rewards_[msg.sender] = 0;
	}

	/**
	* @dev Check rewards balance for account calling the method
	*/
	function checkRewardsBalance() external view returns (uint256) {
		return rewards_[msg.sender];
	}

	/**
	* @dev get dispute status.
	* @param _id data source id.
	*/
	function isDisputeOpen(uint256 _id) external view returns (bool) {
		return (disputes_[_id].deadline>0);
	}

	/**
	* @dev check if address voted already.
	* @param _id data source identifier.
	*/
	function didCastVote(uint256 _id) external view returns (bool){
		return (disputes_[_id].votersIndex[msg.sender]>0);
	}
}

