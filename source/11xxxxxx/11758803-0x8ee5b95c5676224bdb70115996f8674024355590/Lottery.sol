// SPDX-License-Identifier: Apache2.0

pragma solidity ^0.5.0;


// 
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// 
interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// 
contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// 
/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   * @param _seed seed mixed into the input of the VRF.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal LINK;
  address private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

interface ILotteryDao {
    enum Era {
        EXPANSION,
        NEUTRAL,
        DEBT
    }

    function treasury() external view returns (address);
    function dollar() external view returns (address);
    function era() external view returns (Era, uint256);
    function epoch() external view returns (uint256);

    function requestDAI(address recipient, uint256 amount) external;
}

interface ILottery {
    function newGame(uint256[] calldata prizes) external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Lottery is ILottery, VRFConsumerBase {
    using SafeMathChainlink for uint256;

    struct Purchase {
        uint256 ticketStart;
        uint256 ticketEnd;
    }

    struct Game {
        uint256 issuedTickets;
        uint256 totalPurchases;
        bool winnersExtracted;
        bool ongoing;
        address[] winners;
        uint256[] winningTickets;
        uint256[] prizes;
        bool[] rewardsRedeemed;

        mapping(address => uint256[]) players;
        mapping(uint256 => Purchase) purchases;
    }
    
    struct LinkVRF {
        bytes32 keyHash;
        uint256 fee;
    }

    ILotteryDao public dao;

    LinkVRF private link;

    uint256 public gameLength;
    mapping(uint256 => Game) public games;

    constructor()
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) public
    {
        dao = ILotteryDao(0x0aF9087FE3e8e834F3339FE4bEE87705e84Fd488);
        link.fee = 2e18;
        link.keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    }

    event GameStarted(uint256 indexed gameIndex, uint256[] prizes);
    event TicketsPurchase(address indexed sender, uint256 indexed purchaseId, uint256 indexed lotteryId, uint256 ticketStart, uint256 ticketEnd);
    event LotteryEnded(uint256 indexed lotteryId);
    event WinningTicketsSorted(uint256 indexed lotteryId, uint256[] winningTickets);
    event RewardRedeemed(address indexed recipient, uint256 indexed lotteryId, uint256 reward);

    modifier onlyDAO() {
        require(msg.sender == address(dao), "Lottery: sender isn't the DAO");
        _;
    }

    function gameIndex() public view returns (uint256) {
        return gameLength.sub(1);
    }

    function treasury() public view returns (address) {
        return dao.treasury();
    }

    function dollar() public view returns (IERC20) {
        return IERC20(dao.dollar());
    }

    function getWinners(uint256 gameIndex) external view returns(address[] memory) {
        return games[gameIndex].winners;
    }

    function getWinningTickets(uint256 gameIndex) external view returns(uint256[] memory) {
        return games[gameIndex].winningTickets;
    }

    function getPrizes(uint256 gameIndex) external view returns(uint256[] memory) {
        return games[gameIndex].prizes;
    }

    function getIssuedTickets(uint256 gameIndex) external view returns (uint256) {
        return games[gameIndex].issuedTickets;
    }

    function getRedeemedPrizes(uint256 gameIndex) external view returns(bool[] memory) {
        return games[gameIndex].rewardsRedeemed;
    }

    function isOngoing(uint256 gameIndex) external view returns(bool) {
        return games[gameIndex].ongoing;
    }

    function areWinnersExtracted(uint256 gameIndex) external view returns(bool) {
        return games[gameIndex].winnersExtracted;
    }

    function getTotalPurchases(uint256 gameIndex) external view returns(uint256) {
        return games[gameIndex].totalPurchases;
    }

    function getPlayerPurchaseIndexes(uint256 gameIndex, address player) external view returns(uint256[] memory) {
        return games[gameIndex].players[player];
    }

    function getPurchase(uint256 gameIndex, uint256 purchaseIndex) external view returns(uint256, uint256) {
        return (games[gameIndex].purchases[purchaseIndex].ticketStart, games[gameIndex].purchases[purchaseIndex].ticketEnd);
    }

    function newGame(uint256[] calldata prizes) external onlyDAO {   
        require(LINK.balanceOf(address(this)) >= link.fee, "Lottery: Insufficient link balance");

        if (gameLength > 0)
            require(games[gameIndex()].winnersExtracted, "Lottery: can't start a new lottery before the winner is extracted");

        games[gameLength].ongoing = true;
        games[gameLength].prizes = prizes;
        games[gameLength].winners = new address[](prizes.length);
        games[gameLength].rewardsRedeemed = new bool[](prizes.length);

        emit GameStarted(gameLength, prizes);

        gameLength++;
    }

    function changeChainlinkData(bytes32 keyHash, uint256 fee) external onlyDAO {
        link.keyHash = keyHash;
        link.fee = fee;
    }

    function purchaseTickets(uint256 amount) external {
        require(amount >= 10e18, "Lottery: Insufficient purchase amount");

        uint256 finalizedAmount = amount.sub(amount % 10e18);

        Game storage game = games[gameIndex()];

        require(game.ongoing, "Lottery: No ongoing game");

        dollar().transferFrom(msg.sender, treasury(), finalizedAmount);

        uint256 newTickets = finalizedAmount.div(10e18);

        Purchase memory purchase = Purchase(
            game.issuedTickets,
            game.issuedTickets.add(newTickets) - 1
        );

        game.players[msg.sender].push(game.totalPurchases);
        game.purchases[game.totalPurchases] = purchase;

        game.issuedTickets = game.issuedTickets.add(newTickets);

        emit TicketsPurchase(msg.sender, game.totalPurchases, gameIndex(), purchase.ticketStart, purchase.ticketEnd);

        game.totalPurchases += 1;
    }

    function extractWinner() external {
        Game storage game = games[gameIndex()];
        require(game.ongoing, "Lottery: winner already extracted");

        (ILotteryDao.Era era, uint256 start) = dao.era();
        require(era == ILotteryDao.Era.EXPANSION && dao.epoch() >= start + 3, "Lottery: Can only extract during expansion");

        game.ongoing = false;

        requestRandomness(link.keyHash, link.fee, uint256(keccak256(abi.encodePacked(block.number, block.difficulty, now))));

        emit LotteryEnded(gameIndex());
    }

    function redeemReward(uint256 gameIndex, uint256 purchaseIndex, uint256 winningTicket) external {
        Game storage game = games[gameIndex];

        require(game.winnersExtracted, "Lottery: winner hasn't been extracted yet");
        
        bool found;
        uint256 index;
        for (uint256 i = 0; i < game.winningTickets.length; i++) {
            if (winningTicket == game.winningTickets[i]) {
                found = true;
                index = i;
                break;
            }
        }

        require(found, "Lottery: winning ticket not found");
        require(!game.rewardsRedeemed[index], "Lottery: Reward already redeemed");

        game.rewardsRedeemed[index] = true;

        Purchase storage purchase = game.purchases[game.players[msg.sender][purchaseIndex]];

        require(purchase.ticketStart <= winningTicket && purchase.ticketEnd >= winningTicket, "Lottery: purchase doesn't contain the winning ticket");

        dao.requestDAI(msg.sender, game.prizes[index]);

        game.winners[index] = msg.sender;

        emit RewardRedeemed(msg.sender, gameIndex, game.prizes[index]);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal {
        Game storage game = games[gameIndex()];
        
        for (uint256 i = 0; i < game.prizes.length; i++) {
            game.winningTickets.push(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randomness, game.prizes[i]))) % game.issuedTickets);
        }

        game.winnersExtracted = true;

        emit WinningTicketsSorted(gameIndex(), game.winningTickets);
    }

}
