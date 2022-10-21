// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";

abstract contract TaxableToken is Initializable, ERC20Upgradeable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    /// @notice Beneficiary of taxes levied upon transfers
    address private _taxBeneficiary;
    /// @notice Tax percentage
    uint256 private _taxPercentage;
    /// @notice Divisor for calculating the tax percentage
    uint256 internal _taxPercentageDivisor;

    /// @notice Role for access control
    bytes32 public constant TAX_MANAGER_ROLE = keccak256("TAX_MANAGER_ROLE");

    /**
     * @dev Sets the values for {_taxBeneficiary} and {_taxPercentage}
     */
    function __TaxableToken_init_unchained(address taxBeneficiary_, uint256 taxPercentage_) internal initializer {
        _taxPercentageDivisor = 10000;
        _setTaxBeneficiary(taxBeneficiary_);
        _setTaxPercentage(taxPercentage_);
    }

    /**
     * @dev Emitted when the tax beneficiary changes
     */
    event TaxBeneficiaryChanged(address oldBeneficiary, address newBeneficiary);

    /**
     * @dev Emitted when the ta
     uint256 oldPercentage = _taxPercentage;x percentage changes
     */
    event TaxPercentageChanged(uint256 oldPercentage, uint256 newPercentage);

    /**
     * @dev Allow only the addresses with the TAX_MANAGER_ROLE privileges
     */
    modifier onlyTaxManager() {
        _checkRole(TAX_MANAGER_ROLE, _msgSender());
        _;
    }

    /**
     * @dev Retrieve the minimum valid tax percentage
     */
    function minimumTaxPercentage() public pure virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Retrieve the maximum valid tax percentage
     */
    function maximumTaxPercentage() public view virtual returns (uint256) {
        return _taxPercentageDivisor;
    }

    /**
     * @dev Change the beneficiary
     */
    function setTaxBeneficiary(address newBeneficiary) public virtual onlyTaxManager {
        _setTaxBeneficiary(newBeneficiary);
    }

    /**
     * @dev Set the tax percentage
     */
    function setTaxPercentage(uint256 newPercentage) public virtual onlyTaxManager {
        _setTaxPercentage(newPercentage);
    }

    /**
     * @dev Returns the address of the tax beneficiary
     */
    function taxBeneficiary() public view virtual returns (address) {
        return _taxBeneficiary;
    }

    /**
     * @dev Returns the tax percentage
     */
    function taxPercentage() public view virtual returns (uint256) {
        return _taxPercentage;
    }

    /**
     * @dev Calculate the value of the tax to levy for the given `amount`
     */
    function _calculateTaxableAmount(uint256 amount) internal view virtual returns (uint256) {
        uint256 tax = 0;
        if (_taxPercentage > 0) {
            tax = amount.mul(_taxPercentage).div(_taxPercentageDivisor);
        }
        return tax;
    }

    /**
     * @dev Change the beneficiary
     */
    function _setTaxBeneficiary(address newBeneficiary) internal virtual {
        require(newBeneficiary != address(0), "new beneficiary cannot be zero address");
        if (_taxBeneficiary != newBeneficiary) {
            address oldBeneficiary = _taxBeneficiary;
            _taxBeneficiary = newBeneficiary;
            emit TaxBeneficiaryChanged(oldBeneficiary, newBeneficiary);
        }
    }

    /**
     * @dev Validates and checks the tax percentage
     */
    function _setTaxPercentage(uint256 newPercentage) internal virtual {
        if (_taxPercentage != newPercentage) {
            require(
                (newPercentage >= 0 && newPercentage <= _taxPercentageDivisor),
                "outside of valid range"
            );
            uint256 oldPercentage = _taxPercentage;
            _taxPercentage = newPercentage;
            emit TaxPercentageChanged(oldPercentage, newPercentage);
        }
    }

    /**
     * @dev Overridden to add tax levying functionality
     */
    function _transferTaxable(address sender, address recipient, uint256 amount) internal virtual {
        uint256 tax = _calculateTaxableAmount(amount);
        super._transfer(sender, recipient, amount);
        if (tax > 0) {
            super._transfer(sender, _taxBeneficiary, tax);
        }
    }
}

