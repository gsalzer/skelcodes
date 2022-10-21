// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../utils/Ownable.sol";
import "../utils/ContractKeys.sol";

/**
 * @title  LoanRegistry
 * @author NFTfi
 * @dev Registry for Loan Types supported by NFTfi.
 * Each Loan type is associated with the address of a Loan contract that implements the loan type.
 */
contract LoanRegistry is Ownable {
    /* ******* */
    /* STORAGE */
    /* ******* */

    /**
     * @dev For each loan type, records the address of the contract that implements the type
     */
    mapping(bytes32 => address) private typeContracts;
    /**
     * @dev reverse mapping of loanTypes - for each contract address, records the associated loan type
     */
    mapping(address => bytes32) private contractTypes;

    /* ****** */
    /* EVENTS */
    /* ****** */

    /**
     * @notice This event is fired whenever the admins register a loan type.
     *
     * @param loanType - Loan type represented by keccak256('loan type').
     * @param loanContract - Address of the loan type contract.
     */
    event TypeUpdated(bytes32 indexed loanType, address indexed loanContract);

    /* *********** */
    /* CONSTRUCTOR */
    /* *********** */

    /**
     * @notice Sets the admin of the contract.
     * Initializes `contractTypes` with a batch of loan types.
     *
     * @param _admin - Initial admin of this contract.
     * @param _loanTypes - Loan types represented by keccak256('loan type').
     * @param _loanContracts - The addresses of each wrapper contract that implements the loan type's behaviour.
     */
    constructor(
        address _admin,
        string[] memory _loanTypes,
        address[] memory _loanContracts
    ) Ownable(_admin) {
        _registerLoans(_loanTypes, _loanContracts);
    }

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    /**
     * @notice  Set or update the contract address that implements the given Loan Type.
     * Set address(0) for a loan type for un-register such type.
     *
     * @param _loanType - Loan type represented by 'loan type'.
     * @param _loanContract - The address of the wrapper contract that implements the loan type's behaviour.
     */
    function registerLoan(string memory _loanType, address _loanContract) external onlyOwner {
        _registerLoan(_loanType, _loanContract);
    }

    /**
     * @notice  Batch set or update the contract addresses that implement the given batch Loan Type.
     * Set address(0) for a loan type for un-register such type.
     *
     * @param _loanTypes - Loan types represented by 'loan type'.
     * @param _loanContracts - The addresses of each wrapper contract that implements the loan type's behaviour.
     */
    function registerLoans(string[] memory _loanTypes, address[] memory _loanContracts) external onlyOwner {
        _registerLoans(_loanTypes, _loanContracts);
    }

    /**
     * @notice This function can be called by anyone to get the contract address that implements the given loan type.
     *
     * @param  _loanType - The loan type, e.g. bytes32("DIRECT_LOAN_FIXED"), or bytes32("DIRECT_LOAN_PRO_RATED").
     */
    function getContractFromType(bytes32 _loanType) external view returns (address) {
        return typeContracts[_loanType];
    }

    /**
     * @notice This function can be called by anyone to get the loan type of the given contract address.
     *
     * @param  _loanContract - The loan contract
     */
    function getTypeFromContract(address _loanContract) external view returns (bytes32) {
        return contractTypes[_loanContract];
    }

    /**
     * @notice  Set or update the contract address that implements the given Loan Type.
     * Set address(0) for a loan type for un-register such type.
     *
     * @param _loanType - Loan type represented by 'loan type').
     * @param _loanContract - The address of the wrapper contract that implements the loan type's behaviour.
     */
    function _registerLoan(string memory _loanType, address _loanContract) internal {
        require(bytes(_loanType).length != 0, "loanType is empty");
        bytes32 loanTypeKey = ContractKeys.getIdFromStringKey(_loanType);

        typeContracts[loanTypeKey] = _loanContract;
        contractTypes[_loanContract] = loanTypeKey;

        emit TypeUpdated(loanTypeKey, _loanContract);
    }

    /**
     * @notice  Batch set or update the contract addresses that implement the given batch Loan Type.
     * Set address(0) for a loan type for un-register such type.
     *
     * @param _loanTypes - Loan types represented by keccak256('loan type').
     * @param _loanContracts - The addresses of each wrapper contract that implements the loan type's behaviour.
     */
    function _registerLoans(string[] memory _loanTypes, address[] memory _loanContracts) internal {
        require(_loanTypes.length == _loanContracts.length, "registerLoans function information arity mismatch");

        for (uint256 i = 0; i < _loanTypes.length; i++) {
            _registerLoan(_loanTypes[i], _loanContracts[i]);
        }
    }
}

