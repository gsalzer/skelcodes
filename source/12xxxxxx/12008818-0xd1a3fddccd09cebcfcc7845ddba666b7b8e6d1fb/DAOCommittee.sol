// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "AccessControl.sol";
import "StorageStateCommittee.sol";

import { SafeMath } from "SafeMath.sol";
import { IERC20 } from  "IERC20.sol";
import { IDAOCommittee } from "IDAOCommittee.sol";
import { ICandidate } from "ICandidate.sol";
import { ILayer2 } from "ILayer2.sol";
import { IDAOAgendaManager } from "IDAOAgendaManager.sol";
import { LibAgenda } from "LibAgenda.sol";
import { ERC165Checker } from "ERC165Checker.sol";

contract DAOCommittee is StorageStateCommittee, AccessControl, IDAOCommittee {
    using SafeMath for uint256;
    using LibAgenda for *;
     
    enum ApplyResult { NONE, SUCCESS, NOT_ELECTION, ALREADY_COMMITTEE, SLOT_INVALID, ADDMEMBER_FAIL, LOW_BALANCE }

    struct AgendaCreatingData {
        address[] target;
        uint128 noticePeriodSeconds;
        uint128 votingPeriodSeconds;
        bool atomicExecute;
        bytes[] functionBytecode;
    }

    //////////////////////////////
    // Events
    //////////////////////////////

    event QuorumChanged(
        uint256 newQuorum
    );

    event AgendaCreated(
        address indexed from,
        uint256 indexed id,
        address[] targets,
        uint128 noticePeriodSeconds,
        uint128 votingPeriodSeconds,
        bool atomicExecute
    );

    event AgendaVoteCasted(
        address indexed from,
        uint256 indexed id,
        uint256 voting,
        string comment
    );

    event AgendaExecuted(
        uint256 indexed id,
        address[] target
    );

    event CandidateContractCreated(
        address indexed candidate,
        address indexed candidateContract,
        string memo
    );

    event Layer2Registered(
        address indexed candidate,
        address indexed candidateContract,
        string memo
    );

    event ChangedMember(
        uint256 indexed slotIndex,
        address prevMember,
        address indexed newMember
    );

    event ChangedSlotMaximum(
        uint256 indexed prevSlotMax,
        uint256 indexed slotMax
    );

    event ClaimedActivityReward(
        address indexed candidate,
        address receiver,
        uint256 amount
    );

    event ChangedMemo(
        address candidate,
        string newMemo
    );

    event ActivityRewardChanged(
        uint256 newReward
    );
    
    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "DAOCommittee: msg.sender is not an admin");
        _;
    }

    modifier validMemberIndex(uint256 _index) {
        require(_index < maxMember, "DAOCommittee: invalid member index");
        _;
    }

    modifier nonZero(address _addr) {
        require(_addr != address(0), "DAOCommittee: zero address");
        _;
    }

    //////////////////////////////////////////////////////////////////////
    // setters

    /// @notice Set SeigManager contract address
    /// @param _seigManager New SeigManager contract address
    function setSeigManager(address _seigManager) external override onlyOwner nonZero(_seigManager) {
        seigManager = ISeigManager(_seigManager);
    }
     
    /// @notice Set SeigManager contract address on candidate contracts
    /// @param _candidateContracts Candidate contracts to be set
    /// @param _seigManager New SeigManager contract address
    function setCandidatesSeigManager(
        address[] calldata _candidateContracts,
        address _seigManager
    )
        external
        override
        onlyOwner
        nonZero(_seigManager)
    {
        for (uint256 i = 0; i < _candidateContracts.length; i++) {
            ICandidate(_candidateContracts[i]).setSeigManager(_seigManager);
        }
    }

    /// @notice Set DAOCommitteeProxy contract address on candidate contracts
    /// @param _candidateContracts Candidate contracts to be set
    /// @param _committee New DAOCommitteeProxy contract address
    function setCandidatesCommittee(
        address[] calldata _candidateContracts,
        address _committee
    )
        external
        override
        onlyOwner
        nonZero(_committee)
    {
        for (uint256 i = 0; i < _candidateContracts.length; i++) {
            ICandidate(_candidateContracts[i]).setCommittee(_committee);
        }
    }

    /// @notice Set DAOVault contract address
    /// @param _daoVault New DAOVault contract address
    function setDaoVault(address _daoVault) external override onlyOwner nonZero(_daoVault) {
        daoVault = IDAOVault(_daoVault);
    }

    /// @notice Set Layer2Registry contract address
    /// @param _layer2Registry New Layer2Registry contract address
    function setLayer2Registry(address _layer2Registry) external override onlyOwner nonZero(_layer2Registry) {
        layer2Registry = ILayer2Registry(_layer2Registry);
    }

    /// @notice Set DAOAgendaManager contract address
    /// @param _agendaManager New DAOAgendaManager contract address
    function setAgendaManager(address _agendaManager) external override onlyOwner nonZero(_agendaManager) {
        agendaManager = IDAOAgendaManager(_agendaManager);
    }

    /// @notice Set CandidateFactory contract address
    /// @param _candidateFactory New CandidateFactory contract address
    function setCandidateFactory(address _candidateFactory) external override onlyOwner nonZero(_candidateFactory) {
        candidateFactory = ICandidateFactory(_candidateFactory);
    }

    /// @notice Set TON contract address
    /// @param _ton New TON contract address
    function setTon(address _ton) external override onlyOwner nonZero(_ton) {
        ton = _ton;
    }

    /// @notice Set activity reward amount
    /// @param _value New activity reward per second
    function setActivityRewardPerSecond(uint256 _value) external override onlyOwner {
        activityRewardPerSecond = _value;
        emit ActivityRewardChanged(_value);
    }

    /// @notice Increases the number of member slot
    /// @param _newMaxMember New number of member slot
    /// @param _quorum New quorum
    function increaseMaxMember(
        uint256 _newMaxMember,
        uint256 _quorum
    )
        external
        override
        onlyOwner
    {
        require(maxMember < _newMaxMember, "DAOCommittee: You have to call decreaseMaxMember to decrease");
        uint256 prevMaxMember = maxMember;
        maxMember = _newMaxMember;
        fillMemberSlot();
        setQuorum(_quorum);
        emit ChangedSlotMaximum(prevMaxMember, _newMaxMember);
    }

    //////////////////////////////////////////////////////////////////////
    // Managing members

    /// @notice Creates a candidate contract and register it on SeigManager
    /// @param _memo A memo for the candidate
    function createCandidate(string calldata _memo)
        external
        override
        validSeigManager
        validLayer2Registry
        validCommitteeL2Factory
    {
        require(!isExistCandidate(msg.sender), "DAOCommittee: candidate already registerd");

        // Candidate
        address candidateContract = candidateFactory.deploy(
            msg.sender,
            false,
            _memo,
            address(this),
            address(seigManager)
        );

        require(
            candidateContract != address(0),
            "DAOCommittee: deployed candidateContract is zero"
        );
        require(
            _candidateInfos[msg.sender].candidateContract == address(0),
            "DAOCommittee: The candidate already has contract"
        );
        require(
            layer2Registry.registerAndDeployCoinage(candidateContract, address(seigManager)),
            "DAOCommittee: failed to registerAndDeployCoinage"
        );

        _candidateInfos[msg.sender] = CandidateInfo({
            candidateContract: candidateContract,
            memberJoinedTime: 0,
            indexMembers: 0,
            rewardPeriod: 0,
            claimedTimestamp: 0
        });

        candidates.push(msg.sender);
       
        emit CandidateContractCreated(msg.sender, candidateContract, _memo);
    }

    /// @notice Registers the exist layer2 on DAO
    /// @param _layer2 Layer2 contract address to be registered
    /// @param _memo A memo for the candidate
    function registerLayer2Candidate(address _layer2, string memory _memo)
        external
        override
        validSeigManager
        validLayer2Registry
        validCommitteeL2Factory
    {
        _registerLayer2Candidate(msg.sender, _layer2, _memo);
    }

    /// @notice Registers the exist layer2 on DAO by owner
    /// @param _operator Operator address of the layer2 contract
    /// @param _layer2 Layer2 contract address to be registered
    /// @param _memo A memo for the candidate
    function registerLayer2CandidateByOwner(address _operator, address _layer2, string memory _memo)
        external
        override
        onlyOwner
        validSeigManager
        validLayer2Registry
        validCommitteeL2Factory
    {
        _registerLayer2Candidate(_operator, _layer2, _memo);
    }

    /// @notice Replaces an existing member
    /// @param _memberIndex The member slot index to be replaced
    /// @return Whether or not the execution succeeded
    function changeMember(
        uint256 _memberIndex
    )
        external
        override
        validMemberIndex(_memberIndex)
        returns (bool)
    {
        address newMember = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[newMember];
        require(
            ICandidate(msg.sender).isCandidateContract(),
            "DAOCommittee: sender is not a candidate contract"
        );
        require(
            candidateInfo.candidateContract == msg.sender,
            "DAOCommittee: invalid candidate contract"
        );
        require(
            candidateInfo.memberJoinedTime == 0,
            "DAOCommittee: already member"
        );
        
        address prevMember = members[_memberIndex];
        address prevMemberContract = candidateContract(prevMember);

        candidateInfo.memberJoinedTime = uint128(block.timestamp);
        candidateInfo.indexMembers = _memberIndex;

        members[_memberIndex] = newMember;

        if (prevMember == address(0)) {
            emit ChangedMember(_memberIndex, prevMember, newMember);
            return true;
        }

        require(
            ICandidate(msg.sender).totalStaked() > ICandidate(prevMemberContract).totalStaked(),
            "not enough amount"
        );

        CandidateInfo storage prevCandidateInfo = _candidateInfos[prevMember];
        prevCandidateInfo.indexMembers = 0;
        prevCandidateInfo.rewardPeriod = uint128(uint256(prevCandidateInfo.rewardPeriod).add(block.timestamp.sub(prevCandidateInfo.memberJoinedTime)));
        prevCandidateInfo.memberJoinedTime = 0;

        emit ChangedMember(_memberIndex, prevMember, newMember);

        return true;
    }
    
    /// @notice Retires member
    /// @return Whether or not the execution succeeded
    function retireMember() onlyMemberContract external override returns (bool) {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(
            candidateInfo.candidateContract == msg.sender,
            "DAOCommittee: invalid candidate contract"
        );
        members[candidateInfo.indexMembers] = address(0);
        candidateInfo.rewardPeriod = uint128(uint256(candidateInfo.rewardPeriod).add(block.timestamp.sub(candidateInfo.memberJoinedTime)));
        candidateInfo.memberJoinedTime = 0;

        uint256 prevIndex = candidateInfo.indexMembers;
        candidateInfo.indexMembers = 0;
        emit ChangedMember(prevIndex, candidate, address(0));

        return true;
    }

    /// @notice Set memo
    /// @param _candidate candidate address
    /// @param _memo New memo on this candidate
    function setMemoOnCandidate(
        address _candidate,
        string calldata _memo
    )
        external
        override
    {
        address candidateContract = candidateContract(_candidate);
        setMemoOnCandidateContract(candidateContract, _memo);
    }

    /// @notice Set memo
    /// @param _candidateContract candidate contract address
    /// @param _memo New memo on this candidate
    function setMemoOnCandidateContract(
        address _candidateContract,
        string calldata _memo
    )
        public
        override
    {
        address candidate = ICandidate(_candidateContract).candidate();
        address contractOwner = candidate;
        if (ICandidate(_candidateContract).isLayer2Candidate()) {
            contractOwner = ILayer2(candidate).operator();
        }
        require(
            msg.sender == contractOwner,
            "DAOCommittee: sender is not the candidate of this contract"
        );

        ICandidate(_candidateContract).setMemo(_memo);
        emit ChangedMemo(candidate, _memo);
    }

    /// @notice Decreases the number of member slot
    /// @param _reducingMemberIndex Reducing member slot index
    /// @param _quorum New quorum
    function decreaseMaxMember(
        uint256 _reducingMemberIndex,
        uint256 _quorum
    )
        external
        override
        onlyOwner
        validMemberIndex(_reducingMemberIndex)
    {
        address reducingMember = members[_reducingMemberIndex];
        CandidateInfo storage reducingCandidate = _candidateInfos[reducingMember];

        if (_reducingMemberIndex != members.length - 1) {
            address tailmember = members[members.length - 1];
            CandidateInfo storage tailCandidate = _candidateInfos[tailmember];

            tailCandidate.indexMembers = _reducingMemberIndex;
            members[_reducingMemberIndex] = tailmember;
        }
        reducingCandidate.indexMembers = 0;
        reducingCandidate.rewardPeriod = uint128(uint256(reducingCandidate.rewardPeriod).add(block.timestamp.sub(reducingCandidate.memberJoinedTime)));
        reducingCandidate.memberJoinedTime = 0;

        members.pop();
        maxMember = maxMember.sub(1);
        setQuorum(_quorum);

        emit ChangedMember(_reducingMemberIndex, reducingMember, address(0));
        emit ChangedSlotMaximum(maxMember.add(1), maxMember);
    }

    //////////////////////////////////////////////////////////////////////
    // Managing agenda

    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    ) external override returns (bool) {
        AgendaCreatingData memory agendaData = _decodeAgendaData(data);

        _createAgenda(
            owner,
            agendaData.target,
            agendaData.noticePeriodSeconds,
            agendaData.votingPeriodSeconds,
            agendaData.atomicExecute,
            agendaData.functionBytecode
        );

        return true;
    }

    /// @notice Set new quorum
    /// @param _quorum New quorum
    function setQuorum(
        uint256 _quorum
    )
        public
        override
        onlyOwner
        validAgendaManager
    {
        require(_quorum > maxMember.div(2), "DAOCommittee: invalid quorum");
        require(_quorum <= maxMember, "DAOCommittee: quorum exceed max member");
        quorum = _quorum;
        emit QuorumChanged(quorum);
    }

    /// @notice Set fee amount of creating an agenda
    /// @param _fees Fee amount on TON
    function setCreateAgendaFees(
        uint256 _fees
    )
        external
        override
        onlyOwner
        validAgendaManager
    {
        agendaManager.setCreateAgendaFees(_fees);
    }

    /// @notice Set the minimum notice period
    /// @param _minimumNoticePeriod New minimum notice period in second
    function setMinimumNoticePeriodSeconds(
        uint256 _minimumNoticePeriod
    )
        external
        override
        onlyOwner
        validAgendaManager
    {
        agendaManager.setMinimumNoticePeriodSeconds(_minimumNoticePeriod);
    }

    /// @notice Set the minimum voting period
    /// @param _minimumVotingPeriod New minimum voting period in second
    function setMinimumVotingPeriodSeconds(
        uint256 _minimumVotingPeriod
    )
        external
        override
        onlyOwner
        validAgendaManager
    {
        agendaManager.setMinimumVotingPeriodSeconds(_minimumVotingPeriod);
    }

    /// @notice Set the executing period
    /// @param _executingPeriodSeconds New executing period in second
    function setExecutingPeriodSeconds(
        uint256 _executingPeriodSeconds
    )
        external
        override
        onlyOwner
        validAgendaManager
    {
        agendaManager.setExecutingPeriodSeconds(_executingPeriodSeconds);
    }

    /// @notice Vote on an agenda
    /// @param _agendaID The agenda ID
    /// @param _vote voting type
    /// @param _comment voting comment
    function castVote(
        uint256 _agendaID,
        uint256 _vote,
        string calldata _comment
    )
        external 
        override
        validAgendaManager
    {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(
            candidateInfo.candidateContract == msg.sender,
            "DAOCommittee: invalid candidate contract"
        );
        
        agendaManager.castVote(
            _agendaID,
            candidate,
            _vote
        );

        (uint256 yes, uint256 no, uint256 abstain) = agendaManager.getVotingCount(_agendaID);

        if (quorum <= yes) {
            // yes
            agendaManager.setResult(_agendaID, LibAgenda.AgendaResult.ACCEPT);
            agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus.WAITING_EXEC);
        } else if (quorum <= no) {
            // no
            agendaManager.setResult(_agendaID, LibAgenda.AgendaResult.REJECT);
            agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus.ENDED);
        } else if (quorum <= abstain.add(no) ) {
            // dismiss
            agendaManager.setResult(_agendaID, LibAgenda.AgendaResult.DISMISS);
            agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus.ENDED);
        }
        
        emit AgendaVoteCasted(msg.sender, _agendaID, _vote, _comment);
    }

    /// @notice Set the agenda status as ended(denied or dismissed)
    /// @param _agendaID Agenda ID
    function endAgendaVoting(uint256 _agendaID) external override {
        agendaManager.endAgendaVoting(_agendaID);
    }

    /// @notice Execute the accepted agenda
    /// @param _agendaID Agenda ID
    function executeAgenda(uint256 _agendaID) external override validAgendaManager {
        require(
            agendaManager.canExecuteAgenda(_agendaID),
            "DAOCommittee: can not execute the agenda"
        );
        
         (address[] memory target,
             bytes[] memory functionBytecode,
             bool atomicExecute,
             uint256 executeStartFrom
         ) = agendaManager.getExecutionInfo(_agendaID);
       
        if (atomicExecute) {
            agendaManager.setExecutedAgenda(_agendaID);
            for (uint256 i = 0; i < target.length; i++) {
                (bool success, ) = address(target[i]).call(functionBytecode[i]);
                require(success, "DAOCommittee: Failed to execute the agenda");
            }
        } else {
            uint256 succeeded = 0;
            for (uint256 i = executeStartFrom; i < target.length; i++) {
                bool success = _call(target[i], functionBytecode[i].length, functionBytecode[i]);
                if (success) {
                    succeeded = succeeded.add(1);
                } else {
                    break;
                }
            }

            agendaManager.setExecutedCount(_agendaID, succeeded);
            if (executeStartFrom.add(succeeded) == target.length) {
                agendaManager.setExecutedAgenda(_agendaID);
            }
        }

        emit AgendaExecuted(_agendaID, target);
    }

    /// @notice Set status and result of specific agenda
    /// @param _agendaID Agenda ID
    /// @param _status New status
    /// @param _result New result
    function setAgendaStatus(uint256 _agendaID, uint256 _status, uint256 _result) external override onlyOwner {
        agendaManager.setResult(_agendaID, LibAgenda.AgendaResult(_result));
        agendaManager.setStatus(_agendaID, LibAgenda.AgendaStatus(_status));
    }
     
    /// @notice Call updateSeigniorage on SeigManager
    /// @param _candidate Candidate address to be updated
    /// @return Whether or not the execution succeeded
    function updateSeigniorage(address _candidate) public override returns (bool) {
        address candidateContract = _candidateInfos[_candidate].candidateContract;
        return ICandidate(candidateContract).updateSeigniorage();
    }

    /// @notice Call updateSeigniorage on SeigManager
    /// @param _candidates Candidate addresses to be updated
    /// @return Whether or not the execution succeeded
    function updateSeigniorages(address[] calldata _candidates) external override returns (bool) {
        for (uint256 i = 0; i < _candidates.length; i++) {
            require(
                updateSeigniorage(_candidates[i]),
                "DAOCommittee: failed to update seigniorage"
            );
        }

        return true;
    }

    /// @notice Claims the activity reward for member
    function claimActivityReward(address _receiver) external override {
        address candidate = ICandidate(msg.sender).candidate();
        CandidateInfo storage candidateInfo = _candidateInfos[candidate];
        require(
            candidateInfo.candidateContract == msg.sender,
            "DAOCommittee: invalid candidate contract"
        );

        uint256 amount = getClaimableActivityReward(candidate);
        require(amount > 0, "DAOCommittee: you don't have claimable ton");

        daoVault.claimTON(_receiver, amount);
        candidateInfo.claimedTimestamp = uint128(block.timestamp);
        candidateInfo.rewardPeriod = 0;

        emit ClaimedActivityReward(candidate, _receiver, amount);
    }

    function _registerLayer2Candidate(address _operator, address _layer2, string memory _memo)
        internal
        validSeigManager
        validLayer2Registry
        validCommitteeL2Factory
    {
        require(!isExistCandidate(_layer2), "DAOCommittee: candidate already registerd");

        require(
            _layer2 != address(0),
            "DAOCommittee: deployed candidateContract is zero"
        );
        require(
            _candidateInfos[_layer2].candidateContract == address(0),
            "DAOCommittee: The candidate already has contract"
        );
        ILayer2 layer2 = ILayer2(_layer2);
        require(
            layer2.isLayer2(),
            "DAOCommittee: invalid layer2 contract"
        );
        require(
            layer2.operator() == _operator,
            "DAOCommittee: invalid operator"
        );

        address candidateContract = candidateFactory.deploy(
            _layer2,
            true,
            _memo,
            address(this),
            address(seigManager)
        );

        require(
            candidateContract != address(0),
            "DAOCommittee: deployed candidateContract is zero"
        );

        _candidateInfos[_layer2] = CandidateInfo({
            candidateContract: candidateContract,
            memberJoinedTime: 0,
            indexMembers: 0,
            rewardPeriod: 0,
            claimedTimestamp: 0
        });

        candidates.push(_layer2);
       
        emit Layer2Registered(_layer2, candidateContract, _memo);
    }

    function fillMemberSlot() internal {
        for (uint256 i = members.length; i < maxMember; i++) {
            members.push(address(0));
        }
    }

    function _decodeAgendaData(bytes calldata input)
        internal
        view
        returns (AgendaCreatingData memory data)
    {
        (data.target, data.noticePeriodSeconds, data.votingPeriodSeconds, data.atomicExecute, data.functionBytecode) = 
            abi.decode(input, (address[], uint128, uint128, bool, bytes[]));
    }

    function payCreatingAgendaFee(address _creator) internal {
        uint256 fee = agendaManager.createAgendaFees();

        require(IERC20(ton).transferFrom(_creator, address(this), fee), "DAOCommittee: failed to transfer ton from creator");
        require(IERC20(ton).transfer(address(1), fee), "DAOCommittee: failed to burn");
    }
   
    function _createAgenda(
        address _creator,
        address[] memory _targets,
        uint128 _noticePeriodSeconds,
        uint128 _votingPeriodSeconds,
        bool _atomicExecute,
        bytes[] memory _functionBytecodes
    )
        internal
        validAgendaManager
        returns (uint256)
    {
        // pay to create agenda, burn ton.
        payCreatingAgendaFee(_creator);

        uint256 agendaID = agendaManager.newAgenda(
            _targets,
            _noticePeriodSeconds,
            _votingPeriodSeconds,
            _atomicExecute,
            _functionBytecodes
        );
          
        emit AgendaCreated(
            _creator,
            agendaID,
            _targets,
            _noticePeriodSeconds,
            _votingPeriodSeconds,
            _atomicExecute
        );

        return agendaID;
    }

    function _call(address target, uint256 paramLength, bytes memory param) internal returns (bool) {
        bool result;
        assembly {
            let data := add(param, 32)
            result := call(sub(gas(), 40000), target, 0, data, paramLength, 0, 0)
        }

        return result;
    }

    function isCandidate(address _candidate) external view override returns (bool) {
        CandidateInfo storage info = _candidateInfos[_candidate];

        if (info.candidateContract == address(0)) {
            return false;
        }

        bool supportIsCandidateContract = ERC165Checker.supportsInterface(
            info.candidateContract,
            ICandidate(info.candidateContract).isCandidateContract.selector
        );

        if (supportIsCandidateContract == false) {
            return false;
        }

        return ICandidate(info.candidateContract).isCandidateContract();
    }
    
    function totalSupplyOnCandidate(
        address _candidate
    )
        external
        override
        view
        returns (uint256 totalsupply)
    {
        address candidateContract = candidateContract(_candidate);
        return totalSupplyOnCandidateContract(candidateContract);
    }

    function balanceOfOnCandidate(
        address _candidate,
        address _account
    )
        external
        override
        view
        returns (uint256 amount)
    {
        address candidateContract = candidateContract(_candidate);
        return balanceOfOnCandidateContract(candidateContract, _account);
    }
    
    function totalSupplyOnCandidateContract(
        address _candidateContract
    )
        public
        override
        view
        returns (uint256 totalsupply)
    {
        require(_candidateContract != address(0), "This account is not a candidate");

        return ICandidate(_candidateContract).totalStaked();
    }

    function balanceOfOnCandidateContract(
        address _candidateContract,
        address _account
    )
        public
        override
        view
        returns (uint256 amount)
    {
        require(_candidateContract != address(0), "This account is not a candidate");

        return ICandidate(_candidateContract).stakedOf(_account);
    }

    function candidatesLength() external view override returns (uint256) {
        return candidates.length;
    }

    function isExistCandidate(address _candidate) public view override returns (bool isExist) {
        return _candidateInfos[_candidate].candidateContract != address(0);
    }

    function getClaimableActivityReward(address _candidate) public view override returns (uint256) {
        CandidateInfo storage info = _candidateInfos[_candidate];
        uint256 period = info.rewardPeriod;

        if (info.memberJoinedTime > 0) {
            if (info.memberJoinedTime > info.claimedTimestamp) {
                period = period.add(block.timestamp.sub(info.memberJoinedTime));
            } else {
                period = period.add(block.timestamp.sub(info.claimedTimestamp));
            }
        }

        return period.mul(activityRewardPerSecond);
    }
}

