// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ISubscriptions.sol";
import "./IProtocol.sol";
import "./IFeesWallet.sol";
import "./ManagedContract.sol";

contract Subscriptions is ISubscriptions, ManagedContract {
    using SafeMath for uint256;

    enum CommitteeType {
        General,
        Certification
    }

    struct VirtualChain {
        string name;
        string tier;
        uint256 rate; // TODO get rate from subscriber when extending, don't keep in state
        uint expiresAt;
        uint256 genRefTime;
        address owner;
        string deploymentSubset;
        bool isCertified;
    }

    mapping(uint => mapping(string => string)) configRecords;
    mapping(address => bool) public authorizedSubscribers;
    mapping(uint => VirtualChain) virtualChains;

    uint public nextVcId;

    struct Settings {
        uint genesisRefTimeDelay;
        uint256 minimumInitialVcPayment;
    }
    Settings settings;

    IERC20 public erc20;

    constructor (IContractRegistry _contractRegistry, address _registryAdmin, IERC20 _erc20, uint256 _genesisRefTimeDelay, uint256 _minimumInitialVcPayment, uint[] memory vcIds, uint256 initialNextVcId, ISubscriptions previousSubscriptionsContract) ManagedContract(_contractRegistry, _registryAdmin) public {
        require(address(_erc20) != address(0), "erc20 must not be 0");

        erc20 = _erc20;
        nextVcId = initialNextVcId;

        setGenesisRefTimeDelay(_genesisRefTimeDelay);
        setMinimumInitialVcPayment(_minimumInitialVcPayment);

        for (uint i = 0; i < vcIds.length; i++) {
            importSubscription(vcIds[i], previousSubscriptionsContract);
        }
    }

    modifier onlySubscriber {
        require(authorizedSubscribers[msg.sender], "sender must be an authorized subscriber");

        _;
    }

    /*
     *   External functions
     */

    function importSubscription(uint vcId, ISubscriptions previousSubscriptionsContract) public onlyInitializationAdmin {
        require(virtualChains[vcId].owner == address(0), "the vcId already exists");

        (string memory name,
        string memory tier,
        uint256 rate,
        uint expiresAt,
        uint256 genRefTime,
        address owner,
        string memory deploymentSubset,
        bool isCertified) = previousSubscriptionsContract.getVcData(vcId);

        virtualChains[vcId] = VirtualChain({
            name: name,
            tier: tier,
            rate: rate,
            expiresAt: expiresAt,
            genRefTime: genRefTime,
            owner: owner,
            deploymentSubset: deploymentSubset,
            isCertified: isCertified
        });

        if (vcId >= nextVcId) {
            nextVcId = vcId + 1;
        }

        emit SubscriptionChanged(vcId, owner, name, genRefTime, tier, rate, expiresAt, isCertified, deploymentSubset);
    }

    function setVcConfigRecord(uint256 vcId, string calldata key, string calldata value) external override onlyWhenActive {
        require(msg.sender == virtualChains[vcId].owner, "only vc owner can set a vc config record");
        configRecords[vcId][key] = value;
        emit VcConfigRecordChanged(vcId, key, value);
    }

    function getVcConfigRecord(uint256 vcId, string calldata key) external override view returns (string memory) {
        return configRecords[vcId][key];
    }

    function addSubscriber(address addr) external override onlyFunctionalManager {
        authorizedSubscribers[addr] = true;
        emit SubscriberAdded(addr);
    }

    function removeSubscriber(address addr) external override onlyFunctionalManager {
        require(authorizedSubscribers[addr], "given add is not an authorized subscriber");

        authorizedSubscribers[addr] = false;
        emit SubscriberRemoved(addr);
    }

    function createVC(string calldata name, string calldata tier, uint256 rate, uint256 amount, address owner, bool isCertified, string calldata deploymentSubset) external override onlySubscriber onlyWhenActive returns (uint, uint) {
        require(owner != address(0), "vc owner cannot be the zero address");
        require(protocolContract.deploymentSubsetExists(deploymentSubset) == true, "No such deployment subset");
        require(amount >= settings.minimumInitialVcPayment, "initial VC payment must be at least minimumInitialVcPayment");

        uint vcId = nextVcId++;
        VirtualChain memory vc = VirtualChain({
            name: name,
            expiresAt: block.timestamp,
            genRefTime: now + settings.genesisRefTimeDelay,
            owner: owner,
            tier: tier,
            rate: rate,
            deploymentSubset: deploymentSubset,
            isCertified: isCertified
        });
        virtualChains[vcId] = vc;

        emit VcCreated(vcId);

        _extendSubscription(vcId, amount, tier, rate, owner);
        return (vcId, vc.genRefTime);
    }

    function extendSubscription(uint256 vcId, uint256 amount, string calldata tier, uint256 rate, address payer) external override onlySubscriber onlyWhenActive {
        _extendSubscription(vcId, amount, tier, rate, payer);
    }

    function getVcData(uint256 vcId) external override view returns (
        string memory name,
        string memory tier,
        uint256 rate,
        uint expiresAt,
        uint256 genRefTime,
        address owner,
        string memory deploymentSubset,
        bool isCertified
    ) {
        VirtualChain memory vc = virtualChains[vcId];
        name = vc.name;
        tier = vc.tier;
        rate = vc.rate;
        expiresAt = vc.expiresAt;
        genRefTime = vc.genRefTime;
        owner = vc.owner;
        deploymentSubset = vc.deploymentSubset;
        isCertified = vc.isCertified;
    }

    function setVcOwner(uint256 vcId, address owner) external override onlyWhenActive {
        require(msg.sender == virtualChains[vcId].owner, "only the vc owner can transfer ownership");
        require(owner != address(0), "cannot transfer ownership to the zero address");

        virtualChains[vcId].owner = owner;
        emit VcOwnerChanged(vcId, msg.sender, owner);
    }

    /*
     *   Governance functions
     */

    function setGenesisRefTimeDelay(uint256 newGenesisRefTimeDelay) public override onlyFunctionalManager {
        settings.genesisRefTimeDelay = newGenesisRefTimeDelay;
        emit GenesisRefTimeDelayChanged(newGenesisRefTimeDelay);
    }

    function setMinimumInitialVcPayment(uint256 newMinimumInitialVcPayment) public override onlyFunctionalManager {
        settings.minimumInitialVcPayment = newMinimumInitialVcPayment;
        emit MinimumInitialVcPaymentChanged(newMinimumInitialVcPayment);
    }

    function getGenesisRefTimeDelay() external override view returns (uint) {
        return settings.genesisRefTimeDelay;
    }

    function getMinimumInitialVcPayment() external override view returns (uint) {
        return settings.minimumInitialVcPayment;
    }

    function getSettings() external override view returns(
        uint genesisRefTimeDelay,
        uint256 minimumInitialVcPayment
    ) {
        Settings memory _settings = settings;
        genesisRefTimeDelay = _settings.genesisRefTimeDelay;
        minimumInitialVcPayment = _settings.minimumInitialVcPayment;
    }

    /*
    * Private functions
    */

    function _extendSubscription(uint256 vcId, uint256 amount, string memory tier, uint256 rate, address payer) private {
        VirtualChain memory vc = virtualChains[vcId];
        require(vc.genRefTime != 0, "vc does not exist");
        require(keccak256(bytes(tier)) == keccak256(bytes(virtualChains[vcId].tier)), "given tier must match the VC tier");

        IFeesWallet feesWallet = vc.isCertified ? certifiedFeesWallet : generalFeesWallet;
        require(erc20.transferFrom(msg.sender, address(this), amount), "failed to transfer subscription fees from subscriber to subscriptions");
        require(erc20.approve(address(feesWallet), amount), "failed to approve rewards to acquire subscription fees");

        uint fromTimestamp = vc.expiresAt > now ? vc.expiresAt : now;
        feesWallet.fillFeeBuckets(amount, rate, fromTimestamp);

        vc.expiresAt = fromTimestamp.add(amount.mul(30 days).div(rate));
        vc.rate = rate;

        // commit new expiration timestamp to storage
        virtualChains[vcId].expiresAt = vc.expiresAt;
        virtualChains[vcId].rate = vc.rate;

        emit SubscriptionChanged(vcId, vc.owner, vc.name, vc.genRefTime, vc.tier, vc.rate, vc.expiresAt, vc.isCertified, vc.deploymentSubset);
        emit Payment(vcId, payer, amount, vc.tier, vc.rate);
    }

    /*
     * Contracts topology / registry interface
     */

    IFeesWallet generalFeesWallet;
    IFeesWallet certifiedFeesWallet;
    IProtocol protocolContract;
    function refreshContracts() external override {
        generalFeesWallet = IFeesWallet(getGeneralFeesWallet());
        certifiedFeesWallet = IFeesWallet(getCertifiedFeesWallet());
        protocolContract = IProtocol(getProtocolContract());
    }
}

