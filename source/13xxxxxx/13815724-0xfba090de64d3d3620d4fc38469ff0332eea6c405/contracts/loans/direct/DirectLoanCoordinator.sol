// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../LoanRegistry.sol";
import "../../smartNft/SmartNft.sol";
import "../../interfaces/IDirectLoanCoordinator.sol";
import "../../interfaces/INftfiHub.sol";

/**
 * @title  DirectLoanCoordinator
 * @author NFTfi
 * @notice This contract is in charge of coordinating the creation, disctubution and desctruction of the SmartNfts
 * related to a loan, the Promossory Note and Obligaiton Receipt.
 */
contract DirectLoanCoordinator is IDirectLoanCoordinator {
    /* ******* */
    /* STORAGE */
    /* ******* */

    INftfiHub public immutable hub;

    /**
     * @notice A continuously increasing counter that simultaneously allows every loan to have a unique ID and provides
     * a running count of how many loans have been started by this contract.
     */
    uint256 public totalNumLoans = 0;

    // The address that deployed this contract
    address private immutable _deployer;
    bool private _initialized = false;

    mapping(uint256 => Loan) private loans;

    address public override promissoryNoteToken;
    address public override obligationReceiptToken;

    /* ****** */
    /* EVENTS */
    /* ****** */

    event UpdateStatus(
        uint256 indexed loanId,
        uint256 indexed smartNftId,
        address indexed loanContract,
        StatusType newStatus
    );

    /**
     * @dev Function using this modifier can only be executed after this contract is initialized
     *
     */
    modifier onlyInitialized() {
        require(_initialized, "not initialized");

        _;
    }

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @dev Sets `NftfiHub`.
     *
     * @param  _nftfiHub - Address of the NftfiHub contract
     */
    constructor(address _nftfiHub) {
        hub = INftfiHub(_nftfiHub);
        _deployer = msg.sender;
    }

    /**
     * @dev Sets `promissoryNoteToken` and `obligationReceiptToken`.
     * It can be executed once by the deployer.
     *
     * @param  _promissoryNoteToken - Promissory Note Token address
     * @param  _obligationReceiptToken - Obligaiton Recipt Token address
     */
    function initialize(address _promissoryNoteToken, address _obligationReceiptToken) external {
        require(msg.sender == _deployer, "only deployer");
        require(!_initialized, "already initialized");
        require(_promissoryNoteToken != address(0), "promissoryNoteToken is zero");
        require(_obligationReceiptToken != address(0), "obligationReceiptToken is zero");

        _initialized = true;
        promissoryNoteToken = _promissoryNoteToken;
        obligationReceiptToken = _obligationReceiptToken;
    }

    /**
     * @dev This is called by the LoanType beginning the new loan.
     * It initialize the new loan data, mints both PromissoryNote and ObligationReceipt SmartNft's and returns the
     * new loan id.
     *
     * @param _lender - Address of the lender
     * @param _borrower - Address of the borrower
     * @param _loanType - The type of the loan
     */
    function registerLoan(
        address _lender,
        address _borrower,
        bytes32 _loanType
    ) external override onlyInitialized returns (uint256) {
        address loanContract = msg.sender;

        LoanRegistry loanRegistry = LoanRegistry(hub.getContract(ContractKeys.LOAN_REGISTRY));
        require(loanRegistry.getContractFromType(_loanType) == loanContract, "Caller must be registered for loan type");

        // (loanIds start at 1)
        totalNumLoans += 1;

        uint256 smartNftId = uint256(keccak256(abi.encodePacked(address(this), totalNumLoans)));

        Loan memory newLoan = Loan({status: StatusType.NEW, loanContract: loanContract, smartNftId: smartNftId});

        // Issue an ERC721 promissory note to the lender that gives them the
        // right to either the principal-plus-interest or the collateral.
        SmartNft(promissoryNoteToken).mint(_lender, smartNftId, abi.encode(totalNumLoans));

        // Issue an ERC721 obligation receipt to the borrower that gives them the
        // right to pay back the loan and get the collateral back.
        SmartNft(obligationReceiptToken).mint(_borrower, smartNftId, abi.encode(totalNumLoans));

        loans[totalNumLoans] = newLoan;

        emit UpdateStatus(totalNumLoans, smartNftId, loanContract, StatusType.NEW);

        return totalNumLoans;
    }

    /**
     * @dev This is called by the LoanType who created the loan, when a loan is resolved whether by paying back or
     * liquidating the loan.
     * It sets the loan as `RESOLVED` and burns both PromossoryNote and ObligationReceipt SmartNft's.
     *
     * @param _loanId - Id of the loan
     */
    function resolveLoan(uint256 _loanId) external override onlyInitialized {
        Loan storage loan = loans[_loanId];
        require(loan.status == StatusType.NEW, "Loan status must be New");
        require(loan.loanContract == msg.sender, "Not the same Contract that registered Loan");

        loan.status = StatusType.RESOLVED;

        SmartNft(promissoryNoteToken).burn(loan.smartNftId);
        SmartNft(obligationReceiptToken).burn(loan.smartNftId);

        emit UpdateStatus(_loanId, loan.smartNftId, msg.sender, StatusType.RESOLVED);
    }

    /**
     * @dev Returns loan's data for a given id.
     *
     * @param _loanId - Id of the loan
     */
    function getLoanData(uint256 _loanId) external view override returns (Loan memory) {
        return loans[_loanId];
    }

    /**
     * @dev checks if the given id is valid for the given loan contract address
     * @param _loanId - Id of the loan
     * @param _loanContract - address og the loan contract
     */
    function isValidLoanId(uint256 _loanId, address _loanContract) external view override returns (bool validity) {
        validity = loans[_loanId].loanContract == _loanContract;
    }
}

