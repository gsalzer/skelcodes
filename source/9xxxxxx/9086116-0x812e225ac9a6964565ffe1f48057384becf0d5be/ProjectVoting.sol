pragma solidity 0.5.8;

import "./ICALL.sol";
import {Ownable} from "./Ownable.sol";
import {SafeMath} from "./SafeMath.sol";
import {ERC1820Client} from "./ERC1820Client.sol";

contract ProjectVoting is Ownable, ERC1820Client { // solhint-disable-line max-states-count

    using SafeMath for uint256;

    event PVoteStateChanged(PVoteState old_state, PVoteState new_state, uint256 indexed round);

    event Vote(address voter, uint256 power, uint256 indexed project_id, uint256 indexed round);

    event Winner(uint256 project_id, uint256 indexed round);

    event ProjectAdded(bytes32 title, bytes32 ipfsData, uint8 hashFunction, uint8 size, uint256 indexed id, uint256 indexed round);

    enum PVoteState {
        ADD_PROJECTS,
        VOTE,
        REFUND,
        CLEAR
    }

    ICALL public callObj;

    /*                                         GENERAL VARIABLES                                          */
    /*                                               START                                                */
    /* ================================================================================================== */

    uint256 public voteEndTime;
    uint256 public votingTime; //timestamp for vote to end
    uint256 public clearTime;
    PVoteState public state; //0->add projects 1->vote 2->refunding 3->clearing

    uint256 public totalVoters;
    uint256 public totalToRefund;

    mapping(address => uint256) public powerOf; //totalAmount each address submitted
    mapping(uint256 => address) public voters; //mapping finding voters, so as to iterate
    mapping(address => uint256) public votedFor; //mapping so as to know that each address votes exactly for one project

    /*                                         GENERAL VARIABLES                                          */
    /*                                                END                                                 */
    /* ================================================================================================== */

    /*                                          STEP VARIABLES                                            */
    /*                                               START                                                */
    /* ================================================================================================== */

    mapping(uint256 => Project) public projects; //mapping holding info about the steps

    mapping(uint256 => Ipfs) public ipfses;

    struct Ipfs {
        bytes32 data;
        uint8 hashFunction;
        uint8 size;
    }

    struct Project {
        bytes32 title;
        uint256 value;
        uint256 id;
    }

    uint256 public winningId;
    uint256 public winnerId;

    uint256 public noOfProjects;
    uint256 public noOfProjectsAdded;

    uint256 public round = 1;

    /*                                          STEP VARIABLES                                            */
    /*                                               END                                                  */
    /* ================================================================================================== */


    /*                                             MODIFIERS                                              */
    /*                                               START                                                */
    /* ================================================================================================== */
    modifier onlyCall() {
        require(address(callObj) == msg.sender, "ProjectVoting: only from CALL");
        _;
    }

    modifier onlyAddProjectsState() {
        require(state == PVoteState.ADD_PROJECTS, "ProjectVoting: only in add projects state");
        _;
    }

    modifier onlyVoteState() {
        require(state == PVoteState.VOTE, "ProjectVoting: only in vote state");
        _;
    }

    modifier onlyInVoteTime() {
        require(voteEndTime > now, "ProjectVoting: Time for vote has ended");
        _;
    }


    modifier onlyRefundState() {
        require(state == PVoteState.REFUND, "ProjectVoting: only in refund state");
        _;
    }

    modifier onlyInRefundTime() {
        require(voteEndTime.add(clearTime) > now, "ProjectVoting: Time for refund has ended");
        _;
    }

    modifier onlyClearState() {
        require(state == PVoteState.CLEAR, "ProjectVoting: only in clear state");
        _;
    }

    /*                                             MODIFIERS                                              */
    /*                                                END                                                 */
    /* ================================================================================================== */


    constructor(address _callAddress, uint256 _votingTime, uint256 _clearTime, uint256 _noOfProjects) public {
        clearTime = _clearTime;
        votingTime = _votingTime;
        callObj = ICALL(_callAddress);
        noOfProjects = _noOfProjects;
        setInterfaceImplementation("ERC777TokensRecipient", address(this));
    }


    /**
     * @notice Set the CALL address
     * @param _callAddress The address of CALL contract
     */
    function setCallAddress(address _callAddress)
    public
    onlyOwner
    onlyAddProjectsState
    {
        callObj = ICALL(_callAddress);
    }

    function setClearTime(uint256 _clearTime)
    public
    onlyOwner
    onlyAddProjectsState
    {
        clearTime = _clearTime;
    }

    function setVoteTime(uint256 _votingTime)
    public
    onlyOwner
    onlyAddProjectsState
    {
        votingTime = _votingTime;
    }

    function setLimit(uint256 _noOfProjects)
    public
    onlyOwner
    onlyAddProjectsState
    {
        noOfProjects = _noOfProjects;
    }

    function checkVoteState()
    public
    onlyVoteState
    {
        if (voteEndTime <= now) _startRefundState(); // solhint-disable-line not-rely-on-time
    }

    function checkRefundState()
    public
    {
        if (voteEndTime.add(clearTime) <= now) _startClearState(); // solhint-disable-line not-rely-on-time
    }

    /*                                            STEP FUNCTIONS                                          */
    /*                                                START                                               */
    /* ================================================================================================== */


    function addProjects(
        bytes32[10] memory _titles,
        bytes32[10] memory _ipfsData,
        uint8[10] memory _ipfsHashFunction,
        uint8[10] memory _ipfsSize
    )
    public
    onlyOwner
    onlyAddProjectsState
    {
        uint256 loopMax = noOfProjects.sub(noOfProjectsAdded);

        if (loopMax > 10) loopMax = 10;

        for (uint256 i = 0; i < loopMax; i++) {  //cannot overflow, because addition using SafeMath
            noOfProjectsAdded = noOfProjectsAdded.add(1);
            Ipfs memory ipfs = Ipfs(_ipfsData[i], _ipfsHashFunction[i], _ipfsSize[i]);
            Project memory project;
            project.title = _titles[i];
            project.id = noOfProjectsAdded;

            emit ProjectAdded(_titles[i], _ipfsData[i], _ipfsHashFunction[i], _ipfsSize[i], noOfProjectsAdded, round);

            projects[noOfProjectsAdded] = project;
            ipfses[noOfProjectsAdded] = ipfs;
        }

        if (noOfProjectsAdded == noOfProjects) {
            noOfProjectsAdded = 0;
            _startVoteState(now.add(votingTime)); // solhint-disable-line not-rely-on-time
        }
    }

    function addProject(
        bytes32 _title,
        bytes32 _ipfsData,
        uint8 _ipfsHashFunction,
        uint8 _ipfsSize
    )
    public
    onlyOwner
    onlyAddProjectsState
    {
        noOfProjectsAdded = noOfProjectsAdded.add(1);
        Ipfs memory ipfs = Ipfs(_ipfsData, _ipfsHashFunction, _ipfsSize);
        Project memory project;
        project.title = _title;
        project.id = noOfProjectsAdded;

        emit ProjectAdded(_title, _ipfsData, _ipfsHashFunction, _ipfsSize, noOfProjectsAdded, round);

        projects[noOfProjectsAdded] = project;
        ipfses[noOfProjectsAdded] = ipfs;

        if (noOfProjectsAdded == noOfProjects) {
            noOfProjectsAdded = 0;
            _startVoteState(now.add(votingTime)); // solhint-disable-line not-rely-on-time
        }
    }

    function restartAddProjectsState()
    public
    onlyOwner
    onlyAddProjectsState
    {
        noOfProjectsAdded = 0;
    }

    /*                                           STEP FUNCTIONS                                           */
    /*                                                END                                                 */
    /* ================================================================================================== */


    /*                                          VOTING FUNCTIONS                                          */
    /*                                                START                                               */
    /* ================================================================================================== */


    /**
     * @notice function called when this contract receives tokens
     * @param operator Address sending the tx
     * @param from Address that sending the funds for the tx
     * @param to Address in which tx is sent
     * @param amount Amount of tokens sent
     * @param userData Data of the from address
     * @param operatorData Data of the operator address
     */
    function tokensReceived(
        address operator, // solhint-disable no-unused-vars
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )  // solhint-enable no-unused-vars
    public
    onlyCall
    {
        require(userData[0] <= bytes1(uint8(noOfProjects)) && userData[0] > 0x00, "ProjectVoting: Wrong Id");
        _vote(from, amount,  uint8(userData[0]));
    }

    /*                                          VOTING FUNCTIONS                                          */
    /*                                                END                                                 */
    /* ================================================================================================== */

    /*                                          ENDING FUNCTIONS                                          */
    /*                                               START                                                */
    /* ================================================================================================== */

     /**
     * @notice This function returns funds to the voters
     */
    function returnFunds(uint256[] memory _positions)
    public
    onlyRefundState
    onlyInRefundTime
    {
        uint256 size;

        for (uint256 pos = 0; pos < _positions.length; pos++) {
            if (_positions[pos] < totalVoters && powerOf[voters[_positions[pos]]] != 0) size = size.add(1);
        }

        address[] memory addresses = new address[](size);
        uint256[] memory amounts = new uint256[](size);

        uint256 counter;

        for (uint256 pos = 0; pos < _positions.length; pos++) {
            if (powerOf[voters[_positions[pos]]] != 0 && _positions[pos] < totalVoters) {
                addresses[counter] = voters[_positions[pos]];
                amounts[counter] = powerOf[addresses[counter]];
                totalToRefund = totalToRefund.sub(1);
                powerOf[addresses[counter]] = 0;
                counter = counter.add(1);
            }
        }
        callObj.multiPartySend(addresses, amounts, "");
        _startAddProjectsState();
    }

    function returnFunds(uint256 _start, uint256 _stop)
    public
    onlyRefundState
    onlyInRefundTime
    {
        if (_stop > totalVoters) _stop = totalVoters;
        uint256 size = _stop.sub(_start);
        address[] memory addresses = new address[](size);
        uint256[] memory amounts = new uint256[](size);
        uint256 arrCurr = 0;
        for (uint256 pos = _start; pos < _stop; pos++) {
            addresses[arrCurr] = voters[pos];
            amounts[arrCurr] = powerOf[addresses[arrCurr]];
            if (amounts[arrCurr] != 0) {
                totalToRefund = totalToRefund.sub(1);
                powerOf[addresses[arrCurr]] = 0;
            }
            arrCurr = arrCurr.add(1);
        }
        callObj.multiPartySend(addresses, amounts, ""); // solhint-disable-line check-send-result
        _startAddProjectsState();
    }

    function returnFunds()
    public
    onlyRefundState
    onlyInRefundTime
    {
        uint256 amount = powerOf[msg.sender];
        if (amount == 0) return;
        totalToRefund = totalToRefund.sub(1);
        powerOf[msg.sender] = 0;
        callObj.send(msg.sender, amount, ""); // solhint-disable-line check-send-result
        _startAddProjectsState();
    }

    function executeClear(uint256[] memory _positions) public onlyClearState {
        for (uint256 pos = 0; pos < _positions.length; pos++) {
            address addr = voters[_positions[pos]];
            if (powerOf[addr] != 0) {
                totalToRefund = totalToRefund.sub(1);
                powerOf[addr] = 0;
            }
        }
        _startAddProjectsState();
    }

    /*** State Transitions ***/

    function _startAddProjectsState() internal {
        if (totalToRefund == 0) {
            voteEndTime = 0;
            uint256 balance = callObj.balanceOf(address(this));
            PVoteState oldState = state; //we don't know if it was clear or refund before

            state = PVoteState.ADD_PROJECTS; // solhint-disable-line reentrancy
            emit PVoteStateChanged(oldState, PVoteState.ADD_PROJECTS, round);
            round = round.add(1);
            if (balance != 0) callObj.send(owner(), balance, ""); // solhint-disable-line check-send-result
        }
    }

    function _startVoteState(uint256 _endTime) internal {
        // solhint-disable-next-line not-rely-on-time
        require(_endTime > now, "ProjectVoting: timestamp must be a point in the future");
        voteEndTime = _endTime;
        state = PVoteState.VOTE;
        emit PVoteStateChanged(PVoteState.ADD_PROJECTS, PVoteState.VOTE, round);
        totalVoters = 0; //Maybe another place
    }

    function _startRefundState() internal {
        state = PVoteState.REFUND;
        emit PVoteStateChanged(PVoteState.VOTE, PVoteState.REFUND, round);
        winnerId = winningId;
        emit Winner(winnerId, round);
        winningId = 0;
        totalToRefund = totalVoters;
        // event for Winner
    }

    function _startClearState() internal {
        state = PVoteState.CLEAR;
        emit PVoteStateChanged(PVoteState.REFUND, PVoteState.CLEAR, round);
    }

    /**
     * @notice This function is called by CALL contract, when a client decides that he likes changes, in tokensReceived step
     * @param _sender the sender of the tx
     * @param _power The value of tokens _sender moved to this contract
     */
    function _vote(address _sender, uint256 _power, uint256 _id)
    internal
    onlyVoteState
    onlyInVoteTime
    {
        require(_power != 0, "ProjectVoting: Cannot vote with 0 value");

        if (powerOf[_sender] == 0) {
            powerOf[_sender] = _power;
            voters[totalVoters] = _sender;
            totalVoters = totalVoters.add(1);
            votedFor[_sender] = _id;
        } else {
            require(votedFor[_sender] == _id, "ProjectVoting: Cannot vote for different projects");
            powerOf[_sender] = powerOf[_sender].add(_power);
        }
        projects[_id].value = projects[_id].value.add(_power);

        emit Vote(_sender, _power, _id, round);

        if (projects[_id].value > projects[winningId].value) winningId = _id;
    }

    /*                                          ENDING FUNCTIONS                                          */
    /*                                                END                                                 */
    /* ================================================================================================== */
}

