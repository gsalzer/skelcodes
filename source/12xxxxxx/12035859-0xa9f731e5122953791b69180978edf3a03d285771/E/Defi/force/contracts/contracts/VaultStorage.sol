pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

contract VaultStorage is Initializable {
    bytes32 internal constant _STRATEGY_SLOT =
        0xf1a169aa0f736c2813818fdfbdc5755c31e0839c8f49831a16543496b28574ea;
    bytes32 internal constant _UNDERLYING_SLOT =
        0x1994607607e11d53306ef62e45e3bd85762c58d9bf38b5578bc4a258a26a7371;
    bytes32 internal constant _UNDERLYING_UNIT_SLOT =
        0xa66bc57d4b4eed7c7687876ca77997588987307cb13ecc23f5e52725192e5fff;
    bytes32 internal constant _VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT =
        0x39122c9adfb653455d0c05043bd52fcfbc2be864e832efd3abc72ce5a3d7ed5a;
    bytes32 internal constant _VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT =
        0x469a3bad2fab7b936c45eecd1f5da52af89cead3e2ed7f732b6f3fc92ed32308;
    bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT =
        0xb1acf527cd7cd1668b30e5a9a1c0d845714604de29ce560150922c9d8c0937df;
    bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT =
        0x3bc747f4b148b37be485de3223c90b4468252967d2ea7f9fcbd8b6e653f434c9;
    bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT =
        0x82ddc3be3f0c1a6870327f78f4979a0b37b21b16736ef5be6a7a7a35e530bcf0;
    bytes32 internal constant _STRATEGY_TIME_LOCK_SLOT =
        0x6d02338b2e4c913c0f7d380e2798409838a48a2c4d57d52742a808c82d713d8b;
    bytes32 internal constant _FUTURE_STRATEGY_SLOT =
        0xb441b53a4e42c2ca9182bc7ede99bedba7a5d9360d9dfbd31fa8ee2dc8590610;
    bytes32 internal constant _STRATEGY_UPDATE_TIME_SLOT =
        0x56e7c0e75875c6497f0de657009613a32558904b5c10771a825cc330feff7e72;
    bytes32 internal constant _WITHDRAW_FEE =
        0x3405c96d34f8f0e36eac648034ca7e687437f795bbdbdc2cb7db90a89d519f57;
    bytes32 internal constant _TOTAL_DEPOSITS =
        0xaf765835ed5af0d235b6c686724ad31fa90e06b3daf1c074d6cc398b8fcef213;
    bytes32 internal constant _MAX_DEPOSIT_CAP =
        0x0df75d4bdb87be8e3e04e1dc08ec1c98ed6c4147138e5789f0bd448c5c8e1e28;

    constructor() public {
        assert(
            _STRATEGY_SLOT ==
                bytes32(uint256(keccak256("eip1967.vaultStorage.strategy")) - 1)
        );
        assert(
            _UNDERLYING_SLOT ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.underlying")) - 1
                )
        );
        assert(
            _UNDERLYING_UNIT_SLOT ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.underlyingUnit")) -
                        1
                )
        );
        assert(
            _VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.vaultStorage.vaultFractionToInvestNumerator"
                        )
                    ) - 1
                )
        );
        assert(
            _VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.vaultStorage.vaultFractionToInvestDenominator"
                        )
                    ) - 1
                )
        );
        assert(
            _NEXT_IMPLEMENTATION_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.vaultStorage.nextImplementation")
                    ) - 1
                )
        );
        assert(
            _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.vaultStorage.nextImplementationTimestamp"
                        )
                    ) - 1
                )
        );
        assert(
            _NEXT_IMPLEMENTATION_DELAY_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.vaultStorage.nextImplementationDelay"
                        )
                    ) - 1
                )
        );
        assert(
            _STRATEGY_TIME_LOCK_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.vaultStorage.strategyTimeLock")
                    ) - 1
                )
        );
        assert(
            _FUTURE_STRATEGY_SLOT ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.futureStrategy")) -
                        1
                )
        );
        assert(
            _STRATEGY_UPDATE_TIME_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.vaultStorage.strategyUpdateTime")
                    ) - 1
                )
        );
        assert(
            _WITHDRAW_FEE ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.withdrawFee")) - 1
                )
        );
        assert(
            _TOTAL_DEPOSITS ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.totalDeposits")) - 1
                )
        );
        assert(
            _MAX_DEPOSIT_CAP ==
                bytes32(
                    uint256(keccak256("eip1967.vaultStorage.maxDepositCap")) - 1
                )
        );
    }

    function initialize(
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator,
        uint256 _underlyingUnit,
        uint256 _withdrawFee_,
        uint256 _maxDepositCap_,
        uint256 _implementationChangeDelay,
        uint256 _strategyChangeDelay
    ) public initializer {
        _setUnderlying(_underlying);
        _setVaultFractionToInvestNumerator(_toInvestNumerator);
        _setVaultFractionToInvestDenominator(_toInvestDenominator);
        _setWithdrawFee(_withdrawFee_);
        _setMaxDepositCap(_maxDepositCap_);
        _setUnderlyingUnit(_underlyingUnit);
        _setNextImplementationDelay(_implementationChangeDelay);
        _setStrategyTimeLock(_strategyChangeDelay);
        _setStrategyUpdateTime(0);
        _setFutureStrategy(address(0));
    }

    function _setStrategy(address _address) internal {
        setAddress(_STRATEGY_SLOT, _address);
    }

    function _strategy() internal view returns (address) {
        return getAddress(_STRATEGY_SLOT);
    }

    function _setUnderlying(address _address) internal {
        setAddress(_UNDERLYING_SLOT, _address);
    }

    function _underlying() internal view returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    function _setUnderlyingUnit(uint256 _value) internal {
        setUint256(_UNDERLYING_UNIT_SLOT, _value);
    }

    function _underlyingUnit() internal view returns (uint256) {
        return getUint256(_UNDERLYING_UNIT_SLOT);
    }

    function _setVaultFractionToInvestNumerator(uint256 _value) internal {
        setUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT, _value);
    }

    function _vaultFractionToInvestNumerator() internal view returns (uint256) {
        return getUint256(_VAULT_FRACTION_TO_INVEST_NUMERATOR_SLOT);
    }

    function _setVaultFractionToInvestDenominator(uint256 _value) internal {
        setUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT, _value);
    }

    function _vaultFractionToInvestDenominator()
        internal
        view
        returns (uint256)
    {
        return getUint256(_VAULT_FRACTION_TO_INVEST_DENOMINATOR_SLOT);
    }

    function _setWithdrawFee(uint256 _value) internal {
        setUint256(_WITHDRAW_FEE, _value);
    }

    function _withdrawFee() internal view returns (uint256) {
        return getUint256(_WITHDRAW_FEE);
    }

    function _setTotalDeposits(uint256 _value) internal {
        setUint256(_TOTAL_DEPOSITS, _value);
    }

    function _totalDeposits() internal view returns (uint256) {
        return getUint256(_TOTAL_DEPOSITS);
    }

    function _setMaxDepositCap(uint256 _value) internal {
        setUint256(_MAX_DEPOSIT_CAP, _value);
    }

    function _maxDepositCap() internal view returns (uint256) {
        return getUint256(_MAX_DEPOSIT_CAP);
    }

    function _setNextImplementation(address _address) internal {
        setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
    }

    function _nextImplementation() internal view returns (address) {
        return getAddress(_NEXT_IMPLEMENTATION_SLOT);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
    }

    function _nextImplementationTimestamp() internal view returns (uint256) {
        return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
    }

    function _setNextImplementationDelay(uint256 _value) internal {
        setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
    }

    function _nextImplementationDelay() internal view returns (uint256) {
        return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
    }

    function _setStrategyTimeLock(uint256 _value) internal {
        setUint256(_STRATEGY_TIME_LOCK_SLOT, _value);
    }

    function _strategyTimeLock() internal view returns (uint256) {
        return getUint256(_STRATEGY_TIME_LOCK_SLOT);
    }

    function _setFutureStrategy(address _value) internal {
        setAddress(_FUTURE_STRATEGY_SLOT, _value);
    }

    function _futureStrategy() internal view returns (address) {
        return getAddress(_FUTURE_STRATEGY_SLOT);
    }

    function _setStrategyUpdateTime(uint256 _value) internal {
        setUint256(_STRATEGY_UPDATE_TIME_SLOT, _value);
    }

    function _strategyUpdateTime() internal view returns (uint256) {
        return getUint256(_STRATEGY_UPDATE_TIME_SLOT);
    }

    function setAddress(bytes32 slot, address _address) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setUint256(bytes32 slot, uint256 _value) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function getAddress(bytes32 slot) private view returns (address str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function getUint256(bytes32 slot) private view returns (uint256 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    uint256[50] private ______gap;
}

