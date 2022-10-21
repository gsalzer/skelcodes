// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Interface
import { ILazyMintERC1155 } from "./ILazyMintERC1155.sol";

// Token
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// Protocol control center.
import { ProtocolControl } from "../../ProtocolControl.sol";

// Royalties
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

// Access Control + security
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Meta transactions
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

// Utils
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Helper interfaces
import { IWETH } from "../../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LazyMintERC1155 is
    ILazyMintERC1155,
    ERC1155,
    ERC2771Context,
    IERC2981,
    AccessControlEnumerable,
    ReentrancyGuard,
    Multicall
{
    using Strings for uint256;

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs (i.e. can call functions prefixed with `lazyMint`).
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The address of the native token wrapper contract.
    address public immutable nativeTokenWrapper;

    /// @dev The adress that receives all primary sales value.
    address public defaultSaleRecipient;

    /// @dev The next token ID of the NFT to "lazy mint".
    uint256 public nextTokenIdToMint;

    /// @dev Contract interprets 10_000 as 100%.
    uint64 private constant MAX_BPS = 10_000;

    /// @dev The % of secondary sales collected as royalties. See EIP 2981.
    uint64 public royaltyBps;

    /// @dev The % of primary sales collected by the contract as fees.
    uint120 public feeBps;

    /// @dev Whether transfers on tokens are restricted.
    bool public transfersRestricted;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev The protocol control center.
    ProtocolControl internal controlCenter;

    uint256[] private baseURIIndices;

    /// @dev End token Id => URI that overrides `baseURI + tokenId` convention.
    mapping(uint256 => string) private baseURI;
    /// @dev Token ID => total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public totalSupply;
    /// @dev Token ID => public claim conditions for tokens with that ID.
    mapping(uint256 => ClaimConditions) public claimConditions;
    /// @dev Token ID => the address of the recipient of primary sales.
    mapping(uint256 => address) public saleRecipient;

    /// @dev Checks whether caller has DEFAULT_ADMIN_ROLE on the protocol control center.
    modifier onlyProtocolAdmin() {
        require(controlCenter.hasRole(controlCenter.DEFAULT_ADMIN_ROLE(), _msgSender()), "not protocol admin.");
        _;
    }

    /// @dev Checks whether caller has DEFAULT_ADMIN_ROLE.
    modifier onlyModuleAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "not module admin.");
        _;
    }

    /// @dev Checks whether caller has MINTER_ROLE.
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "not minter.");
        _;
    }

    constructor(
        string memory _contractURI,
        address payable _controlCenter,
        address _trustedForwarder,
        address _nativeTokenWrapper,
        address _saleRecipient,
        uint128 _royaltyBps,
        uint128 _feeBps
    ) ERC1155("") ERC2771Context(_trustedForwarder) {
        controlCenter = ProtocolControl(_controlCenter);
        nativeTokenWrapper = _nativeTokenWrapper;
        defaultSaleRecipient = _saleRecipient;
        contractURI = _contractURI;
        royaltyBps = uint64(_royaltyBps);
        feeBps = uint120(_feeBps);

        address deployer = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, deployer);
        _setupRole(MINTER_ROLE, deployer);
        _setupRole(TRANSFER_ROLE, deployer);
    }

    ///     =====   Public functions  =====

    /// @dev Returns the URI for a given tokenId.
    function uri(uint256 _tokenId) public view override returns (string memory _tokenURI) {
        for (uint256 i = 0; i < baseURIIndices.length; i += 1) {
            if (_tokenId < baseURIIndices[i]) {
                return string(abi.encodePacked(baseURI[baseURIIndices[i]], _tokenId.toString()));
            }
        }

        return "";
    }

    /// @dev Returns the URI for a given tokenId.
    function tokenURI(uint256 _tokenId) public view returns (string memory _tokenURI) {
        return uri(_tokenId);
    }

    /// @dev At any given moment, returns the uid for the active mint condition for a given tokenId.
    function getIndexOfActiveCondition(uint256 _tokenId) public view returns (uint256) {
        uint256 totalConditionCount = claimConditions[_tokenId].totalConditionCount;

        require(totalConditionCount > 0, "no public mint condition.");

        for (uint256 i = totalConditionCount; i > 0; i -= 1) {
            if (block.timestamp >= claimConditions[_tokenId].claimConditionAtIndex[i - 1].startTimestamp) {
                return i - 1;
            }
        }

        revert("no active mint condition.");
    }

    ///     =====   External functions  =====

    /**
     *  @dev Lets an account with `MINTER_ROLE` mint tokens of ID from `nextTokenIdToMint`
     *       to `nextTokenIdToMint + _amount - 1`. The URIs for these tokenIds is baseURI + `${tokenId}`.
     */
    function lazyMint(uint256 _amount, string calldata _baseURIForTokens) external onlyMinter {
        uint256 startId = nextTokenIdToMint;
        uint256 baseURIIndex = startId + _amount;

        nextTokenIdToMint = baseURIIndex;
        baseURI[baseURIIndex] = _baseURIForTokens;
        baseURIIndices.push(baseURIIndex);

        emit LazyMintedTokens(startId, startId + _amount - 1, _baseURIForTokens);
    }

    /// @dev Lets an account claim a given quantity of tokens, of a single tokenId.
    function claim(
        uint256 _tokenId,
        uint256 _quantity,
        bytes32[] calldata _proofs
    ) external payable nonReentrant {
        // Get the claim conditions.
        uint256 activeConditionIndex = getIndexOfActiveCondition(_tokenId);
        ClaimCondition memory condition = claimConditions[_tokenId].claimConditionAtIndex[activeConditionIndex];

        // Verify claim validity. If not valid, revert.
        verifyClaimIsValid(_tokenId, _quantity, _proofs, activeConditionIndex, condition);

        // If there's a price, collect price.
        collectClaimPrice(condition, _quantity, _tokenId);

        // Mint the relevant tokens to claimer.
        transferClaimedTokens(activeConditionIndex, _tokenId, _quantity);

        emit ClaimedTokens(activeConditionIndex, _tokenId, _msgSender(), _quantity);
    }

    // @dev Lets a module admin update mint conditions without resetting the restrictions.
    function updateClaimConditions(uint256 _tokenId, ClaimCondition[] calldata _conditions) external onlyModuleAdmin {
        resetClaimConditions(_tokenId, _conditions);

        emit NewClaimConditions(_tokenId, _conditions);
    }

    /// @dev Lets a module admin set mint conditions.
    function setClaimConditions(uint256 _tokenId, ClaimCondition[] calldata _conditions) external onlyModuleAdmin {
        uint256 numOfConditionsSet = resetClaimConditions(_tokenId, _conditions);
        resetTimestampRestriction(_tokenId, numOfConditionsSet);

        emit NewClaimConditions(_tokenId, _conditions);
    }

    /// @dev See EIP 2981
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = controlCenter.getRoyaltyTreasury(address(this));
        royaltyAmount = (salePrice * royaltyBps) / MAX_BPS;
    }

    //      =====   Setter functions  =====

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setDefaultSaleRecipient(address _saleRecipient) external onlyModuleAdmin {
        defaultSaleRecipient = _saleRecipient;
        emit NewSaleRecipient(_saleRecipient, type(uint256).max, true);
    }

    /// @dev Lets a module admin set the recipient of all primary sales for a given token ID.
    function setSaleRecipient(uint256 _tokenId, address _saleRecipient) external onlyModuleAdmin {
        saleRecipient[_tokenId] = _saleRecipient;
        emit NewSaleRecipient(_saleRecipient, _tokenId, false);
    }

    /// @dev Lets a module admin update the royalties paid on secondary token sales.
    function setRoyaltyBps(uint256 _royaltyBps) public onlyModuleAdmin {
        require(_royaltyBps <= MAX_BPS, "bps <= 10000.");

        royaltyBps = uint64(_royaltyBps);

        emit RoyaltyUpdated(_royaltyBps);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setFeeBps(uint256 _feeBps) public onlyModuleAdmin {
        require(_feeBps <= MAX_BPS, "bps <= 10000.");

        feeBps = uint120(_feeBps);

        emit PrimarySalesFeeUpdates(_feeBps);
    }

    /// @dev Lets a module admin restrict token transfers.
    function setRestrictedTransfer(bool _restrictedTransfer) external onlyModuleAdmin {
        transfersRestricted = _restrictedTransfer;

        emit TransfersRestricted(_restrictedTransfer);
    }

    /// @dev Lets a module admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyProtocolAdmin {
        contractURI = _uri;
    }

    //      =====   Getter functions  =====

    /// @dev Returns the current active mint condition for a given tokenId.
    function getTimestampForNextValidClaim(
        uint256 _tokenId,
        uint256 _index,
        address _claimer
    ) public view returns (uint256 nextValidTimestampForClaim) {
        uint256 timestampIndex = _index + claimConditions[_tokenId].timstampLimitIndex;
        uint256 timestampOfLastClaim = claimConditions[_tokenId].timestampOfLastClaim[_claimer][timestampIndex];

        unchecked {
            nextValidTimestampForClaim =
                timestampOfLastClaim +
                claimConditions[_tokenId].claimConditionAtIndex[_index].waitTimeInSecondsBetweenClaims;

            if (nextValidTimestampForClaim < timestampOfLastClaim) {
                nextValidTimestampForClaim = type(uint256).max;
            }
        }
    }

    /// @dev Returns the  mint condition for a given tokenId, at the given index.
    function getClaimConditionAtIndex(uint256 _tokenId, uint256 _index)
        external
        view
        returns (ClaimCondition memory mintCondition)
    {
        mintCondition = claimConditions[_tokenId].claimConditionAtIndex[_index];
    }

    //      =====   Internal functions  =====

    /// @dev Lets a module admin set mint conditions for a given tokenId.
    function resetClaimConditions(uint256 _tokenId, ClaimCondition[] calldata _conditions)
        internal
        returns (uint256 indexForCondition)
    {
        // make sure the conditions are sorted in ascending order
        uint256 lastConditionStartTimestamp;

        for (uint256 i = 0; i < _conditions.length; i++) {
            require(
                lastConditionStartTimestamp == 0 || lastConditionStartTimestamp < _conditions[i].startTimestamp,
                "startTimestamp must be in ascending order."
            );
            require(_conditions[i].maxClaimableSupply > 0, "max mint supply cannot be 0.");
            require(_conditions[i].quantityLimitPerTransaction > 0, "quantity limit cannot be 0.");

            claimConditions[_tokenId].claimConditionAtIndex[indexForCondition] = ClaimCondition({
                startTimestamp: _conditions[i].startTimestamp,
                maxClaimableSupply: _conditions[i].maxClaimableSupply,
                supplyClaimed: 0,
                quantityLimitPerTransaction: _conditions[i].quantityLimitPerTransaction,
                waitTimeInSecondsBetweenClaims: _conditions[i].waitTimeInSecondsBetweenClaims,
                pricePerToken: _conditions[i].pricePerToken,
                currency: _conditions[i].currency,
                merkleRoot: _conditions[i].merkleRoot
            });

            indexForCondition += 1;
            lastConditionStartTimestamp = _conditions[i].startTimestamp;
        }

        uint256 totalConditionCount = claimConditions[_tokenId].totalConditionCount;
        if (indexForCondition < totalConditionCount) {
            for (uint256 j = indexForCondition; j < totalConditionCount; j += 1) {
                delete claimConditions[_tokenId].claimConditionAtIndex[j];
            }
        }

        claimConditions[_tokenId].totalConditionCount = indexForCondition;
    }

    /// @dev Updates the `timstampLimitIndex` to reset the time restriction between claims, for a claim condition.
    function resetTimestampRestriction(uint256 _tokenId, uint256 _factor) internal {
        claimConditions[_tokenId].timstampLimitIndex += _factor;
    }

    /// @dev Checks whether a request to claim tokens obeys the active mint condition.
    function verifyClaimIsValid(
        uint256 _tokenId,
        uint256 _quantity,
        bytes32[] calldata _proofs,
        uint256 _conditionIndex,
        ClaimCondition memory _mintCondition
    ) internal view {
        require(_quantity > 0 && _quantity <= _mintCondition.quantityLimitPerTransaction, "invalid quantity claimed.");
        require(
            _mintCondition.supplyClaimed + _quantity <= _mintCondition.maxClaimableSupply,
            "exceed max mint supply."
        );

        uint256 timestampIndex = _conditionIndex + claimConditions[_tokenId].timstampLimitIndex;
        uint256 timestampOfLastClaim = claimConditions[_tokenId].timestampOfLastClaim[_msgSender()][timestampIndex];
        uint256 nextValidTimestampForClaim = getTimestampForNextValidClaim(_tokenId, _conditionIndex, _msgSender());
        require(timestampOfLastClaim == 0 || block.timestamp >= nextValidTimestampForClaim, "cannot claim yet.");

        if (_mintCondition.merkleRoot != bytes32(0)) {
            bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
            require(MerkleProof.verify(_proofs, _mintCondition.merkleRoot, leaf), "not in whitelist.");
        }
    }

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectClaimPrice(
        ClaimCondition memory _mintCondition,
        uint256 _quantityToClaim,
        uint256 _tokenId
    ) internal {
        if (_mintCondition.pricePerToken <= 0) {
            return;
        }

        uint256 totalPrice = _quantityToClaim * _mintCondition.pricePerToken;
        uint256 fees = (totalPrice * feeBps) / MAX_BPS;

        if (_mintCondition.currency == NATIVE_TOKEN) {
            require(msg.value == totalPrice, "must send total price.");
        } else {
            validateERC20BalAndAllowance(_msgSender(), _mintCondition.currency, totalPrice);
        }

        transferCurrency(_mintCondition.currency, _msgSender(), controlCenter.getRoyaltyTreasury(address(this)), fees);

        address recipient = saleRecipient[_tokenId];
        transferCurrency(
            _mintCondition.currency,
            _msgSender(),
            recipient == address(0) ? defaultSaleRecipient : recipient,
            totalPrice - fees
        );
    }

    /// @dev Transfers the tokens being claimed.
    function transferClaimedTokens(
        uint256 _claimConditionIndex,
        uint256 _tokenId,
        uint256 _quantityBeingClaimed
    ) internal {
        // Update the supply minted under mint condition.
        claimConditions[_tokenId].claimConditionAtIndex[_claimConditionIndex].supplyClaimed += _quantityBeingClaimed;
        // Update the claimer's next valid timestamp to mint. If next mint timestamp overflows, cap it to max uint256.
        uint256 timestampIndex = _claimConditionIndex + claimConditions[_tokenId].timstampLimitIndex;
        claimConditions[_tokenId].timestampOfLastClaim[_msgSender()][timestampIndex] = block.timestamp;

        _mint(_msgSender(), _tokenId, _quantityBeingClaimed, "");
    }

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }
        
        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                IWETH(nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeToken(_to, _amount);
            } else if (_to == address(this)) {
                require(_amount == msg.value, "native token value does not match bid amount.");
                IWETH(nativeTokenWrapper).deposit{ value: _amount }();
            } else {
                safeTransferNativeToken(_to, _amount);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Validates that `_addrToCheck` owns and has approved contract to transfer the appropriate amount of currency
    function validateERC20BalAndAllowance(
        address _addrToCheck,
        address _currency,
        uint256 _currencyAmountToCheckAgainst
    ) internal view {
        require(
            IERC20(_currency).balanceOf(_addrToCheck) >= _currencyAmountToCheckAgainst &&
                IERC20(_currency).allowance(_addrToCheck, address(this)) >= _currencyAmountToCheckAgainst,
            "insufficient currency balance or allowance."
        );
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }("");
        if (!success) {
            IWETH(nativeTokenWrapper).deposit{ value: value }();
            safeTransferERC20(nativeTokenWrapper, address(this), to, value);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if(_from == _to) {
            return;
        }
        uint256 balBefore = IERC20(_currency).balanceOf(_to);
        bool success = _from == address(this)
            ? IERC20(_currency).transfer(_to, _amount)
            : IERC20(_currency).transferFrom(_from, _to, _amount);
        uint256 balAfter = IERC20(_currency).balanceOf(_to);

        require(success && balAfter == balBefore + _amount, "failed to transfer currency.");
    }

    ///     =====   ERC 1155 functions  =====

    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burn(account, id, value);
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (transfersRestricted && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "restricted to TRANSFER_ROLE holders.");
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    ///     =====   Low level overrides  =====

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC1155).interfaceId || interfaceId == type(IERC2981).interfaceId;
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}

