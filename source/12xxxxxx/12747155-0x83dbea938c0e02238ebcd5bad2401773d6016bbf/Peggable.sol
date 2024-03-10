// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./ERC20Upgradeable.sol";

abstract contract PeggableToken is Initializable, ERC20Upgradeable, AccessControlUpgradeable {
    /// @notice Address that receives the pegged token when minting occurs
    address private _mintingBeneficiary;
    /// @notice Address of the pegged token
    address private _peggedToken;

    /// @notice Role for access control
    bytes32 public constant BENEFICIARY_MANAGER_ROLE = keccak256("BENEFICIARY_MANAGER_ROLE");

    /**
     * @dev Sets the values for {_peggedToken}, {_mintingBeneficiary}, and {_decimals}
     */
    function __Peggable_init_unchained(address peggedToken, address mintingBeneficiary_) internal initializer {
        _peggedToken = peggedToken;
        _changeMintingBeneficiary(mintingBeneficiary_);
    }

    /**
     * @dev Emitted when the minting beneficiary changes
     */
    event MintingBeneficiaryChanged(address oldBeneficiary, address newBeneficiary);

    /**
     * @dev Allow only the addresses with the BENEFICIARY_MANAGER_ROLE privileges
     */
    modifier onlyBeneficiaryManager() {
        _checkRole(BENEFICIARY_MANAGER_ROLE, _msgSender());
        _;
    }

    /**
     * @dev Burn the sender's tokens and return them the equivalent in the pegged token
     */
    function burn(uint256 amount) public virtual {
        _burn(amount);
    }

    /**
     * @dev Update the minting beneficiary
     */
    function changeMintingBeneficiary(address newBeneficiary) public virtual onlyBeneficiaryManager {
        _changeMintingBeneficiary(newBeneficiary);
    }

    /**
     * @dev Mint `amount` tokens and send them to `recipient`
     */
    function mint(address recipient, uint256 amount) public virtual {
        _mint(recipient, amount);
    }

    /**
     * @dev Returns the beneficiary of the pegged tokens taken during minting
     */
    function mintingBeneficiary() public view virtual returns (address) {
        return _mintingBeneficiary;
    }

    /**
     * @dev Returns the address of the pegged ERC-20 token
     */
    function peggedTokenAddress() public view virtual returns (address) {
        return _peggedToken;
    }

    /**
     * @dev Burn the sender's tokens and return them the equivalent in the pegged token
     */
    function _burn(uint256 amount) internal virtual {
        _burn(_msgSender(), amount);
        IERC20(_peggedToken).transfer(_msgSender(), amount);
    }

    /**
     * @dev Update the minting beneficiary
     */
    function _changeMintingBeneficiary(address newBeneficiary) internal virtual {
        require(newBeneficiary != address(0), "minting beneficiary cannot be zero address");
        if (_mintingBeneficiary != newBeneficiary) {
            address oldBeneficiary = _mintingBeneficiary;
            _mintingBeneficiary = newBeneficiary;
            emit MintingBeneficiaryChanged(oldBeneficiary, newBeneficiary);
        }
    }

    /**
     * @dev Mint `amount` tokens and send them to `recipient`
     */
    function _mint(address recipient, uint256 amount) internal virtual override {
        IERC20(_peggedToken).transferFrom(_msgSender(), _mintingBeneficiary, amount);
        super._mint(recipient, amount);
    }
}

