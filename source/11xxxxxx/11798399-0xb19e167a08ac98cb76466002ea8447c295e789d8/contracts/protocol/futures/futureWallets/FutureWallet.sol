pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "contracts/interfaces/ERC20.sol";
import "contracts/interfaces/apwine/tokens/IFutureYieldToken.sol";
import "contracts/interfaces/apwine/IFuture.sol";
import "contracts/interfaces/apwine/IController.sol";
import "contracts/interfaces/apwine/IRegistry.sol";

import "contracts/interfaces/apwine/utils/IAPWineMath.sol";

/**
 * @title Future Wallet abstraction
 * @author Gaspard Peduzzi
 * @notice Main abstraction for the future wallets contract
 * @dev The future wallets stores the yield after each expiration of the future period
 */
abstract contract FutureWallet is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FUTURE_ROLE = keccak256("FUTURE_ROLE");

    IFuture public future;
    ERC20 public ibt;

    event YieldRedeemed(address _user, uint256 _periodIndex);

    /**
     * @notice Intializer
     * @param _futureAddress the address of the corresponding future
     * @param _adminAddress the address of the admin
     */
    function initialize(address _futureAddress, address _adminAddress) public virtual initializer {
        future = IFuture(_futureAddress);
        ibt = ERC20(future.getIBTAddress());
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _setupRole(ADMIN_ROLE, _adminAddress);
        _setupRole(FUTURE_ROLE, _futureAddress);
    }

    /**
     * @notice register the yield of an expired period
     * @param _amount the amount of yield to be registered
     */
    function registerExpiredFuture(uint256 _amount) public virtual;

    /**
     * @notice redeem the yield of the underlying yield of the FYT held by the sender
     * @param _periodIndex the index of the period to redeem the yield from
     */
    function redeemYield(uint256 _periodIndex) public virtual nonReentrant {
        require(_periodIndex < future.getNextPeriodIndex() - 1, "Invalid period index");
        IFutureYieldToken fyt = IFutureYieldToken(future.getFYTofPeriod(_periodIndex));
        uint256 senderTokenBalance = fyt.balanceOf(msg.sender);
        require(senderTokenBalance > 0, "FYT sender balance should not be null");

        uint256 claimableYield = _updateYieldBalances(_periodIndex, senderTokenBalance, fyt.totalSupply());

        fyt.burnFrom(msg.sender, senderTokenBalance);
        ibt.transfer(msg.sender, claimableYield);
        emit YieldRedeemed(msg.sender, _periodIndex);
    }

    /**
     * @notice return the yield that could be redeemed by an address for a particular period
     * @param _periodIndex the index of the corresponding period
     * @param _tokenHolder the FYT holder
     * @return the yield that could be redeemed by the token holder for this period
     */
    function getRedeemableYield(uint256 _periodIndex, address _tokenHolder) public view virtual returns (uint256);

    /**
     * @notice collect and update the yield balance of the sender
     * @param _periodIndex the index of the corresponding period
     * @param _userFYT the FYT holder balance
     * @param _totalFYT the total FYT supply
     * @return the yield that could be redeemed by the token holder for this period
     */
    function _updateYieldBalances(
        uint256 _periodIndex,
        uint256 _userFYT,
        uint256 _totalFYT
    ) internal virtual returns (uint256);

    /**
     * @notice getter for the address of the future corresponding to this future wallet
     * @return the address of the future
     */
    function getFutureAddress() public view virtual returns (address) {
        return address(future);
    }

    /**
     * @notice getter for the address of the IBT corresponding to this future wallet
     * @return the address of the IBT
     */
    function getIBTAddress() public view virtual returns (address) {
        return address(ibt);
    }
}

