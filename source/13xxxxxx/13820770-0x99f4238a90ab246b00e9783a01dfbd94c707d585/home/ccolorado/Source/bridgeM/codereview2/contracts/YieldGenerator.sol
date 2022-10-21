// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IContractsRegistry.sol";
import "./interfaces/IYieldGenerator.sol";
import "./interfaces/IDefiProtocol.sol";
import "./interfaces/ICapitalPool.sol";

import "./abstract/AbstractDependant.sol";

import "./Globals.sol";

contract YieldGenerator is IYieldGenerator, OwnableUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public constant DEPOSIT_SAFETY_MARGIN = 15 * 10**24; //1.5
    uint256 public constant PROTOCOLS_NUMBER = 3;

    ERC20 public stblToken;
    ICapitalPool public capitalPool;

    uint256 public totalDeposit;
    uint256 public whitelistedProtocols;

    // index => defi protocol
    mapping(uint256 => DefiProtocol) internal defiProtocols;
    // index => defi protocol addresses
    mapping(uint256 => address) internal defiProtocolsAddresses;
    // available protcols to deposit/withdraw (weighted and threshold is true)
    uint256[] internal availableProtocols;
    // selected protocols for multiple deposit/withdraw
    uint256[] internal _selectedProtocols;

    event DefiDeposited(
        uint256 indexed protocolIndex,
        uint256 amount,
        uint256 depositedPercentage
    );
    event DefiWithdrawn(uint256 indexed protocolIndex, uint256 amount, uint256 withdrawPercentage);

    modifier onlyCapitalPool() {
        require(_msgSender() == address(capitalPool), "YG: Not a capital pool contract");
        _;
    }

    modifier updateDefiProtocols(bool isDeposit) {
        _updateDefiProtocols(isDeposit);
        _;
    }

    function __YieldGenerator_init() external initializer {
        __Ownable_init();
        whitelistedProtocols = 3;
        // setup AAVE
        defiProtocols[uint256(DefiProtocols.AAVE)].targetAllocation = 45 * PRECISION;
        defiProtocols[uint256(DefiProtocols.AAVE)].whiteListed = true;
        defiProtocols[uint256(DefiProtocols.AAVE)].threshold = true;
        // setup Compound
        defiProtocols[uint256(DefiProtocols.COMPOUND)].targetAllocation = 45 * PRECISION;
        defiProtocols[uint256(DefiProtocols.COMPOUND)].whiteListed = true;
        defiProtocols[uint256(DefiProtocols.COMPOUND)].threshold = true;
        // setup Yearn
        defiProtocols[uint256(DefiProtocols.YEARN)].targetAllocation = 10 * PRECISION;
        defiProtocols[uint256(DefiProtocols.YEARN)].whiteListed = true;
        defiProtocols[uint256(DefiProtocols.YEARN)].threshold = true;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stblToken = ERC20(_contractsRegistry.getUSDTContract());
        capitalPool = ICapitalPool(_contractsRegistry.getCapitalPoolContract());
        defiProtocolsAddresses[uint256(DefiProtocols.AAVE)] = _contractsRegistry
            .getAaveProtocolContract();
        defiProtocolsAddresses[uint256(DefiProtocols.COMPOUND)] = _contractsRegistry
            .getCompoundProtocolContract();
        defiProtocolsAddresses[uint256(DefiProtocols.YEARN)] = _contractsRegistry
            .getYearnProtocolContract();
    }

    /// @notice deposit stable coin into multiple defi protocols using formulas, access: capital pool
    /// @param amount uint256 the amount of stable coin to deposit
    function deposit(uint256 amount) external override onlyCapitalPool returns (uint256) {
        if (amount == 0 && _getCurrentvSTBLVolume() == 0) return 0;
        return _aggregateDepositWithdrawFunction(amount, true);
    }

    /// @notice withdraw stable coin from mulitple defi protocols using formulas, access: capital pool
    /// @param amount uint256 the amount of stable coin to withdraw
    function withdraw(uint256 amount) external override onlyCapitalPool returns (uint256) {
        if (amount == 0 && _getCurrentvSTBLVolume() == 0) return 0;
        return _aggregateDepositWithdrawFunction(amount, false);
    }

    /// @notice set the protocol settings for each defi protocol (allocations, whitelisted, threshold), access: owner
    /// @param whitelisted bool[] list of whitelisted values for each protocol
    /// @param allocations uint256[] list of allocations value for each protocol
    /// @param threshold bool[] list of threshold values for each protocol
    function setProtocolSettings(
        bool[] calldata whitelisted,
        uint256[] calldata allocations,
        bool[] calldata threshold
    ) external override onlyOwner {
        require(
            whitelisted.length == PROTOCOLS_NUMBER &&
                allocations.length == PROTOCOLS_NUMBER &&
                threshold.length == PROTOCOLS_NUMBER,
            "YG: Invlaid arr length"
        );

        whitelistedProtocols = 0;
        bool _whiteListed;
        for (uint256 i = 0; i < PROTOCOLS_NUMBER; i++) {
            _whiteListed = whitelisted[i];

            if (_whiteListed) {
                whitelistedProtocols = whitelistedProtocols.add(1);
            }

            defiProtocols[i].targetAllocation = allocations[i];

            defiProtocols[i].whiteListed = _whiteListed;
            defiProtocols[i].threshold = threshold[i];
        }
    }

    /// @notice claim rewards for all defi protocols and send them to reinsurance pool, access: owner
    function claimRewards() external override onlyOwner {
        for (uint256 i = 0; i < PROTOCOLS_NUMBER; i++) {
            IDefiProtocol(defiProtocolsAddresses[i]).claimRewards();
        }
    }

    /// @notice returns defi protocol info by its index
    /// @param index uint256 the index of the defi protocol
    function defiProtocol(uint256 index)
        external
        view
        override
        returns (DefiProtocol memory _defiProtocol)
    {
        _defiProtocol = DefiProtocol(
            defiProtocols[index].targetAllocation,
            _calcProtocolCurrentAllocation(index),
            defiProtocols[index].rebalanceWeight,
            defiProtocols[index].depositedAmount,
            defiProtocols[index].whiteListed,
            defiProtocols[index].threshold,
            defiProtocols[index].withdrawMax,
            IDefiProtocol(defiProtocolsAddresses[index]).totalValue()
        );
    }

    function _aggregateDepositWithdrawFunction(uint256 amount, bool isDeposit)
        internal
        updateDefiProtocols(isDeposit)
        returns (uint256 _actualAmount)
    {
        uint256 _protocolIndex;
        uint256 _protocolsNo = _howManyProtocols(amount, isDeposit);
        if (_protocolsNo == 1) {
            if (availableProtocols.length == 0) {
                return _actualAmount;
            }

            if (isDeposit) {
                _protocolIndex = _getProtocolOfMaxWeight();
                // deposit 100% to this protocol
                _depoist(_protocolIndex, amount, PERCENTAGE_100);
                _actualAmount = amount;
            } else {
                _protocolIndex = _getProtocolOfMinWeight();
                // withdraw 100% from this protocol
                _actualAmount = _withdraw(_protocolIndex, amount, PERCENTAGE_100);
            }
        } else if (_protocolsNo > 1) {
            delete _selectedProtocols;

            uint256 _totalWeight;
            uint256 _depoistedAmount;
            uint256 _protocolRebalanceAllocation;

            for (uint256 i = 0; i < _protocolsNo; i++) {
                if (availableProtocols.length == 0) {
                    break;
                }
                if (isDeposit) {
                    _protocolIndex = _getProtocolOfMaxWeight();
                } else {
                    _protocolIndex = _getProtocolOfMinWeight();
                }
                _totalWeight = _totalWeight.add(defiProtocols[_protocolIndex].rebalanceWeight);
                _selectedProtocols.push(_protocolIndex);
            }

            if (_selectedProtocols.length > 0) {
                for (uint256 i = 0; i < _selectedProtocols.length; i++) {
                    _protocolRebalanceAllocation = _calcRebalanceAllocation(
                        _selectedProtocols[i],
                        _totalWeight
                    );

                    if (isDeposit) {
                        // deposit % allocation to this protocol
                        _depoistedAmount = amount.mul(_protocolRebalanceAllocation).div(
                            PERCENTAGE_100
                        );
                        _depoist(
                            _selectedProtocols[i],
                            _depoistedAmount,
                            _protocolRebalanceAllocation
                        );
                        _actualAmount += _depoistedAmount;
                    } else {
                        _actualAmount += _withdraw(
                            _selectedProtocols[i],
                            amount.mul(_protocolRebalanceAllocation).div(PERCENTAGE_100),
                            _protocolRebalanceAllocation
                        );
                    }
                }
            }
        }
    }

    /// @notice deposit into defi protocols
    /// @param _protocolIndex uint256 the predefined index of the defi protocol
    /// @param _amount uint256 amount of stable coin to deposit
    /// @param _depositedPercentage uint256 the percentage of deposited amount into the protocol
    function _depoist(
        uint256 _protocolIndex,
        uint256 _amount,
        uint256 _depositedPercentage
    ) internal {
        // should approve yield to transfer from the capital pool
        stblToken.safeTransferFrom(_msgSender(), defiProtocolsAddresses[_protocolIndex], _amount);

        IDefiProtocol(defiProtocolsAddresses[_protocolIndex]).deposit(_amount);

        defiProtocols[_protocolIndex].depositedAmount += _amount;

        totalDeposit = totalDeposit.add(_amount);

        emit DefiDeposited(_protocolIndex, _amount, _depositedPercentage);
    }

    /// @notice withdraw from defi protocols
    /// @param _protocolIndex uint256 the predefined index of the defi protocol
    /// @param _amount uint256 amount of stable coin to withdraw
    /// @param _withdrawnPercentage uint256 the percentage of withdrawn amount from the protocol
    function _withdraw(
        uint256 _protocolIndex,
        uint256 _amount,
        uint256 _withdrawnPercentage
    ) internal returns (uint256) {
        uint256 _actualAmountWithdrawn;
        uint256 allocatedFunds = defiProtocols[_protocolIndex].depositedAmount;

        if (allocatedFunds == 0) return _actualAmountWithdrawn;

        if (allocatedFunds < _amount) {
            _amount = allocatedFunds;
        }

        _actualAmountWithdrawn = IDefiProtocol(defiProtocolsAddresses[_protocolIndex]).withdraw(
            _amount
        );

        defiProtocols[_protocolIndex].depositedAmount -= _actualAmountWithdrawn;

        totalDeposit = totalDeposit.sub(_actualAmountWithdrawn);

        emit DefiWithdrawn(_protocolIndex, _actualAmountWithdrawn, _withdrawnPercentage);

        return _actualAmountWithdrawn;
    }

    /// @notice get the number of protocols need to rebalance
    /// @param rebalanceAmount uint256 the amount of stable coin will depsoit or withdraw
    function _howManyProtocols(uint256 rebalanceAmount, bool isDeposit)
        internal
        view
        returns (uint256)
    {
        uint256 _no1;
        if (isDeposit) {
            _no1 = whitelistedProtocols.mul(rebalanceAmount);
        } else {
            _no1 = PROTOCOLS_NUMBER.mul(rebalanceAmount);
        }

        uint256 _no2 = _getCurrentvSTBLVolume();

        return _no1.add(_no2 - 1).div(_no2);
        //return _no1.div(_no2).add(_no1.mod(_no2) == 0 ? 0 : 1);
    }

    /// @notice update defi protocols rebalance weight and threshold status
    /// @param isDeposit bool determine the rebalance is for deposit or withdraw
    function _updateDefiProtocols(bool isDeposit) internal {
        delete availableProtocols;

        for (uint256 i = 0; i < PROTOCOLS_NUMBER; i++) {
            uint256 _targetAllocation = defiProtocols[i].targetAllocation;
            uint256 _currentAllocation = _calcProtocolCurrentAllocation(i);
            uint256 _diffAllocation;

            if (isDeposit) {
                if (_targetAllocation > _currentAllocation) {
                    // max weight
                    _diffAllocation = _targetAllocation.sub(_currentAllocation);
                } else if (_currentAllocation >= _targetAllocation) {
                    _diffAllocation = 0;
                }
            } else {
                if (_currentAllocation > _targetAllocation) {
                    // max weight
                    _diffAllocation = _currentAllocation.sub(_targetAllocation);
                    defiProtocols[i].withdrawMax = true;
                } else if (_targetAllocation >= _currentAllocation) {
                    // min weight
                    _diffAllocation = _targetAllocation.sub(_currentAllocation);
                    defiProtocols[i].withdrawMax = false;
                }
            }

            // update rebalance weight
            defiProtocols[i].rebalanceWeight = _diffAllocation.mul(_getCurrentvSTBLVolume()).div(
                PERCENTAGE_100
            );

            if (
                defiProtocols[i].rebalanceWeight > 0 &&
                (
                    isDeposit
                        ? defiProtocols[i].whiteListed && defiProtocols[i].threshold
                        : _currentAllocation > 0
                )
            ) {
                availableProtocols.push(i);
            }
        }
    }

    /// @notice get the defi protocol has max weight to deposit
    /// @dev only select the positive weight from largest to smallest
    function _getProtocolOfMaxWeight() internal returns (uint256) {
        uint256 _largest;
        uint256 _protocolIndex;
        uint256 _indexToDelete;

        for (uint256 i = 0; i < availableProtocols.length; i++) {
            if (defiProtocols[availableProtocols[i]].rebalanceWeight > _largest) {
                _largest = defiProtocols[availableProtocols[i]].rebalanceWeight;
                _protocolIndex = availableProtocols[i];
                _indexToDelete = i;
            }
        }

        availableProtocols[_indexToDelete] = availableProtocols[availableProtocols.length - 1];
        availableProtocols.pop();

        return _protocolIndex;
    }

    /// @notice get the defi protocol has min weight to deposit
    /// @dev only select the negative weight from smallest to largest
    function _getProtocolOfMinWeight() internal returns (uint256) {
        uint256 _maxWeight;
        for (uint256 i = 0; i < availableProtocols.length; i++) {
            if (defiProtocols[availableProtocols[i]].rebalanceWeight > _maxWeight) {
                _maxWeight = defiProtocols[availableProtocols[i]].rebalanceWeight;
            }
        }

        uint256 _smallest = _maxWeight;
        uint256 _largest;
        uint256 _maxProtocolIndex;
        uint256 _maxIndexToDelete;
        uint256 _minProtocolIndex;
        uint256 _minIndexToDelete;

        for (uint256 i = 0; i < availableProtocols.length; i++) {
            if (
                defiProtocols[availableProtocols[i]].rebalanceWeight <= _smallest &&
                !defiProtocols[availableProtocols[i]].withdrawMax
            ) {
                _smallest = defiProtocols[availableProtocols[i]].rebalanceWeight;
                _minProtocolIndex = availableProtocols[i];
                _minIndexToDelete = i;
            } else if (
                defiProtocols[availableProtocols[i]].rebalanceWeight > _largest &&
                defiProtocols[availableProtocols[i]].withdrawMax
            ) {
                _largest = defiProtocols[availableProtocols[i]].rebalanceWeight;
                _maxProtocolIndex = availableProtocols[i];
                _maxIndexToDelete = i;
            }
        }
        if (_largest > 0) {
            availableProtocols[_maxIndexToDelete] = availableProtocols[
                availableProtocols.length - 1
            ];
            availableProtocols.pop();
            return _maxProtocolIndex;
        } else {
            availableProtocols[_minIndexToDelete] = availableProtocols[
                availableProtocols.length - 1
            ];
            availableProtocols.pop();
            return _minProtocolIndex;
        }
    }

    /// @notice calc the current allocation of defi protocol against current vstable volume
    /// @param _protocolIndex uint256 the predefined index of defi protocol
    function _calcProtocolCurrentAllocation(uint256 _protocolIndex)
        internal
        view
        returns (uint256 _currentAllocation)
    {
        uint256 _depositedAmount = defiProtocols[_protocolIndex].depositedAmount;
        uint256 _currentvSTBLVolume = _getCurrentvSTBLVolume();
        if (_currentvSTBLVolume > 0) {
            _currentAllocation = _depositedAmount.mul(PERCENTAGE_100).div(_currentvSTBLVolume);
        }
    }

    /// @notice calc the rebelance allocation % for one protocol for deposit/withdraw
    /// @param _protocolIndex uint256 the predefined index of defi protocol
    /// @param _totalWeight uint256 sum of rebelance weight for all protocols which avaiable for deposit/withdraw
    function _calcRebalanceAllocation(uint256 _protocolIndex, uint256 _totalWeight)
        internal
        view
        returns (uint256)
    {
        return defiProtocols[_protocolIndex].rebalanceWeight.mul(PERCENTAGE_100).div(_totalWeight);
    }

    function _getCurrentvSTBLVolume() internal view returns (uint256) {
        return capitalPool.virtualUsdtAccumulatedBalance();
    }
}

