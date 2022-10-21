pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./MinterRole.sol";
import "./SafeMath.sol";

contract ERC20VotingMintable is Context, ERC20, MinterRole {
    using SafeMath for uint256;
    
    event Voted(address indexed voter, uint proposalId, bool vote, uint256 amount);
    event MintProposal(uint256 indexed proposalId, address proposalAddress, uint256 amount, uint256 endTime);
    event ReleaseProposal(uint256 indexed proposalId, address proposalAddress, uint256  amount, bool isSuccess);
    event Retrieved(uint256 indexed proposalId, uint256 amount);

    struct Proposal{
        bool _isActive;
        address _proposalAddress;
        uint256 _mintAmount;
        uint256 _votingEnds;
        uint256 _agree;
        uint256 _disagree;   
    }

    struct Vote{
        bool _vote;
        uint256 _amount;
        bool _retrieved;
    }

    mapping (address => mapping(uint256 => Vote)) private _votes;

    mapping (address => uint256) private _retrieveFrom;
    
    uint256 private _proposalId = 0;
    Proposal[] private _proposalList;
    
    function mintProposal(uint256 amount, uint256 duration) public onlyMinter returns (bool) {
        
        if( _proposalList.length == 0 ){
            _proposalList.push( Proposal(false, address(0), 0, 0, 0, 0) );
        }

        require(!_proposalList[_proposalId]._isActive, "mintProposal: proposal already in progress");
        require(amount > 0, "mintProposal: amount is zero" );
        require(duration >= 1800, "mintProposal: duration is less than 30 min");

        _proposalList[_proposalId]._isActive = true;
        _proposalList[_proposalId]._proposalAddress = _msgSender();
        _proposalList[_proposalId]._mintAmount = amount;
        _proposalList[_proposalId]._votingEnds =  duration.add(block.timestamp);
        
        emit MintProposal(_proposalId, _proposalList[_proposalId]._proposalAddress, _proposalList[_proposalId]._mintAmount, _proposalList[_proposalId]._votingEnds);

        return true;
    }
    
    function voting(bool vote, uint256 amount) public returns (bool) {
        
        if (_proposalList.length == 0) { // minting Proposal array is empty
            revert("voting: proposal not active");
        } else {
            require(_proposalList[_proposalId]._isActive, "voting: proposal not active" );
        }
        
        if(_votes[_msgSender()][_proposalId]._amount == 0) { // if voter hasn't voted, or reduced vote to zero previously
            require(amount > 0, "voting: vote amount is zero" );
        }
        require(_proposalList[_proposalId]._votingEnds > block.timestamp, "voting: voting period has closed");
        require(balanceOf(_msgSender()) >= amount, "voting: vote amount cannot exceed token balance");
        
        // adjust the proposal voting balances
        if (_votes[_msgSender()][_proposalId]._vote != vote && vote == true) { // voter switched thier vote from disagree to agree
            // subtract from disagree and add to agree
            _proposalList[_proposalId]._disagree = _proposalList[_proposalId]._disagree.sub(_votes[_msgSender()][_proposalId]._amount);
            _proposalList[_proposalId]._agree = _proposalList[_proposalId]._agree.add(amount);
        } else if (_votes[_msgSender()][_proposalId]._vote != vote && vote == false){ // voter switched their vote form agree to disagree
            // subtract from agree and add to disagree
            _proposalList[_proposalId]._agree = _proposalList[_proposalId]._agree.sub(_votes[_msgSender()][_proposalId]._amount);
            _proposalList[_proposalId]._disagree = _proposalList[_proposalId]._disagree.add(amount);
        } else if ( vote == true) { // voter reinforced their agree vote
            // add to agree
            _proposalList[_proposalId]._agree = _proposalList[_proposalId]._agree.sub(_votes[_msgSender()][_proposalId]._amount).add(amount);
        } else { // voter reinforced their disagree vote
            // add to disagree
            _proposalList[_proposalId]._disagree = _proposalList[_proposalId]._disagree.sub(_votes[_msgSender()][_proposalId]._amount).add(amount);
        }
        // update 
        _votes[_msgSender()][_proposalId]._vote = vote;

        uint256 oldAmount = _votes[_msgSender()][_proposalId]._amount;

        // assign the new vote amount to this Vote
        _votes[_msgSender()][_proposalId]._amount = amount;


        if(oldAmount > amount) { // refund excess token if vote amount reduced
            _transfer(address(this), _msgSender(), oldAmount.sub(amount));    
        } else { // lock new tokens if vote amount increased
            _transfer(_msgSender(), address(this), amount.sub(oldAmount));  
        }

        emit Voted(_msgSender(), _proposalId, vote,  amount);

        return true;
    }
    
    function releaseProposal() public returns (bool) {
        if (_proposalList.length == 0) {
            revert("releaseProposal: proposal not active");
        } else {
            require(_proposalList[_proposalId]._isActive, "releaseProposal: proposal not active" );
        }
        //require(_proposalList[_proposalId]._isActive, "releaseProposal: proposal not active");
        require( _proposalList[_proposalId]._votingEnds < block.timestamp, "releaseProposal: voting period has not ended");

        _proposalList[_proposalId]._isActive = false; // deactivate proposal
        _proposalList.push(Proposal(false, address(0), 0, 0, 0, 0) );

        uint256 proposalId = _proposalId;
        
        _proposalId = _proposalId.add(1); // increase proposalId for next proposal

        bool success = _proposalList[proposalId]._agree > _proposalList[proposalId]._disagree;
        // check if anyone voted and if agree total is grater than disagree total
        if(_proposalList[proposalId]._agree > 0 && success) {
            _mint( _proposalList[proposalId]._proposalAddress, _proposalList[proposalId]._mintAmount );
        }

        emit ReleaseProposal(proposalId, _proposalList[proposalId]._proposalAddress, _proposalList[proposalId]._mintAmount, success);
        
        return true;
    }

    function retrieve(uint proposalId) public {
        require(_proposalList[proposalId]._votingEnds < block.timestamp, "retrieve: voting period has not ended");

        if (_votes[_msgSender()][proposalId]._retrieved || _votes[_msgSender()][proposalId]._amount == 0) {
            return;
        }

        _votes[_msgSender()][proposalId]._retrieved = true;

        _transfer(address(this), _msgSender(), _votes[_msgSender()][proposalId]._amount);          

       emit Retrieved(proposalId, _votes[_msgSender()][proposalId]._amount);

    }

    function retrieveAll() public {

        for (uint i = _retrieveFrom[_msgSender()]; i < currentProposalID(); i++) {
            retrieve(i);
            _retrieveFrom[_msgSender()] = i;
        }

    }

    function getVote(address voter, uint256 proposalId) public view returns( bool vote, uint256 amount, bool retrieved) {
        
        vote = _votes[voter][proposalId]._vote ;
        amount = _votes[voter][proposalId]._amount;
        retrieved = _votes[voter][proposalId]._retrieved;

        return ( vote, amount, retrieved);
    }
    
    function getProposal(uint256 proposalId) public view returns( bool isActive, string memory state, address proposalAddress, uint256 mintAmount, uint256 endTime, uint256 remainingTime, uint256 agree, uint256 disagree, bool isSuccess){
        if (_proposalList.length > 0) {
            Proposal memory proposal = _proposalList[proposalId];

            uint256 remaining;
            if (proposal._votingEnds > block.timestamp) {
                remaining = proposal._votingEnds.sub(block.timestamp);
            } else {
                remaining = 0;
            }

            string memory _state = ( proposal._isActive && proposal._votingEnds > block.timestamp ) ? "voting" : "closed";
            return ( proposal._isActive, _state , proposal._proposalAddress, proposal._mintAmount, proposal._votingEnds, remaining, proposal._agree, proposal._disagree, proposal._agree > proposal._disagree);
        } else {
            return (false, "closed", address(0), 0, 0, 0, 0, 0, false);
        }
    }
    
    function currentProposal() public view returns (bool isActive, string memory state ,address proposalAddress, uint256 mintAmount, uint256 endTime, uint256 remainingTime, uint256 agree, uint256 disagree, bool isSuccess) {
        return getProposal(currentProposalID());
    }

    function currentProposalID() public view returns (uint256 proposalId){
        return _proposalId;
    }
    
}
