pragma solidity ^0.5.0;

import "./TripioToken.sol";
import "./Owned.sol";

contract FoundingTeam is Owned {

    // Team with 4 members
    struct Team {
        address m0;
        address m1;
        address m2;
        address m3;
    }

    struct Proposal {
        address sponsor;
        mapping(address => bool) signatures;
        uint256 timestamp;
        uint8 proposalType;
    }

    uint256 public proposalLength = 0;

    // decisions,all proposals are indexed by decisionIndex
    mapping(uint256 => Proposal) public proposalMap;

    mapping (uint256 => mapping (address => uint16)) public suggestedPercentagesMap;
    mapping (uint256 => Team) public suggestedTeamMap;
    mapping (uint256 => uint8) public suggestStatusMap; 
    mapping (uint256 => bool) public suggestTerminalMap;

    Team team;

    // TRIO contract 
    TripioToken tripio;

    // Percentage of funds
    mapping(address => uint16) percentages;

    // Enable 
    bool public enabled;

    address public fundingSource;

    // Timestamps
    uint256[] timestamps;

    // proposalType == 1
    event PercentagesProposalMade(address _sponsor, uint256 _timestamp, uint16 _m0P, uint16 _m1P, uint16 _m2P, uint16 _m3P);

    // proposalType == 2
    event MembersProposalMade(address _sponsor, uint256 _timestamp, address _m0, address _m1, address _m2, address _m3);

    // proposalType == 3
    event StatusProposalMade(address _sponsor, uint256 _timestamp, uint8 _status);

    // proposalType == 4
    event TerminalProposalMade(address _sponsor, uint256 _timestamp, bool _terminal);

    event Vote(address _voter, uint256 _proposalIndex);
    /**
     * This emits when deposited
     */
    event Deposited(address _owner, uint256 _value);

    /**
     * This emits when percentages updated
     */
    event PercentagesUpdated(uint16 _m0, uint16 _m1, uint16 _m2, uint16 _m3);

    /**
     * This emits when members updated
     */
    event MembersUpdated(address _m0, address _m1, address _m2, address _m3);
    
    /**
     * This emits when status updated
     */
    event StatusUpdated(uint8 _status);

    /**
     * This emits when terminated
     */
    event Terminated();

    /**
     * This emits when candied
     */
    event Candy();

    /**
     * @dev Constructor 
     * @param _m0 Team member 0 has 44% found
     * @param _m1 Team member 1 has 25% found
     * @param _m2 Team member 2 has 18.6% found
     * @param _m3 Team member 3 has 12.4% found 
     * @param _trio TRIO contract address
     */
    constructor(address _m0, address _m1, address _m2, address _m3, address _trio, address _fundingSource) public {
        team = Team(_m0, _m1, _m2, _m3);
        percentages[_m0] = 440;
        percentages[_m1] = 250;
        percentages[_m2] = 186;
        percentages[_m3] = 124;

        tripio = TripioToken(_trio);
        fundingSource = _fundingSource;

        enabled = true;
        
        // All timestamps from 2019-06-01 to 2021-05-01
        timestamps.push(1559361600); // 2019-06-01	12:00 
        timestamps.push(1561953600); // 2019-07-01	12:00 
        timestamps.push(1564632000); // 2019-08-01	12:00 
        timestamps.push(1567310400); // 2019-09-01	12:00 
        timestamps.push(1569902400); // 2019-10-01	12:00 
        timestamps.push(1572580800); // 2019-11-01	12:00
        timestamps.push(1575172800); // 2019-12-01	12:00
        timestamps.push(1577851200); // 2020-01-01	12:00
        timestamps.push(1580529600); // 2020-02-01	12:00
        timestamps.push(1583035200); // 2020-03-01	12:00
        timestamps.push(1585713600); // 2020-04-01	12:00
        timestamps.push(1588305600); // 2020-05-01	12:00
        timestamps.push(1590984000); // 2020-06-01	12:00
        timestamps.push(1593576000); // 2020-07-01	12:00
        timestamps.push(1596254400); // 2020-08-01	12:00
        timestamps.push(1598932800); // 2020-09-01	12:00
        timestamps.push(1601524800); // 2020-10-01	12:00
        timestamps.push(1604203200); // 2020-11-01	12:00
        timestamps.push(1606795200); // 2020-12-01	12:00
        timestamps.push(1609473600); // 2021-01-01	12:00
        timestamps.push(1612152000); // 2021-02-01	12:00
        timestamps.push(1614571200); // 2021-03-01	12:00
        timestamps.push(1617249600); // 2021-04-01	12:00
        timestamps.push(1619841600); // 2021-05-01	12:00
    }

    /**
     * Only member
     */
    modifier onlyMember {
        require(team.m0 == msg.sender || team.m1 == msg.sender || team.m2 == msg.sender || team.m3 == msg.sender, "Only member");
        _;
    }

    /**
     * Only owner or members
     */
    modifier onlyOwnerOrMember {
        require(msg.sender == owner || team.m0 == msg.sender || team.m1 == msg.sender || team.m2 == msg.sender || team.m3 == msg.sender, "Only member");
        _;
    }

    function _withdraw() private {
        uint256 tokens = tripio.balanceOf(address(this));
        tripio.transfer(fundingSource, tokens);
    }

    /**
     * query the proposal by proposalLength
     */
    function teamProposal(uint256 _proposalIndex) external view returns(
        address _sponsor,
        bool[] memory _signatures,
        uint256 _timestamp,
        uint8 _proposalType,
        uint16[] memory _percentages,
        address[] memory _members,
        uint8 _status,
        bool _terminal
    ) {
        Proposal storage proposal = proposalMap[_proposalIndex];
        mapping (address => bool) storage signatures = proposal.signatures;
        _signatures = new bool[](4);
        _percentages = new uint16[](4);
        _members = new address[](4);

        _sponsor = proposal.sponsor;
        _signatures[0] = signatures[team.m0];
        _signatures[1] = signatures[team.m1];
        _signatures[2] = signatures[team.m2];
        _signatures[3] = signatures[team.m3];
        _timestamp = proposal.timestamp;
        _proposalType = proposal.proposalType;

        if (_proposalType == 1) {  
            _percentages[0] = suggestedPercentagesMap[_proposalIndex][team.m0];
            _percentages[1] = suggestedPercentagesMap[_proposalIndex][team.m1];
            _percentages[2] = suggestedPercentagesMap[_proposalIndex][team.m2];
            _percentages[3] = suggestedPercentagesMap[_proposalIndex][team.m3];
        } else if (_proposalType == 2) {
            _members[0] = suggestedTeamMap[_proposalIndex].m0;
            _members[1] = suggestedTeamMap[_proposalIndex].m1;
            _members[2] = suggestedTeamMap[_proposalIndex].m2;
            _members[3] = suggestedTeamMap[_proposalIndex].m3;
        } else if (_proposalType == 3) {
            _status = suggestStatusMap[_proposalIndex];
        } else if (_proposalType == 4) {
            _terminal = suggestTerminalMap[_proposalIndex];
        }

    }

    /**
     * Current percentages
     */
    function teamPercentages() external view returns(uint16[] memory _percentages) {
        _percentages = new uint16[](4);
        _percentages[0] = percentages[team.m0];
        _percentages[1] = percentages[team.m1];
        _percentages[2] = percentages[team.m2];
        _percentages[3] = percentages[team.m3];
    }

    /**
     * Current members
     */
    function teamMembers() external view returns(address[] memory _members) {
        _members = new address[](4);
        _members[0] = team.m0;
        _members[1] = team.m1;
        _members[2] = team.m2;
        _members[3] = team.m3;
    }

    /**
     * All schedules 
     */
    function teamTimestamps() external view returns(uint256[] memory _timestamps) {
        _timestamps = new uint256[](timestamps.length);
        for(uint256 i = 0; i < timestamps.length; i++) {
            _timestamps[i] = timestamps[i];
        }
    }

    /**
     * Record fund reserve
     */
    function deposit() external returns(bool) {
        require (msg.sender == fundingSource, "msg.sender must be fundingSource");
        uint256 value = tripio.allowance(msg.sender, address(this));
        require(value > 0, "Value must more than 0");
        tripio.transferFrom(msg.sender, address(this), value);
        
        // Event
        emit Deposited(msg.sender, value);
    }

    /**
     * Make a proposal for updating percentages
     */
    function vote (address _sponsor, uint256 _proposalIndex, uint _proposalType) external onlyMember {
        Proposal storage proposal = proposalMap[_proposalIndex];
        require (proposal.sponsor == _sponsor && proposal.proposalType == _proposalType, "proposal check fail");
        require (proposal.timestamp + 2 days > now, "Expired proposal");

        proposal.signatures[msg.sender] = true;
       
        if (_proposalType == 1) {
            _updatePercentages(_proposalIndex);
        }
        if (_proposalType == 2) {
            _updateMembers(_proposalIndex);
        }
        if (_proposalType == 3) {
            _updateStatus(_proposalIndex);
        }
        if (_proposalType == 4) {
            _terminate(_proposalIndex);
        }

        emit Vote(msg.sender, _proposalIndex);
    }

    /**
     * check if 3/4 agree
     */
    function _isThreeQuarterAgree (Proposal storage _proposal) private view returns (bool res) {
        mapping (address => bool) storage signatures = _proposal.signatures;
        return (
            (signatures[team.m0] && signatures[team.m1] && signatures[team.m2])
            || (signatures[team.m0] && signatures[team.m2] && signatures[team.m3])
            || (signatures[team.m1] && signatures[team.m2] && signatures[team.m3])
        );
    }

    /**
     * check if 4/4 agree
     */
    function _isAllAgree (Proposal storage _proposal) private view returns (bool res) {
        mapping (address => bool) storage signatures = _proposal.signatures;
        return signatures[team.m0] && signatures[team.m1] && signatures[team.m2] && signatures[team.m3];
    }

    function _createProposal (uint8 _proposalType) private {
        Proposal storage proposal = proposalMap[proposalLength];
        proposal.sponsor = msg.sender;
        proposal.signatures[msg.sender] = true;
        proposal.timestamp = now;
        proposal.proposalType = _proposalType;
        proposalLength += 1;
    }

    /**
     * Make a proposal for updating percentages
     */
    function updatePercentagesProposal(uint16 _m0, uint16 _m1, uint16 _m2, uint16 _m3) external onlyMember {
        require (_m0 + _m1 + _m2 + _m3 == 1000, "the sum must be 1000");   
        mapping (address => uint16) storage suggestedPercentage = suggestedPercentagesMap[proposalLength];
        
        suggestedPercentage[team.m0] = _m0;
        suggestedPercentage[team.m1] = _m1;
        suggestedPercentage[team.m2] = _m2;
        suggestedPercentage[team.m3] = _m3;

        _createProposal(1);
        // Event
        emit PercentagesProposalMade(msg.sender, now, _m0, _m1, _m2, _m3);
    }

    function _updatePercentages (uint256 _proposalIndex) private {
        if (_isAllAgree(proposalMap[_proposalIndex])) {        
            percentages[team.m0] = suggestedPercentagesMap[_proposalIndex][team.m0];
            percentages[team.m1] = suggestedPercentagesMap[_proposalIndex][team.m1];
            percentages[team.m2] = suggestedPercentagesMap[_proposalIndex][team.m2];
            percentages[team.m3] = suggestedPercentagesMap[_proposalIndex][team.m3];
            emit PercentagesUpdated(percentages[team.m0], percentages[team.m1], percentages[team.m2], percentages[team.m3]);
        }
    }

    /**
     * Update the team members, need all memebers's signatures
     */
    function updateMembersProposal(address _m0, address _m1, address _m2, address _m3) external onlyMember {
        require (_m0 != address(0) && _m1 != address(0) && _m2 != address(0) && _m3 != address(0), "invalid addresses");
        Team storage suggestedTeam = suggestedTeamMap[proposalLength];

        suggestedTeam.m0 = _m0;
        suggestedTeam.m1 = _m1;
        suggestedTeam.m2 = _m2;
        suggestedTeam.m3 = _m3;

        _createProposal(2);
        // Event
        emit MembersProposalMade(msg.sender, now, _m0, _m1, _m2, _m3);
    }

    function _updateMembers (uint256 _proposalIndex) private {
        if (_isAllAgree(proposalMap[_proposalIndex])) {
            Team memory newTeam = Team(
                suggestedTeamMap[_proposalIndex].m0,
                suggestedTeamMap[_proposalIndex].m1,
                suggestedTeamMap[_proposalIndex].m2,
                suggestedTeamMap[_proposalIndex].m3
            );
            percentages[newTeam.m0] = percentages[team.m0];
            percentages[newTeam.m1] = percentages[team.m1];
            percentages[newTeam.m2] = percentages[team.m2];
            percentages[newTeam.m3] = percentages[team.m3];

            team = newTeam;
            emit MembersUpdated(team.m0, team.m1, team.m2, team.m3);
        }
    }

    /**
     * Update the contract status, enable for 1 or disable for 2
     */
    function updateStatusProposal(uint8 _status) external onlyMember {
        require (_status == 1 || _status == 2, "must be one of 1 and 2");

        suggestStatusMap[proposalLength] = _status;
        _createProposal(3);
        // Event
        emit StatusProposalMade(msg.sender, now, _status);
    }

    function _updateStatus(uint256 _proposalIndex) private {
        if (_isThreeQuarterAgree(proposalMap[_proposalIndex])) {        
            if (suggestStatusMap[_proposalIndex] == 1) {
                enabled = true;               
                // restart and reset timestamps
                for(uint256 i = 0; i < timestamps.length; i++) {
                    if(timestamps[i] != 0 && timestamps[i] < now) {
                        timestamps[i] = 0;
                    }
                }
            } else if (suggestStatusMap[_proposalIndex] == 2) {
                enabled = false;
            }

            // Event
            emit StatusUpdated(suggestStatusMap[_proposalIndex]);
        }
    }

    /**
     * Terminate the contract
     * the remaining candy will transfer to the original owner
     * _terminal cant be false
     */
    function terminateProposal(bool _terminal) external onlyMember {
        require (_terminal, "must true");

        suggestTerminalMap[proposalLength] = _terminal;
        _createProposal(4);
        // Event
        emit TerminalProposalMade(msg.sender, now, _terminal);
    }

    function _terminate(uint256 _proposalIndex) private {
        if (_isAllAgree(proposalMap[_proposalIndex])) {        
            _withdraw();

            // Event
            emit Terminated();
        }
    }

    /**
     * Candy every month
     */
    function candy() external onlyOwnerOrMember {
        require(enabled, "Must enabled");
        // Remaining tokens
        uint256 tokens = tripio.balanceOf(address(this));
        uint256 count = 0;
        for(uint256 i = 0; i < timestamps.length; i++) {
            if(timestamps[i] != 0) {
                count++;
            }
        }
        require(tokens > count && count > 0, "tokens should be larger than count");

        uint256 token0 = tokens * percentages[team.m0]/1000/count;
        uint256 token1 = tokens * percentages[team.m1]/1000/count;
        uint256 token2 = tokens * percentages[team.m2]/1000/count;
        uint256 token3 = tokens * percentages[team.m3]/1000/count;

        uint256 enabledCount = 0;
        for(uint256 i = 0; i < timestamps.length; i++) {
            if(timestamps[i] != 0 && timestamps[i] <= now) {
                enabledCount++;
                if(token0 > 0) {
                    tripio.transfer(team.m0, token0);
                    tokens -= token0;
                }
                if(token1 > 0) {
                    tripio.transfer(team.m1, token1);
                    tokens -= token1;
                }
                if(token2 > 0) {
                    tripio.transfer(team.m2, token2);
                    tokens -= token2;
                }
                if(token3 > 0) {
                    tripio.transfer(team.m3, token3);
                    tokens -= token3;
                }
                timestamps[i] = 0;
            }
        }
        require(enabledCount > 0, "enabledCount cant be zero");

        if(count == 1 && tokens > 0) {
            // withdraw the remaining candy
            _withdraw();
        }

        // Event
        emit Candy();
    }
}
