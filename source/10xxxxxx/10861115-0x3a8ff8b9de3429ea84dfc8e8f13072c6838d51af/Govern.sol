pragma solidity ^0.5.0;

import "./Math.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

interface Executor {
    function execute(uint, uint, uint, uint) external;
}

contract KaniGovernance is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    function seize(IERC20 _token, uint amount) external {
        require(msg.sender == governance, "!governance");
        require(_token != token, "reward");
        _token.safeTransfer(governance, amount);
    }

    bool public breaker = false;
    function setBreaker(bool _breaker) external {
        require(msg.sender == governance, "!governance");
        breaker = _breaker;
    }

    mapping(address => uint) public voteLock; // period that your sake it locked to keep it for voting

    struct Proposal {
        uint id;
        address proposer;
        mapping(address => uint) forVotes;
        mapping(address => uint) againstVotes;
        uint totalForVotes;
        uint totalAgainstVotes;
        uint start; // block start;
        uint end; // start + period
        address executor;
        string hash;
        uint totalVotesAvailable;
        uint quorum;
        uint quorumRequired;
        bool open;
    }

    mapping (uint => Proposal) public proposals;
    uint public proposalCount;
    uint public period = 17280; // voting period in blocks ~ 17280 3 days for 15s/block
    uint public lock = 17280; // vote lock in blocks ~ 17280 3 days for 15s/block
    uint public minimum = 1e18;
    uint public quorum = 2000;
    bool public config = true;


    address public governance;

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setQuorum(uint _quorum) public {
        require(msg.sender == governance, "!governance");
        quorum = _quorum;
    }

    function setMinimum(uint _minimum) public {
        require(msg.sender == governance, "!governance");
        minimum = _minimum;
    }

    function setPeriod(uint _period) public {
        require(msg.sender == governance, "!governance");
        period = _period;
    }

    function setLock(uint _lock) public {
        require(msg.sender == governance, "!governance");
        lock = _lock;
    }

    function initialize(uint id) public {
        require(config == true, "!config");
        config = false;
        proposalCount = id;
        governance = 0x4384f49d5ABc78cD05dFe37E2FFc35A519262071;
    }

    event NewProposal(uint id, address creator, uint start, uint duration, address executor);
    event Vote(uint indexed id, address indexed voter, bool vote, uint weight);

    function propose(address executor, string memory hash) public {
        require(votesOf(msg.sender) > minimum, "<minimum");
        proposals[proposalCount++] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            start: block.number,
            end: period.add(block.number),
            executor: executor,
            hash: hash,
            totalVotesAvailable: totalVotes,
            quorum: 0,
            quorumRequired: quorum,
            open: true
            });

        emit NewProposal(proposalCount, msg.sender, block.number, period, executor);
        voteLock[msg.sender] = lock.add(block.number);
    }

    function execute(uint id) public {
        (uint _for, uint _against, uint _quorum) = getStats(id);
        require(proposals[id].quorumRequired < _quorum, "!quorum");
        require(proposals[id].end < block.number , "!end");
        if (proposals[id].open == true) {
            tallyVotes(id);
        }
        Executor(proposals[id].executor).execute(id, _for, _against, _quorum);
    }

    function getStats(uint id) public view returns (uint _for, uint _against, uint _quorum) {
        _for = proposals[id].totalForVotes;
        _against = proposals[id].totalAgainstVotes;

        uint _total = _for.add(_against);
        _for = _for.mul(10000).div(_total);
        _against = _against.mul(10000).div(_total);

        _quorum = _total.mul(10000).div(proposals[id].totalVotesAvailable);
    }

    event ProposalFinished(uint indexed id, uint _for, uint _against, bool quorumReached);

    function tallyVotes(uint id) public {
        require(proposals[id].open == true, "!open");
        require(proposals[id].end < block.number, "!end");

        (uint _for, uint _against,) = getStats(id);
        bool _quorum = false;
        if (proposals[id].quorum >= proposals[id].quorumRequired) {
            _quorum = true;
        }
        proposals[id].open = false;
        emit ProposalFinished(id, _for, _against, _quorum);
    }

    function votesOf(address voter) public view returns (uint) {
        return votes[voter];
    }

    uint public totalVotes;
    mapping(address => uint) public votes;
    event RegisterVoter(address voter, uint votes, uint totalVotes);
    event RevokeVoter(address voter, uint votes, uint totalVotes);

    function register() public {
        require(voters[msg.sender] == false, "voter");
        voters[msg.sender] = true;
        votes[msg.sender] = plyr_[msg.sender].stake;
        totalVotes = totalVotes.add(votes[msg.sender]);
        emit RegisterVoter(msg.sender, votes[msg.sender], totalVotes);
    }


    function revoke() public {
        require(voters[msg.sender] == true, "!voter");
        voters[msg.sender] = false;
        if (totalVotes < votes[msg.sender]) {
            //edge case, should be impossible, but this is defi
            totalVotes = 0;
        } else {
            totalVotes = totalVotes.sub(votes[msg.sender]);
        }
        emit RevokeVoter(msg.sender, votes[msg.sender], totalVotes);
        votes[msg.sender] = 0;
    }

    mapping(address => bool) public voters;

    function voteFor(uint id) public {
        require(proposals[id].start < block.number , "<start");
        require(proposals[id].end > block.number , ">end");

        uint _against = proposals[id].againstVotes[msg.sender];
        if (_against > 0) {
            proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.sub(_against);
            proposals[id].againstVotes[msg.sender] = 0;
        }

        uint vote = votesOf(msg.sender).sub(proposals[id].forVotes[msg.sender]);
        proposals[id].totalForVotes = proposals[id].totalForVotes.add(vote);
        proposals[id].forVotes[msg.sender] = votesOf(msg.sender);

        proposals[id].totalVotesAvailable = totalVotes;
        uint _votes = proposals[id].totalForVotes.add(proposals[id].totalAgainstVotes);
        proposals[id].quorum = _votes.mul(10000).div(totalVotes);

        voteLock[msg.sender] = lock.add(block.number);

        emit Vote(id, msg.sender, true, vote);
    }

    function voteAgainst(uint id) public {
        require(proposals[id].start < block.number , "<start");
        require(proposals[id].end > block.number , ">end");

        uint _for = proposals[id].forVotes[msg.sender];
        if (_for > 0) {
            proposals[id].totalForVotes = proposals[id].totalForVotes.sub(_for);
            proposals[id].forVotes[msg.sender] = 0;
        }

        uint vote = votesOf(msg.sender).sub(proposals[id].againstVotes[msg.sender]);
        proposals[id].totalAgainstVotes = proposals[id].totalAgainstVotes.add(vote);
        proposals[id].againstVotes[msg.sender] = votesOf(msg.sender);

        proposals[id].totalVotesAvailable = totalVotes;
        uint _votes = proposals[id].totalForVotes.add(proposals[id].totalAgainstVotes);
        proposals[id].quorum = _votes.mul(10000).div(totalVotes);

        voteLock[msg.sender] = lock.add(block.number);

        emit Vote(id, msg.sender, false, vote);
    }


    IERC20 public token = IERC20(0x790aCe920bAF3af2b773D4556A69490e077F6B4A);

    struct Player {
        uint256 stake; // 总质押总数
        uint256 payout; //
        uint256 total_out; // 已经领取的分红
    }
    mapping(address => Player) public plyr_; // (player => data) player data

    struct Global {
        uint256 total_stake; // 总质押总数
        uint256 total_out; //  总分红金额
        uint256 earnings_per_share; // 每股分红
    }
    mapping(uint256 => Global) public global_; // (global => data) global data
    mapping (address => uint256) public deposittime;
    uint256 constant internal magnitude = 10**40;

    uint256 constant internal extraReward = 500000*1e18;
    uint256 internal rewarded = 0;
    uint256 internal dailyReward = extraReward.div(365);
    uint256 internal lastUpdateTime = 0;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    function make_profit(uint256 amount) public {
        require(amount>0,"not 0");
        token.safeTransferFrom(msg.sender, address(this), amount);
        make_profit_internal(amount);
    }
    
    function make_profit_internal(uint256 amount) internal{
        if (global_[0].total_stake > 0) {
            global_[0].earnings_per_share = global_[0].earnings_per_share.add(
                amount.mul(magnitude).div(global_[0].total_stake)
            );
        }
        global_[0].total_out = global_[0].total_out.add(amount);
        emit RewardAdded(amount);
    }

    function deposit(uint amount) external daily_reward {
        token.safeTransferFrom(msg.sender, address(this), amount);
        plyr_[msg.sender].stake = plyr_[msg.sender].stake.add(amount);
        if (global_[0].earnings_per_share != 0) {
            plyr_[msg.sender].payout = plyr_[msg.sender].payout.add(
                global_[0].earnings_per_share.mul(amount).sub(1).div(magnitude).add(1)
            );
        }
        global_[0].total_stake = global_[0].total_stake.add(amount);
        deposittime[msg.sender] = now;
        emit Staked(msg.sender, amount);
    }

    function cal_out(address user) public view returns (uint256) {
        uint256 _cal = global_[0].earnings_per_share.mul(plyr_[user].stake).div(magnitude);
        if (_cal < plyr_[user].payout) {
            return 0;
        } else {
            return _cal.sub(plyr_[user].payout);
        }
    }

    function cal_out_pending(uint256 _pendingBalance,address user) public view returns (uint256) {
        uint256 _earnings_per_share = global_[0].earnings_per_share.add(
            _pendingBalance.mul(magnitude).div(global_[0].total_stake)
        );
        uint256 _cal = _earnings_per_share.mul(plyr_[user].stake).div(magnitude);
        _cal = _cal.sub(cal_out(user));
        if (_cal < plyr_[user].payout) {
            return 0;
        } else {
            return _cal.sub(plyr_[user].payout);
        }
    }

    function claim() public daily_reward {
        uint256 out = cal_out(msg.sender);
        plyr_[msg.sender].payout = global_[0].earnings_per_share.mul(plyr_[msg.sender].stake).div(magnitude);
        plyr_[msg.sender].total_out = plyr_[msg.sender].total_out.add(out);

        if (out > 0) {
            uint256 _depositTime = now - deposittime[msg.sender];
            if (_depositTime < 1 days){ //deposit in 24h
                uint256 actually_out = _depositTime.mul(out).mul(1e18).div(1 days).div(1e18);
                uint256 back_to_profit = out.sub(actually_out);
                make_profit_internal(back_to_profit);
                out = actually_out;
            }
            token.safeTransfer(msg.sender, out);
            emit RewardPaid(msg.sender, out);
        }
    }

    function withdraw(uint amount) public daily_reward {
        claim();
        require(amount<=plyr_[msg.sender].stake,"!balance");
        uint r = amount;

        // Check balance
        uint b = token.balanceOf(address(this));
        if (b < r) {
            uint _withdraw = r.sub(b);
            // Controller(controller).withdraw(address(token), _withdraw);
            uint _after = token.balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        plyr_[msg.sender].payout = plyr_[msg.sender].payout.sub(
            global_[0].earnings_per_share.mul(amount).div(magnitude)
        );
        plyr_[msg.sender].stake = plyr_[msg.sender].stake.sub(amount);
        global_[0].total_stake = global_[0].total_stake.sub(amount);

        token.safeTransfer(msg.sender, r);
        emit Withdrawn(msg.sender, r);
    }

    modifier daily_reward(){
        require(lastUpdateTime > 0, "not start");
        if (block.timestamp.sub(lastUpdateTime) > 1 days &&
            rewarded < extraReward) {
            rewarded = rewarded.add(dailyReward);
            lastUpdateTime = block.timestamp;
            make_profit_internal(dailyReward);
        }
        _;
    }

    function notifyRewardAmount() public onlyOwner {
        require(lastUpdateTime == 0, "inited");
        token.mint(address(this),extraReward);
        lastUpdateTime = block.timestamp.sub(1 days);
        emit RewardAdded(extraReward);
    }

}
