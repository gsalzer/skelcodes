// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/AMMLib.sol";
import "./PriceOracle.sol";
import "./OptionVault.sol";
import "./interfaces/IOptionVault.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IAMM.sol";

/**
 * @notice AMM contract is Automated Market Maker for option contracts.
 * It manages LP(Liquidity provider) tokens and liquidity to write options.
 */
contract AMM is IAMM, ERC1155, Ownable, IERC1155Receiver, ReentrancyGuard {
    using AMMLib for AMMLib.PoolInfo;
    using AMMLib for mapping(uint32 => AMMLib.Tick);
    using AMMLib for AMMLib.Tick;

    /// @dev pool info
    AMMLib.PoolInfo poolInfo;

    /// @dev price oracle contract
    PriceOracle priceOracle;

    /// @dev fee pool contract
    IFeePool public override feePool;

    /// @dev operator address
    address operator;

    /// @dev bot address
    address bot;

    /// @dev emergency mode or not
    bool isEmergencyMode;

    /// @dev nobody can provide liquidity after depositAllowedUntil timestamp
    uint256 depositAllowedUntil;

    /// @dev lp address => rangeId => amount of reservation
    mapping(address => mapping(uint256 => AMMLib.Reservation)) public reservations;

    /// @dev last provided timestamp of liquidity
    mapping(address => uint256) public lastProvidedAt;

    /// @dev lockup period for liquidity withdrawal
    uint256 lockupPeriod = 2 weeks;

    mapping(address => bool) addressesAllowedSkippingLockup;

    // events
    event Deposited(address indexed account, address asset, uint256 rangeId, uint128 amount, uint128 mint);
    event Withdrawn(address indexed account, address asset, uint256 rangeId, uint128 amount, uint128 burn);
    event OptionBought(uint256 seriesId, address indexed buyer, uint128 amount, uint128 premium);
    event OptionSold(uint256 seriesId, address indexed seller, uint128 amount, uint128 premium);
    event Settled(uint256 indexed _expiryId, uint128 protocolFee);
    event EmergencyStateChanged(bool isEmergencyMode);
    event ConfigUpdated(uint8 key, uint128 value);
    event DepositAllowedUntilUpdated(uint256 depositAllowedUntil);
    event LockupPeriodUpdated(uint256 period);

    modifier onlyOperator() {
        require(msg.sender == operator, "AMM: caller must be operator");
        _;
    }

    modifier onlyBot() {
        require(msg.sender == bot, "AMM: caller must be bot");
        _;
    }

    modifier isDepositAllowed() {
        require(block.timestamp < depositAllowedUntil, "AMM: deposit not allowed");
        _;
    }

    modifier notEmergencyMode() {
        require(!isEmergencyMode, "AMM: emergency mode");
        _;
    }

    constructor(
        string memory _uri,
        address _aggregator,
        address _collateral,
        address _priceOracle,
        address _feeRecipient,
        address _operator,
        address _optionContract
    ) ERC1155(_uri) {
        operator = _operator;
        bot = _operator;

        priceOracle = PriceOracle(_priceOracle);

        feePool = IFeePool(_feeRecipient);

        depositAllowedUntil = 2**256 - 1;

        poolInfo.init(_aggregator, _collateral, _optionContract);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes memory data
    ) external override(IERC1155Receiver) returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) external override(IERC1155Receiver) returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function _beforeTokenTransfer(
        address _operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._beforeTokenTransfer(_operator, from, to, ids, amounts, data);

        if (!addressesAllowedSkippingLockup[_operator]) {
            // LPs can't transfer LP tokens before lockupPeriod
            require(lastProvidedAt[from] + lockupPeriod <= block.timestamp, "AMM: liquidity is locked up");
        }
    }

    /**
     * @notice deposit collateral asset to pool
     * price of LP token is '(balance - lockedPremium) / supply'
     * @param _mintAmount amount of write token to mint.
     *   it must be muptiples of _tickEnd - _tickStart.
     * @param _maxDeposit max deposit collateral amount scaled by 1e6
     * @param _tickStart lower tick
     * @param _tickEnd upper tick
     */
    function deposit(
        uint128 _mintAmount,
        uint128 _maxDeposit,
        uint32 _tickStart,
        uint32 _tickEnd
    ) external notEmergencyMode isDepositAllowed nonReentrant {
        // validate inputs
        AMMLib.validateRange(_tickStart, _tickEnd);

        // mint LP tokens
        uint128 amountDeposited = poolInfo.addBalance(_tickStart, _tickEnd, _mintAmount);
        require(amountDeposited > 0, "AMM: amount is too small");
        require(amountDeposited <= _maxDeposit, "AMM: amount deposited is greater than max");
        uint128 rangeId = genRangeId(_tickStart, _tickEnd);

        // receive collateral from LP
        IERC20(poolInfo.collateral).transferFrom(msg.sender, address(this), amountDeposited);

        // mint LP tokens
        _mint(msg.sender, rangeId, _mintAmount, "");

        lastProvidedAt[msg.sender] = block.timestamp;

        //emit event
        emit Deposited(msg.sender, poolInfo.collateral, rangeId, amountDeposited, _mintAmount);
    }

    /**
     * @notice reserve withdrawal.
     * LPs can make reservation for withdrawal.
     * withdrawable timestamp is last expiry of live option serieses.
     * The AMM sets aside funds for withdrawals at each maturity.
     * @param _reserveAmount amount of LP token
     * @param _rangeId range id represents lower tick to upper tick
     */
    function reserveWithdrawal(uint128 _reserveAmount, uint128 _rangeId) external {
        // validate inputs
        require(_reserveAmount > 0, "AMM: amount is too small");

        (uint32 tickStart, uint32 tickEnd) = getRange(_rangeId);
        AMMLib.validateRange(tickStart, tickEnd);
        AMMLib.Reservation storage reservation = reservations[msg.sender][_rangeId];

        require(balanceOf(msg.sender, _rangeId) >= _reserveAmount + reservation.burn, "AMM: amount is too large");

        // get the last expiry
        uint128 withdrawableTimestamp = poolInfo.optionVault.getLastExpiry();

        poolInfo.reserveWithdrawal(tickStart, tickEnd, _reserveAmount);

        if (reservation.burn > 0) {
            reservation.burn += _reserveAmount;
            reservation.withdrawableTimestamp = withdrawableTimestamp;
        } else {
            reservations[msg.sender][_rangeId] = AMMLib.Reservation(_reserveAmount, withdrawableTimestamp);
        }
    }

    /**
     * @notice withdraw collateral asset from pool
     * withdrawable amount is calculated by the following formula.
     * amount = (burn amount) * (pool quote value) / supply
     * However, if available amount is less than the withdrawable amount,
     * LP need to make reservation in advance.
     * LPs should specify minimum withdrawable amount as _minWithdrawal
     * @param _burnAmount amount of write token to burn.
     * @param _minWithdrawal minimal withdraw collateral amount scaled by 1e6
     * @param _rangeId range id represents lower tick to upper tick
     * @param _useReservation use reservation or not
     */
    function withdraw(
        uint128 _burnAmount,
        uint128 _minWithdrawal,
        uint128 _rangeId,
        bool _useReservation
    ) external notEmergencyMode nonReentrant {
        // validate inputs
        (uint32 tickStart, uint32 tickEnd) = getRange(_rangeId);
        AMMLib.Reservation memory reservation = reservations[msg.sender][_rangeId];

        AMMLib.validateRange(tickStart, tickEnd);

        require(balanceOf(msg.sender, _rangeId) >= _burnAmount, "AMM: msg.sender doesn't have enough LP tokens");

        // burn LP tokens
        uint128 withdrawnAmount;

        if (_useReservation) {
            require(_burnAmount <= reservation.burn, "AMM: burnAmount must be reserved");

            require(block.timestamp > reservation.withdrawableTimestamp, "AMM: withdrawable period must have passed");

            withdrawnAmount = poolInfo.removeBalanceFromReservation(tickStart, tickEnd, _burnAmount);

            reservations[msg.sender][_rangeId].burn -= _burnAmount;
        } else {
            require(reservation.burn == 0, "AMM: reservation must not be exists");

            withdrawnAmount = poolInfo.removeBalance(tickStart, tickEnd, _burnAmount);
        }

        require(withdrawnAmount > 0, "AMM: amount is too small");

        _burn(msg.sender, _rangeId, _burnAmount);

        // send collateral to LP
        require(withdrawnAmount >= _minWithdrawal, "AMM: _burnAmount is too small");
        IERC20(poolInfo.collateral).transfer(msg.sender, withdrawnAmount);

        //emit event
        emit Withdrawn(msg.sender, poolInfo.collateral, _rangeId, withdrawnAmount, _burnAmount);
    }

    /**
     * @notice calculate option premium
     * @param _seriesId option series id
     * @param _size option size scaled by 1e8
     */
    function calculatePremium(
        uint256 _seriesId,
        uint128 _size,
        bool _isSelling
    ) external view returns (uint128) {
        require(_size > 0, "AMM: size must not be 0");

        uint128 spot = getPrice();

        return poolInfo.calculatePremium(_seriesId, _size, spot, _isSelling);
    }

    /**
     * @notice send premium and receive options
     * @param _seriesId option series id
     * @param _amount amount to buy scaled by 1e8
     * @param _maxFee max total amount of premium to pay
     */
    function buy(
        uint256 _seriesId,
        uint128 _amount,
        uint128 _maxFee
    ) external notEmergencyMode nonReentrant {
        require(_amount > 0, "AMM: amount must not be 0");

        uint128 spot = getPrice();

        uint128 premium = poolInfo.buy(_seriesId, _amount, spot, msg.sender);
        require(premium <= _maxFee, "AMM: total fee exceeds maxFeeAmount");

        // receive premium from trader
        IERC20(poolInfo.collateral).transferFrom(msg.sender, address(this), premium);

        emit OptionBought(_seriesId, msg.sender, _amount, premium);
    }

    /**
     * @notice send options and receive premium
     * @param _seriesId option series id
     * @param _amount amount to sell scaled by 1e8
     * @param _minFee minimal premium to receive
     */
    function sell(
        uint256 _seriesId,
        uint128 _amount,
        uint128 _minFee
    ) external override notEmergencyMode nonReentrant returns (uint128) {
        require(_amount > 0, "AMM: amount must not be 0");

        require(
            ERC1155(address(poolInfo.optionVault)).balanceOf(msg.sender, _seriesId) >= _amount,
            "AMM: msg.sender doesn't have enough amount"
        );

        ERC1155(address(poolInfo.optionVault)).safeTransferFrom(msg.sender, address(this), _seriesId, _amount, "");

        uint128 spot = getPrice();

        uint128 premium = poolInfo.sell(_seriesId, _amount, spot, msg.sender);

        require(premium >= _minFee, "AMM: premium is too low");

        // send premium to trader from pool
        IERC20(poolInfo.collateral).transfer(msg.sender, premium);

        // emit event
        emit OptionSold(_seriesId, msg.sender, _amount, premium);

        return premium;
    }

    ////////////////////////
    // Operator Functions //
    ////////////////////////

    /**
     * @notice settle option serieses of an expiration
     * settle vaults for pool's short positions and unlock collaterals.
     * claim profit of pool's long positions.
     * @param _expiryId expiration id
     */
    function settle(uint256 _expiryId) external onlyBot {
        uint128 protocolFee = poolInfo.settle(_expiryId);

        if (protocolFee > 0) {
            // send protocolFee to fee recipient
            IERC20(poolInfo.collateral).approve(address(feePool), protocolFee);
            feePool.sendProfitERC20(address(this), protocolFee);
        }

        emit Settled(_expiryId, protocolFee);
    }

    /**
     * @notice rebalance collateral for a tick
     * withdraw collaterals from the vault if there are extra collaterals.
     * Only the operator can call this function.
     * @param _tickId tick id
     * @param _expiryId expiry id
     */
    function rebalanceCollateral(uint32 _tickId, uint256 _expiryId) external onlyOperator {
        poolInfo.rebalanceCollateral(_tickId, _expiryId);
    }

    /**
     * @notice set or unset emergency mode
     * @param _isEmergencyMode if true, set emergency mode.
     *  if false unset emergency mode.
     */
    function changeState(bool _isEmergencyMode) external onlyOperator {
        isEmergencyMode = _isEmergencyMode;

        emit EmergencyStateChanged(_isEmergencyMode);
    }

    /**
     * @notice set depositAllowedUntil parameter
     * @param _depositAllowedUntil no one can provide liquidity after this timestamp
     */
    function setDepositAllowedUntil(uint256 _depositAllowedUntil) external onlyOperator {
        depositAllowedUntil = _depositAllowedUntil;

        emit DepositAllowedUntilUpdated(_depositAllowedUntil);
    }

    /**
     * @notice set lockup period
     * @param _lockupPeriod depositor cannot withdraw during lockup period
     */
    function setLockupPeriod(uint256 _lockupPeriod) external onlyOperator {
        lockupPeriod = _lockupPeriod;

        emit LockupPeriodUpdated(_lockupPeriod);
    }

    function setAddressAllowedSkippingLockup(address _address, bool _isAllowed) external onlyOperator {
        addressesAllowedSkippingLockup[_address] = _isAllowed;
    }

    /**
     * @notice update a config value
     */
    function setConfig(uint8 _key, uint128 _value) external onlyOperator {
        poolInfo.configs[_key] = _value;

        // emit event
        emit ConfigUpdated(_key, _value);
    }

    /**
     * @notice set bot address
     * @param _bot bot address
     */
    function setBot(address _bot) external onlyOperator {
        bot = _bot;
    }

    /**
     * @notice set new fee recipient
     * @param _feeRecipient fee recipient
     */
    function setFeeRecipient(address _feeRecipient) external onlyOperator {
        feePool = IFeePool(_feeRecipient);
    }

    /**
     * @notice set new operator
     * @param _operator operator address
     */
    function setNewOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    //////////////////////
    // Getter Functions //
    //////////////////////

    /**
     * @notice get mint amount of LP token
     * @param _depositAmount amount of collateral to deposit scaled by 1e6
     * @param _tickStart lower tick
     * @param _tickEnd upper tick
     */
    function getMintAmount(
        uint128 _depositAmount,
        uint32 _tickStart,
        uint32 _tickEnd
    ) external view returns (uint128) {
        return poolInfo.getMintAmount(_tickStart, _tickEnd, _depositAmount);
    }

    /**
     * @notice get withdrawable amount of collateral scaled by 1e6
     * @param _burnAmount LP token to burn
     * @param _tickStart lower tick
     * @param _tickEnd upper tick
     */
    function getWithdrawableAmount(
        uint128 _burnAmount,
        uint32 _tickStart,
        uint32 _tickEnd
    ) external view returns (uint128) {
        return poolInfo.getWithdrawableAmount(_tickStart, _tickEnd, _burnAmount);
    }

    /**
     * @notice get tick list
     * @param _tickStart lower tick
     * @param _tickEnd upper tick
     * @return tick list
     */
    function getTicks(uint32 _tickStart, uint32 _tickEnd) public view returns (AMMLib.Tick[] memory) {
        AMMLib.validateRange(_tickStart, _tickEnd);
        AMMLib.Tick[] memory _ticks = new AMMLib.Tick[](_tickEnd - _tickStart);
        for (uint32 i = _tickStart; i < _tickEnd; i++) {
            _ticks[i - _tickStart] = poolInfo.ticks[i];
        }
        return _ticks;
    }

    function getSeriesState(uint32 _tickId, uint256 _seriesId)
        public
        view
        returns (AMMLib.LockedOptionStatePerTick memory, bool exists)
    {
        return AMMLib.getLockedOptionStatePerTick(poolInfo, _seriesId, _tickId);
    }

    function getProfitState(uint32 _tickId, uint256 _expiryId) public view returns (AMMLib.Profit memory) {
        return poolInfo.profits[_expiryId][_tickId];
    }

    /**
     * @notice get tick cumulative of earning seconds per liquidity
     */
    function getSecondsPerLiquidity(uint32 _tickLower, uint32 _tickUpper) external view returns (uint128) {
        AMMLib.validateRange(_tickLower, _tickUpper);
        return poolInfo.ticks.getSecondsPerLiquidity(_tickLower, _tickUpper);
    }

    function getLockupPeriod() external view returns (uint256) {
        return lockupPeriod;
    }

    /**
     * @notice get a config value
     */
    function getConfig(uint8 _key) external view returns (uint128) {
        return poolInfo.configs[_key];
    }

    function genRangeId(uint32 _tickStart, uint32 _tickEnd) public pure returns (uint128) {
        return _tickStart + 1e2 * _tickEnd;
    }

    function getRange(uint128 _rangeId) public pure returns (uint32 _start, uint32 _end) {
        _start = uint32(_rangeId % 1e2);
        _end = uint32(_rangeId / 1e2);
    }

    function getPrice() internal view returns (uint128) {
        (uint256 spot, ) = priceOracle.getPrice(poolInfo.aggregator);
        return uint128(spot);
    }
}

