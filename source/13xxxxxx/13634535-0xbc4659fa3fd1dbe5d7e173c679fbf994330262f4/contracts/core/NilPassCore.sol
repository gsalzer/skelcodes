// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IN.sol";
import "../interfaces/INilPass.sol";
import "../interfaces/IPricingStrategy.sol";

/**
 * @title NilPassCore contract
 * @author Tony Snark
 * @notice This contract provides basic functionalities to allow minting using the NilPass
 * @dev This contract should be used only for testing or testnet deployments
 */
abstract contract NilPassCore is ERC721Enumerable, ReentrancyGuard, AccessControl, INilPass, IPricingStrategy {
    uint128 public constant MAX_MULTI_MINT_AMOUNT = 32;
    uint128 public constant MAX_N_TOKEN_ID = 8888;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant DAO_ROLE = keccak256("DAO");

    IN public immutable n;
    uint16 public reserveMinted;
    uint256 public mintedOutsideNRange;
    address public masterMint;
    DerivativeParameters public derivativeParams;
    uint128 maxTokenId;

    struct DerivativeParameters {
        bool onlyNHolders;
        bool supportsTokenId;
        uint16 reservedAllowance;
        uint128 maxTotalSupply;
        uint128 maxMintAllowance;
    }

    event Minted(address to, uint256 tokenId);

    /**
     * @notice Construct an NilPassCore instance
     * @param name Name of the token
     * @param symbol Symbol of the token
     * @param n_ Address of your n instance (only for testing)
     * @param derivativeParams_ Parameters describing the derivative settings
     * @param masterMint_ Address of the master mint contract
     * @param dao_ Address of the NIL DAO
     */
    constructor(
        string memory name,
        string memory symbol,
        IN n_,
        DerivativeParameters memory derivativeParams_,
        address masterMint_,
        address dao_
    ) ERC721(name, symbol) {
        derivativeParams = derivativeParams_;
        require(derivativeParams.maxTotalSupply > 0, "NilPass:INVALID_SUPPLY");
        require(
            !derivativeParams.onlyNHolders ||
                (derivativeParams.onlyNHolders && derivativeParams.maxTotalSupply <= MAX_N_TOKEN_ID),
            "NilPass:INVALID_SUPPLY"
        );
        require(derivativeParams.maxTotalSupply >= derivativeParams.reservedAllowance, "NilPass:INVALID_ALLOWANCE");
        require(masterMint_ != address(0), "NilPass:INVALID_MASTERMINT");
        require(dao_ != address(0), "NilPass:INVALID_DAO");
        n = n_;
        masterMint = masterMint_;
        derivativeParams.maxMintAllowance = derivativeParams.maxMintAllowance < MAX_MULTI_MINT_AMOUNT
            ? derivativeParams.maxMintAllowance
            : MAX_MULTI_MINT_AMOUNT;
        maxTokenId = derivativeParams.maxTotalSupply > MAX_N_TOKEN_ID
            ? derivativeParams.maxTotalSupply
            : MAX_N_TOKEN_ID;
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DAO_ROLE, dao_);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(DAO_ROLE, DAO_ROLE);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Nil:ACCESS_DENIED");
        _;
    }

    modifier onlyDAO() {
        require(hasRole(DAO_ROLE, msg.sender), "Nil:ACCESS_DENIED");
        _;
    }

    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted.
     *         n token holders can use this function without using the n token holders allowance,
     *         this is useful when the allowance is fully utilized.
     * @param recipient Recipient of the mint
     * @param amount Amount of tokens to mint
     * @param paid Amount paid for the mint
     */
    function mint(
        address recipient,
        uint8 amount,
        uint256 paid,
        bytes calldata data
    ) public virtual override;

    /**
     * @notice Allow anyone to mint multiple tokens with the provided IDs if this pass is unrestricted.
     *         n token holders can use this function without using the n token holders allowance,
     *         this is useful when the allowance is fully utilized.
     */
    function mintTokenId(
        address,
        uint256[] calldata,
        uint256
    ) public view override {
        require(derivativeParams.supportsTokenId, "NilPass: TOKENID_MINTING_DISABLED");
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`
     */
    function _safeMint(address to, uint256 tokenId) internal virtual override {
        require(msg.sender == masterMint, "NilPass:INVALID_MINTER");
        super._safeMint(to, tokenId);
        emit Minted(to, tokenId);
    }

    /**
     * @notice Set the exclusivity flag to only allow N holders to mint
     * @param status Boolean to enable or disable N holder exclusivity
     */
    function setOnlyNHolders(bool status) public onlyAdmin {
        derivativeParams.onlyNHolders = status;
    }

    /**
     * @notice Calculate the currently available number of reserved tokens for n token holders
     * @return Reserved mint available
     */
    function nHoldersMintsAvailable() public view virtual returns (uint256);

    /**
     * @notice Calculate the currently available number of open mints
     * @return Open mint available
     */
    function openMintsAvailable() public view virtual returns (uint256);

    /**
     * @notice Calculate the total available number of mints
     * @return total mint available
     */
    function totalMintsAvailable() public view virtual override returns (uint256);

    function mintParameters() external view override returns (INilPass.MintParams memory) {
        return
            INilPass.MintParams({
                reservedAllowance: derivativeParams.reservedAllowance,
                maxTotalSupply: derivativeParams.maxTotalSupply,
                openMintsAvailable: openMintsAvailable(),
                totalMintsAvailable: totalMintsAvailable(),
                nHoldersMintsAvailable: nHoldersMintsAvailable(),
                nHolderPriceInWei: getNextPriceForNHoldersInWei(1),
                openPriceInWei: getNextPriceForOpenMintInWei(1),
                totalSupply: totalSupply(),
                onlyNHolders: derivativeParams.onlyNHolders,
                maxMintAllowance: derivativeParams.maxMintAllowance,
                supportsTokenId: derivativeParams.supportsTokenId
            });
    }

    /**
     * @notice Check if a token with an Id exists
     * @param tokenId The token Id to check for
     */
    function tokenExists(uint256 tokenId) external view override returns (bool) {
        return _exists(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function maxTotalSupply() external view override returns (uint256) {
        return derivativeParams.maxTotalSupply;
    }

    function reservedAllowance() public view returns (uint16) {
        return derivativeParams.reservedAllowance;
    }

    function getNextPriceForNHoldersInWei(uint256) public view virtual override returns (uint256);

    function getNextPriceForOpenMintInWei(uint256) public view virtual override returns (uint256);

    function canMint(address account, bytes calldata data) public view virtual override returns (bool);
}

