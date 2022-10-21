// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./vendor/openzeppelin/SafeMath.sol";
import "./vendor/openzeppelin/ECDSA.sol";

/**
 * @dev Escrow contract for ETH based escrows
 */
contract Escrow {

    using SafeMath for uint256;
    using ECDSA for bytes32;

    event FundsDeposited(address indexed buyer, uint256 amount);
    event FundsRefunded();
    event FundsReleased(address indexed seller, uint256 amount);
    event DisputeResolved();
    event OwnershipTransferred(address indexed oldOwner, address newOwner);
    event MediatorChanged(address indexed oldMediator, address newMediator);

    enum Status { AWAITING_PAYMENT, PAID, REFUNDED, MEDIATED, COMPLETE }

    Status public status;
    bytes32 public escrowID;
    uint256 public amount;
    uint256 public fee;
    uint256 public commission;
    address payable public owner;
    address payable public mediator;
    address payable public affiliate;
    address payable public buyer;
    address payable public seller;
    bool public funded = false;
    bool public completed = false;
    bytes32 public releaseMsgHash;
    bytes32 public resolveMsgHash;

    modifier onlyExactAmount(uint256 _amount) {
        require(_amount == depositAmount(), "Amount needs to be exact.");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can call this function.");
        _;
    }

    modifier onlyWithBuyerSignature(bytes32 hash, bytes memory signature) {
        require(
            hash.toEthSignedMessageHash()
                .recover(signature) == buyer,
            "Must be signed by buyer."
        );
        _;
    }

    modifier onlyWithParticipantSignature(bytes32 hash, bytes memory signature) {
        address signer = hash.toEthSignedMessageHash()
            .recover(signature);
        require(
            signer == buyer || signer == seller,
            "Must be signed by either buyer or seller."
        );
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can call this function.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyMediator() {
        require(msg.sender == mediator, "Only the mediator can call this function.");
        _;
    }

    modifier onlyUnfunded() {
        require(funded == false, "Escrow already funded.");
        funded = true;
        _;
    }

    modifier onlyFunded() {
        require(funded == true, "Escrow not funded.");
        _;
    }

    modifier onlyIncompleted() {
        require(completed == false, "Escrow already completed.");
        completed = true;
        _;
    }

    constructor(
        bytes32 _escrowID,
        address payable _owner,
        address payable _buyer,
        address payable  _seller,
        address payable _mediator,
        address payable _affiliate,
        uint256 _amount,
        uint256 _fee,
        uint256 _commission
    )
    {
        status = Status.AWAITING_PAYMENT;
        escrowID = _escrowID;
        owner = _owner;
        buyer = _buyer;
        seller = _seller;
        mediator = _mediator;
        affiliate = _affiliate;
        amount = _amount;
        fee = _fee;
        commission = _commission;
        releaseMsgHash = keccak256(
            abi.encodePacked("releaseFunds()", escrowID, address(this))
        );
        resolveMsgHash = keccak256(
            abi.encodePacked("resolveDispute()", escrowID, address(this))
        );
        emit OwnershipTransferred(address(0), _owner);
        emit MediatorChanged(address(0), _owner);
    }

    receive() external payable {
        deposit();
    }

    function depositAmount() public view returns (uint256) {
        return amount;
    }

    function deposit()
        public
        payable
        onlyUnfunded
        onlyExactAmount(msg.value)
    {
        status = Status.PAID;
        emit FundsDeposited(msg.sender, msg.value);
    }

    function refund()
        public
        onlySeller
        onlyFunded
        onlyIncompleted
    {
        buyer.transfer(depositAmount());
        status = Status.REFUNDED;
        emit FundsRefunded();
    }

    function _releaseFees() private {
        (bool success, ) = mediator.call{value: fee}("");
        require(success, "Transfer to mediator failed");
        if (affiliate != address(0) && commission > 0) {
            (success, ) = affiliate.call{value: commission}("");
            require(success, "Transfer to affiliate failed");
        }
    }

    function releaseFunds(
        bytes calldata _signature
    )
        external
        onlyFunded
        onlyIncompleted
        onlyWithBuyerSignature(releaseMsgHash, _signature)
    {
        uint256 releaseAmount = depositAmount().sub(fee);
        if (affiliate != address(0) && commission > 0) {
            releaseAmount = releaseAmount.sub(commission);
        }
        (bool success, ) = seller.call{value: releaseAmount}("");
        require(success, "Transfer to seller failed");
        _releaseFees();
        status = Status.COMPLETE;
        emit FundsReleased(seller, releaseAmount);
    }

    function resolveDispute(
        bytes calldata _signature,
        uint8 _buyerPercent
    )
        external
        onlyFunded
        onlyMediator
        onlyIncompleted
        onlyWithParticipantSignature(resolveMsgHash, _signature)
    {
        require(_buyerPercent <= 100, "_buyerPercent must be 100 or lower");
        uint256 releaseAmount = depositAmount().sub(fee);
        if (affiliate != address(0) && commission > 0) {
            releaseAmount = releaseAmount.sub(commission);
        }

        status = Status.MEDIATED;
        emit DisputeResolved();

        if (_buyerPercent > 0)
          buyer.transfer(releaseAmount.mul(uint256(_buyerPercent)).div(100));
        if (_buyerPercent < 100)
          seller.transfer(releaseAmount.mul(uint256(100).sub(_buyerPercent)).div(100));

        _releaseFees();
    }

    function setOwner(address payable _newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function setMediator(address payable _newMediator) external onlyOwner {
        emit MediatorChanged(mediator, _newMediator);
        mediator = _newMediator;
    }
}
