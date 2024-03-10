pragma solidity >=0.5.0;

contract HeatChek {

    struct Proposal {
        address clientAddress;
        address influencerAddress;
        uint256 minimumLengthOfTimePostedInHours;
        uint256 lockedRate;
        uint256 userId;
        uint256 hourlyRate;
        uint256 pricePerPost;
        bool violatedContract;
        uint256 proposalUUID;
        bool completed;
    }

    event ProposalCreated(
        string message,
        address clientAddress,
        address influencerAddress,
        uint256 minimumLengthOfTimePostedInHours,
        uint256 lockedRate,
        uint256 userId,
        uint256 hourlyRate,
        uint256 pricePerPost,
        bool violatedContract,
        uint256 proposalUUID
    );

    event ServiceFeeDistributed(
        string message,
        address servicerAddress,
        uint256 proposalUUID,
        uint256 serviceFeeAmmount
    );

    event InfluencerPaymentDistributed(
        string message,
        address influencerAddress,
        uint256 proposalUUID,
        uint256 lockedRate,
        uint256 influencerPayment,
        uint256 serviceFeeCharged
    );

    event ProposalCompleted(
        string message,
        address servicerAddress,
        address clientAddress,
        address influencerAddress,
        uint256 lockedRate,
        uint256 serviceFeeCharged,
        uint256 influencerPayment,
        uint256 proposalUUID
    );

     event NullifyProposalContract(
        string message,
        uint256 proposalUUID,
        address clientAddress,
        address influencerAddress
    );

    event RefundClient(
        string message,
        address clientAddress,
        uint256 refundAmmount
    );

    event CompleteWithdrawalAccepted(
        string message,
        uint256 ammount
    );

    event PartialWithdrawalAccepted(
        string message,
        uint256 ammount
    );

    address contractOwner;
    mapping(address => uint256) balances;
    mapping(uint256 => Proposal) proposals;

    constructor() public {
        contractOwner = msg.sender;
        balances[contractOwner] = 0;
    }

    function createProposal(
        address _influencerAddress,
        uint256 _minimumLengthOfTimePostedInHours,
        uint256 _lockedRate,
        uint256 _userId,
        uint256 _hourlyRate,
        uint256 _pricePerPost,
        uint256 _proposalUUID
    )
        public
        payable
        returns (bool)
    {

        Proposal memory p = Proposal({
            clientAddress: msg.sender,
            influencerAddress: _influencerAddress,
            minimumLengthOfTimePostedInHours: _minimumLengthOfTimePostedInHours,
            lockedRate: _lockedRate,
            userId: _userId,
            hourlyRate: _hourlyRate,
            pricePerPost: _pricePerPost,
            violatedContract: false,
            proposalUUID: _proposalUUID,
            completed: false
        });

        proposals[_proposalUUID] = p;

        balances[_influencerAddress] += msg.value;

        emit ProposalCreated({
            message: "Proposal was created",
            clientAddress: msg.sender,
            influencerAddress: _influencerAddress,
            minimumLengthOfTimePostedInHours: _minimumLengthOfTimePostedInHours,
            lockedRate: _lockedRate,
            userId: _userId,
            hourlyRate: _hourlyRate,
            pricePerPost: _pricePerPost,
            violatedContract: false,
            proposalUUID: _proposalUUID
        });

        return true;
    }


    function getProposal(uint256 _proposalId)
        proposalExists(_proposalId)
        public
        view
        returns (
            address _clientAddress,
            address _influencerAddress,
            uint256 _minimumLengthOfTimePostedInHours,
            uint256 _lockedRate,
            uint256 _userId,
            uint256 _hourlyRate,
            uint256 _pricePerPost,
            bool _violatedContract,
            uint256 _proposalUUID,
            bool completed
        )
    {
        Proposal memory p = proposals[_proposalId];

        return (
            p.clientAddress,
            p.influencerAddress,
            p.minimumLengthOfTimePostedInHours,
            p.lockedRate,
            p.userId,
            p.hourlyRate,
            p.pricePerPost,
            p.violatedContract,
            p.proposalUUID,
            p.completed
        );
    }

    function payInfluencer(uint256 _proposalUUID)
        isOwner
        proposalExists(_proposalUUID)
        validProposal(_proposalUUID)
        incompleteProposal(_proposalUUID)
        public
        payable
        returns (bool)
    {
        uint256 preformattedRate = proposals[_proposalUUID].lockedRate * 10 ** uint256(18);
        uint256 serviceFee = preformattedRate / 100;
        uint256 influencerPayment = preformattedRate - serviceFee;
        address payable influencerAddress = address(uint160(proposals[_proposalUUID].influencerAddress));

        balances[msg.sender] += serviceFee;
        balances[influencerAddress] -= influencerPayment;

        msg.sender.transfer(serviceFee);

        emit ServiceFeeDistributed({
            message: "Service Fee has been sent",
            servicerAddress: msg.sender,
            proposalUUID: _proposalUUID,
            serviceFeeAmmount: serviceFee
        });

        influencerAddress.transfer(influencerPayment);

        emit InfluencerPaymentDistributed({
            message: "Influencer payment has been sent",
            influencerAddress: influencerAddress,
            proposalUUID: _proposalUUID,
            lockedRate: proposals[_proposalUUID].lockedRate,
            influencerPayment: influencerPayment,
            serviceFeeCharged: serviceFee
        });
        
        proposals[_proposalUUID].completed = true;

        emit ProposalCompleted({
            message: "Proposal has been completed",
            servicerAddress: msg.sender,
            clientAddress: proposals[_proposalUUID].clientAddress,
            influencerAddress: proposals[_proposalUUID].influencerAddress,
            lockedRate: proposals[_proposalUUID].lockedRate,
            serviceFeeCharged: serviceFee,
            influencerPayment: influencerPayment,
            proposalUUID: _proposalUUID
        });
        
        return true;
    }

    function voidContractAndRefundClient(uint256 _proposalUUID)
        isOwner
        proposalExists(_proposalUUID)
        public
        payable
        returns (bool)
    {
        proposals[_proposalUUID].violatedContract = true;
        
        emit NullifyProposalContract({
            message: "Contract has been voided",
            proposalUUID: _proposalUUID,
            clientAddress: proposals[_proposalUUID].clientAddress,
            influencerAddress: proposals[_proposalUUID].influencerAddress
        });
        
        balances[proposals[_proposalUUID].influencerAddress] -= proposals[_proposalUUID].lockedRate;
        address payable clientAddress = address(uint160(proposals[_proposalUUID].clientAddress));
        uint256 formattedRefundAmmount = proposals[_proposalUUID].lockedRate * 10 ** uint256(18);
        clientAddress.transfer(formattedRefundAmmount);

        emit RefundClient({
            message: "Refund completed",
            clientAddress: proposals[_proposalUUID].clientAddress,
            refundAmmount: formattedRefundAmmount
        });
    }

    function widthraw()
        isOwner
        hasFunds
        public
        returns (bool)
    {
        msg.sender.transfer(balances[msg.sender]);
        return true;
    }

    function owner() public view returns (address) {
        return contractOwner;
    }
    
    modifier incompleteProposal(uint256 _proposalUUID) {
        require(proposals[_proposalUUID].completed == false);
        _;
    }

    modifier belongsToInfluencer(uint256 _proposalUUID) {
        require(msg.sender == proposals[_proposalUUID].influencerAddress);
        _;
    }

    modifier isOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    modifier hasFunds() {
        require(balances[msg.sender] > 0 ether);
        _;
    }

    modifier belongsToRequester(uint256 _proposalUUID) {
        require(_proposalUUID > 0);
        require(proposals[_proposalUUID].clientAddress == msg.sender);
        _;
    }

    modifier validProposal(uint256 _proposalUUID) {
        require(_proposalUUID > 0);
        require(proposals[_proposalUUID].violatedContract == false);
        _;
    }

    modifier voidProposal(uint256 _proposalUUID) {
        require(_proposalUUID > 0);
        require(proposals[_proposalUUID].violatedContract == true);
        _;
    }

    modifier proposalExists(uint256 _proposalUUID) {
        require(_proposalUUID > 0);
        require(proposals[_proposalUUID].lockedRate > 0);
        _;
    }

    modifier couldAffordTx(uint256 _lockedRate) {
        uint256 lockedRate = _lockedRate * 10 ** uint256(18);
        require(lockedRate > 0);
        require(lockedRate == msg.value);
        _;
    }

    modifier notContractOwner() {
        require(msg.sender != contractOwner);
        _;
    }


    modifier proposalDoesNotExist(uint256 _proposalUUID) {
        require(_proposalUUID > 0);
        require(proposals[_proposalUUID].lockedRate == 0);
        _;
    }

}
