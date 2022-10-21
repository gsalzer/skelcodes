// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

import './Prophets.sol';

contract ProphetsArrival is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using ECDSA for bytes32;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ============ Constants ============ */

    uint256 public constant PROPHET_PRICE = 25e16; // 0.25 ETH
    uint256 public constant DENOM_FLOOR_PRICE_BABL = 5e16; // 0.05 ETH
    address payable public constant BABYLON_TREASURY = payable(0xD7AAf4676F0F52993cb33aD36784BF970f0E1259); // treasury

    bytes32 private constant BID_TYPEHASH = keccak256('Bid(uint256 _bid,uint256 _nonce)');

    /* ============ Immutables ============ */

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20Upgradeable public immutable weth;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    Prophets public immutable prophetsNft;

    // 1636992000 Monday, 15 November 2021, 8:00:00 AM in Timezone (GMT -8:00) Pacific Time (US & Canada)
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable eventStartsTS;
    // 16 November 2021, 8:00:00 AM in Timezone (GMT -8:00) Pacific Time (US & Canada)
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable secondRoundTS;
    // 17 November 2021, 8:00:00 AM in Timezone (GMT -8:00) Pacific Time (US & Canada)
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable thirdRoundTS;
    // 19 November 2021, 4:00:00 PM in Timezone (GMT -8:00) Pacific Time (US & Canada)
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable eventEndsTS;

    /* ============ Structs ============ */

    /* ============ Private State Variables ============ */

    /* ============ Public State Variables ============ */

    bytes32 public settlersRoot;
    bytes32 public firstRoot;
    bytes32 public secondRoot;
    mapping(address => bool) public mintedProphet;
    mapping(address => uint256) public nonces;

    /* ============ Events ============ */

    /* ============ Constructor ============ */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        Prophets _prophets,
        IERC20Upgradeable _weth,
        uint256 _eventStartsTS
    ) initializer {
        require(address(_prophets) != address(0), '0x0 NFT address');
        require(address(_weth) != address(0), '0x0 WETH address');

        prophetsNft = _prophets;
        weth = _weth;

        eventStartsTS = _eventStartsTS;
        secondRoundTS = eventStartsTS + 1 days;
        thirdRoundTS = secondRoundTS + 1 days;
        eventEndsTS = thirdRoundTS + 2 days + 8 hours;
    }

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    /* ============ Modifiers ============ */

    modifier isEventOpen() {
        require(prophetsNft.prophetsSupply() < prophetsNft.PROPHETS(), 'All prophets are minted');
        require(block.timestamp < eventEndsTS && block.timestamp >= eventStartsTS, 'Event is not open');
        _;
    }

    modifier isEventOver() {
        require(block.timestamp > eventEndsTS, 'Event is not over');
        _;
    }

    /* ============ External Write Functions ============ */

    function addUsersToWhitelist(
        bytes32 _settlers,
        bytes32 _firstRoundUsers,
        bytes32 _secondRoundUsers
    ) external onlyOwner {
        settlersRoot = _settlers;
        firstRoot = _firstRoundUsers;
        secondRoot = _secondRoundUsers;
    }

    function mintProphet(bytes32[] calldata _proof) external payable isEventOpen nonReentrant {
        bool isSettler = _proof.length != 0 ?  MerkleProof.verify(_proof, settlersRoot, leaf(msg.sender)): false;
        require(msg.value == PROPHET_PRICE || (msg.value == 0 && isSettler && !mintedProphet[msg.sender] ), 'msg.value has to be 0.25');

        if(isSettler && msg.value == 0) {
          mintedProphet[msg.sender] = true;
        }

        prophetsNft.mintProphet(msg.sender);
    }

    function batchMintGreat(
        uint256[] memory _id,
        uint256[] memory _amount,
        uint256[] memory _bid,
        uint256[] memory _nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public onlyOwner isEventOver {
        for (uint256 i = 0; i < _id.length; i++) {
            mintGreat(_id[i], _amount[i], _bid[i], _nonce[i], v[i], r[i], s[i]);
        }
    }

    function mintGreat(
        uint256 _id,
        uint256 _amount,
        uint256 _bid,
        uint256 _nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public onlyOwner isEventOver {
        bytes32 hash = keccak256(abi.encode(BID_TYPEHASH, address(this), _bid, _nonce)).toEthSignedMessageHash();
        address signer = ECDSA.recover(hash, v, r, s);

        require(_bid >= _amount, 'Amount is greater than bid');
        require(_amount >= getStartingPrice(_id), 'Bid is too low');
        // Note that bits are 0-indexed, thus bit 1 is at position 0, bit 2 is at position 1, etc.
        require((nonces[signer] & (1 << (_nonce - 1))) == 0, 'Nonce is used');

        weth.safeTransferFrom(signer, BABYLON_TREASURY, _amount);
        prophetsNft.mintGreatProphet(signer, _id);
        nonces[signer] = nonces[signer] | (1 << (_nonce - 1));
    }

    function withdrawAll() external payable onlyOwner isEventOver {
        require(address(this).balance > 0, 'No funds');

        AddressUpgradeable.sendValue(BABYLON_TREASURY, address(this).balance);
    }

    /* ============ External View Functions ============ */

    function getStartingPrice(uint256 _id) public view returns (uint256) {
        Prophets.Attributes memory attr = prophetsNft.getAttributes(_id);
        return (attr.bablLoot * DENOM_FLOOR_PRICE_BABL) / 1e18;
    }

    /* ============ Internal Write Functions ============ */

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /* ============ Internal View Functions ============ */


    function leaf(address _user) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user));
    }
}

contract ProphetsArrivalV2 is ProphetsArrival {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        Prophets _prophets,
        IERC20Upgradeable _weth,
        uint256 _eventStartsTS
    )
        ProphetsArrival(_prophets, _weth, _eventStartsTS)
    {}
}

