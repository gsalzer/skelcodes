// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PoolERC20Permit.sol";
import "./PoolStorage.sol";
import "./Errors.sol";
import "../Governed.sol";
import "../Pausable.sol";
import "../interfaces/bloq/IAddressList.sol";
import "../interfaces/vesper/IPoolRewards.sol";

/// @title Holding pool share token
// solhint-disable no-empty-blocks
abstract contract PoolShareToken is Initializable, PoolStorageV1, PoolERC20Permit, Governed, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint256 public constant MAX_BPS = 10_000;

    event Deposit(address indexed owner, uint256 shares, uint256 amount);
    event Withdraw(address indexed owner, uint256 shares, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) PoolERC20(_name, _symbol) {
        token = IERC20(_token);
    }

    /// @dev Equivalent to constructor for proxy. It can be called only once per proxy.
    function _initializePool(
        string memory _name,
        string memory _symbol,
        address _token
    ) internal initializer {
        _setName(_name);
        _setSymbol(_symbol);
        _initializePermit(_name);
        token = IERC20(_token);

        // Assuming token supports 18 or less decimals
        uint256 _decimals = IERC20Metadata(_token).decimals();
        decimalConversionFactor = 10**(18 - _decimals);
    }

    /**
     * @notice Deposit ERC20 tokens and receive pool shares depending on the current share price.
     * @param _amount ERC20 token amount.
     */
    function deposit(uint256 _amount) external virtual nonReentrant whenNotPaused {
        _deposit(_amount);
    }

    /**
     * @notice Deposit ERC20 tokens with permit aka gasless approval.
     * @param _amount ERC20 token amount.
     * @param _deadline The time at which signature will expire
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual nonReentrant whenNotPaused {
        IERC20Permit(address(token)).permit(_msgSender(), address(this), _amount, _deadline, _v, _r, _s);
        _deposit(_amount);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * Withdraw fee, if any, will be deduced from given shares and transferred to feeCollector.
     * Burn remaining shares and return collateral.
     * @param _shares Pool shares. It will be in 18 decimals.
     */
    function withdraw(uint256 _shares) external virtual nonReentrant whenNotShutdown {
        _withdraw(_shares);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * @dev Burn shares and return collateral. No withdraw fee will be assessed
     * when this function is called. Only some white listed address can call this function.
     * @param _shares Pool shares. It will be in 18 decimals.
     */
    function whitelistedWithdraw(uint256 _shares) external virtual nonReentrant whenNotShutdown {
        require(IAddressList(feeWhitelist).contains(_msgSender()), Errors.NOT_WHITELISTED_ADDRESS);
        _withdrawWithoutFee(_shares);
    }

    /**
     * @notice Transfer tokens to multiple recipient
     * @dev Address array and amount array are 1:1 and are in order.
     * @param _recipients array of recipient addresses
     * @param _amounts array of token amounts
     * @return true/false
     */
    function multiTransfer(address[] calldata _recipients, uint256[] calldata _amounts) external returns (bool) {
        require(_recipients.length == _amounts.length, Errors.INPUT_LENGTH_MISMATCH);
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(transfer(_recipients[i], _amounts[i]), Errors.MULTI_TRANSFER_FAILED);
        }
        return true;
    }

    /**
     * @notice Get price per share
     * @dev Return value will be in token defined decimals.
     */
    function pricePerShare() public view returns (uint256) {
        if (totalSupply() == 0 || totalValue() == 0) {
            return convertFrom18(1e18);
        }
        return (totalValue() * 1e18) / totalSupply();
    }

    /// @dev Convert from 18 decimals to token defined decimals.
    function convertFrom18(uint256 _amount) public view virtual returns (uint256) {
        return _amount / decimalConversionFactor;
    }

    /// @dev Returns the token stored in the pool. It will be in token defined decimals.
    function tokensHere() public view virtual returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Returns sum of token locked in other contracts and token stored in the pool.
     * Default tokensHere. It will be in token defined decimals.
     */
    function totalValue() public view virtual returns (uint256);

    /**
     * @dev Hook that is called just before burning tokens. This withdraw collateral from withdraw queue
     * @param _share Pool share in 18 decimals
     */
    function _beforeBurning(uint256 _share) internal virtual returns (uint256) {}

    /**
     * @dev Hook that is called just after burning tokens.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _afterBurning(uint256 _amount) internal virtual returns (uint256) {
        token.safeTransfer(_msgSender(), _amount);
        return _amount;
    }

    /**
     * @dev Hook that is called just before minting new tokens. To be used i.e.
     * if the deposited amount is to be transferred from user to this contract.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _beforeMinting(uint256 _amount) internal virtual {
        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /**
     * @dev Hook that is called just after minting new tokens. To be used i.e.
     * if the deposited amount is to be transferred to a different contract.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _afterMinting(uint256 _amount) internal virtual {}

    /// @dev Update pool rewards of sender and receiver during transfer.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (poolRewards != address(0)) {
            IPoolRewards(poolRewards).updateReward(sender);
            IPoolRewards(poolRewards).updateReward(recipient);
        }
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Calculate shares to mint based on the current share price and given amount.
     * @param _amount Collateral amount in collateral token defined decimals.
     * @return share amount in 18 decimal
     */
    function _calculateShares(uint256 _amount) internal view returns (uint256) {
        require(_amount != 0, Errors.INVALID_COLLATERAL_AMOUNT);
        uint256 _share = ((_amount * 1e18) / pricePerShare());
        return _amount > ((_share * pricePerShare()) / 1e18) ? _share + 1 : _share;
    }

    /// @notice claim rewards of account
    function _claimRewards(address _account) internal {
        if (poolRewards != address(0)) {
            IPoolRewards(poolRewards).claimReward(_account);
        }
    }

    /// @dev Deposit incoming token and mint pool token i.e. shares.
    function _deposit(uint256 _amount) internal {
        _claimRewards(_msgSender());
        uint256 _shares = _calculateShares(_amount);
        _beforeMinting(_amount);
        _mint(_msgSender(), _shares);
        _afterMinting(_amount);
        emit Deposit(_msgSender(), _shares, _amount);
    }

    /// @dev Burns shares and returns the collateral value, after fee, of those.
    function _withdraw(uint256 _shares) internal {
        if (withdrawFee == 0) {
            _withdrawWithoutFee(_shares);
        } else {
            require(_shares != 0, Errors.INVALID_SHARE_AMOUNT);
            _claimRewards(_msgSender());
            uint256 _fee = (_shares * withdrawFee) / MAX_BPS;
            uint256 _sharesAfterFee = _shares - _fee;
            uint256 _amountWithdrawn = _beforeBurning(_sharesAfterFee);
            // Recalculate proportional share on actual amount withdrawn
            uint256 _proportionalShares = _calculateShares(_amountWithdrawn);

            // Using convertFrom18() to avoid dust.
            // Pool share token is in 18 decimal and collateral token decimal is <=18.
            // Anything less than 10**(18-collateralTokenDecimal) is dust.
            if (convertFrom18(_proportionalShares) < convertFrom18(_sharesAfterFee)) {
                // Recalculate shares to withdraw, fee and shareAfterFee
                _shares = (_proportionalShares * MAX_BPS) / (MAX_BPS - withdrawFee);
                _fee = _shares - _proportionalShares;
                _sharesAfterFee = _proportionalShares;
            }
            _burn(_msgSender(), _sharesAfterFee);
            _transfer(_msgSender(), feeCollector, _fee);
            _afterBurning(_amountWithdrawn);
            emit Withdraw(_msgSender(), _shares, _amountWithdrawn);
        }
    }

    /// @dev Burns shares and returns the collateral value of those.
    function _withdrawWithoutFee(uint256 _shares) internal {
        require(_shares != 0, Errors.INVALID_SHARE_AMOUNT);
        _claimRewards(_msgSender());
        uint256 _amountWithdrawn = _beforeBurning(_shares);
        uint256 _proportionalShares = _calculateShares(_amountWithdrawn);
        if (convertFrom18(_proportionalShares) < convertFrom18(_shares)) {
            _shares = _proportionalShares;
        }
        _burn(_msgSender(), _shares);
        _afterBurning(_amountWithdrawn);
        emit Withdraw(_msgSender(), _shares, _amountWithdrawn);
    }
}

