pragma solidity >=0.4.25 <0.6.0;
pragma experimental ABIEncoderV2;


interface BalanceRecordable {
    
    function balanceRecordsCount(address account)
    external
    view
    returns (uint256);

    
    function recordBalance(address account, uint256 index)
    external
    view
    returns (uint256);

    
    function recordBlockNumber(address account, uint256 index)
    external
    view
    returns (uint256);

    
    function recordIndexByBlockNumber(address account, uint256 blockNumber)
    external
    view
    returns (int256);
}

library SafeMathUintLib {
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        
        uint256 c = a / b;
        
        return c;
    }

    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    
    
    
    function clamp(uint256 a, uint256 min, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : ((a < min) ? min : a);
    }

    function clampMin(uint256 a, uint256 min)
    public
    pure
    returns (uint256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(uint256 a, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : a;
    }
}

contract BalanceAucCalculator {
    using SafeMathUintLib for uint256;

    
    
    
    
    
    
    
    
    
    
    function calculate(BalanceRecordable balanceRecordable, address wallet, uint256 startBlock, uint256 endBlock)
    public
    view
    returns (uint256)
    {
        
        if (endBlock < startBlock)
            return 0;

        
        uint256 recordsCount = balanceRecordable.balanceRecordsCount(wallet);

        
        if (0 == recordsCount)
            return 0;

        
        int256 _endIndex = balanceRecordable.recordIndexByBlockNumber(wallet, endBlock);

        
        if (0 > _endIndex)
            return 0;

        
        uint256 endIndex = uint256(_endIndex);

        
        
        startBlock = startBlock.clampMin(balanceRecordable.recordBlockNumber(wallet, 0));

        
        uint256 startIndex = uint256(balanceRecordable.recordIndexByBlockNumber(wallet, startBlock));

        
        uint256 result = 0;

        
        if (startIndex < endIndex)
            result = result.add(
                balanceRecordable.recordBalance(wallet, startIndex).mul(
                    balanceRecordable.recordBlockNumber(wallet, startIndex.add(1)).sub(startBlock)
                )
            );

        
        for (uint256 i = startIndex.add(1); i < endIndex; i = i.add(1))
            result = result.add(
                balanceRecordable.recordBalance(wallet, i).mul(
                    balanceRecordable.recordBlockNumber(wallet, i.add(1)).sub(
                        balanceRecordable.recordBlockNumber(wallet, i)
                    )
                )
            );

        
        result = result.add(
            balanceRecordable.recordBalance(wallet, endIndex).mul(
                endBlock.sub(
                    balanceRecordable.recordBlockNumber(wallet, endIndex).clampMin(startBlock)
                ).add(1)
            )
        );

        
        return result;
    }
}

library ConstantsLib {
    
    function PARTS_PER()
    public
    pure
    returns (int256)
    {
        return 1e18;
    }
}

contract Modifiable {
    
    
    
    modifier notNullAddress(address _address) {
        require(_address != address(0));
        _;
    }

    modifier notThisAddress(address _address) {
        require(_address != address(this));
        _;
    }

    modifier notNullOrThisAddress(address _address) {
        require(_address != address(0));
        require(_address != address(this));
        _;
    }

    modifier notSameAddresses(address _address1, address _address2) {
        if (_address1 != _address2)
            _;
    }
}

contract SelfDestructible {
    
    
    
    bool public selfDestructionDisabled;

    
    
    
    event SelfDestructionDisabledEvent(address wallet);
    event TriggerSelfDestructionEvent(address wallet);

    
    
    
    
    function destructor()
    public
    view
    returns (address);

    
    
    function disableSelfDestruction()
    public
    {
        
        require(destructor() == msg.sender);

        
        selfDestructionDisabled = true;

        
        emit SelfDestructionDisabledEvent(msg.sender);
    }

    
    function triggerSelfDestruction()
    public
    {
        
        require(destructor() == msg.sender);

        
        require(!selfDestructionDisabled);

        
        emit TriggerSelfDestructionEvent(msg.sender);

        
        selfdestruct(msg.sender);
    }
}

contract Ownable is Modifiable, SelfDestructible {
    
    
    
    address public deployer;
    address public operator;

    
    
    
    event SetDeployerEvent(address oldDeployer, address newDeployer);
    event SetOperatorEvent(address oldOperator, address newOperator);

    
    
    
    constructor(address _deployer) internal notNullOrThisAddress(_deployer) {
        deployer = _deployer;
        operator = _deployer;
    }

    
    
    
    
    function destructor()
    public
    view
    returns (address)
    {
        return deployer;
    }

    
    
    function setDeployer(address newDeployer)
    public
    onlyDeployer
    notNullOrThisAddress(newDeployer)
    {
        if (newDeployer != deployer) {
            
            address oldDeployer = deployer;
            deployer = newDeployer;

            
            emit SetDeployerEvent(oldDeployer, newDeployer);
        }
    }

    
    
    function setOperator(address newOperator)
    public
    onlyOperator
    notNullOrThisAddress(newOperator)
    {
        if (newOperator != operator) {
            
            address oldOperator = operator;
            operator = newOperator;

            
            emit SetOperatorEvent(oldOperator, newOperator);
        }
    }

    
    
    function isDeployer()
    internal
    view
    returns (bool)
    {
        return msg.sender == deployer;
    }

    
    
    function isOperator()
    internal
    view
    returns (bool)
    {
        return msg.sender == operator;
    }

    
    
    
    function isDeployerOrOperator()
    internal
    view
    returns (bool)
    {
        return isDeployer() || isOperator();
    }

    
    
    modifier onlyDeployer() {
        require(isDeployer());
        _;
    }

    modifier notDeployer() {
        require(!isDeployer());
        _;
    }

    modifier onlyOperator() {
        require(isOperator());
        _;
    }

    modifier notOperator() {
        require(!isOperator());
        _;
    }

    modifier onlyDeployerOrOperator() {
        require(isDeployerOrOperator());
        _;
    }

    modifier notDeployerOrOperator() {
        require(!isDeployerOrOperator());
        _;
    }
}

contract Beneficiary {
    
    
    
    function receiveEthersTo(address wallet, string memory balanceType)
    public
    payable;

    
    
    
    
    
    
    
    
    function receiveTokensTo(address wallet, string memory balanceType, int256 amount, address currencyCt,
        uint256 currencyId, string memory standard)
    public;
}

library MonetaryTypesLib {
    
    
    
    struct Currency {
        address ct;
        uint256 id;
    }

    struct Figure {
        int256 amount;
        Currency currency;
    }

    struct NoncedAmount {
        uint256 nonce;
        int256 amount;
    }
}

contract AccrualBeneficiary is Beneficiary {
    
    
    
    event CloseAccrualPeriodEvent();

    
    
    
    function closeAccrualPeriod(MonetaryTypesLib.Currency[] memory)
    public
    {
        emit CloseAccrualPeriodEvent();
    }
}

contract Benefactor is Ownable {
    
    
    
    Beneficiary[] public beneficiaries;
    mapping(address => uint256) public beneficiaryIndexByAddress;

    
    
    
    event RegisterBeneficiaryEvent(Beneficiary beneficiary);
    event DeregisterBeneficiaryEvent(Beneficiary beneficiary);

    
    
    
    
    
    function registerBeneficiary(Beneficiary beneficiary)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        address _beneficiary = address(beneficiary);

        if (beneficiaryIndexByAddress[_beneficiary] > 0)
            return false;

        beneficiaries.push(beneficiary);
        beneficiaryIndexByAddress[_beneficiary] = beneficiaries.length;

        
        emit RegisterBeneficiaryEvent(beneficiary);

        return true;
    }

    
    
    function deregisterBeneficiary(Beneficiary beneficiary)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        address _beneficiary = address(beneficiary);

        if (beneficiaryIndexByAddress[_beneficiary] == 0)
            return false;

        uint256 idx = beneficiaryIndexByAddress[_beneficiary] - 1;
        if (idx < beneficiaries.length - 1) {
            
            beneficiaries[idx] = beneficiaries[beneficiaries.length - 1];
            beneficiaryIndexByAddress[address(beneficiaries[idx])] = idx + 1;
        }
        beneficiaries.length--;
        beneficiaryIndexByAddress[_beneficiary] = 0;

        
        emit DeregisterBeneficiaryEvent(beneficiary);

        return true;
    }

    
    
    
    function isRegisteredBeneficiary(Beneficiary beneficiary)
    public
    view
    returns (bool)
    {
        return beneficiaryIndexByAddress[address(beneficiary)] > 0;
    }

    
    
    function registeredBeneficiariesCount()
    public
    view
    returns (uint256)
    {
        return beneficiaries.length;
    }
}

library SafeMathIntLib {
    int256 constant INT256_MIN = int256((uint256(1) << 255));
    int256 constant INT256_MAX = int256(~((uint256(1) << 255)));

    
    
    
    function div(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a != INT256_MIN || b != - 1);
        return a / b;
    }

    function mul(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a != - 1 || b != INT256_MIN);
        
        require(b != - 1 || a != INT256_MIN);
        
        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }

    function sub(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
        return a - b;
    }

    function add(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    
    
    
    function div_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b > 0);
        return a / b;
    }

    function mul_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b >= 0);
        int256 c = a * b;
        require(a == 0 || c / a == b);
        require(c >= 0);
        return c;
    }

    function sub_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b >= 0 && b <= a);
        return a - b;
    }

    function add_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b >= 0);
        int256 c = a + b;
        require(c >= a);
        return c;
    }

    
    
    
    function abs(int256 a)
    public
    pure
    returns (int256)
    {
        return a < 0 ? neg(a) : a;
    }

    function neg(int256 a)
    public
    pure
    returns (int256)
    {
        return mul(a, - 1);
    }

    function toNonZeroInt256(uint256 a)
    public
    pure
    returns (int256)
    {
        require(a > 0 && a < (uint256(1) << 255));
        return int256(a);
    }

    function toInt256(uint256 a)
    public
    pure
    returns (int256)
    {
        require(a >= 0 && a < (uint256(1) << 255));
        return int256(a);
    }

    function toUInt256(int256 a)
    public
    pure
    returns (uint256)
    {
        require(a >= 0);
        return uint256(a);
    }

    function isNonZeroPositiveInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a > 0);
    }

    function isPositiveInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a >= 0);
    }

    function isNonZeroNegativeInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a < 0);
    }

    function isNegativeInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a <= 0);
    }

    
    
    
    function clamp(int256 a, int256 min, int256 max)
    public
    pure
    returns (int256)
    {
        if (a < min)
            return min;
        return (a > max) ? max : a;
    }

    function clampMin(int256 a, int256 min)
    public
    pure
    returns (int256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(int256 a, int256 max)
    public
    pure
    returns (int256)
    {
        return (a > max) ? max : a;
    }
}

contract AccrualBenefactor is Benefactor {
    using SafeMathIntLib for int256;

    
    
    
    mapping(address => int256) private _beneficiaryFractionMap;
    int256 public totalBeneficiaryFraction;

    
    
    
    event RegisterAccrualBeneficiaryEvent(Beneficiary beneficiary, int256 fraction);
    event DeregisterAccrualBeneficiaryEvent(Beneficiary beneficiary);

    
    
    
    
    
    function registerBeneficiary(Beneficiary beneficiary)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        return registerFractionalBeneficiary(AccrualBeneficiary(address(beneficiary)), ConstantsLib.PARTS_PER());
    }

    
    
    
    function registerFractionalBeneficiary(AccrualBeneficiary beneficiary, int256 fraction)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        require(fraction > 0, "Fraction not strictly positive [AccrualBenefactor.sol:59]");
        require(
            totalBeneficiaryFraction.add(fraction) <= ConstantsLib.PARTS_PER(),
            "Total beneficiary fraction out of bounds [AccrualBenefactor.sol:60]"
        );

        if (!super.registerBeneficiary(beneficiary))
            return false;

        _beneficiaryFractionMap[address(beneficiary)] = fraction;
        totalBeneficiaryFraction = totalBeneficiaryFraction.add(fraction);

        
        emit RegisterAccrualBeneficiaryEvent(beneficiary, fraction);

        return true;
    }

    
    
    function deregisterBeneficiary(Beneficiary beneficiary)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        if (!super.deregisterBeneficiary(beneficiary))
            return false;

        address _beneficiary = address(beneficiary);

        totalBeneficiaryFraction = totalBeneficiaryFraction.sub(_beneficiaryFractionMap[_beneficiary]);
        _beneficiaryFractionMap[_beneficiary] = 0;

        
        emit DeregisterAccrualBeneficiaryEvent(beneficiary);

        return true;
    }

    
    
    
    function beneficiaryFraction(AccrualBeneficiary beneficiary)
    public
    view
    returns (int256)
    {
        return _beneficiaryFractionMap[address(beneficiary)];
    }
}

contract TransferController {
    
    
    
    event CurrencyTransferred(address from, address to, uint256 value,
        address currencyCt, uint256 currencyId);

    
    
    
    function isFungible()
    public
    view
    returns (bool);

    function standard()
    public
    view
    returns (string memory);

    
    function receive(address from, address to, uint256 value, address currencyCt, uint256 currencyId)
    public;

    
    function approve(address to, uint256 value, address currencyCt, uint256 currencyId)
    public;

    
    function dispatch(address from, address to, uint256 value, address currencyCt, uint256 currencyId)
    public;

    

    function getReceiveSignature()
    public
    pure
    returns (bytes4)
    {
        return bytes4(keccak256("receive(address,address,uint256,address,uint256)"));
    }

    function getApproveSignature()
    public
    pure
    returns (bytes4)
    {
        return bytes4(keccak256("approve(address,uint256,address,uint256)"));
    }

    function getDispatchSignature()
    public
    pure
    returns (bytes4)
    {
        return bytes4(keccak256("dispatch(address,address,uint256,address,uint256)"));
    }
}

contract TransferControllerManager is Ownable {
    
    
    
    struct CurrencyInfo {
        bytes32 standard;
        bool blacklisted;
    }

    
    
    
    mapping(bytes32 => address) public registeredTransferControllers;
    mapping(address => CurrencyInfo) public registeredCurrencies;

    
    
    
    event RegisterTransferControllerEvent(string standard, address controller);
    event ReassociateTransferControllerEvent(string oldStandard, string newStandard, address controller);

    event RegisterCurrencyEvent(address currencyCt, string standard);
    event DeregisterCurrencyEvent(address currencyCt);
    event BlacklistCurrencyEvent(address currencyCt);
    event WhitelistCurrencyEvent(address currencyCt);

    
    
    
    constructor(address deployer) Ownable(deployer) public {
    }

    
    
    
    function registerTransferController(string calldata standard, address controller)
    external
    onlyDeployer
    notNullAddress(controller)
    {
        require(bytes(standard).length > 0, "Empty standard not supported [TransferControllerManager.sol:58]");
        bytes32 standardHash = keccak256(abi.encodePacked(standard));

        registeredTransferControllers[standardHash] = controller;

        
        emit RegisterTransferControllerEvent(standard, controller);
    }

    function reassociateTransferController(string calldata oldStandard, string calldata newStandard, address controller)
    external
    onlyDeployer
    notNullAddress(controller)
    {
        require(bytes(newStandard).length > 0, "Empty new standard not supported [TransferControllerManager.sol:72]");
        bytes32 oldStandardHash = keccak256(abi.encodePacked(oldStandard));
        bytes32 newStandardHash = keccak256(abi.encodePacked(newStandard));

        require(registeredTransferControllers[oldStandardHash] != address(0), "Old standard not registered [TransferControllerManager.sol:76]");
        require(registeredTransferControllers[newStandardHash] == address(0), "New standard previously registered [TransferControllerManager.sol:77]");

        registeredTransferControllers[newStandardHash] = registeredTransferControllers[oldStandardHash];
        registeredTransferControllers[oldStandardHash] = address(0);

        
        emit ReassociateTransferControllerEvent(oldStandard, newStandard, controller);
    }

    function registerCurrency(address currencyCt, string calldata standard)
    external
    onlyOperator
    notNullAddress(currencyCt)
    {
        require(bytes(standard).length > 0, "Empty standard not supported [TransferControllerManager.sol:91]");
        bytes32 standardHash = keccak256(abi.encodePacked(standard));

        require(registeredCurrencies[currencyCt].standard == bytes32(0), "Currency previously registered [TransferControllerManager.sol:94]");

        registeredCurrencies[currencyCt].standard = standardHash;

        
        emit RegisterCurrencyEvent(currencyCt, standard);
    }

    function deregisterCurrency(address currencyCt)
    external
    onlyOperator
    {
        require(registeredCurrencies[currencyCt].standard != 0, "Currency not registered [TransferControllerManager.sol:106]");

        registeredCurrencies[currencyCt].standard = bytes32(0);
        registeredCurrencies[currencyCt].blacklisted = false;

        
        emit DeregisterCurrencyEvent(currencyCt);
    }

    function blacklistCurrency(address currencyCt)
    external
    onlyOperator
    {
        require(registeredCurrencies[currencyCt].standard != bytes32(0), "Currency not registered [TransferControllerManager.sol:119]");

        registeredCurrencies[currencyCt].blacklisted = true;

        
        emit BlacklistCurrencyEvent(currencyCt);
    }

    function whitelistCurrency(address currencyCt)
    external
    onlyOperator
    {
        require(registeredCurrencies[currencyCt].standard != bytes32(0), "Currency not registered [TransferControllerManager.sol:131]");

        registeredCurrencies[currencyCt].blacklisted = false;

        
        emit WhitelistCurrencyEvent(currencyCt);
    }

    
    function transferController(address currencyCt, string memory standard)
    public
    view
    returns (TransferController)
    {
        if (bytes(standard).length > 0) {
            bytes32 standardHash = keccak256(abi.encodePacked(standard));

            require(registeredTransferControllers[standardHash] != address(0), "Standard not registered [TransferControllerManager.sol:150]");
            return TransferController(registeredTransferControllers[standardHash]);
        }

        require(registeredCurrencies[currencyCt].standard != bytes32(0), "Currency not registered [TransferControllerManager.sol:154]");
        require(!registeredCurrencies[currencyCt].blacklisted, "Currency blacklisted [TransferControllerManager.sol:155]");

        address controllerAddress = registeredTransferControllers[registeredCurrencies[currencyCt].standard];
        require(controllerAddress != address(0), "No matching transfer controller [TransferControllerManager.sol:158]");

        return TransferController(controllerAddress);
    }
}

contract TransferControllerManageable is Ownable {
    
    
    
    TransferControllerManager public transferControllerManager;

    
    
    
    event SetTransferControllerManagerEvent(TransferControllerManager oldTransferControllerManager,
        TransferControllerManager newTransferControllerManager);

    
    
    
    
    
    function setTransferControllerManager(TransferControllerManager newTransferControllerManager)
    public
    onlyDeployer
    notNullAddress(address(newTransferControllerManager))
    notSameAddresses(address(newTransferControllerManager), address(transferControllerManager))
    {
        
        TransferControllerManager oldTransferControllerManager = transferControllerManager;
        transferControllerManager = newTransferControllerManager;

        
        emit SetTransferControllerManagerEvent(oldTransferControllerManager, newTransferControllerManager);
    }

    
    function transferController(address currencyCt, string memory standard)
    internal
    view
    returns (TransferController)
    {
        return transferControllerManager.transferController(currencyCt, standard);
    }

    
    
    
    modifier transferControllerManagerInitialized() {
        require(address(transferControllerManager) != address(0), "Transfer controller manager not initialized [TransferControllerManageable.sol:63]");
        _;
    }
}

library CurrenciesLib {
    using SafeMathUintLib for uint256;

    
    
    
    struct Currencies {
        MonetaryTypesLib.Currency[] currencies;
        mapping(address => mapping(uint256 => uint256)) indexByCurrency;
    }

    
    
    
    function add(Currencies storage self, address currencyCt, uint256 currencyId)
    internal
    {
        
        if (0 == self.indexByCurrency[currencyCt][currencyId]) {
            self.currencies.push(MonetaryTypesLib.Currency(currencyCt, currencyId));
            self.indexByCurrency[currencyCt][currencyId] = self.currencies.length;
        }
    }

    function removeByCurrency(Currencies storage self, address currencyCt, uint256 currencyId)
    internal
    {
        
        uint256 index = self.indexByCurrency[currencyCt][currencyId];
        if (0 < index)
            removeByIndex(self, index - 1);
    }

    function removeByIndex(Currencies storage self, uint256 index)
    internal
    {
        require(index < self.currencies.length, "Index out of bounds [CurrenciesLib.sol:51]");

        address currencyCt = self.currencies[index].ct;
        uint256 currencyId = self.currencies[index].id;

        if (index < self.currencies.length - 1) {
            self.currencies[index] = self.currencies[self.currencies.length - 1];
            self.indexByCurrency[self.currencies[index].ct][self.currencies[index].id] = index + 1;
        }
        self.currencies.length--;
        self.indexByCurrency[currencyCt][currencyId] = 0;
    }

    function count(Currencies storage self)
    internal
    view
    returns (uint256)
    {
        return self.currencies.length;
    }

    function has(Currencies storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return 0 != self.indexByCurrency[currencyCt][currencyId];
    }

    function getByIndex(Currencies storage self, uint256 index)
    internal
    view
    returns (MonetaryTypesLib.Currency memory)
    {
        require(index < self.currencies.length, "Index out of bounds [CurrenciesLib.sol:85]");
        return self.currencies[index];
    }

    function getByIndices(Currencies storage self, uint256 low, uint256 up)
    internal
    view
    returns (MonetaryTypesLib.Currency[] memory)
    {
        require(0 < self.currencies.length, "No currencies found [CurrenciesLib.sol:94]");
        require(low <= up, "Bounds parameters mismatch [CurrenciesLib.sol:95]");

        up = up.clampMax(self.currencies.length - 1);
        MonetaryTypesLib.Currency[] memory _currencies = new MonetaryTypesLib.Currency[](up - low + 1);
        for (uint256 i = low; i <= up; i++)
            _currencies[i - low] = self.currencies[i];

        return _currencies;
    }
}

library FungibleBalanceLib {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using CurrenciesLib for CurrenciesLib.Currencies;

    
    
    
    struct Record {
        int256 amount;
        uint256 blockNumber;
    }

    struct Balance {
        mapping(address => mapping(uint256 => int256)) amountByCurrency;
        mapping(address => mapping(uint256 => Record[])) recordsByCurrency;

        CurrenciesLib.Currencies inUseCurrencies;
        CurrenciesLib.Currencies everUsedCurrencies;
    }

    
    
    
    function get(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256)
    {
        return self.amountByCurrency[currencyCt][currencyId];
    }

    function getByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (int256)
    {
        (int256 amount,) = recordByBlockNumber(self, currencyCt, currencyId, blockNumber);
        return amount;
    }

    function set(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = amount;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function setByBlockNumber(Balance storage self, int256 amount, address currencyCt, uint256 currencyId,
        uint256 blockNumber)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = amount;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], blockNumber)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function add(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].add(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function addByBlockNumber(Balance storage self, int256 amount, address currencyCt, uint256 currencyId,
        uint256 blockNumber)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].add(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], blockNumber)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function sub(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].sub(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function subByBlockNumber(Balance storage self, int256 amount, address currencyCt, uint256 currencyId,
        uint256 blockNumber)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].sub(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], blockNumber)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function transfer(Balance storage _from, Balance storage _to, int256 amount,
        address currencyCt, uint256 currencyId)
    internal
    {
        sub(_from, amount, currencyCt, currencyId);
        add(_to, amount, currencyCt, currencyId);
    }

    function add_nn(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].add_nn(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function sub_nn(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].sub_nn(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function transfer_nn(Balance storage _from, Balance storage _to, int256 amount,
        address currencyCt, uint256 currencyId)
    internal
    {
        sub_nn(_from, amount, currencyCt, currencyId);
        add_nn(_to, amount, currencyCt, currencyId);
    }

    function recordsCount(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.recordsByCurrency[currencyCt][currencyId].length;
    }

    function recordByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (int256, uint256)
    {
        uint256 index = indexByBlockNumber(self, currencyCt, currencyId, blockNumber);
        return 0 < index ? recordByIndex(self, currencyCt, currencyId, index - 1) : (0, 0);
    }

    function recordByIndex(Balance storage self, address currencyCt, uint256 currencyId, uint256 index)
    internal
    view
    returns (int256, uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (0, 0);

        index = index.clampMax(self.recordsByCurrency[currencyCt][currencyId].length - 1);
        Record storage record = self.recordsByCurrency[currencyCt][currencyId][index];
        return (record.amount, record.blockNumber);
    }

    function lastRecord(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256, uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (0, 0);

        Record storage record = self.recordsByCurrency[currencyCt][currencyId][self.recordsByCurrency[currencyCt][currencyId].length - 1];
        return (record.amount, record.blockNumber);
    }

    function hasInUseCurrency(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return self.inUseCurrencies.has(currencyCt, currencyId);
    }

    function hasEverUsedCurrency(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return self.everUsedCurrencies.has(currencyCt, currencyId);
    }

    function updateCurrencies(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    {
        if (0 == self.amountByCurrency[currencyCt][currencyId] && self.inUseCurrencies.has(currencyCt, currencyId))
            self.inUseCurrencies.removeByCurrency(currencyCt, currencyId);
        else if (!self.inUseCurrencies.has(currencyCt, currencyId)) {
            self.inUseCurrencies.add(currencyCt, currencyId);
            self.everUsedCurrencies.add(currencyCt, currencyId);
        }
    }

    function indexByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return 0;
        for (uint256 i = self.recordsByCurrency[currencyCt][currencyId].length; i > 0; i--)
            if (self.recordsByCurrency[currencyCt][currencyId][i - 1].blockNumber <= blockNumber)
                return i;
        return 0;
    }
}

library TxHistoryLib {
    
    
    
    struct AssetEntry {
        int256 amount;
        uint256 blockNumber;
        address currencyCt;      
        uint256 currencyId;
    }

    struct TxHistory {
        AssetEntry[] deposits;
        mapping(address => mapping(uint256 => AssetEntry[])) currencyDeposits;

        AssetEntry[] withdrawals;
        mapping(address => mapping(uint256 => AssetEntry[])) currencyWithdrawals;
    }

    
    
    
    function addDeposit(TxHistory storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        AssetEntry memory deposit = AssetEntry(amount, block.number, currencyCt, currencyId);
        self.deposits.push(deposit);
        self.currencyDeposits[currencyCt][currencyId].push(deposit);
    }

    function addWithdrawal(TxHistory storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        AssetEntry memory withdrawal = AssetEntry(amount, block.number, currencyCt, currencyId);
        self.withdrawals.push(withdrawal);
        self.currencyWithdrawals[currencyCt][currencyId].push(withdrawal);
    }

    

    function deposit(TxHistory storage self, uint index)
    internal
    view
    returns (int256 amount, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        require(index < self.deposits.length, "Index ouf of bounds [TxHistoryLib.sol:56]");

        amount = self.deposits[index].amount;
        blockNumber = self.deposits[index].blockNumber;
        currencyCt = self.deposits[index].currencyCt;
        currencyId = self.deposits[index].currencyId;
    }

    function depositsCount(TxHistory storage self)
    internal
    view
    returns (uint256)
    {
        return self.deposits.length;
    }

    function currencyDeposit(TxHistory storage self, address currencyCt, uint256 currencyId, uint index)
    internal
    view
    returns (int256 amount, uint256 blockNumber)
    {
        require(index < self.currencyDeposits[currencyCt][currencyId].length, "Index out of bounds [TxHistoryLib.sol:77]");

        amount = self.currencyDeposits[currencyCt][currencyId][index].amount;
        blockNumber = self.currencyDeposits[currencyCt][currencyId][index].blockNumber;
    }

    function currencyDepositsCount(TxHistory storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.currencyDeposits[currencyCt][currencyId].length;
    }

    

    function withdrawal(TxHistory storage self, uint index)
    internal
    view
    returns (int256 amount, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        require(index < self.withdrawals.length, "Index out of bounds [TxHistoryLib.sol:98]");

        amount = self.withdrawals[index].amount;
        blockNumber = self.withdrawals[index].blockNumber;
        currencyCt = self.withdrawals[index].currencyCt;
        currencyId = self.withdrawals[index].currencyId;
    }

    function withdrawalsCount(TxHistory storage self)
    internal
    view
    returns (uint256)
    {
        return self.withdrawals.length;
    }

    function currencyWithdrawal(TxHistory storage self, address currencyCt, uint256 currencyId, uint index)
    internal
    view
    returns (int256 amount, uint256 blockNumber)
    {
        require(index < self.currencyWithdrawals[currencyCt][currencyId].length, "Index out of bounds [TxHistoryLib.sol:119]");

        amount = self.currencyWithdrawals[currencyCt][currencyId][index].amount;
        blockNumber = self.currencyWithdrawals[currencyCt][currencyId][index].blockNumber;
    }

    function currencyWithdrawalsCount(TxHistory storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.currencyWithdrawals[currencyCt][currencyId].length;
    }
}

contract RevenueFund is Ownable, AccrualBeneficiary, AccrualBenefactor, TransferControllerManageable {
    using FungibleBalanceLib for FungibleBalanceLib.Balance;
    using TxHistoryLib for TxHistoryLib.TxHistory;
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using CurrenciesLib for CurrenciesLib.Currencies;

    
    
    
    FungibleBalanceLib.Balance periodAccrual;
    CurrenciesLib.Currencies periodCurrencies;

    FungibleBalanceLib.Balance aggregateAccrual;
    CurrenciesLib.Currencies aggregateCurrencies;

    TxHistoryLib.TxHistory private txHistory;

    
    
    
    event ReceiveEvent(address from, int256 amount, address currencyCt, uint256 currencyId);
    event CloseAccrualPeriodEvent();
    event RegisterServiceEvent(address service);
    event DeregisterServiceEvent(address service);

    
    
    
    constructor(address deployer) Ownable(deployer) public {
    }

    
    
    
    
    function() external payable {
        receiveEthersTo(msg.sender, "");
    }

    
    
    function receiveEthersTo(address wallet, string memory)
    public
    payable
    {
        int256 amount = SafeMathIntLib.toNonZeroInt256(msg.value);

        
        periodAccrual.add(amount, address(0), 0);
        aggregateAccrual.add(amount, address(0), 0);

        
        periodCurrencies.add(address(0), 0);
        aggregateCurrencies.add(address(0), 0);

        
        txHistory.addDeposit(amount, address(0), 0);

        
        emit ReceiveEvent(wallet, amount, address(0), 0);
    }

    
    
    
    
    
    function receiveTokens(string memory balanceType, int256 amount, address currencyCt,
        uint256 currencyId, string memory standard)
    public
    {
        receiveTokensTo(msg.sender, balanceType, amount, currencyCt, currencyId, standard);
    }

    
    
    
    
    
    
    function receiveTokensTo(address wallet, string memory, int256 amount,
        address currencyCt, uint256 currencyId, string memory standard)
    public
    {
        require(amount.isNonZeroPositiveInt256(), "Amount not strictly positive [RevenueFund.sol:115]");

        
        TransferController controller = transferController(currencyCt, standard);
        (bool success,) = address(controller).delegatecall(
            abi.encodeWithSelector(
                controller.getReceiveSignature(), msg.sender, this, uint256(amount), currencyCt, currencyId
            )
        );
        require(success, "Reception by controller failed [RevenueFund.sol:124]");

        
        periodAccrual.add(amount, currencyCt, currencyId);
        aggregateAccrual.add(amount, currencyCt, currencyId);

        
        periodCurrencies.add(currencyCt, currencyId);
        aggregateCurrencies.add(currencyCt, currencyId);

        
        txHistory.addDeposit(amount, currencyCt, currencyId);

        
        emit ReceiveEvent(wallet, amount, currencyCt, currencyId);
    }

    
    
    
    
    function periodAccrualBalance(address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return periodAccrual.get(currencyCt, currencyId);
    }

    
    
    
    
    
    function aggregateAccrualBalance(address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return aggregateAccrual.get(currencyCt, currencyId);
    }

    
    
    function periodCurrenciesCount()
    public
    view
    returns (uint256)
    {
        return periodCurrencies.count();
    }

    
    
    
    
    function periodCurrenciesByIndices(uint256 low, uint256 up)
    public
    view
    returns (MonetaryTypesLib.Currency[] memory)
    {
        return periodCurrencies.getByIndices(low, up);
    }

    
    
    function aggregateCurrenciesCount()
    public
    view
    returns (uint256)
    {
        return aggregateCurrencies.count();
    }

    
    
    
    
    function aggregateCurrenciesByIndices(uint256 low, uint256 up)
    public
    view
    returns (MonetaryTypesLib.Currency[] memory)
    {
        return aggregateCurrencies.getByIndices(low, up);
    }

    
    
    function depositsCount()
    public
    view
    returns (uint256)
    {
        return txHistory.depositsCount();
    }

    
    
    function deposit(uint index)
    public
    view
    returns (int256 amount, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        return txHistory.deposit(index);
    }

    
    
    function closeAccrualPeriod(MonetaryTypesLib.Currency[] memory currencies)
    public
    onlyOperator
    {
        require(
            ConstantsLib.PARTS_PER() == totalBeneficiaryFraction,
            "Total beneficiary fraction out of bounds [RevenueFund.sol:236]"
        );

        
        for (uint256 i = 0; i < currencies.length; i++) {
            MonetaryTypesLib.Currency memory currency = currencies[i];

            int256 remaining = periodAccrual.get(currency.ct, currency.id);

            if (0 >= remaining)
                continue;

            for (uint256 j = 0; j < beneficiaries.length; j++) {
                AccrualBeneficiary beneficiary = AccrualBeneficiary(address(beneficiaries[j]));

                if (beneficiaryFraction(beneficiary) > 0) {
                    int256 transferable = periodAccrual.get(currency.ct, currency.id)
                    .mul(beneficiaryFraction(beneficiary))
                    .div(ConstantsLib.PARTS_PER());

                    if (transferable > remaining)
                        transferable = remaining;

                    if (transferable > 0) {
                        
                        if (currency.ct == address(0))
                            beneficiary.receiveEthersTo.value(uint256(transferable))(address(0), "");

                        
                        else {
                            TransferController controller = transferController(currency.ct, "");
                            (bool success,) = address(controller).delegatecall(
                                abi.encodeWithSelector(
                                    controller.getApproveSignature(), address(beneficiary), uint256(transferable), currency.ct, currency.id
                                )
                            );
                            require(success, "Approval by controller failed [RevenueFund.sol:274]");

                            beneficiary.receiveTokensTo(address(0), "", transferable, currency.ct, currency.id, "");
                        }

                        remaining = remaining.sub(transferable);
                    }
                }
            }

            
            periodAccrual.set(remaining, currency.ct, currency.id);

            
            if (0 == remaining)
                periodCurrencies.removeByCurrency(currency.ct, currency.id);
        }

        
        for (uint256 j = 0; j < beneficiaries.length; j++) {
            AccrualBeneficiary beneficiary = AccrualBeneficiary(address(beneficiaries[j]));

            
            if (0 >= beneficiaryFraction(beneficiary))
                continue;

            
            beneficiary.closeAccrualPeriod(currencies);
        }

        
        emit CloseAccrualPeriodEvent();
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        
        
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
        

        
        
        
        
        
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract TokenMultiTimelock is Ownable {
    using SafeMathUintLib for uint256;
    using SafeERC20 for IERC20;

    
    
    
    struct Release {
        uint256 blockNumber;
        uint256 earliestReleaseTime;
        uint256 amount;
        uint256 totalAmount;
        bool done;
    }

    
    
    
    IERC20 public token;
    address public beneficiary;

    Release[] public releases;
    uint256 public totalReleasedAmount;
    uint256 public totalLockedAmount;
    uint256 public executedReleasesCount;

    
    
    
    event SetTokenEvent(IERC20 token);
    event SetBeneficiaryEvent(address beneficiary);
    event DefineReleaseEvent(uint256 blockNumber, uint256 earliestReleaseTime, uint256 amount,
        uint256 totalAmount, bool done);
    event SetReleaseBlockNumberEvent(uint256 index, uint256 blockNumber);
    event ReleaseEvent(uint256 index, uint256 blockNumber, uint256 earliestReleaseTime,
        uint256 actualReleaseTime, uint256 amount);

    
    
    
    constructor(address deployer)
    Ownable(deployer)
    public
    {
    }

    
    
    
    
    
    function setToken(IERC20 _token)
    public
    onlyOperator
    notNullOrThisAddress(address(_token))
    {
        
        require(address(token) == address(0), "Token previously set [TokenMultiTimelock.sol:79]");

        
        token = _token;

        
        emit SetTokenEvent(token);
    }

    
    
    function setBeneficiary(address _beneficiary)
    public
    onlyOperator
    notNullAddress(_beneficiary)
    {
        
        beneficiary = _beneficiary;

        
        emit SetBeneficiaryEvent(beneficiary);
    }

    
    
    function defineReleases(Release[] memory _releases)
    onlyOperator
    public
    {
        
        require(address(token) != address(0), "Token not initialized [TokenMultiTimelock.sol:109]");

        
        for (uint256 i = 0; i < _releases.length; i++) {
            
            totalLockedAmount += _releases[i].amount;

            
            
            require(token.balanceOf(address(this)) >= totalLockedAmount, "Total locked amount overrun [TokenMultiTimelock.sol:118]");

            
            releases.push(_releases[i]);

            
            emit DefineReleaseEvent(_releases[i].blockNumber, _releases[i].earliestReleaseTime, _releases[i].amount,
                totalLockedAmount, _releases[i].done);
        }
    }

    
    
    function releasesCount()
    public
    view
    returns (uint256)
    {
        return releases.length;
    }

    
    
    
    function setReleaseBlockNumber(uint256 index, uint256 blockNumber)
    public
    onlyBeneficiary
    {
        
        require(!releases[index].done, "Release previously done [TokenMultiTimelock.sol:147]");

        
        releases[index].blockNumber = blockNumber;

        
        emit SetReleaseBlockNumberEvent(index, blockNumber);
    }

    
    
    
    
    function releaseIndexByBlockNumber(uint256 blockNumber)
    public
    view
    returns (int256)
    {
        for (uint256 i = releases.length; i > 0;) {
            i = i.sub(1);
            if (0 < releases[i].blockNumber && releases[i].blockNumber <= blockNumber)
                return int256(i);
        }
        return - 1;
    }

    
    
    function release(uint256 index)
    public
    onlyBeneficiary
    {
        
        Release storage _release = releases[index];

        
        require(0 < _release.amount, "Release amount not strictly positive [TokenMultiTimelock.sol:183]");

        
        require(!_release.done, "Release previously done [TokenMultiTimelock.sol:186]");

        
        require(block.timestamp >= _release.earliestReleaseTime, "Block time stamp less than earliest release time [TokenMultiTimelock.sol:189]");

        
        totalReleasedAmount = totalReleasedAmount.add(_release.amount);

        
        _release.totalAmount = totalReleasedAmount;

        
        _release.done = true;

        
        if (0 == _release.blockNumber)
            _release.blockNumber = block.number;

        
        executedReleasesCount = executedReleasesCount.add(1);

        
        totalLockedAmount = totalLockedAmount.sub(_release.amount);

        
        token.safeTransfer(beneficiary, _release.amount);

        
        emit ReleaseEvent(index, _release.blockNumber, _release.earliestReleaseTime, block.timestamp, _release.amount);
    }

    
    
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Message sender not beneficiary [TokenMultiTimelock.sol:220]");
        _;
    }
}

contract RevenueTokenManager is TokenMultiTimelock, BalanceRecordable {
    using SafeMathUintLib for uint256;

    
    
    
    constructor(address deployer)
    public
    TokenMultiTimelock(deployer)
    {
    }

    
    
    
    
    
    function balanceRecordsCount(address)
    external
    view
    returns (uint256)
    {
        return executedReleasesCount;
    }

    
    
    
    function recordBalance(address, uint256 index)
    external
    view
    returns (uint256)
    {
        return releases[index].totalAmount;
    }

    
    
    
    function recordBlockNumber(address, uint256 index)
    external
    view
    returns (uint256)
    {
        return releases[index].blockNumber;
    }

    
    
    
    
    function recordIndexByBlockNumber(address, uint256 blockNumber)
    external
    view
    returns (int256)
    {
        return releaseIndexByBlockNumber(blockNumber);
    }
}

contract Servable is Ownable {
    
    
    
    struct ServiceInfo {
        bool registered;
        uint256 activationTimestamp;
        mapping(bytes32 => bool) actionsEnabledMap;
        bytes32[] actionsList;
    }

    
    
    
    mapping(address => ServiceInfo) internal registeredServicesMap;
    uint256 public serviceActivationTimeout;

    
    
    
    event ServiceActivationTimeoutEvent(uint256 timeoutInSeconds);
    event RegisterServiceEvent(address service);
    event RegisterServiceDeferredEvent(address service, uint256 timeout);
    event DeregisterServiceEvent(address service);
    event EnableServiceActionEvent(address service, string action);
    event DisableServiceActionEvent(address service, string action);

    
    
    
    
    
    function setServiceActivationTimeout(uint256 timeoutInSeconds)
    public
    onlyDeployer
    {
        serviceActivationTimeout = timeoutInSeconds;

        
        emit ServiceActivationTimeoutEvent(timeoutInSeconds);
    }

    
    
    function registerService(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        _registerService(service, 0);

        
        emit RegisterServiceEvent(service);
    }

    
    
    function registerServiceDeferred(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        _registerService(service, serviceActivationTimeout);

        
        emit RegisterServiceDeferredEvent(service, serviceActivationTimeout);
    }

    
    
    function deregisterService(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        require(registeredServicesMap[service].registered);

        registeredServicesMap[service].registered = false;

        
        emit DeregisterServiceEvent(service);
    }

    
    
    
    function enableServiceAction(address service, string memory action)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        require(registeredServicesMap[service].registered);

        bytes32 actionHash = hashString(action);

        require(!registeredServicesMap[service].actionsEnabledMap[actionHash]);

        registeredServicesMap[service].actionsEnabledMap[actionHash] = true;
        registeredServicesMap[service].actionsList.push(actionHash);

        
        emit EnableServiceActionEvent(service, action);
    }

    
    
    
    function disableServiceAction(address service, string memory action)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        bytes32 actionHash = hashString(action);

        require(registeredServicesMap[service].actionsEnabledMap[actionHash]);

        registeredServicesMap[service].actionsEnabledMap[actionHash] = false;

        
        emit DisableServiceActionEvent(service, action);
    }

    
    
    
    function isRegisteredService(address service)
    public
    view
    returns (bool)
    {
        return registeredServicesMap[service].registered;
    }

    
    
    
    function isRegisteredActiveService(address service)
    public
    view
    returns (bool)
    {
        return isRegisteredService(service) && block.timestamp >= registeredServicesMap[service].activationTimestamp;
    }

    
    
    
    function isEnabledServiceAction(address service, string memory action)
    public
    view
    returns (bool)
    {
        bytes32 actionHash = hashString(action);
        return isRegisteredActiveService(service) && registeredServicesMap[service].actionsEnabledMap[actionHash];
    }

    
    
    
    function hashString(string memory _string)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_string));
    }

    
    
    
    function _registerService(address service, uint256 timeout)
    private
    {
        if (!registeredServicesMap[service].registered) {
            registeredServicesMap[service].registered = true;
            registeredServicesMap[service].activationTimestamp = block.timestamp + timeout;
        }
    }

    
    
    
    modifier onlyActiveService() {
        require(isRegisteredActiveService(msg.sender));
        _;
    }

    modifier onlyEnabledServiceAction(string memory action) {
        require(isEnabledServiceAction(msg.sender, action));
        _;
    }
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

contract ERC20Mintable is ERC20, MinterRole {
    
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

library Math {
    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract TokenUpgradeAgent {

    
    address public origin;

    constructor(address _origin)
    public
    {
        origin = _origin;
    }

    
    
    
    function upgradeFrom(address from, uint256 value)
    public
    returns (bool);

    
    
    
    modifier onlyOrigin() {
        require(msg.sender == origin);
        _;
    }
}

contract RevenueToken is ERC20Mintable, BalanceRecordable {
    using SafeMath for uint256;
    using Math for uint256;

    struct BalanceRecord {
        uint256 blockNumber;
        uint256 balance;
    }

    mapping(address => BalanceRecord[]) public balanceRecords;

    bool public mintingDisabled;

    event DisableMinting();
    event Upgrade(TokenUpgradeAgent tokenUpgradeAgent, address from, uint256 value);
    event UpgradeFrom(TokenUpgradeAgent tokenUpgradeAgent, address upgrader, address from, uint256 value);
    event UpgradeBalanceRecords(address account, uint256 startIndex, uint256 endIndex);

    
    function disableMinting()
    public
    onlyMinter
    {
        
        mintingDisabled = true;

        
        emit DisableMinting();
    }

    
    function mint(address to, uint256 value)
    public
    onlyMinter
    returns (bool)
    {
        
        require(!mintingDisabled, "Minting disabled [RevenueToken.sol:68]");

        
        bool minted = super.mint(to, value);

        
        if (minted)
            _addBalanceRecord(to);

        
        return minted;
    }

    
    function transfer(address to, uint256 value)
    public
    returns (bool)
    {
        
        bool transferred = super.transfer(to, value);

        
        if (transferred) {
            _addBalanceRecord(msg.sender);
            _addBalanceRecord(to);
        }

        
        return transferred;
    }

    
    function approve(address spender, uint256 value)
    public
    returns (bool)
    {
        
        require(
            0 == value || 0 == allowance(msg.sender, spender),
            "Value or allowance non-zero [RevenueToken.sol:117]"
        );

        
        return super.approve(spender, value);
    }

    
    function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
    {
        
        bool transferred = super.transferFrom(from, to, value);

        
        if (transferred) {
            _addBalanceRecord(from);
            _addBalanceRecord(to);
        }

        
        return transferred;
    }

    
    function upgrade(TokenUpgradeAgent tokenUpgradeAgent, uint256 value)
    public
    returns (bool)
    {
        
        _burn(msg.sender, value);

        
        bool upgraded = tokenUpgradeAgent.upgradeFrom(msg.sender, value);

        
        require(upgraded, "Upgrade failed [RevenueToken.sol:168]");

        
        emit Upgrade(tokenUpgradeAgent, msg.sender, value);

        
        return upgraded;
    }

    
    function upgradeFrom(TokenUpgradeAgent tokenUpgradeAgent, address from, uint256 value)
    public
    returns (bool)
    {
        
        _burnFrom(from, value);

        
        bool upgraded = tokenUpgradeAgent.upgradeFrom(from, value);

        
        require(upgraded, "Upgrade failed [RevenueToken.sol:195]");

        
        emit UpgradeFrom(tokenUpgradeAgent, msg.sender, from, value);

        
        return upgraded;
    }

    
    function balanceRecordsCount(address account)
    public
    view
    returns (uint256)
    {
        return balanceRecords[account].length;
    }

    
    function recordBalance(address account, uint256 index)
    public
    view
    returns (uint256)
    {
        return balanceRecords[account][index].balance;
    }

    
    function recordBlockNumber(address account, uint256 index)
    public
    view
    returns (uint256)
    {
        return balanceRecords[account][index].blockNumber;
    }

    
    function recordIndexByBlockNumber(address account, uint256 blockNumber)
    public
    view
    returns (int256)
    {
        for (uint256 i = balanceRecords[account].length; i > 0;) {
            i = i.sub(1);
            if (balanceRecords[account][i].blockNumber <= blockNumber)
                return int256(i);
        }
        return - 1;
    }

    
    function upgradeBalanceRecords(address account, BalanceRecord[] memory _balanceRecords)
    public
    onlyMinter
    {
        
        if (0 < _balanceRecords.length) {
            
            require(!mintingDisabled, "Minting disabled [RevenueToken.sol:280]");

            
            uint256 startIndex = balanceRecords[account].length;
            uint256 endIndex = startIndex.add(_balanceRecords.length).sub(1);

            
            uint256 previousBlockNumber = startIndex > 0 ? balanceRecords[account][startIndex - 1].blockNumber : 0;

            
            for (uint256 i = 0; i < _balanceRecords.length; i++) {
                
                require(previousBlockNumber <= _balanceRecords[i].blockNumber, "Invalid balance record block number [RevenueToken.sol:292]");

                
                balanceRecords[account].push(_balanceRecords[i]);

                
                previousBlockNumber = _balanceRecords[i].blockNumber;
            }

            
            emit UpgradeBalanceRecords(account, startIndex, endIndex);
        }
    }

    
    function _addBalanceRecord(address account)
    private
    {
        balanceRecords[account].push(BalanceRecord(block.number, balanceOf(account)));
    }
}

contract TokenHolderRevenueFund is Ownable, AccrualBeneficiary, Servable, TransferControllerManageable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using FungibleBalanceLib for FungibleBalanceLib.Balance;
    using CurrenciesLib for CurrenciesLib.Currencies;

    
    
    
    string constant public CLOSE_ACCRUAL_PERIOD_ACTION = "close_accrual_period";

    
    
    
    struct Accrual {
        uint256 startBlock;
        uint256 endBlock;
        int256 amount;

        mapping(address => ClaimRecord) claimRecordsByWallet;
    }

    struct ClaimRecord {
        bool completed;
        BlockSpan[] completedSpans;
    }

    struct BlockSpan {
        uint256 startBlock;
        uint256 endBlock;
    }

    
    
    
    RevenueTokenManager public revenueTokenManager;
    BalanceAucCalculator public balanceBlocksCalculator;
    BalanceAucCalculator public releasedAmountBlocksCalculator;

    FungibleBalanceLib.Balance private periodAccrual;
    CurrenciesLib.Currencies private periodCurrencies;

    FungibleBalanceLib.Balance private aggregateAccrual;
    CurrenciesLib.Currencies private aggregateCurrencies;

    mapping(address => mapping(uint256 => Accrual[])) public closedAccrualsByCurrency;

    address[] public nonClaimers;
    mapping(address => uint256) public nonClaimerIndicesByWallet;

    mapping(address => mapping(address => mapping(uint256 => uint256[]))) public claimedAccrualIndicesByWalletCurrency;
    mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => bool)))) public accrualClaimedByWalletCurrencyAccrual;

    mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => uint256)))) public maxClaimedBlockNumberByWalletCurrencyAccrual;
    uint256 public claimBlockNumberBatchSize;

    mapping(address => mapping(uint256 => mapping(uint256 => int256))) public aggregateAccrualAmountByCurrencyBlockNumber;

    mapping(address => FungibleBalanceLib.Balance) private stagedByWallet;

    
    
    
    event SetRevenueTokenManagerEvent(RevenueTokenManager manager);
    event SetBalanceBlocksCalculatorEvent(BalanceAucCalculator calculator);
    event SetReleasedAmountBlocksCalculatorEvent(BalanceAucCalculator calculator);
    event SetClaimBlockNumberBatchSizeEvent(uint256 batchSize);
    event RegisterNonClaimerEvent(address wallet);
    event DeregisterNonClaimerEvent(address wallet);
    event ReceiveEvent(address wallet, int256 amount, address currencyCt,
        uint256 currencyId);
    event WithdrawEvent(address to, int256 amount, address currencyCt, uint256 currencyId);
    event CloseAccrualPeriodEvent(int256 periodAmount, int256 aggregateAmount, address currencyCt,
        uint256 currencyId);
    event ClaimAndTransferToBeneficiaryByAccrualsEvent(address wallet, string balanceType, int256 amount,
        address currencyCt, uint256 currencyId, uint256 startAccrualIndex, uint256 endAccrualIndex,
        string standard);
    event ClaimAndTransferToBeneficiaryByBlockNumbersEvent(address wallet, string balanceType, int256 amount,
        address currencyCt, uint256 currencyId, uint256 startBlock, uint256 endBlock,
        string standard);
    event ClaimAndStageByAccrualsEvent(address from, int256 amount, address currencyCt,
        uint256 currencyId, uint256 startAccrualIndex, uint256 endAccrualIndex);
    event ClaimAndStageByBlockNumbersEvent(address from, int256 amount, address currencyCt,
        uint256 currencyId, uint256 startBlock, uint256 endBlock);
    event WithdrawEvent(address from, int256 amount, address currencyCt, uint256 currencyId,
        string standard);

    
    
    
    constructor(address deployer) Ownable(deployer) public {
    }

    
    
    
    
    
    function setRevenueTokenManager(RevenueTokenManager manager)
    public
    onlyDeployer
    notNullAddress(address(manager))
    {
        
        revenueTokenManager = manager;

        
        emit SetRevenueTokenManagerEvent(manager);
    }

    
    
    function setBalanceBlocksCalculator(BalanceAucCalculator calculator)
    public
    onlyDeployer
    notNullOrThisAddress(address(calculator))
    {
        
        balanceBlocksCalculator = calculator;

        
        emit SetBalanceBlocksCalculatorEvent(balanceBlocksCalculator);
    }

    
    
    function setReleasedAmountBlocksCalculator(BalanceAucCalculator calculator)
    public
    onlyDeployer
    notNullOrThisAddress(address(calculator))
    {
        
        releasedAmountBlocksCalculator = calculator;

        
        emit SetReleasedAmountBlocksCalculatorEvent(releasedAmountBlocksCalculator);
    }

    
    
    
    
    function setClaimBlockNumberBatchSize(uint256 batchSize)
    public
    onlyDeployer
    {
        
        claimBlockNumberBatchSize = batchSize;

        
        emit SetClaimBlockNumberBatchSizeEvent(batchSize);
    }

    
    
    function nonClaimersCount()
    public
    view
    returns (uint256)
    {
        return nonClaimers.length;
    }

    
    
    
    function isNonClaimer(address wallet)
    public
    view
    returns (bool)
    {
        return 0 < nonClaimerIndicesByWallet[wallet];
    }

    
    
    function registerNonClaimer(address wallet)
    public
    onlyDeployer
    notNullAddress(wallet)
    {
        
        if (0 == nonClaimerIndicesByWallet[wallet]) {
            
            nonClaimers.push(wallet);
            nonClaimerIndicesByWallet[wallet] = nonClaimers.length;

            
            emit RegisterNonClaimerEvent(wallet);
        }
    }

    
    
    function deregisterNonClaimer(address wallet)
    public
    onlyDeployer
    notNullAddress(wallet)
    {
        
        if (0 < nonClaimerIndicesByWallet[wallet]) {
            
            if (nonClaimerIndicesByWallet[wallet] < nonClaimers.length) {
                nonClaimers[nonClaimerIndicesByWallet[wallet].sub(1)] = nonClaimers[nonClaimers.length.sub(1)];
                nonClaimerIndicesByWallet[nonClaimers[nonClaimers.length.sub(1)]] = nonClaimerIndicesByWallet[wallet];
            }
            nonClaimers.length--;
            nonClaimerIndicesByWallet[wallet] = 0;

            
            emit DeregisterNonClaimerEvent(wallet);
        }
    }

    
    function() external payable {
        receiveEthersTo(msg.sender, "");
    }

    
    
    function receiveEthersTo(address wallet, string memory)
    public
    payable
    {
        int256 amount = SafeMathIntLib.toNonZeroInt256(msg.value);

        
        periodAccrual.add(amount, address(0), 0);
        aggregateAccrual.add(amount, address(0), 0);

        
        periodCurrencies.add(address(0), 0);
        aggregateCurrencies.add(address(0), 0);

        
        emit ReceiveEvent(wallet, amount, address(0), 0);
    }

    
    
    
    
    
    function receiveTokens(string memory, int256 amount, address currencyCt, uint256 currencyId,
        string memory standard)
    public
    {
        receiveTokensTo(msg.sender, "", amount, currencyCt, currencyId, standard);
    }

    
    
    
    
    
    
    function receiveTokensTo(address wallet, string memory, int256 amount, address currencyCt,
        uint256 currencyId, string memory standard)
    public
    {
        require(amount.isNonZeroPositiveInt256(), "Amount not strictly positive [TokenHolderRevenueFund.sol:293]");

        
        TransferController controller = transferController(currencyCt, standard);
        (bool success,) = address(controller).delegatecall(
            abi.encodeWithSelector(
                controller.getReceiveSignature(), msg.sender, this, uint256(amount), currencyCt, currencyId
            )
        );
        require(success, "Reception by controller failed [TokenHolderRevenueFund.sol:302]");

        
        periodAccrual.add(amount, currencyCt, currencyId);
        aggregateAccrual.add(amount, currencyCt, currencyId);

        
        periodCurrencies.add(currencyCt, currencyId);
        aggregateCurrencies.add(currencyCt, currencyId);

        
        emit ReceiveEvent(wallet, amount, currencyCt, currencyId);
    }

    
    
    
    
    function periodAccrualBalance(address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return periodAccrual.get(currencyCt, currencyId);
    }

    
    
    
    
    
    function aggregateAccrualBalance(address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return aggregateAccrual.get(currencyCt, currencyId);
    }

    
    
    function periodCurrenciesCount()
    public
    view
    returns (uint256)
    {
        return periodCurrencies.count();
    }

    
    
    
    
    function periodCurrenciesByIndices(uint256 low, uint256 up)
    public
    view
    returns (MonetaryTypesLib.Currency[] memory)
    {
        return periodCurrencies.getByIndices(low, up);
    }

    
    
    function aggregateCurrenciesCount()
    public
    view
    returns (uint256)
    {
        return aggregateCurrencies.count();
    }

    
    
    
    
    function aggregateCurrenciesByIndices(uint256 low, uint256 up)
    public
    view
    returns (MonetaryTypesLib.Currency[] memory)
    {
        return aggregateCurrencies.getByIndices(low, up);
    }

    
    
    
    
    
    function stagedBalance(address wallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return stagedByWallet[wallet].get(currencyCt, currencyId);
    }

    
    
    
    
    function closedAccrualsCount(address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return closedAccrualsByCurrency[currencyCt][currencyId].length;
    }

    
    
    function closeAccrualPeriod(MonetaryTypesLib.Currency[] memory currencies)
    public
    onlyEnabledServiceAction(CLOSE_ACCRUAL_PERIOD_ACTION)
    {
        
        for (uint256 i = 0; i < currencies.length; i = i.add(1)) {
            MonetaryTypesLib.Currency memory currency = currencies[i];

            
            int256 periodAmount = periodAccrual.get(currency.ct, currency.id);

            
            uint256 startBlock = (
            0 == closedAccrualsByCurrency[currency.ct][currency.id].length ?
            0 :
            closedAccrualsByCurrency[currency.ct][currency.id][closedAccrualsByCurrency[currency.ct][currency.id].length - 1].endBlock + 1
            );

            
            closedAccrualsByCurrency[currency.ct][currency.id].push(Accrual(startBlock, block.number, periodAmount));

            
            aggregateAccrualAmountByCurrencyBlockNumber[currency.ct][currency.id][block.number] = aggregateAccrualBalance(
                currency.ct, currency.id
            );

            if (periodAmount > 0) {
                
                periodAccrual.set(0, currency.ct, currency.id);

                
                periodCurrencies.removeByCurrency(currency.ct, currency.id);
            }

            
            emit CloseAccrualPeriodEvent(
                periodAmount,
                aggregateAccrualAmountByCurrencyBlockNumber[currency.ct][currency.id][block.number],
                currency.ct, currency.id
            );
        }
    }

    
    
    
    
    
    function closedAccrualIndexByBlockNumber(address currencyCt, uint256 currencyId, uint256 blockNumber)
    public
    view
    returns (uint256)
    {
        for (uint256 i = closedAccrualsByCurrency[currencyCt][currencyId].length; i > 0;) {
            i = i.sub(1);
            if (closedAccrualsByCurrency[currencyCt][currencyId][i].startBlock <= blockNumber)
                return i;
        }
        return 0;
    }

    
    
    
    
    
    
    
    
    function claimableAmountByAccruals(address wallet, address currencyCt, uint256 currencyId,
        uint256 startAccrualIndex, uint256 endAccrualIndex)
    public
    view
    returns (int256)
    {
        
        if (isNonClaimer(wallet))
            return 0;

        
        if (0 == closedAccrualsByCurrency[currencyCt][currencyId].length)
            return 0;

        
        require(startAccrualIndex <= endAccrualIndex, "Accrual index ordinality mismatch [TokenHolderRevenueFund.sol:496]");

        
        int256 claimableAmount = 0;

        
        for (
            uint256 i = startAccrualIndex;
            i <= endAccrualIndex && i < closedAccrualsByCurrency[currencyCt][currencyId].length;
            i = i.add(1)
        ) {
            
            claimableAmount = claimableAmount.add(
                _claimableAmount(wallet, closedAccrualsByCurrency[currencyCt][currencyId][i])
            );
        }

        
        return claimableAmount;
    }

    
    
    
    
    
    
    
    
    function claimableAmountByBlockNumbers(address wallet, address currencyCt, uint256 currencyId,
        uint256 startBlock, uint256 endBlock)
    public
    view
    returns (int256)
    {
        
        if (isNonClaimer(wallet))
            return 0;

        
        if (0 == closedAccrualsByCurrency[currencyCt][currencyId].length)
            return 0;

        
        require(startBlock <= endBlock, "Block number ordinality mismatch [TokenHolderRevenueFund.sol:540]");

        
        uint256 startAccrualIndex = closedAccrualIndexByBlockNumber(currencyCt, currencyId, startBlock);
        uint256 endAccrualIndex = closedAccrualIndexByBlockNumber(currencyCt, currencyId, endBlock);

        
        Accrual storage endAccrual = closedAccrualsByCurrency[currencyCt][currencyId][endAccrualIndex];

        
        if (endBlock < endAccrual.startBlock)
            return 0;

        
        int256 claimableAmount = 0;

        
        if (startAccrualIndex < endAccrualIndex) {
            
            Accrual storage startAccrual = closedAccrualsByCurrency[currencyCt][currencyId][startAccrualIndex];

            
            claimableAmount = _claimableAmount(
                wallet, startAccrual,
                startBlock.clampMin(startAccrual.startBlock),
                endBlock.clampMax(startAccrual.endBlock)
            );
        }

        
        for (uint256 i = startAccrualIndex.add(1); i < endAccrualIndex; i = i.add(1)) {
            
            claimableAmount = claimableAmount.add(
                _claimableAmount(wallet, closedAccrualsByCurrency[currencyCt][currencyId][i])
            );
        }

        
        claimableAmount = claimableAmount.add(
            _claimableAmount(
                wallet, endAccrual,
                startBlock.clampMin(endAccrual.startBlock),
                endBlock.clampMax(endAccrual.endBlock)
            )
        );

        
        return claimableAmount;
    }

    
    
    
    
    
    
    
    
    
    function claimAndTransferToBeneficiaryByAccruals(Beneficiary beneficiary, address destWallet, string memory balanceType,
        address currencyCt, uint256 currencyId, uint256 startAccrualIndex, uint256 endAccrualIndex,
        string memory standard)
    public
    {
        
        require(!isNonClaimer(msg.sender), "Message sender is non-claimer [TokenHolderRevenueFund.sol:605]");

        
        int256 claimedAmount = _claimByAccruals(msg.sender, currencyCt, currencyId, startAccrualIndex, endAccrualIndex);

        
        _transferToBeneficiary(beneficiary, destWallet, balanceType, claimedAmount,
            currencyCt, currencyId, standard);

        
        emit ClaimAndTransferToBeneficiaryByAccrualsEvent(msg.sender, balanceType, claimedAmount, currencyCt, currencyId,
            startAccrualIndex, endAccrualIndex, standard);
    }

    
    
    
    
    
    
    
    
    
    function claimAndTransferToBeneficiaryByBlockNumbers(Beneficiary beneficiary, address destWallet,
        string memory balanceType, address currencyCt, uint256 currencyId, uint256 startBlock,
        uint256 endBlock, string memory standard)
    public
    {
        
        require(!isNonClaimer(msg.sender), "Message sender is non-claimer [TokenHolderRevenueFund.sol:634]");

        
        int256 claimedAmount = _claimByBlockNumbers(msg.sender, currencyCt, currencyId, startBlock, endBlock);

        
        _transferToBeneficiary(beneficiary, destWallet, balanceType, claimedAmount,
            currencyCt, currencyId, standard);

        
        emit ClaimAndTransferToBeneficiaryByBlockNumbersEvent(msg.sender, balanceType, claimedAmount, currencyCt,
            currencyId, startBlock, endBlock, standard);
    }

    
    
    
    
    
    
    
    function claimAndTransferToBeneficiary(Beneficiary beneficiary, address destWallet, string memory balanceType,
        address currencyCt, uint256 currencyId, string memory standard)
    public
    {
        
        
        uint256 accrualIndex = (
        0 == claimedAccrualIndicesByWalletCurrency[msg.sender][currencyCt][currencyId].length ?
        0 :
        claimedAccrualIndicesByWalletCurrency[msg.sender][currencyCt][currencyId][
        claimedAccrualIndicesByWalletCurrency[msg.sender][currencyCt][currencyId].length - 1
        ] + 1
        );

        
        if (0 == claimBlockNumberBatchSize) {
            
            _updateClaimedAccruals(msg.sender, currencyCt, currencyId, accrualIndex);

            
            claimAndTransferToBeneficiaryByAccruals(
                beneficiary, destWallet, balanceType, currencyCt, currencyId,
                accrualIndex, accrualIndex, standard
            );
        }

        
        else {
            
            Accrual storage accrual = closedAccrualsByCurrency[currencyCt][currencyId][accrualIndex];

            
            uint256 startBlock = (
            0 == maxClaimedBlockNumberByWalletCurrencyAccrual[msg.sender][currencyCt][currencyId][accrualIndex] ?
            accrual.startBlock :
            maxClaimedBlockNumberByWalletCurrencyAccrual[msg.sender][currencyCt][currencyId][accrualIndex] + 1
            ).clampMax(accrual.endBlock);
            uint256 endBlock = (startBlock + claimBlockNumberBatchSize - 1).clampMax(accrual.endBlock);

            
            if (endBlock == accrual.endBlock)
                _updateClaimedAccruals(msg.sender, currencyCt, currencyId, accrualIndex);

            
            maxClaimedBlockNumberByWalletCurrencyAccrual[msg.sender][currencyCt][currencyId][accrualIndex] = endBlock;

            
            claimAndTransferToBeneficiaryByBlockNumbers(
                beneficiary, destWallet, balanceType, currencyCt, currencyId,
                startBlock, endBlock, standard
            );
        }
    }

    
    
    
    
    
    function claimAndStageByAccruals(address currencyCt, uint256 currencyId,
        uint256 startAccrualIndex, uint256 endAccrualIndex)
    public
    {
        
        require(!isNonClaimer(msg.sender), "Message sender is non-claimer [TokenHolderRevenueFund.sol:719]");

        
        int256 claimedAmount = _claimByAccruals(msg.sender, currencyCt, currencyId, startAccrualIndex, endAccrualIndex);

        
        if (0 < claimedAmount) {
            
            stagedByWallet[msg.sender].add(claimedAmount, currencyCt, currencyId);

            
            emit ClaimAndStageByAccrualsEvent(msg.sender, claimedAmount, currencyCt, currencyId, startAccrualIndex, endAccrualIndex);
        }
    }

    
    
    
    
    
    function claimAndStageByBlockNumbers(address currencyCt, uint256 currencyId,
        uint256 startBlock, uint256 endBlock)
    public
    {
        
        require(!isNonClaimer(msg.sender), "Message sender is non-claimer [TokenHolderRevenueFund.sol:744]");

        
        int256 claimedAmount = _claimByBlockNumbers(msg.sender, currencyCt, currencyId, startBlock, endBlock);

        
        if (0 < claimedAmount) {
            
            stagedByWallet[msg.sender].add(claimedAmount, currencyCt, currencyId);

            
            emit ClaimAndStageByBlockNumbersEvent(msg.sender, claimedAmount, currencyCt, currencyId, startBlock, endBlock);
        }
    }

    
    
    
    
    
    
    
    function fullyClaimed(address wallet, address currencyCt, uint256 currencyId, uint256 accrualIndex)
    public
    view
    returns (bool)
    {
        
        return (
        accrualIndex < closedAccrualsByCurrency[currencyCt][currencyId].length &&
        closedAccrualsByCurrency[currencyCt][currencyId][accrualIndex].claimRecordsByWallet[wallet].completed
        );
    }

    
    
    
    
    
    
    
    function partiallyClaimed(address wallet, address currencyCt, uint256 currencyId, uint256 accrualIndex)
    public
    view
    returns (bool)
    {
        
        return (
        accrualIndex < closedAccrualsByCurrency[currencyCt][currencyId].length &&
        0 < closedAccrualsByCurrency[currencyCt][currencyId][accrualIndex].claimRecordsByWallet[wallet].completedSpans.length
        );
    }

    
    
    
    
    
    
    function claimedBlockSpans(address wallet, address currencyCt, uint256 currencyId, uint256 accrualIndex)
    public
    view
    returns (BlockSpan[] memory)
    {
        if (closedAccrualsByCurrency[currencyCt][currencyId].length <= accrualIndex)
            return new BlockSpan[](0);

        return closedAccrualsByCurrency[currencyCt][currencyId][accrualIndex].claimRecordsByWallet[wallet].completedSpans;
    }

    
    
    
    
    
    function withdraw(int256 amount, address currencyCt, uint256 currencyId, string memory standard)
    public
    {
        
        require(amount.isNonZeroPositiveInt256(), "Amount not strictly positive [TokenHolderRevenueFund.sol:823]");

        
        amount = amount.clampMax(stagedByWallet[msg.sender].get(currencyCt, currencyId));

        
        stagedByWallet[msg.sender].sub(amount, currencyCt, currencyId);

        
        if (address(0) == currencyCt && 0 == currencyId)
            msg.sender.transfer(uint256(amount));

        else {
            TransferController controller = transferController(currencyCt, standard);
            (bool success,) = address(controller).delegatecall(
                abi.encodeWithSelector(
                    controller.getDispatchSignature(), address(this), msg.sender, uint256(amount), currencyCt, currencyId
                )
            );
            require(success, "Dispatch by controller failed [TokenHolderRevenueFund.sol:842]");
        }

        
        emit WithdrawEvent(msg.sender, amount, currencyCt, currencyId, standard);
    }

    
    
    
    function _claimByAccruals(address wallet, address currencyCt, uint256 currencyId,
        uint256 startAccrualIndex, uint256 endAccrualIndex)
    private
    returns (int256)
    {
        
        require(0 < closedAccrualsByCurrency[currencyCt][currencyId].length, "No terminated accrual found [TokenHolderRevenueFund.sol:858]");

        
        require(startAccrualIndex <= endAccrualIndex, "Accrual index mismatch [TokenHolderRevenueFund.sol:861]");

        
        int256 claimedAmount = 0;

        
        for (
            uint256 i = startAccrualIndex;
            i <= endAccrualIndex && i < closedAccrualsByCurrency[currencyCt][currencyId].length;
            i = i.add(1)
        ) {
            
            Accrual storage accrual = closedAccrualsByCurrency[currencyCt][currencyId][i];

            
            claimedAmount = claimedAmount.add(_claimableAmount(wallet, accrual));

            
            _updateClaimRecord(wallet, accrual);
        }

        
        return claimedAmount;
    }

    function _claimByBlockNumbers(address wallet, address currencyCt, uint256 currencyId,
        uint256 startBlock, uint256 endBlock)
    private
    returns (int256)
    {
        
        require(0 < closedAccrualsByCurrency[currencyCt][currencyId].length, "No terminated accrual found [TokenHolderRevenueFund.sol:892]");

        
        require(startBlock <= endBlock, "Block number mismatch [TokenHolderRevenueFund.sol:895]");

        
        uint256 startAccrualIndex = closedAccrualIndexByBlockNumber(currencyCt, currencyId, startBlock);
        uint256 endAccrualIndex = closedAccrualIndexByBlockNumber(currencyCt, currencyId, endBlock);

        
        int256 claimedAmount = 0;
        uint256 clampedStartBlock = 0;
        uint256 clampedEndBlock = 0;

        
        if (startAccrualIndex < endAccrualIndex) {
            
            Accrual storage accrual = closedAccrualsByCurrency[currencyCt][currencyId][startAccrualIndex];

            
            clampedStartBlock = startBlock.clampMin(accrual.startBlock);
            clampedEndBlock = endBlock.clampMax(accrual.endBlock);

            
            claimedAmount = _claimableAmount(wallet, accrual, clampedStartBlock, clampedEndBlock);

            
            _updateClaimRecord(wallet, accrual, clampedStartBlock, clampedEndBlock);
        }

        
        for (uint256 i = startAccrualIndex.add(1); i < endAccrualIndex; i = i.add(1)) {
            
            Accrual storage accrual = closedAccrualsByCurrency[currencyCt][currencyId][i];

            
            claimedAmount = claimedAmount.add(_claimableAmount(wallet, accrual));

            
            _updateClaimRecord(wallet, accrual);
        }

        
        Accrual storage accrual = closedAccrualsByCurrency[currencyCt][currencyId][endAccrualIndex];

        
        clampedStartBlock = startBlock.clampMin(accrual.startBlock);
        clampedEndBlock = endBlock.clampMax(accrual.endBlock);

        
        claimedAmount = claimedAmount.add(
            _claimableAmount(wallet, accrual, clampedStartBlock, clampedEndBlock)
        );

        
        _updateClaimRecord(wallet, accrual, clampedStartBlock, clampedEndBlock);

        
        return claimedAmount;
    }

    function _transferToBeneficiary(Beneficiary beneficiary, address destWallet, string memory balanceType,
        int256 amount, address currencyCt, uint256 currencyId, string memory standard)
    private
    {
        
        if (address(0) == currencyCt && 0 == currencyId)
            beneficiary.receiveEthersTo.value(uint256(amount))(destWallet, balanceType);

        else {
            
            TransferController controller = transferController(currencyCt, standard);
            (bool success,) = address(controller).delegatecall(
                abi.encodeWithSelector(
                    controller.getApproveSignature(), address(beneficiary), uint256(amount), currencyCt, currencyId
                )
            );
            require(success, "Approval by controller failed [TokenHolderRevenueFund.sol:969]");

            
            beneficiary.receiveTokensTo(destWallet, balanceType, amount, currencyCt, currencyId, standard);
        }
    }

    function _updateClaimRecord(address wallet, Accrual storage accrual)
    private
    {
        
        accrual.claimRecordsByWallet[wallet].completed = true;

        
        if (0 < accrual.claimRecordsByWallet[wallet].completedSpans.length)
            accrual.claimRecordsByWallet[wallet].completedSpans.length = 0;
    }

    function _updateClaimRecord(address wallet, Accrual storage accrual,
        uint256 startBlock, uint256 endBlock)
    private
    {
        
        accrual.claimRecordsByWallet[wallet].completedSpans.push(
            BlockSpan(startBlock, endBlock)
        );
    }

    function _updateClaimedAccruals(address wallet, address currencyCt, uint256 currencyId, uint256 accrualIndex)
    private
    {
        if (!accrualClaimedByWalletCurrencyAccrual[wallet][currencyCt][currencyId][accrualIndex]) {
            claimedAccrualIndicesByWalletCurrency[wallet][currencyCt][currencyId].push(accrualIndex);
            accrualClaimedByWalletCurrencyAccrual[wallet][currencyCt][currencyId][accrualIndex] = true;
        }
    }

    
    
    function _isClaimable(address wallet, Accrual storage accrual)
    private
    view
    returns (bool)
    {
        
        return (
        0 < accrual.amount &&
        !accrual.claimRecordsByWallet[wallet].completed &&
        0 == accrual.claimRecordsByWallet[wallet].completedSpans.length
        );
    }

    function _isClaimable(address wallet, Accrual storage accrual,
        uint256 startBlock, uint256 endBlock)
    private
    view
    returns (bool)
    {
        
        if (
            0 == accrual.amount ||
        accrual.claimRecordsByWallet[wallet].completed
        )
            return false;

        
        for (uint256 i = 0;
            i < accrual.claimRecordsByWallet[wallet].completedSpans.length;
            i = i.add(1)) {
            if (
                (
                accrual.claimRecordsByWallet[wallet].completedSpans[i].startBlock <= startBlock &&
                startBlock <= accrual.claimRecordsByWallet[wallet].completedSpans[i].endBlock
                ) ||
                (
                accrual.claimRecordsByWallet[wallet].completedSpans[i].startBlock <= endBlock &&
                endBlock <= accrual.claimRecordsByWallet[wallet].completedSpans[i].endBlock
                )
            )
                return false;
        }

        return true;
    }

    function _claimableAmount(address wallet, Accrual storage accrual)
    private
    view
    returns (int256)
    {
        
        if (!_isClaimable(wallet, accrual))
            return 0;

        
        int256 _releasedAmountBlocks = _correctedReleasedAmountBlocks(
            accrual.startBlock, accrual.endBlock
        );

        
        if (0 == _releasedAmountBlocks)
            return 0;

        
        int256 _walletBalanceBlocks = _balanceBlocks(
            wallet, accrual.startBlock, accrual.endBlock
        );

        
        return accrual.amount
        .mul_nn(_walletBalanceBlocks)
        .div_nn(_releasedAmountBlocks);
    }

    function _claimableAmount(address wallet, Accrual storage accrual,
        uint256 startBlock, uint256 endBlock)
    private
    view
    returns (int256)
    {
        
        if (!_isClaimable(wallet, accrual, startBlock, endBlock))
            return 0;

        
        int256 _releasedAmountBlocks = _correctedReleasedAmountBlocks(
            startBlock, endBlock
        );

        
        if (0 == _releasedAmountBlocks)
            return 0;

        
        int256 _walletBalanceBlocks = _balanceBlocks(
            wallet, startBlock, endBlock
        );

        
        int256 _accrualNumerator = int256(endBlock.sub(startBlock).add(1));
        int256 _accrualDenominator = int256(accrual.endBlock.sub(accrual.startBlock).add(1));

        
        return accrual.amount
        .mul_nn(_walletBalanceBlocks)
        .mul_nn(_accrualNumerator)
        .div_nn(_releasedAmountBlocks.mul_nn(_accrualDenominator));
    }

    function _balanceBlocks(address wallet, uint256 startBlock, uint256 endBlock)
    private
    view
    returns (int256)
    {
        return int256(balanceBlocksCalculator.calculate(
                BalanceRecordable(address(revenueTokenManager.token())), wallet, startBlock, endBlock
            ));
    }

    function _correctedReleasedAmountBlocks(uint256 startBlock, uint256 endBlock)
    private
    view
    returns (int256)
    {
        
        int256 amountBlocks = int256(releasedAmountBlocksCalculator.calculate(
                BalanceRecordable(address(revenueTokenManager)), address(0), startBlock, endBlock
            ));

        
        for (uint256 i = 0; i < nonClaimers.length; i = i.add(1))
            amountBlocks = amountBlocks.sub(_balanceBlocks(nonClaimers[i], startBlock, endBlock));

        
        return amountBlocks;
    }
}

contract RevenueFundAccrualMonitor is Ownable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;

    
    
    
    RevenueFund public revenueFund;
    TokenHolderRevenueFund public tokenHolderRevenueFund;
    RevenueTokenManager public revenueTokenManager;
    BalanceAucCalculator public balanceBlocksCalculator;
    BalanceAucCalculator public releasedAmountBlocksCalculator;

    
    
    
    event SetRevenueFundEvent(RevenueFund revenueFund);
    event SetTokenHolderRevenueFundEvent(TokenHolderRevenueFund tokenHolderRvenueFund);
    event SetRevenueTokenManagerEvent(RevenueTokenManager revenueTokenManager);
    event SetBalanceBlocksCalculatorEvent(BalanceAucCalculator balanceAucCalculator);
    event SetReleasedAmountBlocksCalculatorEvent(BalanceAucCalculator balanceAucCalculator);

    
    
    
    constructor(address deployer) Ownable(deployer) public {
    }

    
    
    
    
    
    function setRevenueFund(RevenueFund _revenueFund)
    public
    onlyDeployer
    notNullAddress(address(_revenueFund))
    {
        
        revenueFund = _revenueFund;

        
        emit SetRevenueFundEvent(revenueFund);
    }

    
    
    function setTokenHolderRevenueFund(TokenHolderRevenueFund _tokenHolderRevenueFund)
    public
    onlyDeployer
    notNullAddress(address(_tokenHolderRevenueFund))
    {
        
        tokenHolderRevenueFund = _tokenHolderRevenueFund;

        
        emit SetTokenHolderRevenueFundEvent(tokenHolderRevenueFund);
    }

    
    
    function setRevenueTokenManager(RevenueTokenManager _revenueTokenManager)
    public
    onlyDeployer
    notNullAddress(address(_revenueTokenManager))
    {
        
        revenueTokenManager = _revenueTokenManager;

        
        emit SetRevenueTokenManagerEvent(revenueTokenManager);
    }

    
    
    function setBalanceBlocksCalculator(BalanceAucCalculator _balanceAucCalculator)
    public
    onlyDeployer
    notNullOrThisAddress(address(_balanceAucCalculator))
    {
        
        balanceBlocksCalculator = _balanceAucCalculator;

        
        emit SetBalanceBlocksCalculatorEvent(balanceBlocksCalculator);
    }

    
    
    function setReleasedAmountBlocksCalculator(BalanceAucCalculator _balanceAucCalculator)
    public
    onlyDeployer
    notNullOrThisAddress(address(_balanceAucCalculator))
    {
        
        releasedAmountBlocksCalculator = _balanceAucCalculator;

        
        emit SetReleasedAmountBlocksCalculatorEvent(releasedAmountBlocksCalculator);
    }

    
    
    
    
    
    
    function claimableAmount(address wallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        
        
        int256 accrualClaimableAmount = _accrualClaimableAmount(currencyCt, currencyId);

        
        
        uint256 currentAccrualStartBlock = _currentAccrualStartBlock(currencyCt, currencyId);

        
        int256 balanceBlocks = _balanceBlocks(wallet, currentAccrualStartBlock, block.number);

        
        
        int256 amountBlocks = _correctedReleasedAmountBlocks(currentAccrualStartBlock, block.number);

        
        return accrualClaimableAmount
        .mul_nn(balanceBlocks)
        .div_nn(amountBlocks);
    }

    
    
    
    function _accrualClaimableAmount(address currencyCt, uint256 currencyId)
    private
    view
    returns (int256)
    {
        int256 periodAccrualBalance = revenueFund.periodAccrualBalance(currencyCt, currencyId);

        int256 beneficiaryFraction = revenueFund.beneficiaryFraction(tokenHolderRevenueFund);

        return periodAccrualBalance
        .mul_nn(beneficiaryFraction)
        .div_nn(ConstantsLib.PARTS_PER());
    }

    function _currentAccrualStartBlock(address currencyCt, uint256 currencyId)
    private
    view
    returns (uint256)
    {
        uint256 lastClosedAccrualIndex = tokenHolderRevenueFund.closedAccrualsCount(
            currencyCt, currencyId
        );
        if (0 == lastClosedAccrualIndex)
            return 0;
        else {
            (,uint256 endBlock,) = tokenHolderRevenueFund.closedAccrualsByCurrency(
                currencyCt, currencyId, lastClosedAccrualIndex.sub(1)
            );
            return endBlock.add(1);
        }
    }

    function _balanceBlocks(address wallet, uint256 startBlock, uint256 endBlock)
    private
    view
    returns (int256)
    {
        return int256(balanceBlocksCalculator.calculate(
                BalanceRecordable(address(revenueTokenManager.token())), wallet, startBlock, endBlock
            ));
    }

    function _correctedReleasedAmountBlocks(uint256 startBlock, uint256 endBlock)
    private
    view
    returns (int256)
    {
        
        int256 amountBlocks = int256(releasedAmountBlocksCalculator.calculate(
                BalanceRecordable(address(revenueTokenManager)), address(0), startBlock, endBlock
            ));

        
        for (uint256 i = 0; i < tokenHolderRevenueFund.nonClaimersCount(); i = i.add(1))
            amountBlocks = amountBlocks.sub(_balanceBlocks(tokenHolderRevenueFund.nonClaimers(i), startBlock, endBlock));

        
        return amountBlocks;
    }
}
