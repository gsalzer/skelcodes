/*
███████╗ ██████╗ ██╗  ██╗     ██████╗  █████╗ ███╗   ███╗███████╗
██╔════╝██╔═══██╗╚██╗██╔╝    ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
█████╗  ██║   ██║ ╚███╔╝     ██║  ███╗███████║██╔████╔██║█████╗  
██╔══╝  ██║   ██║ ██╔██╗     ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
██║     ╚██████╔╝██╔╝ ██╗    ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝     ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./IFoxGame.sol";
import "./IFoxGameCarrot.sol";
import "./IFoxGameNFT.sol";

contract FoxGames_v1_1 is IFoxGame, OwnableUpgradeable, IERC721ReceiverUpgradeable,
                    PausableUpgradeable, ReentrancyGuardUpgradeable {
  using ECDSAUpgradeable for bytes32; // signature verification helpers
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet; // iterable staked tokens

  /****
   * Thanks for checking out our contracts.
   * If you're interested in working with us, you can find us on
   * discord (https://discord.gg/foxgame). We also have a bug bounty
   * program and are available at @officialfoxgame or bugs@fox.game.
   ***/

  // Maximum advantage score for both foxes and hunters
  uint8 public constant MAX_ADVANTAGE = 8;

  // Foxes take a 20% tax on all rabbiot $CARROT claimed
  uint8 public constant RABBIT_CLAIM_TAX_PERCENTAGE = 20;

  // Hunters have a 5% chance of stealing a fox as it unstakes
  uint8 private hunterStealFoxProbabilityMod;

  // Cut between hunters and foxes
  uint8 private hunterTaxCutPercentage;

  // Total hunter marksman scores staked
  uint16 public totalMarksmanPointsStaked;

  // Total fox cunning scores staked
  uint16 public totalCunningPointsStaked;

  // Number of Rabbit staked
  uint32 public totalRabbitsStaked;

  // Number of Foxes staked
  uint32 public totalFoxesStaked;

  // Number of Hunters staked
  uint32 public totalHuntersStaked;

  // The last time $CARROT was claimed
  uint48 public lastClaimTimestamp;

  // Rabbits must have 2 days worth of $CARROT to unstake or else it's too cold
  uint48 public constant RABBIT_MINIMUM_TO_EXIT = 2 days;

  // There will only ever be (roughly) 2.5 billion $CARROT earned through staking
  uint128 public constant MAXIMUM_GLOBAL_CARROT = 2500000000 ether;

  // amount of $CARROT earned so far
  uint128 public totalCarrotEarned;

  // Collected rewards before any foxes staked
  uint128 public unaccountedFoxRewards;

  // Collected rewards before any foxes staked
  uint128 public unaccountedHunterRewards;

  // Amount of $CARROT due for each cunning point staked
  uint128 public carrotPerCunningPoint;

  // Amount of $CARROT due for each marksman point staked
  uint128 public carrotPerMarksmanPoint; 

  // Rabbit earn 10000 $CARROT per day
  uint128 public constant RABBIT_EARNING_RATE = 115740740740740740; // 10000 ether / 1 days;

  // Hunters earn 20000 $CARROT per day
  uint128 public constant HUNTER_EARNING_RATE = 231481481481481470; // 20000 ether / 1 days;

  // Staking maps for both time-based and ad-hoc-earning-based
  struct TimeStake { uint16 tokenId; uint48 time; address owner; }
  struct EarningStake { uint16 tokenId; uint128 earningRate; address owner; }

  // Events
  event TokenStaked(string kind, uint16 tokenId, address owner);
  event TokenUnstaked(string kind, uint16 tokenId, address owner, uint128 earnings);
  event FoxStolen(uint16 foxTokenId, address thief, address victim);

  // Signature to prove membership and randomness
  address private signVerifier;

  // External contract reference
  IFoxGameNFT private foxNFT;
  IFoxGameCarrot private foxCarrot;

  // Staked rabbits
  mapping(uint16 => TimeStake) public rabbitStakeByToken;

  // Staked foxes
  mapping(uint8 => EarningStake[]) public foxStakeByCunning; // foxes grouped by cunning
  mapping(uint16 => uint16) public foxHierarchy; // fox location within cunning group

  // Staked hunters
  mapping(uint16 => TimeStake) public hunterStakeByToken;
  mapping(uint8 => EarningStake[]) public hunterStakeByMarksman; // hunter grouped by markman
  mapping(uint16 => uint16) public hunterHierarchy; // hunter location within marksman group

  // FoxGame membership date
  mapping(address => uint48) public membershipDate;
  mapping(address => uint32) public memberNumber;
  event MemberJoined(address member, uint32 memberCount);
  uint32 public membershipCount;

  // External contract reference
  IFoxGameNFT private foxNFTGen1;

  // Mapping for staked tokens
  mapping(address => EnumerableSetUpgradeable.UintSet) private _stakedTokens;

  // Bool to store staking data
  bool private _storeStaking;

  // Use seed instead
  uint256 private _seed;

  /**
   * Fetch and replace seeds
   */
  function _getSeed(uint16 offset, uint256 offset2) internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      _seed,
      offset,
      offset2
    )));
  }

  /**
   * Fetch and replace seeds
   */
  function getSeed(uint16 offset) external view returns (uint256) {
    require(msg.sender == address(foxNFTGen1), "not approved");
    return _getSeed(offset, 0);
  }

  /**
   * Update seeds used for randomness.
   */
  function setSeed(uint256 seed) external onlyOwner {
    _seed = seed;
  }

  /**
   * Init contract upgradability (only called once).
   */
  function initialize() public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __Pausable_init();

    hunterStealFoxProbabilityMod = 20; // 100/5=20
    hunterTaxCutPercentage = 30; // whole number %

    // Pause staking on init
    _pause();
  }

  /**
   * FoxGames welcomes you to the club!
   */
  function joinFoxGames() external {
    require(tx.origin == msg.sender, "eos only");
    require(membershipDate[msg.sender] == 0, "already joined");
    membershipDate[msg.sender] = uint48(block.timestamp);
    memberNumber[msg.sender] = membershipCount;
    emit MemberJoined(msg.sender, membershipCount);
    membershipCount += 1;
  }

  /**
   * Hash together proof of membership and randomness.
   */
  function getSigningHash(address recipient, bool membership, uint48 expiration, uint256 seed) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(recipient, membership, expiration, seed));
  }

  /**
   * Validate mebership and randomness.
   */
  function isValidSignature(address recipient, bool membership, uint48 expiration, uint256 seed, bytes memory sig) public view returns (bool) {
    bytes32 message = getSigningHash(recipient, membership, expiration, seed).toEthSignedMessageHash();
    return ECDSAUpgradeable.recover(message, sig) == signVerifier;
  }

  /**
   * Return the appropriate contract interface for token.
   */
  function getTokenContract(uint16 tokenId) private view returns (IFoxGameNFT) {
    return tokenId <= 10000 ? foxNFT : foxNFTGen1;
  }

  /**
   * Adds Rabbits, Foxes and Hunters to their respective safe homes.
   * @param account the address of the staker
   * @param tokenIds the IDs of the Rabbit and Foxes to stake
   */
  function stakeTokens(address account, uint16[] calldata tokenIds) external whenNotPaused nonReentrant _updateEarnings {
    require((account == msg.sender && tx.origin == msg.sender) || msg.sender == address(foxNFTGen1), "not approved");
    
    IFoxGameNFT nftContract;
    for (uint16 i = 0; i < tokenIds.length; i++) {

      // Thieves abound and leave minting gaps
      if (tokenIds[i] == 0) {
        continue;
      }

      // Add to respective safe homes
      nftContract = getTokenContract(tokenIds[i]);
      IFoxGameNFT.Kind kind = _getKind(nftContract, tokenIds[i]);
      if (kind == IFoxGameNFT.Kind.RABBIT) {
        _addRabbitToKeep(account, tokenIds[i]);
      } else if (kind == IFoxGameNFT.Kind.FOX) {
        _addFoxToDen(nftContract, account, tokenIds[i]);
      } else { // HUNTER
        _addHunterToCabin(nftContract, account, tokenIds[i]);
      }

      // Transfer into safe house
      if (msg.sender != address(foxNFTGen1)) { // dont do this step if its a mint + stake
        require(nftContract.ownerOf(tokenIds[i]) == msg.sender, "only token owners can stake");
        nftContract.transferFrom(msg.sender, address(this), tokenIds[i]);
      }
    }
  }

  /**
   * Adds Rabbit to the Keep.
   * @param account the address of the staker
   * @param tokenId the ID of the Rabbit to add to the Barn
   */
  function _addRabbitToKeep(address account, uint16 tokenId) internal {
    rabbitStakeByToken[tokenId] = TimeStake({
      owner: account,
      tokenId: tokenId,
      time: uint48(block.timestamp)
    });
    totalRabbitsStaked += 1;
    if (_storeStaking) _stakedTokens[account].add(tokenId); // add staked ref
    emit TokenStaked("RABBIT", tokenId, account);
  }

  /**
   * Add Fox to the Den.
   * @param account the address of the staker
   * @param tokenId the ID of the Fox
   */
  function _addFoxToDen(IFoxGameNFT nftContract, address account, uint16 tokenId) internal {
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    totalCunningPointsStaked += cunning;
    // Store fox by rating
    foxHierarchy[tokenId] = uint16(foxStakeByCunning[cunning].length);
    // Add fox to their cunning group
    foxStakeByCunning[cunning].push(EarningStake({
      owner: account,
      tokenId: tokenId,
      earningRate: carrotPerCunningPoint
    }));
    totalFoxesStaked += 1;
    if (_storeStaking) _stakedTokens[account].add(tokenId); // add staked ref
    emit TokenStaked("FOX", tokenId, account);
  }

  /**
   * Adds Hunter to the Cabin.
   * @param account the address of the staker
   * @param tokenId the ID of the Hunter
   */
  function _addHunterToCabin(IFoxGameNFT nftContract, address account, uint16 tokenId) internal {
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    totalMarksmanPointsStaked += marksman;
    // Store hunter by rating
    hunterHierarchy[tokenId] = uint16(hunterStakeByMarksman[marksman].length);
    // Add hunter to their marksman group
    hunterStakeByMarksman[marksman].push(EarningStake({
      owner: account,
      tokenId: tokenId,
      earningRate: carrotPerMarksmanPoint
    }));
    hunterStakeByToken[tokenId] = TimeStake({
      owner: account,
      tokenId: tokenId,
      time: uint48(block.timestamp)
    });
    totalHuntersStaked += 1;
    if (_storeStaking) _stakedTokens[account].add(tokenId); // add staked ref
    emit TokenStaked("HUNTER", tokenId, account);
  }

  /**
   * Realize $CARROT earnings and optionally unstake tokens.
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   * @param membership wheather user is membership or not
   * @param originSeed account seed
   * @param sig signature
   */
  function claimRewardsAndUnstake(uint16[] calldata tokenIds, bool unstake, bool membership, uint48 expiration, uint256 originSeed, bytes memory sig) external whenNotPaused nonReentrant _updateEarnings {
    require(tx.origin == msg.sender, "eos only");
    require(isValidSignature(msg.sender, membership, expiration, originSeed, sig), "invalid signature");

    uint256 seed;
    uint128 reward;
    IFoxGameNFT.Kind kind;
    IFoxGameNFT nftContract;
    uint48 time = uint48(block.timestamp);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      nftContract = getTokenContract(tokenIds[i]);
      kind = _getKind(nftContract, tokenIds[i]);
      seed = _getSeed(tokenIds[i], originSeed);
      if (kind == IFoxGameNFT.Kind.RABBIT) {
        reward += _claimRabbitsFromKeep(nftContract, tokenIds[i], unstake, time, seed);
      } else if (kind == IFoxGameNFT.Kind.FOX) {
        reward += _claimFoxFromDen(nftContract, tokenIds[i], unstake, seed);
      } else { // HUNTER
        reward += _claimHunterFromCabin(nftContract, tokenIds[i], unstake, time);
      }
    }
    if (reward != 0) {
      foxCarrot.mint(msg.sender, reward);
    }
  }

  /**
   * realize $CARROT earnings for a single Rabbit and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked foxes
   * if unstaking, there is a 50% chance all $CARROT is stolen
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Rabbit to claim earnings from
   * @param unstake whether or not to unstake the Rabbit
   * @param time currnet block time
   * @param seed account seed
   * @return reward - the amount of $CARROT earned
   */
  function _claimRabbitsFromKeep(IFoxGameNFT nftContract, uint16 tokenId, bool unstake, uint48 time, uint256 seed) internal returns (uint128 reward) {
    TimeStake memory stake = rabbitStakeByToken[tokenId];
    require(stake.owner == msg.sender, "only token owners can unstake");
    require(!(unstake && block.timestamp - stake.time < RABBIT_MINIMUM_TO_EXIT), "rabbits need 2 days of carrot");

    // Calcuate time-based rewards
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      reward = (time - stake.time) * RABBIT_EARNING_RATE;
    } else if (stake.time <= lastClaimTimestamp) {
      // stop earning additional $CARROT if it's all been earned
      reward = (lastClaimTimestamp - stake.time) * RABBIT_EARNING_RATE;
    }

    // Update reward based on game rules
    if (unstake) {
      // 50% chance of all $CARROT stolen
      if (((seed >> 245) % 2) == 0) {
        _payTaxToPredators(reward, true);
        reward = 0;
      }
      delete rabbitStakeByToken[tokenId];
      totalRabbitsStaked -= 1;
      if (_storeStaking) _stakedTokens[stake.owner].remove(tokenId); // delete staked ref
      // send back Rabbit
      nftContract.safeTransferFrom(address(this), msg.sender, tokenId, "");
    } else {
      // Pay foxes their tax
      _payTaxToPredators(reward * RABBIT_CLAIM_TAX_PERCENTAGE / 100, false);
      reward = reward * (100 - RABBIT_CLAIM_TAX_PERCENTAGE) / 100;
      // Update last earned time
      rabbitStakeByToken[tokenId] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time
      });
    }

    emit TokenUnstaked("RABBIT", tokenId, stake.owner, reward);
  }

  /**
   * realize $CARROT earnings for a single Fox and optionally unstake it
   * foxes earn $CARROT proportional to their Alpha rank
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param unstake whether or not to unstake the Fox
   * @param seed account seed
   * @return reward - the amount of $CARROT earned
   */
  function _claimFoxFromDen(IFoxGameNFT nftContract, uint16 tokenId, bool unstake, uint256 seed) internal returns (uint128 reward) {
    require(nftContract.ownerOf(tokenId) == address(this), "must be staked to claim rewards");
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    EarningStake memory stake = foxStakeByCunning[cunning][foxHierarchy[tokenId]];
    require(stake.owner == msg.sender, "only token owners can unstake");

    // Calculate advantage-based rewards
    reward = (cunning) * (carrotPerCunningPoint - stake.earningRate);
    if (unstake) {
      totalCunningPointsStaked -= cunning; // Remove Alpha from total staked
      EarningStake memory lastStake = foxStakeByCunning[cunning][foxStakeByCunning[cunning].length - 1];
      foxStakeByCunning[cunning][foxHierarchy[tokenId]] = lastStake; // Shuffle last Fox to current position
      foxHierarchy[lastStake.tokenId] = foxHierarchy[tokenId];
      foxStakeByCunning[cunning].pop(); // Remove duplicate
      delete foxHierarchy[tokenId]; // Delete old mapping
      totalFoxesStaked -= 1;
      if (_storeStaking) _stakedTokens[stake.owner].remove(tokenId); // delete staked ref

      // Determine if Fox should be stolen by hunter
      address recipient = msg.sender;
      if (((seed >> 245) % hunterStealFoxProbabilityMod) == 0) {
        recipient = _randomHunterOwner(seed);
        if (recipient == address(0x0)) {
          recipient = msg.sender;
        } else if (recipient != msg.sender) {
          emit FoxStolen(tokenId, recipient, msg.sender);
        }
      }
      nftContract.safeTransferFrom(address(this), recipient, tokenId, "");
    } else {
      // Update earning rate
      foxStakeByCunning[cunning][foxHierarchy[tokenId]] = EarningStake({
        owner: msg.sender,
        tokenId: tokenId,
        earningRate: carrotPerCunningPoint
      });
    }

    emit TokenUnstaked("FOX", tokenId, stake.owner, reward);
  }

  /**
   * realize $CARROT earnings for a single Fox and optionally unstake it
   * foxes earn $CARROT proportional to their Alpha rank
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param unstake whether or not to unstake the Fox
   * @param time currnet block time
   * @return reward - the amount of $CARROT earned
   */
  function _claimHunterFromCabin(IFoxGameNFT nftContract, uint16 tokenId, bool unstake, uint48 time) internal returns (uint128 reward) {
    require(foxNFTGen1.ownerOf(tokenId) == address(this), "must be staked to claim rewards");
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    EarningStake memory earningStake = hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]];
    require(earningStake.owner == msg.sender, "only token owners can unstake");

    // Calculate advantage-based rewards
    reward = (marksman) * (carrotPerMarksmanPoint - earningStake.earningRate);
    if (unstake) {
      totalMarksmanPointsStaked -= marksman; // Remove Alpha from total staked
      EarningStake memory lastStake = hunterStakeByMarksman[marksman][hunterStakeByMarksman[marksman].length - 1];
      hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]] = lastStake; // Shuffle last Fox to current position
      hunterHierarchy[lastStake.tokenId] = hunterHierarchy[tokenId];
      hunterStakeByMarksman[marksman].pop(); // Remove duplicate
      delete hunterHierarchy[tokenId]; // Delete old mapping
      if (_storeStaking) _stakedTokens[earningStake.owner].remove(tokenId); // delete staked ref
    } else {
      // Update earning rate
      hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]] = EarningStake({
        owner: msg.sender,
        tokenId: tokenId,
        earningRate: carrotPerMarksmanPoint
      });
    }

    // Calcuate time-based rewards
    TimeStake memory timeStake = hunterStakeByToken[tokenId];
    require(timeStake.owner == msg.sender, "only token owners can unstake");
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      reward += (time - timeStake.time) * HUNTER_EARNING_RATE;
    } else if (timeStake.time <= lastClaimTimestamp) {
      // stop earning additional $CARROT if it's all been earned
      reward += (lastClaimTimestamp - timeStake.time) * HUNTER_EARNING_RATE;
    }
    if (unstake) {
      delete hunterStakeByToken[tokenId];
      totalHuntersStaked -= 1;
      // Unstake to owner
      foxNFTGen1.safeTransferFrom(address(this), msg.sender, tokenId, "");
    } else {
      // Update last earned time
      hunterStakeByToken[tokenId] = TimeStake({
        owner: msg.sender,
        tokenId: tokenId,
        time: time
      });
    }

    emit TokenUnstaked("HUNTER", tokenId, earningStake.owner, reward);
  }

  /** 
   * Add $CARROT claimable pots for hunters and foxes
   * @param amount $CARROT to add to the pot
   * @param includeHunters true if hunters take a cut of the spoils
   */
  function _payTaxToPredators(uint128 amount, bool includeHunters) internal {
    uint128 amountDueFoxes = amount;

    // Hunters take their cut first
    if (includeHunters) {
      uint128 amountDueHunters = amount * hunterTaxCutPercentage / 100;
      amountDueFoxes -= amountDueHunters;

      // Update hunter pools
      if (totalMarksmanPointsStaked == 0) {
        unaccountedHunterRewards += amountDueHunters;
      } else {
        carrotPerMarksmanPoint += (amountDueHunters + unaccountedHunterRewards) / totalMarksmanPointsStaked;
        unaccountedHunterRewards = 0;
      }
    }

    // Update fox pools
    if (totalCunningPointsStaked == 0) {
      unaccountedFoxRewards += amountDueFoxes;
    } else {
      // makes sure to include any unaccounted $CARROT 
      carrotPerCunningPoint += (amountDueFoxes + unaccountedFoxRewards) / totalCunningPointsStaked;
      unaccountedFoxRewards = 0;
    }
  }

  /**
   * Tracks $CARROT earnings to ensure it stops once 2.4 billion is eclipsed
   */
  modifier _updateEarnings() {
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      uint48 time = uint48(block.timestamp);
      uint48 elapsed = time - lastClaimTimestamp;
      totalCarrotEarned +=
        (elapsed * totalRabbitsStaked * RABBIT_EARNING_RATE) +
        (elapsed * totalHuntersStaked * HUNTER_EARNING_RATE);
      lastClaimTimestamp = time;
    }
    _;
  }

  /**
   * Get token kind (rabbit, fox, hunter)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(IFoxGameNFT nftContract, uint16 tokenId) internal view returns (IFoxGameNFT.Kind) {
    return nftContract.getTraits(tokenId).kind;
  }

  /**
   * gets the alpha score for a Fox
   * @param tokenId the ID of the Fox to get the alpha score for
   * @return the alpha score of the Fox (5-8)
   */
  function _getAdvantagePoints(IFoxGameNFT nftContract, uint16 tokenId) internal view returns (uint8) {
    return MAX_ADVANTAGE - nftContract.getTraits(tokenId).advantage; // alpha index is 0-3
  }

  /**
   * chooses a random Fox thief when a newly minted token is stolen
   * @param seed a random value to choose a Fox from
   * @return the owner of the randomly selected Fox thief
   */
  function randomFoxOwner(uint256 seed) external view returns (address) {
    if (totalCunningPointsStaked == 0) {
      return address(0x0); // use 0x0 to return to msg.sender
    }
    // choose a value from 0 to total alpha staked
    uint256 bucket = (seed & 0xFFFFFFFF) % totalCunningPointsStaked;
    uint256 cumulative;
    seed >>= 32;
    // loop through each cunning bucket of Foxes
    for (uint8 i = MAX_ADVANTAGE - 3; i <= MAX_ADVANTAGE; i++) {
      cumulative += foxStakeByCunning[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Fox with that alpha score
      return foxStakeByCunning[i][seed % foxStakeByCunning[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * Chooses a random Hunter to steal a fox.
   * @param seed a random value to choose a Hunter from
   * @return the owner of the randomly selected Hunter thief
   */
  function _randomHunterOwner(uint256 seed) internal view returns (address) {
    if (totalMarksmanPointsStaked == 0) {
      return address(0x0); // use 0x0 to return to msg.sender
    }
    // choose a value from 0 to total alpha staked
    uint256 bucket = (seed & 0xFFFFFFFF) % totalMarksmanPointsStaked;
    uint256 cumulative;
    seed >>= 32;
    // loop through each cunning bucket of Foxes
    for (uint8 i = MAX_ADVANTAGE - 3; i <= MAX_ADVANTAGE; i++) {
      cumulative += hunterStakeByMarksman[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Fox with that alpha score
      return hunterStakeByMarksman[i][seed % hunterStakeByMarksman[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * Hydrate existing staked token owners into owner mapping.
   */
  function storeStakedUsers() external onlyOwner {
    // Rabbits
    TimeStake memory timeStake;
    for (uint16 tokenId = 0; tokenId < 10000; tokenId++) {
      timeStake = rabbitStakeByToken[tokenId];
      if (timeStake.tokenId != 0) {
        _stakedTokens[timeStake.owner].add(tokenId);
      }
    }

    uint256 earningLength;
    uint8 earningIdx;
    EarningStake memory earningStake;
    for (uint8 advantage = 5; advantage < 9; advantage++) {
      // Foxes
      earningLength = foxStakeByCunning[advantage].length;
      for (earningIdx = 5; earningIdx < earningLength; earningIdx++) {
        earningStake = foxStakeByCunning[advantage][earningIdx];
        _stakedTokens[earningStake.owner].add(earningStake.tokenId);
      }

      // Hunters
      earningLength = hunterStakeByMarksman[advantage].length;
      for (earningIdx = 5; earningIdx < earningLength; earningIdx++) {
        earningStake = hunterStakeByMarksman[advantage][earningIdx];
        _stakedTokens[earningStake.owner].add(earningStake.tokenId);
      }
    }

    _storeStaking = true;
  }

  /**
   * Realize $CARROT earnings and optionally unstake tokens.
   * @param tokenIds the IDs of the tokens to claim earnings from
   */
  function calculateRewards(uint16[] calldata tokenIds) external view returns (uint256[] memory) {
    require(tx.origin == msg.sender, "eos only");

    IFoxGameNFT.Kind kind;
    IFoxGameNFT nftContract;
    uint256[] memory rewards = new uint256[](tokenIds.length);
    uint48 time = uint48(block.timestamp);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      nftContract = getTokenContract(tokenIds[i]);
      kind = _getKind(nftContract, tokenIds[i]);
      if (kind == IFoxGameNFT.Kind.RABBIT) {
        rewards[i] = _calculateRabbitReward(tokenIds[i], time);
      } else if (kind == IFoxGameNFT.Kind.FOX) {
        rewards[i] = _calculateFoxReward(nftContract, tokenIds[i]);
      } else { // HUNTER
        rewards[i] = _calculateHunterReward(nftContract, tokenIds[i], time);
      }
    }

    return rewards;
  }

  /**
   * Calculate rabbit reward.
   * @param tokenId the ID of the Rabbit to claim earnings from
   * @param time currnet block time
   * @return reward - the amount of $CARROT earned
   */
  function _calculateRabbitReward(uint16 tokenId, uint48 time) internal view returns (uint256) {
    TimeStake memory stake = rabbitStakeByToken[tokenId];
    require(stake.owner == msg.sender, "only token owners can unstake");

    // Calcuate time-based rewards
    uint256 reward = 0;
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      reward = (time - stake.time) * RABBIT_EARNING_RATE;
    } else if (stake.time <= lastClaimTimestamp) {
      // stop earning additional $CARROT if it's all been earned
      reward = (lastClaimTimestamp - stake.time) * RABBIT_EARNING_RATE;
    }

    // Fox tax
    return reward * (100 - RABBIT_CLAIM_TAX_PERCENTAGE) / 100;
  }

  /**
   * Calculate fox reward.
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @return reward - the amount of $CARROT earned
   */
  function _calculateFoxReward(IFoxGameNFT nftContract, uint16 tokenId) internal view returns (uint256) {
    uint8 cunning = _getAdvantagePoints(nftContract, tokenId);
    EarningStake memory stake = foxStakeByCunning[cunning][foxHierarchy[tokenId]];
    require(stake.owner == msg.sender, "only token owners can unstake");

    // Calculate advantage-based rewards
    return (cunning) * (carrotPerCunningPoint - stake.earningRate);
  }

  /**
   * Calculate hunter reward.
   * @param nftContract Contract belonging to the token
   * @param tokenId the ID of the Fox to claim earnings from
   * @param time currnet block time
   * @return reward - the amount of $CARROT earned
   */
  function _calculateHunterReward(IFoxGameNFT nftContract, uint16 tokenId, uint48 time) internal view returns (uint256) {
    uint8 marksman = _getAdvantagePoints(nftContract, tokenId);
    EarningStake memory earningStake = hunterStakeByMarksman[marksman][hunterHierarchy[tokenId]];
    require(earningStake.owner == msg.sender, "only token owners can unstake");

    // Calculate advantage-based rewards
    uint256 reward = 0;
    reward = (marksman) * (carrotPerMarksmanPoint - earningStake.earningRate);

    // Calcuate time-based rewards
    TimeStake memory timeStake = hunterStakeByToken[tokenId];
    require(timeStake.owner == msg.sender, "only token owners can unstake");
    if (totalCarrotEarned < MAXIMUM_GLOBAL_CARROT) {
      reward += (time - timeStake.time) * HUNTER_EARNING_RATE;
    } else if (timeStake.time <= lastClaimTimestamp) {
      reward += (lastClaimTimestamp - timeStake.time) * HUNTER_EARNING_RATE;
    }

    return reward;
  }

  /**
   * Toggle staking / unstaking.
   */
  function togglePaused() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  /**
   * Sets a new signature verifier.
   */
  function setSignVerifier(address verifier) external onlyOwner {
    signVerifier = verifier;
  }

  /**
   * Update the NFT GEN 0 contract address.
   */
  function setNFTContract(address _address) external onlyOwner {
    foxNFT = IFoxGameNFT(_address);
  }

  /**
   * Update the NFT GEN 1 contract address.
   */
  function setNFTGen1Contract(address _address) external onlyOwner {
    foxNFTGen1 = IFoxGameNFT(_address);
  }

  /**
   * Update the utility token contract address.
   */
  function setCarrotContract(address _address) external onlyOwner {
    foxCarrot = IFoxGameCarrot(_address);
  }

  /**
   * Update the balance between Hunter and Fox tax distribution. 
   */
  function setHunterTaxCutPercentage(uint8 percentCut) external onlyOwner {
    hunterTaxCutPercentage = percentCut;
  }

  /**
   * Update the liklihood foxes will get stolen by hunters.
   */
  function setHunterStealFoxPropabilityMod(uint8 mod) external onlyOwner {
    hunterStealFoxProbabilityMod = mod;
  }

  /**
   * List staked tokens by user.
   */
  function depositsOf(address account) external view returns (uint16[] memory) {
    EnumerableSetUpgradeable.UintSet storage depositSet = _stakedTokens[account];
    uint16[] memory tokenIds = new uint16[] (depositSet.length());

    for (uint16 i; i < depositSet.length(); i++) {
      tokenIds[i] = uint16(depositSet.at(i));
    }

    return tokenIds;
  }

  /**
   * Store staking mapping from owners to tokens.
   */
  function setStoredStaking(bool value) external onlyOwner {
    _storeStaking = value;
  }

  /**
   * Interface support to allow player staking.
   */
  function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {    
    require(from == address(0x0), "only allow directly from mint");
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }
}
