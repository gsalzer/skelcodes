// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../Governable.sol";
import "../interface/IPolicyManager.sol";
import "../interface/IRiskManager.sol";
import "../interface/ITreasury.sol";
import "../interface/IClaimsEscrow.sol";
import "../interface/IRegistry.sol";
import "../interface/IProduct.sol";


/**
 * @title BaseProduct
 * @author solace.fi
 * @notice The abstract smart contract that is inherited by every concrete individual **Product** contract.
 *
 * It is required to extend [`IProduct`](../interface/IProduct) and recommended to extend `BaseProduct`. `BaseProduct` extends [`IProduct`](../interface/IProduct) and takes care of the heavy lifting; new products simply need to set some variables in the constructor. It has some helpful functionality not included in [`IProduct`](../interface/IProduct) including claim signers.
 */
abstract contract BaseProduct is IProduct, EIP712, ReentrancyGuard, Governable {
    using Address for address;

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    /// @notice Policy Manager.
    IPolicyManager internal _policyManager; // Policy manager ERC721 contract

    // Registry.
    IRegistry internal _registry;

    /// @notice The minimum policy period in blocks.
    uint40 internal _minPeriod;
    /// @notice The maximum policy period in blocks.
    uint40 internal _maxPeriod;
    /// @notice Covered platform.
    /// A platform contract which locates contracts that are covered by this product.
    /// (e.g., UniswapProduct will have Factory as coveredPlatform contract, because every Pair address can be located through getPool() function).
    address internal _coveredPlatform;
    /// @notice Cannot buy new policies while paused. (Default is False)
    bool internal _paused;

    /****
        Book-Keeping Variables
    ****/
    /// @notice The current amount covered (in wei).
    uint256 internal _activeCoverAmount;
    /// @notice The authorized signers.
    mapping(address => bool) internal _isAuthorizedSigner;

    // Typehash for claim submissions.
    // Must be unique for all products.
    // solhint-disable-next-line var-name-mixedcase
    bytes32 internal _SUBMIT_CLAIM_TYPEHASH;

    // The name of the product.
    string internal _productName;

    // used in our floating point price math
    // price is measured in wei per block per wei of coverage * Q12
    // divide by Q12 to get premium
    uint256 internal constant Q12 = 1e12;

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a claim signer is added.
    event SignerAdded(address indexed signer);
    /// @notice Emitted when a claim signer is removed.
    event SignerRemoved(address indexed signer);

    modifier whileUnpaused() {
        require(!_paused, "cannot buy when paused");
        _;
    }

    /**
     * @notice Constructs the product. `BaseProduct` by itself is not deployable, only its subclasses.
     * @param governance_ The governor.
     * @param policyManager_ The IPolicyManager contract.
     * @param registry_ The IRegistry contract.
     * @param coveredPlatform_ A platform contract which locates contracts that are covered by this product.
     * @param minPeriod_ The minimum policy period in blocks to purchase a **policy**.
     * @param maxPeriod_ The maximum policy period in blocks to purchase a **policy**.
     * @param domain_ The user readable name of the EIP712 signing domain.
     * @param version_ The current major version of the signing domain.
     */
    constructor (
        address governance_,
        IPolicyManager policyManager_,
        IRegistry registry_,
        address coveredPlatform_,
        uint40 minPeriod_,
        uint40 maxPeriod_,
        string memory domain_,
        string memory version_
    ) EIP712(domain_, version_) Governable(governance_) {
        require(address(registry_) != address(0x0), "zero address registry");
        _registry = registry_;
        require(address(policyManager_) != address(0x0), "zero address policymanager");
        _policyManager = policyManager_;
        require(coveredPlatform_ != address(0x0), "zero address coveredplatform");
        _coveredPlatform = coveredPlatform_;
        require(minPeriod_ <= maxPeriod_, "invalid period");
        _minPeriod = minPeriod_;
        _maxPeriod = maxPeriod_;
    }

    /***************************************
    POLICYHOLDER FUNCTIONS
    ***************************************/

    /**
     * @notice Purchases and mints a policy on the behalf of the policyholder.
     * User will need to pay **ETH**.
     * @param policyholder Holder of the position(s) to cover.
     * @param coverAmount The value to cover in **ETH**.
     * @param blocks The length (in blocks) for policy.
     * @param positionDescription A byte encoded description of the position(s) to cover.
     * @return policyID The ID of newly created policy.
     */
    function buyPolicy(address policyholder, uint256 coverAmount, uint40 blocks, bytes memory positionDescription) external payable override nonReentrant whileUnpaused returns (uint256 policyID) {
        require(policyholder != address(0x0), "zero address");
        require(coverAmount > 0, "zero cover value");
        require(isValidPositionDescription(positionDescription), "invalid position description");
        // check that the product can provide coverage for this policy
        (bool acceptable, uint24 price) = IRiskManager(_registry.riskManager()).assessRisk(address(this), 0, coverAmount);
        require(acceptable, "cannot accept that risk");
        // check that the buyer has paid the correct premium
        uint256 premium = coverAmount * blocks * price / Q12;
        require(msg.value >= premium && premium != 0, "insufficient payment");
        // check that the buyer provided valid period
        require(blocks >= _minPeriod && blocks <= _maxPeriod, "invalid period");
        // create the policy
        uint40 expirationBlock = uint40(block.number + blocks);
        policyID = _policyManager.createPolicy(policyholder, coverAmount, expirationBlock, price, positionDescription);
        // update local book-keeping variables
        _activeCoverAmount += coverAmount;
        // return excess payment
        if(msg.value > premium) Address.sendValue(payable(msg.sender), msg.value - premium);
        // transfer premium to the treasury
        ITreasury(payable(_registry.treasury())).routePremiums{value: premium}();
        emit PolicyCreated(policyID);
        return policyID;
    }

    /**
     * @notice Increase or decrease the cover amount of the policy.
     * User may need to pay **ETH** for increased cover amount or receive a refund for decreased cover amount.
     * Can only be called by the policyholder.
     * @param policyID The ID of the policy.
     * @param coverAmount The new value to cover in **ETH**.
     */
    function updateCoverAmount(uint256 policyID, uint256 coverAmount) external payable override nonReentrant whileUnpaused {
        require(coverAmount > 0, "zero cover value");
        (address policyholder, address product, uint256 previousCoverAmount, uint40 expirationBlock, uint24 purchasePrice, bytes memory positionDescription) = _policyManager.getPolicyInfo(policyID);
        // check msg.sender is policyholder
        require(policyholder == msg.sender, "!policyholder");
        // check for correct product
        require(product == address(this), "wrong product");
        // check for policy expiration
        require(expirationBlock >= block.number, "policy is expired");
        // check that the product can provide coverage for this policy
        (bool acceptable, uint24 price) = IRiskManager(_registry.riskManager()).assessRisk(address(this), previousCoverAmount, coverAmount);
        require(acceptable, "cannot accept that risk");
        // update local book-keeping variables
        _activeCoverAmount = _activeCoverAmount + coverAmount - previousCoverAmount;
        // calculate premium needed for new cover amount as if policy is bought now
        uint256 remainingBlocks = expirationBlock - block.number;
        uint256 newPremium = coverAmount * remainingBlocks * price / Q12;
        // calculate premium already paid based on current policy
        uint256 paidPremium = previousCoverAmount * remainingBlocks * purchasePrice / Q12;
        if (newPremium >= paidPremium) {
            uint256 premium = newPremium - paidPremium;
            // check that the buyer has paid the correct premium
            require(msg.value >= premium, "insufficient payment");
            if(msg.value > premium) Address.sendValue(payable(msg.sender), msg.value - premium);
            // transfer premium to the treasury
            ITreasury(payable(_registry.treasury())).routePremiums{value: premium}();
        } else {
            if(msg.value > 0) Address.sendValue(payable(msg.sender), msg.value);
            uint256 refundAmount = paidPremium - newPremium;
            ITreasury(payable(_registry.treasury())).refund(msg.sender, refundAmount);
        }
        // update policy's URI and emit event
        _policyManager.setPolicyInfo(policyID, coverAmount, expirationBlock, price, positionDescription);
        emit PolicyUpdated(policyID);
    }

    /**
     * @notice Extend a policy.
     * User will need to pay **ETH**.
     * Can only be called by the policyholder.
     * @param policyID The ID of the policy.
     * @param extension The length of extension in blocks.
     */
    function extendPolicy(uint256 policyID, uint40 extension) external payable override nonReentrant whileUnpaused {
        // check that the msg.sender is the policyholder
        (address policyholder, address product, uint256 coverAmount, uint40 expirationBlock, uint24 purchasePrice, bytes memory positionDescription) = _policyManager.getPolicyInfo(policyID);
        require(policyholder == msg.sender,"!policyholder");
        require(product == address(this), "wrong product");
        require(expirationBlock >= block.number, "policy is expired");
        // compute the premium
        uint256 premium = coverAmount * extension * purchasePrice / Q12;
        // check that the buyer has paid the correct premium
        require(msg.value >= premium, "insufficient payment");
        if(msg.value > premium) Address.sendValue(payable(msg.sender), msg.value - premium);
        // transfer premium to the treasury
        ITreasury(payable(_registry.treasury())).routePremiums{value: premium}();
        // check that the buyer provided valid period
        uint40 newExpirationBlock = expirationBlock + extension;
        uint40 duration = newExpirationBlock - uint40(block.number);
        require(duration >= _minPeriod && duration <= _maxPeriod, "invalid period");
        // update the policy's URI
        _policyManager.setPolicyInfo(policyID, coverAmount, newExpirationBlock, purchasePrice, positionDescription);
        emit PolicyExtended(policyID);
    }

    /**
     * @notice Extend a policy and update its cover amount.
     * User may need to pay **ETH** for increased cover amount or receive a refund for decreased cover amount.
     * Can only be called by the policyholder.
     * @param policyID The ID of the policy.
     * @param coverAmount The new value to cover in **ETH**.
     * @param extension The length of extension in blocks.
     */
    function updatePolicy(uint256 policyID, uint256 coverAmount, uint40 extension) external payable override nonReentrant whileUnpaused {
        require(coverAmount > 0, "zero cover value");
        (address policyholder, address product, uint256 previousCoverAmount, uint40 previousExpirationBlock, uint24 purchasePrice, bytes memory positionDescription) = _policyManager.getPolicyInfo(policyID);
        require(policyholder == msg.sender,"!policyholder");
        require(product == address(this), "wrong product");
        require(previousExpirationBlock >= block.number, "policy is expired");
        // check that the product can provide coverage for this policy
        (bool acceptable, uint24 price) = IRiskManager(_registry.riskManager()).assessRisk(address(this), previousCoverAmount, coverAmount);
        require(acceptable, "cannot accept that risk");
        // add new block extension
        uint40 newExpirationBlock = previousExpirationBlock + extension;
        // check if duration is valid
        uint40 duration = newExpirationBlock - uint40(block.number);
        require(duration >= _minPeriod && duration <= _maxPeriod, "invalid period");
        // update local book-keeping variables
        _activeCoverAmount = _activeCoverAmount + coverAmount - previousCoverAmount;
        // update policy info
        _policyManager.setPolicyInfo(policyID, coverAmount, newExpirationBlock, price, positionDescription);
        // calculate premium needed for new cover amount as if policy is bought now
        uint256 newPremium = coverAmount * duration * price / Q12;
        // calculate premium already paid based on current policy
        uint256 paidPremium = previousCoverAmount * (previousExpirationBlock - uint40(block.number)) * purchasePrice / Q12;
        if (newPremium >= paidPremium) {
            uint256 premium = newPremium - paidPremium;
            require(msg.value >= premium, "insufficient payment");
            if(msg.value > premium) Address.sendValue(payable(msg.sender), msg.value - premium);
            ITreasury(payable(_registry.treasury())).routePremiums{value: premium}();
        } else {
            if(msg.value > 0) Address.sendValue(payable(msg.sender), msg.value);
            uint256 refund = paidPremium - newPremium;
            ITreasury(payable(_registry.treasury())).refund(msg.sender, refund);
        }
        emit PolicyUpdated(policyID);
    }

    /**
     * @notice Cancel and burn a policy.
     * User will receive a refund for the remaining blocks.
     * Can only be called by the policyholder.
     * @param policyID The ID of the policy.
     */
    function cancelPolicy(uint256 policyID) external override nonReentrant {
        (address policyholder, address product, uint256 coverAmount, uint40 expirationBlock, uint24 purchasePrice, ) = _policyManager.getPolicyInfo(policyID);
        require(policyholder == msg.sender,"!policyholder");
        require(product == address(this), "wrong product");
        uint40 blocksLeft = expirationBlock - uint40(block.number);
        uint256 refundAmount = blocksLeft * coverAmount * purchasePrice / Q12;
        _policyManager.burn(policyID);
        ITreasury(payable(_registry.treasury())).refund(msg.sender, refundAmount);
        _activeCoverAmount -= coverAmount;
        emit PolicyCanceled(policyID);
    }

    /**
     * @notice Submit a claim.
     * The user can only submit one claim per policy and the claim must be signed by an authorized signer.
     * If successful the policy is burnt and a new claim is created.
     * The new claim will be in [`ClaimsEscrow`](../ClaimsEscrow) and have the same ID as the policy.
     * Can only be called by the policyholder.
     * @param policyID The policy that suffered a loss.
     * @param amountOut The amount the user will receive.
     * @param deadline Transaction must execute before this timestamp.
     * @param signature Signature from the signer.
     */
    function submitClaim(
        uint256 policyID,
        uint256 amountOut,
        uint256 deadline,
        bytes calldata signature
    ) external nonReentrant {
        // validate inputs
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "expired deadline");
        (address policyholder, address product, uint256 coverAmount, , , ) = _policyManager.getPolicyInfo(policyID);
        require(policyholder == msg.sender, "!policyholder");
        require(product == address(this), "wrong product");
        require(amountOut <= coverAmount, "excessive amount out");
        // verify signature
        {
        bytes32 structHash = keccak256(abi.encode(_SUBMIT_CLAIM_TYPEHASH, policyID, msg.sender, amountOut, deadline));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        require(_isAuthorizedSigner[signer], "invalid signature");
        }
        // update local book-keeping variables
        _activeCoverAmount -= coverAmount;
        // burn policy
        _policyManager.burn(policyID);
        // submit claim to ClaimsEscrow
        IClaimsEscrow(payable(_registry.claimsEscrow())).receiveClaim(policyID, policyholder, amountOut);
        emit ClaimSubmitted(policyID);
    }

    /***************************************
    QUOTE VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Calculate a premium quote for a policy.
     * @param coverAmount The value to cover in **ETH**.
     * @param blocks The duration of the policy in blocks.
     * @return premium The quote for their policy in **ETH**.
     */
    function getQuote(uint256 coverAmount, uint40 blocks) external view override returns (uint256 premium) {
        (, uint24 price, ) = IRiskManager(_registry.riskManager()).productRiskParams(address(this));
        return coverAmount * blocks * price / Q12;
    }

    /***************************************
    GLOBAL VIEW FUNCTIONS
    ***************************************/

    /// @notice The minimum policy period in blocks.
    function minPeriod() external view override returns (uint40) {
        return _minPeriod;
    }

    /// @notice The maximum policy period in blocks.
    function maxPeriod() external view override returns (uint40) {
        return _maxPeriod;
    }

    /// @notice Covered platform.
    /// A platform contract which locates contracts that are covered by this product.
    /// (e.g., `UniswapProduct` will have `Factory` as `coveredPlatform` contract, because every `Pair` address can be located through `getPool()` function).
    function coveredPlatform() external view override returns (address) {
        return _coveredPlatform;
    }
    /// @notice The current amount covered (in wei).
    function activeCoverAmount() external view override returns (uint256) {
        return _activeCoverAmount;
    }

    /**
     * @notice Returns the name of the product.
     * @return productName The name of the product.
     */
    function name() external view virtual override returns (string memory productName) {
        return _productName;
    }

    /// @notice Returns whether or not product is currently in paused state.
    function paused() external view override returns (bool) {
        return _paused;
    }

    /// @notice Address of the [`PolicyManager`](../PolicyManager).
    function policyManager() external view override returns (address) {
        return address(_policyManager);
    }

    /**
     * @notice Returns true if the given account is authorized to sign claims.
     * @param account Potential signer to query.
     * @return status True if is authorized signer.
     */
     function isAuthorizedSigner(address account) external view override returns (bool status) {
        return _isAuthorizedSigner[account];
     }

     /**
      * @notice Determines if the byte encoded description of a position(s) is valid.
      * The description will only make sense in context of the product.
      * @dev This function should be overwritten in inheriting Product contracts.
      * If invalid, return false if possible. Reverting is also acceptable.
      * @param positionDescription The description to validate.
      * @return isValid True if is valid.
      */
     function isValidPositionDescription(bytes memory positionDescription) public view virtual returns (bool isValid);

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Updates the product's book-keeping variables.
     * Can only be called by the [`PolicyManager`](../PolicyManager).
     * @param coverDiff The change in active cover amount.
     */
    function updateActiveCoverAmount(int256 coverDiff) external override {
        require(msg.sender == address(_policyManager), "!policymanager");
        _activeCoverAmount = add(_activeCoverAmount, coverDiff);
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the minimum number of blocks a policy can be purchased for.
     * @param minPeriod_ The minimum number of blocks.
     */
    function setMinPeriod(uint40 minPeriod_) external override onlyGovernance {
        require(minPeriod_ <= _maxPeriod, "invalid period");
        _minPeriod = minPeriod_;
        emit MinPeriodSet(minPeriod_);
    }

    /**
     * @notice Sets the maximum number of blocks a policy can be purchased for.
     * @param maxPeriod_ The maximum number of blocks
     */
    function setMaxPeriod(uint40 maxPeriod_) external override onlyGovernance {
        require(_minPeriod <= maxPeriod_, "invalid period");
        _maxPeriod = maxPeriod_;
        emit MaxPeriodSet(maxPeriod_);
    }

    /**
     * @notice Adds a new signer that can authorize claims.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param signer The signer to add.
     */
    function addSigner(address signer) external onlyGovernance {
        require(signer != address(0x0), "zero address signer");
        _isAuthorizedSigner[signer] = true;
        emit SignerAdded(signer);
    }

    /**
     * @notice Removes a signer.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param signer The signer to remove.
     */
    function removeSigner(address signer) external onlyGovernance {
        _isAuthorizedSigner[signer] = false;
        emit SignerRemoved(signer);
    }

    /**
     * @notice Pauses or unpauses buying and extending policies.
     * Cancelling policies and submitting claims are unaffected by pause.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @dev Used for security and to gracefully phase out old products.
     * @param paused_ True to pause, false to unpause.
     */
    function setPaused(bool paused_) external onlyGovernance {
        _paused = paused_;
        emit PauseSet(paused_);
    }

    /**
     * @notice Changes the covered platform.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @dev Use this if the the protocol changes their registry but keeps the children contracts.
     * A new version of the protocol will likely require a new Product.
     * @param coveredPlatform_ The platform to cover.
     */
    function setCoveredPlatform(address coveredPlatform_) public virtual override onlyGovernance {
        require(coveredPlatform_ != address(0x0), "zero address coveredplatform");
        _coveredPlatform = coveredPlatform_;
        emit CoveredPlatformSet(coveredPlatform_);
    }

    /**
     * @notice Changes the policy manager.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param policyManager_ The new policy manager.
     */
    function setPolicyManager(address policyManager_) external override onlyGovernance {
        require(policyManager_ != address(0x0), "zero address policymanager");
        _policyManager = IPolicyManager(policyManager_);
        emit PolicyManagerSet(policyManager_);
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Adds two numbers.
     * @param a The first number as a uint256.
     * @param b The second number as an int256.
     * @return c The sum as a uint256.
     */
    function add(uint256 a, int256 b) internal pure returns (uint256 c) {
        return (b > 0)
            ? a + uint256(b)
            : a - uint256(-b);
    }
}

