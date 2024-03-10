// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./IINFPermissionManager.sol";

contract INFPermissionManager is AccessControlEnumerable, IINFPermissionManager {
    // Admin role can add operators
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // KYCed investors
    mapping(address => bool) public whitelistedInvestors; 

    // Fee exemptions
    uint256 private constant NONE_EXEMPT = 0; // default user purchase from swap 
    uint256 private constant SENDER_EXEMPT = 4; // from allowed swap contract/router
    uint256 private constant RECIPIENT_EXEMPT = 3; // normal erc20 transfer
    uint256 private constant SENDER_RECIPIENT_EXEMPT = 7; // add/remove liquidity with swap contract/router
    mapping(address => uint256) public isFeeExempt;

    // Fee related
    address public feeRecipient;
    uint256 private constant DEFAULT_FEE = 1e3;
    uint256 public fee = DEFAULT_FEE;
    uint256 private FEE_MAXIMUM = 1e4;
    uint256 private FEE_PRECISION = 1e5;
    mapping(address => uint256) public tokenFees; // token-based specific fee adjustment, by default flat fee

    // EIP712 related variables and functions
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    bytes32 private constant APPROVAL_SIGNATURE_HASH =
        keccak256("SetInvestorWhitelisting(address investor,bool approved,uint256 deadline)");

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    // solhint-disable-next-line var-name-mixedcase
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    modifier onlyRoleFor(bytes32 role, address from) {
        _checkRole(role, from);
        _;
    }

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, keccak256("PermissionManager"), chainId, address(this)));
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    constructor(address to, address _feeRecipient) {
        // Set default roles
        _setupRole(DEFAULT_ADMIN_ROLE, to);
        _setupRole(ADMIN_ROLE, to);

        // Recipient
        feeRecipient = _feeRecipient;
        emit LogSetFeeAndFeeRecipient(DEFAULT_FEE, _feeRecipient);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    function setFeeExempt(address user, bool senderExempt, bool recipientExempt) override public onlyRole(OPERATOR_ROLE) {
        uint256 status = NONE_EXEMPT;

        if (senderExempt && recipientExempt) {
            status = SENDER_RECIPIENT_EXEMPT;
        } else if (senderExempt) {
            status = SENDER_EXEMPT;
        } else if (recipientExempt) {
            status = RECIPIENT_EXEMPT;
        }

        isFeeExempt[user] = status;
        emit LogFeeExempt(user, status);
    }

    function getStatusAndFee(
        address sender,
        address receiver
    ) 
        public
        override
        view
        returns (
            bool exempt,
            uint256,
            uint256,
            address
        )
    {
        uint256 feeExemptStatusSender = 0;
        uint256 feeExemptStatusReceiver = 0;

        if (!whitelistedInvestors[sender]) {
            feeExemptStatusSender = isFeeExempt[sender];
            require(feeExemptStatusSender > 0, "Sender not whitelisted");
        }

        if (!whitelistedInvestors[receiver]) {
            feeExemptStatusReceiver = isFeeExempt[receiver];
            require(feeExemptStatusReceiver > 0, "Receiver not whitelisted");
        }

        // Should be exempt if sender OR receiver is exempt
        exempt = (feeExemptStatusSender % 3 == 1 || feeExemptStatusReceiver % 2 == 1);

        // Set token specific fee if available
        uint256 tokenFee = fee;
        if (tokenFees[msg.sender] > 0) {
            tokenFee = tokenFees[msg.sender];
        }

        return (exempt, tokenFee, FEE_PRECISION, feeRecipient);
    }

    /// @notice Sets or adjusts current fee for all tokens
    /// @param _fee The flat fee for all tokens
    /// @param _feeRecipient The account to receive all fees
    function setFeeAndFeeRecipient(uint256 _fee, address _feeRecipient) public onlyRole(ADMIN_ROLE) {
        require(_fee <= FEE_MAXIMUM, "Fee too high");
        fee = _fee;
        feeRecipient = _feeRecipient;
        emit LogSetFeeAndFeeRecipient(_fee, _feeRecipient);
    }

    /// @notice Sets or adjusts fee for one token only
    /// @param _fee The individual fee for this token
    /// @param _tokenId The address for the token to set the fee
    function setTokenFee(uint256 _fee, address _tokenId) public onlyRole(ADMIN_ROLE) {
        require(_fee <= FEE_MAXIMUM, "Fee too high");
        tokenFees[_tokenId] = _fee;
        emit LogSetTokenFee(_fee, _tokenId);
    }

    function whitelistInvestors(address[] calldata investors, bool[] calldata approved) public onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < investors.length; i++) {
            _whitelistInvestor(investors[i], approved[i]);
        }
    }

    function whitelistInvestor(address investor, bool approved) override public onlyRole(OPERATOR_ROLE) {
        _whitelistInvestor(investor, approved);
    }

    function _whitelistInvestor(address investor, bool approved) private {
        whitelistedInvestors[investor] = approved;
        emit LogWhiteListInvestor(investor, approved);
    }

    /// @notice Approves or revokes whitelisting for investors
    /// @param operator The address of the operator that approves or revokes access.
    /// @param investor The address who gains or loses access.
    /// @param approved If True approves access. If False revokes access.
    /// @param deadline Time when signature expires to prohibit replays.
    /// @param v Part of the signature. (See EIP-191)
    /// @param r Part of the signature. (See EIP-191)
    /// @param s Part of the signature. (See EIP-191)
    function setInvestorWhitelisting(
        address operator,
        address investor,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyRoleFor(OPERATOR_ROLE, operator) {
        // Checks
        require(investor != address(0), "PermissionMgr: Investor not set");

        // Also, ecrecover returns address(0) on failure. So we check this, even if the modifier should prevent this:
        require(operator != address(0), "PermissionMgr: Operator cannot be 0");

        require(deadline >= block.timestamp && deadline <= (block.timestamp + 1 weeks), 'PermissionMgr: EXPIRED');

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            APPROVAL_SIGNATURE_HASH,
                            investor,
                            approved,
                            deadline
                        )
                    )
                )
            );

        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == operator, "PermissionMgr: Invalid Signature");

        _whitelistInvestor(investor, approved);
    }
}

