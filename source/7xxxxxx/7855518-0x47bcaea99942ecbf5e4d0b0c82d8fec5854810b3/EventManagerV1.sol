pragma solidity >=0.5.3 < 0.6.0;

import { SafeMath } from "./SafeMath.sol";
import { IMembershipManager } from "./IMembershipManager.sol";
import { BaseUtility } from "./BaseUtility.sol";

/// @author Ryan @ Protea
/// @title Basic staked event manager
contract EventManagerV1 is BaseUtility {
    mapping(uint256 => EventData) internal events_;
    /// For a reward to be issued, user state must be set to 99, meaning "Rewardable" this is to be considered the final state of users in issuer contracts
    mapping(uint256 => mapping(address => uint8)) internal memberState_;
    // States:
    // 0: Not registered
    // 1: RSVP'd
    // 98: Paid
    // 99: Attended (Rewardable)

    struct EventData{
        address organiser;
        uint256 requiredDai;
        uint256 gift;
        uint24 state; // 0: not created, 1: pending start, 2: started, 3: ended, 4: cancelled
        uint24 maxAttendees;
        address[] currentAttendees;
        uint24 totalAttended;
        string name;
    }

    event EventCreated(uint256 indexed index, address publisher);
    event EventStarted(uint256 indexed index, address publisher);
    event EventConcluded(uint256 indexed index, address publisher, uint256 state);
    event MemberRegistered(uint256 indexed index, address member, uint256 memberIndex);
    event MemberCancelled(uint256 indexed index, address member);
    event MemberAttended(uint256 indexed index, address member);

    /// @dev Sets the address of the admin to the msg.sender.
    /// @param _tokenManager        :address
    /// @param _membershipManager   :address
    /// @param _communityCreator    :address
    constructor (
        address _tokenManager,
        address _membershipManager,
        address _communityCreator
    )
        public
        BaseUtility(_tokenManager, _membershipManager, _communityCreator)
    {}

    modifier onlyRsvpAvailable(uint256 _index) {
        uint24 currentAttending = uint24(events_[_index].currentAttendees.length);
        require((events_[_index].maxAttendees == 0 || currentAttending < events_[_index].maxAttendees), "RSVP not available");
        _;
    }

    modifier onlyActiveMember(address _account){
        (,,uint256 availableStake) = IMembershipManager(membershipManager_).getMembershipStatus(_account);
        require(availableStake > 0, "Membership invalid");
        _;
    }

    modifier onlyMember(address _member, uint256 _index){
        require(memberState_[_index][_member] >= 1, "User not registered");
        _;
    }

    modifier onlyOrganiser(uint256 _index) {
        require(events_[_index].organiser == msg.sender, "Account not organiser");
        _;
    }

    modifier onlyPending(uint256 _index) {
        require(events_[_index].state == 1, "Event not pending");
        _;
    }

    modifier onlyStarted(uint256 _index) {
        require(events_[_index].state == 2, "Event not started");
        _;
    }

    modifier onlyRegistered(uint256 _index) {
        require(memberState_[_index][msg.sender] == 1, "User not registered");
        _;
    }

    /// @dev Creates an event.
    /// @param _name                :string The name of the event.
    /// @param _maxAttendees        :uint24 The max number of attendees for this event.
    /// @param _organiser           :address The orgoniser of the event
    /// @param _requiredDai       :uint256  The price of a 'deposit' for the event.
    function createEvent(
        string calldata _name,
        uint24 _maxAttendees,
        address _organiser,
        uint256 _requiredDai
    )
        external
        onlyActiveMember(msg.sender)
        returns(bool)
    {
        uint256 index = index_;

        events_[index].name = _name;
        events_[index].maxAttendees = _maxAttendees;
        events_[index].organiser = _organiser;
        events_[index].requiredDai = _requiredDai;
        events_[index].state = 1;
        memberState_[index][_organiser] = 99;
        events_[index].currentAttendees.push(_organiser);

        index_++;
        emit EventCreated(index, _organiser);
        return true;
    }

    /// @dev Changes the limit on the number of participants. Only the event organiser can call this function.
    /// @param _index           :uint256 The index of the event.
    /// @param _limit           :uint24  The new participation limit for the event.
    function changeParticipantLimit(uint256 _index, uint24 _limit)
        external
        onlyOrganiser(_index)
    {
        if(_limit == 0) {
            events_[_index].maxAttendees = 0;
        }else{
            require((events_[_index].currentAttendees.length < _limit), "Limit can only be increased");
            events_[_index].maxAttendees = _limit;
        }
    }

    /// @dev Allows an event organiser to end an event. This function is only callable by the organiser of the event.
    /// @param _index : The index of the event in the array of events.
    function startEvent(uint256 _index)
        external
        onlyOrganiser(_index)
        onlyPending(_index)
    {
        require(events_[_index].state == 1, "Unable to start event, either already started or ended");
        events_[_index].state = 2;
        emit EventStarted(_index, msg.sender);
    }

    /// @dev Allows an event organiser to end an event. This function is only callable by the manager of the event.
    /// @param _index : The index of the event in the array of events.
    function endEvent(uint256 _index)
        external
        onlyOrganiser(_index)
        onlyStarted(_index)
    {
        events_[_index].state = 3;
        calcGift(_index);
        emit EventConcluded(_index, msg.sender, events_[_index].state);
    }

    /// @dev Allows an event organiser to cancel an event.
    ///     This function is only callable by the event organiser.
    /// @param _index : The index of the event in the array of events.
    function cancelEvent(uint256 _index)
        external
        onlyOrganiser(_index)
        onlyPending(_index)
    {
        events_[_index].state = 4;
        emit EventConcluded(_index, msg.sender, events_[_index].state);
    }

    /// @dev Allows a member to RSVP for an event.
    /// @param _index           :uint256 The index of the event.
    function rsvp(uint256 _index)
        external
        onlyPending(_index)
        onlyRsvpAvailable(_index)
        returns (bool)
    {
        require(memberState_[_index][msg.sender] == 0, "RSVP not available");
        require(IMembershipManager(membershipManager_).lockCommitment(msg.sender, _index, events_[_index].requiredDai), "Insufficent tokens");

        memberState_[_index][msg.sender] = 1;
        events_[_index].currentAttendees.push(msg.sender);
        emit MemberRegistered(_index, msg.sender, events_[_index].currentAttendees.length - 1);
        return true;
    }

    /// @dev Allows a member to cancel an RSVP for an event.
    /// @param _index           :uint256 The index of the event.
    function cancelRsvp(uint256 _index)
        external
        onlyPending(_index)
        returns (bool)
    {
        require(memberState_[_index][msg.sender] == 1, "User not RSVP'd");
        require(IMembershipManager(membershipManager_).unlockCommitment(msg.sender, _index, 0), "Unlock of tokens failed");

        memberState_[_index][msg.sender] = 0;

        events_[_index].currentAttendees = removeFromList(msg.sender, events_[_index].currentAttendees);

        emit MemberCancelled(_index, msg.sender);
        return true;
    }

    /// @dev Allows a member to confirm attendance. Uses the msg.sender as the address of the member.
    /// @param _index : The index of the event in the array.
    function confirmAttendance(uint256 _index)
        external
        onlyStarted(_index)
        onlyRegistered(_index)
    {
        memberState_[_index][msg.sender] = 99;
        events_[_index].totalAttended = events_[_index].totalAttended + 1;

        require(IMembershipManager(membershipManager_).unlockCommitment(msg.sender, _index, 0), "Unlocking has failed");
        // Manual exposed attend until Proof of Attendance
        //partial release mechanisim is finished
        emit MemberAttended(_index, msg.sender);
    }

    /// @dev Allows the admin to confirm attendance for attendees
    /// @param _index       :uint256 The index of the event in the array.
    /// @param _attendees   :address[] List of attendee accounts.
    function organiserConfirmAttendance(uint256 _index, address[] calldata _attendees)
        external
        onlyStarted(_index)
        onlyOrganiser(_index)
    {
        uint256 arrayLength = _attendees.length;
        for(uint256 i = 0; i < arrayLength; i++){
            if(memberState_[_index][_attendees[i]] == 1){
                memberState_[_index][_attendees[i]] = 99;
                events_[_index].totalAttended = events_[_index].totalAttended + 1;

                require(IMembershipManager(membershipManager_).unlockCommitment(_attendees[i], _index, 0), "Unlocking has failed");
                emit MemberAttended(_index, _attendees[i]);
            }
        }
    }

    /// @dev Pays out an atendee of an event. This function is only callable by the attendee.
    /// @param _member : The member to be paid out
    /// @param _index : The index of the event of the array.
    function claimGift(address _member, uint256 _index)
        external
        onlyMember(_member, _index)
        returns(bool)
    {
        require(events_[_index].state == 3 || events_[_index].state == 4, "Event not concluded");
        if(events_[_index].state == 3){
            require(memberState_[_index][_member] == 99, "Deposits returned");
            require(IMembershipManager(membershipManager_).manualTransfer(events_[_index].gift, _index, _member), "Return amount invalid");
            memberState_[_index][msg.sender] = 98;
        }else{
            require(memberState_[_index][msg.sender] == 1, "Request invalid");
            require(IMembershipManager(membershipManager_).unlockCommitment(msg.sender, _index, 50), "Unlocking has failed");
            memberState_[_index][msg.sender] = 98;
        }

        return true;
    }

    /// @dev Allows an organiser to send any remaining tokens that could be left from math inaccuracies
    /// @param _index       :uint265 The index of the event of the array.
    /// @param _target      :address Account to receive the remaining tokens
    /// @notice  Due to division having some aspects of rounding, theres a potential to have tiny amounts of tokens locked, since these grow in value they should be managed
    function emptyActivitySlot(uint256 _index, address _target)
        external
        onlyOrganiser(_index)
    {
        require(events_[_index].state == 3, "Event not concluded");
        uint256 totalRemaining = IMembershipManager(membershipManager_).getUtilityStake(address(this), _index);
        require(totalRemaining <= 100, "Pool not low enough to allow");
        require(IMembershipManager(membershipManager_).manualTransfer(totalRemaining, _index, _target), "Return amount invalid");
    }

    /// @dev Calculates the gift for atendees.
    /// @param _index : The index of the event in the event manager.
    function calcGift(uint256 _index)
        internal
    {
        uint256 totalRemaining = IMembershipManager(membershipManager_).getUtilityStake(address(this), _index);
        if(totalRemaining > 0){
            events_[_index].gift = totalRemaining.div(events_[_index].totalAttended + 1);// accounts for the organizer to get a share
        }
    }

    /// @dev Used to get the members current state per activity
    /// @param _member : The member to be paid out
    /// @param _index : The index of the event in the event manager.
    function getUserState(address _member, uint256 _index) external view returns(uint8) {
        return memberState_[_index][_member];
    }

    /// @dev Gets the details of an event.
    /// @param _index           : The index of the event in the array of events.
    /// @return                 :EventData Event details.
    function getEvent(uint256 _index)
        external
        view
        returns(
            string memory,
            uint24,
            uint256,
            uint24,
            uint256
        )
    {
        return (
            events_[_index].name,
            events_[_index].maxAttendees,
            events_[_index].requiredDai,
            events_[_index].state,
            events_[_index].gift
        );
    }

    /// @dev Get a list of RSVP'd members
    /// @param _index : The index of the event in the event manager.
    function getRSVPdAttendees(uint256 _index)
        external
        view
        returns(address[] memory)
    {
        return events_[_index].currentAttendees;
    }

    /// @dev Used to get the organiser for a specific event
    /// @param _index : The index of the event in the event manager.
    function getOrganiser(uint256 _index)
        external
        view
        returns(address)
    {
        return events_[_index].organiser;
    }

    /// @dev Used for removing members from RSVP lists
    /// @param _target      :address account to remove
    /// @param _addressList :address[] The current list of attendees
    function removeFromList(address _target, address[] memory _addressList) internal pure returns(address[] memory) {
        uint256 offset = 0;
        address[] memory newList = new address[](_addressList.length-1);
        uint256 arrayLength = _addressList.length;
        for (uint256 i = 0; i < arrayLength; i++){
            if(_addressList[i] != _target){
                newList[i - offset] = _addressList[i];
            }else{
                offset = 1;
            }
        }
        return newList;
    }
}
