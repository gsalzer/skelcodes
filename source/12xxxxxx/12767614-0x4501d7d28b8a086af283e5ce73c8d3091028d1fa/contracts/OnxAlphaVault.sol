pragma solidity 0.7.3;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interface/IStrategy.sol";
import "./interface/IVault.sol";
import "./interface/IController.sol";
import "./interface/IUpgradeSource.sol";
import "./ControllableInit.sol";
import "./VaultStorage.sol";

contract OnxAlphaVault is ERC20Upgradeable, IVault, IUpgradeSource, ControllableInit, VaultStorage {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event Withdraw(address indexed beneficiary, uint256 amount);
  event Deposit(address indexed beneficiary, uint256 amount);
  event Invest(uint256 amount);

  constructor() public {}

  function initializeVault(
    address _storage,
    address _underlying
  ) public initializer {
    __ERC20_init(
      string(abi.encodePacked("alpha_", ERC20Upgradeable(_underlying).symbol())),
      string(abi.encodePacked("alpha", ERC20Upgradeable(_underlying).symbol()))
    );
    _setupDecimals(ERC20Upgradeable(_underlying).decimals());

    ControllableInit.initialize(
      _storage
    );

    uint256 underlyingUnit = 10 ** uint256(ERC20Upgradeable(address(_underlying)).decimals());
    uint256 implementationDelay = 12 hours;
    uint256 strategyChangeDelay = 12 hours;
    VaultStorage.initialize(
      _underlying,
      underlyingUnit,
      implementationDelay,
      strategyChangeDelay
    );
  }

  function strategy() public view override returns(address) {
    return _strategy();
  }

  function underlying() public view override returns(address) {
    return _underlying();
  }

  function underlyingUnit() public view returns(uint256) {
    return _underlyingUnit();
  }

  function nextImplementation() public view returns(address) {
    return _nextImplementation();
  }

  function nextImplementationTimestamp() public view returns(uint256) {
    return _nextImplementationTimestamp();
  }

  function nextImplementationDelay() public view returns(uint256) {
    return _nextImplementationDelay();
  }

  modifier whenStrategyDefined() {
    require(address(strategy()) != address(0), "undefined strategy");
    _;
  }

  function setStrategy(address _strategy) public override onlyControllerOrGovernance {
    require(_strategy != address(0), "empty strategy");
    require(IStrategy(_strategy).underlying() == address(underlying()), "underlying not match");
    require(IStrategy(_strategy).vault() == address(this), "strategy vault not match");

    _setStrategy(_strategy);
    IERC20Upgradeable(underlying()).safeApprove(address(strategy()), 0);
    IERC20Upgradeable(underlying()).safeApprove(address(strategy()), uint256(~0));
  }

  // Only smart contracts will be affected by this modifier
  modifier defense() {
    require(
      (msg.sender == tx.origin) ||                // If it is a normal user and not smart contract,
                                                  // then the requirement will pass
      !IController(controller()).greyList(msg.sender), // If it is a smart contract, then
      "grey listed"  // make sure that it is not on our greyList.
    );
    _;
  }

  function stakeOnsenFarm() whenStrategyDefined onlyControllerOrGovernance external override {
    invest();
    IStrategy(strategy()).stakeOnsenFarm();
  }

  function stakeSushiBar() whenStrategyDefined onlyControllerOrGovernance external override {
    IStrategy(strategy()).stakeSushiBar();
  }

  function stakeOnxFarm() whenStrategyDefined onlyControllerOrGovernance external override {
    IStrategy(strategy()).stakeOnxFarm();
  }

  function stakeOnx() whenStrategyDefined onlyControllerOrGovernance external override {
    IStrategy(strategy()).stakeOnx();
  }

  function withdrawPendingTeamFund() whenStrategyDefined onlyControllerOrGovernance external override {
    IStrategy(strategy()).withdrawPendingTeamFund();
  }

  function withdrawPendingTreasuryFund() whenStrategyDefined onlyControllerOrGovernance external override {
    IStrategy(strategy()).withdrawPendingTreasuryFund();
  }
  
  function underlyingBalanceInVault() view public override returns (uint256) {
    return IERC20Upgradeable(underlying()).balanceOf(address(this));
  }
  
  function underlyingBalanceWithInvestment() view public override returns (uint256) {
    if (address(strategy()) == address(0)) {
      // initial state, when not set
      return underlyingBalanceInVault();
    }
    return underlyingBalanceInVault().add(IStrategy(strategy()).investedUnderlyingBalance());
  }

  function underlyingBalanceWithInvestmentForHolder(address holder) view external override returns (uint256) {
    if (totalSupply() == 0) {
      return 0;
    }
    return underlyingBalanceWithInvestment()
        .mul(balanceOf(holder))
        .div(totalSupply());
  }
  
  function rebalance() external onlyControllerOrGovernance {
    withdrawAll();
    invest();
  }
  
  function invest() internal whenStrategyDefined {
    uint256 availableAmount = underlyingBalanceInVault();
    if (availableAmount > 0) {
      IERC20Upgradeable(underlying()).safeTransfer(address(strategy()), availableAmount);
      emit Invest(availableAmount);
    }
  }
  
  function deposit(uint256 amount) external override defense {
    _deposit(amount, msg.sender, msg.sender);
  }
  
  function depositFor(uint256 amount, address holder) public override defense {
    _deposit(amount, msg.sender, holder);
  }

  function withdrawAll() public onlyControllerOrGovernance override whenStrategyDefined {
    IStrategy(strategy()).withdrawAllToVault();
  }

  function withdraw(uint256 numberOfShares) override external {
    require(totalSupply() > 0, "no shares");
    require(numberOfShares > 0, "numberOfShares zero");
    
    IStrategy(strategy()).updateAccPerShare(msg.sender);
    IStrategy(strategy()).withdrawReward(msg.sender);

    uint256 totalSupply = totalSupply();
    _burn(msg.sender, numberOfShares);

    uint256 underlyingAmountToWithdraw = underlyingBalanceWithInvestment()
        .mul(numberOfShares)
        .div(totalSupply);
    if (underlyingAmountToWithdraw > underlyingBalanceInVault()) {
      // withdraw everything from the strategy to accurately check the share value
      if (numberOfShares == totalSupply) {
        IStrategy(strategy()).withdrawAllToVault();
      } else {
        uint256 missing = underlyingAmountToWithdraw.sub(underlyingBalanceInVault());
        IStrategy(strategy()).withdrawToVault(missing);
      }
      // recalculate to improve accuracy
      underlyingAmountToWithdraw = MathUpgradeable.min(underlyingBalanceWithInvestment()
          .mul(numberOfShares)
          .div(totalSupply), underlyingBalanceInVault());
    }

    IERC20Upgradeable(underlying()).safeTransfer(msg.sender, underlyingAmountToWithdraw);

    // update the withdrawal amount for the holder
    emit Withdraw(msg.sender, underlyingAmountToWithdraw);
  }

  function _deposit(uint256 amount, address sender, address beneficiary) internal {
    require(amount > 0, "deposit 0");
    require(beneficiary != address(0), "holder undefined");
    
    IStrategy(strategy()).updateAccPerShare(beneficiary);
    IStrategy(strategy()).withdrawReward(beneficiary);

    uint256 toMint = totalSupply() == 0
        ? amount
        : amount.mul(totalSupply()).div(underlyingBalanceWithInvestment());
    _mint(beneficiary, toMint);

    IERC20Upgradeable(underlying()).safeTransferFrom(sender, address(this), amount);

    // update the contribution amount for the beneficiary
    emit Deposit(beneficiary, amount);
  }

  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }
  
  function shouldUpgrade() external view override returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  function finalizeUpgrade() external override onlyGovernance {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }
}

