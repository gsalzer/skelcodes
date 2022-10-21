// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./vendor/openzeppelin/SafeERC20.sol";
import "./vendor/openzeppelin/SafeMath.sol";
import "./vendor/openzeppelin/ECDSA.sol";

/**
 * @dev Escrow contract for ERC20 token based escrows
 */
contract ERC20Escrow {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
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
    address public owner;
    address public mediator;
    address public affiliate;
    address public buyer;
    address public seller;
    IERC20 public token;
    bool public funded = false;
    bool public completed = false;
    bytes32 public releaseMsgHash;
    bytes32 public resolveMsgHash;

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
        IERC20 _token,
        address _owner,
        address _buyer,
        address _seller,
        address _mediator,
        address _affiliate,
        uint256 _amount,
        uint256 _fee,
        uint256 _commission
    )
    {
        status = Status.AWAITING_PAYMENT;
        escrowID = _escrowID;
        token = _token;
        owner = _owner;
        buyer = _buyer;
        mediator = _mediator;
        affiliate = _affiliate;
        seller = _seller;
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

    function depositAmount() public view returns (uint256) {
        return amount;
    }

    function deposit()
        public
        onlyUnfunded
    {
        token.safeTransferFrom(msg.sender, address(this), depositAmount());
        status = Status.PAID;
        emit FundsDeposited(msg.sender, depositAmount());
    }

    function _releaseFees() private {
        token.safeTransfer(mediator, fee);
        if (affiliate != address(0) && commission > 0) {
            token.safeTransfer(affiliate, commission);
        }
    }

    function refund()
        public
        onlySeller
        onlyFunded
        onlyIncompleted
    {
        token.safeTransfer(buyer, depositAmount());
        status = Status.REFUNDED;
        emit FundsRefunded();
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
        token.safeTransfer(seller, releaseAmount);
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
          token.safeTransfer(buyer, releaseAmount.mul(uint256(_buyerPercent)).div(100));
        if (_buyerPercent < 100)
          token.safeTransfer(seller, releaseAmount.mul(uint256(100).sub(_buyerPercent)).div(100));

        _releaseFees();
    }

    function setOwner(address _newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function setMediator(address _newMediator) external onlyOwner {
        emit MediatorChanged(mediator, _newMediator);
        mediator = _newMediator;
    }
}
