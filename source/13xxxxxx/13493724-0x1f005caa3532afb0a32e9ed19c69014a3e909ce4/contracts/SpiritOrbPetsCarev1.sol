// SPDX-License-Identifier: MIT
//
// Spirit Orb Pets Pet Care Contract for v1 Pets
// Developed by:  Heartfelt Games LLC
//
// This is the first of many contracts that allows Spirit Orb Pets to be
// interactable in the Spirit Orb Pets blockchain-based game.
//

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICareToken is IERC20 {
  function mintToApprovedContract(uint256 amount, address mintToAddress) external;
  function burn(address sender, uint256 paymentAmount) external;
}

interface ISpiritOrbPetsv1 is IERC721, IERC721Enumerable {
  function getPetInfo(uint16 id) external view returns (
    uint8 level,
    bool active
  );

  function getPetCooldowns(uint16 id) external view returns (
    uint64 cdPlay,
    uint64 cdFeed,
    uint64 cdClean,
    uint64 cdTrain,
    uint64 cdDaycare
  );

  function getPausedState() external view returns (bool);
  function getMaxPetLevel() external view returns (uint8);
  function petName(uint16 id) external view returns (string memory);

  function setPetName(uint16 id, string memory name) external;
  function setPetLevel(uint16 id, uint8 level) external;
  function setPetActive(uint16 id, bool active) external;
  function setPetCdPlay(uint16 id, uint64 cdPlay) external;
  function setPetCdFeed(uint16 id, uint64 cdFeed) external;
  function setPetCdClean(uint16 id, uint64 cdClean) external;
  function setPetCdTrain(uint16 id, uint64 cdTrain) external;
  function setPetCdDaycare(uint16 id, uint64 cdDaycare) external;
}

contract SpiritOrbPetsCarev1 is Ownable {

    ISpiritOrbPetsv1 public SOPv1;
    ICareToken public CareToken;

    uint256 public _timeUntilLevelDown = 72 hours; // 259200 uint value in seconds

    event Activated(address sender, uint16 id);
    event Deactivated(address sender, uint16 id);
    event PlayedWithPet(address sender, uint16 id, bool levelDownEventOccurred);
    event FedPet(address sender, uint16 id, uint careTokensToPay, bool levelDownEventOccurred);
    event CleanedPet(address sender,uint16 id, bool levelDownEventOccurred);
    event TrainedPet(address sender, uint16 id);
    event SentToDaycare(address sender, uint16 id, uint daysToPayFor);

    modifier notAtDaycare(uint16 id) {
      ( , , , , uint cdDaycare ) = SOPv1.getPetCooldowns(id);
      require(cdDaycare <= block.timestamp, "Cannot perform action while pet is at daycare.");
      _;
    }

    function setTimeUntilLevelDown(uint256 newTime) external onlyOwner {
      _timeUntilLevelDown = newTime;
    }

    function getTrueLevel(uint16 id) public view returns (uint8) {
      (uint64 cdPlay, uint64 cdFeed, uint64 cdClean, , ) = SOPv1.getPetCooldowns(id);
      (uint8 level, ) = SOPv1.getPetInfo(id);
      uint64 blockTimestamp = uint64(block.timestamp);
      bool hungry = cdFeed <= blockTimestamp;
      bool dirty = cdClean + _timeUntilLevelDown <= blockTimestamp;
      bool unhappy = cdPlay + _timeUntilLevelDown <= blockTimestamp;

      // if completely neglected, pet's level resets to 1
      if (hungry && dirty && unhappy && level != 30) {
        level = 1;
      }
      // Separated into 3 so it doesn't go below 1
      if (hungry && level > 1 && level != 30) {
        level = level - 1;
      }
      if (dirty && level > 1 && level != 30) {
        level = level - 1;
      }
      if (unhappy && level > 1 && level != 30) {
        level = level - 1;
      }
      return level;
    }

    /*
    / @dev Enables all pet interactions.
    */
    function activatePet(uint16 id) external {
      ( , bool active) = SOPv1.getPetInfo(id);
      require(!SOPv1.getPausedState(), "Pet adoption has not yet begun.");
      require(SOPv1.ownerOf(id) == msg.sender);
      require(!active, "Pet is already active!");

      resetPetCooldowns(id);

      emit Activated(msg.sender, id);
    }

    function resetPetCooldowns(uint16 id) internal {
      (uint64 cdPlay, , , , ) = SOPv1.getPetCooldowns(id);
      SOPv1.setPetActive(id, true);
      if (cdPlay == 0) SOPv1.setPetCdPlay(id, uint64(block.timestamp));
      SOPv1.setPetCdFeed(id, uint64(block.timestamp + 1 hours));
      SOPv1.setPetCdClean(id, uint64(block.timestamp + 3 days - 1 hours));
      SOPv1.setPetCdTrain(id, uint64(block.timestamp + 23 hours));
    }

    /**
    * @dev Deactivating the pet will reduce the level to 1 unless they are at max level
    */
    function deactivatePet(uint16 id) external {
      ( , , , , uint cdDaycare) = SOPv1.getPetCooldowns(id);
      (  uint8 level, bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender);
      require(active, "Pet is not active yet.");

      SOPv1.setPetActive(id, false);
      if (cdDaycare > uint64(block.timestamp)) {
        SOPv1.setPetCdDaycare(id, 0);
        SOPv1.setPetCdPlay(id, uint64(block.timestamp));
        // everything else is reset during reactivation
      }
      if (level < SOPv1.getMaxPetLevel()) {
        SOPv1.setPetLevel(id, 1);
      }

      emit Deactivated(msg.sender, id);
    }

    function levelDown(uint16 id) internal {
      (uint64 cdPlay, uint64 cdFeed, uint64 cdClean, , ) = SOPv1.getPetCooldowns(id);
      (uint8 level, ) = SOPv1.getPetInfo(id);
      uint64 blockTimestamp = uint64(block.timestamp);
      bool hungry = cdFeed <= blockTimestamp;
      bool dirty = cdClean + _timeUntilLevelDown <= blockTimestamp;
      bool unhappy = cdPlay + _timeUntilLevelDown <= blockTimestamp;

      if (level > 1 && level != 30) {
        SOPv1.setPetLevel(id, level - 1);
      }

      // if completely neglected, pet's level resets to 1
      if (hungry && dirty && unhappy && level != 30) {
        SOPv1.setPetLevel(id, 1);
      }
    }

    function levelUp(uint16 id) internal {
      (uint8 level, ) = SOPv1.getPetInfo(id);
      if (level < SOPv1.getMaxPetLevel()) {
        SOPv1.setPetLevel(id, level + 1);
      }
    }

    /**
    * @dev Playing with your pet is one of the primary ways to earn CARE tokens.
    */
    function playWithPet(uint16 id) external {
      (uint64 cdPlay, uint64 cdFeed, uint64 cdClean, , ) = SOPv1.getPetCooldowns(id);
      ( , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can play with it!");
      require(active, "Pet needs to be active to receive CARE tokens.");
      require(cdFeed >= uint64(block.timestamp), "Pet is too hungry to play.");
      require(cdClean >= uint64(block.timestamp), "Pet is too dirty to play.");
      require(cdPlay <= uint64(block.timestamp), "You can only redeem CARE tokens every 23 hours.");

      // send CARE tokens to owner
      CareToken.mintToApprovedContract(10 * 10 ** 18, msg.sender);

      // check if the pet was played with on time, if not, level down
      bool levelDownEventOccurred = false;
      if (cdPlay + _timeUntilLevelDown <= uint64(block.timestamp)) {
        levelDown(id);
        levelDownEventOccurred = true;
      }

      // set new time for playing with pet
      SOPv1.setPetCdPlay(id, uint64(block.timestamp + 23 hours));

      emit PlayedWithPet(msg.sender, id, levelDownEventOccurred);
    }

    /**
    * @dev Sets the cdFeed timer when you activate it. The user must approve
    * @dev token use on the ERC20 contract so that this contract can accept the
    * @dev transaction.  The pet will level down if you took too long to feed it.
    */
    function feedPet(uint16 id, uint careTokensToPay) external notAtDaycare(id) {
      ( , uint64 cdFeed, uint64 cdClean,  ,  ) = SOPv1.getPetCooldowns(id);
      ( , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can feed it!");
      require(active, "Pet needs to be active to feed it.");
      require(cdClean >= uint64(block.timestamp), "Pet is too dirty to eat.");
      require(careTokensToPay <= 15, "You should not overfeed your pet.");
      require(careTokensToPay >= 5, "Too little CARE sent to feed pet.");
      // Skip checking if it's too soon to feed the pet.  We can just
      // control this from the front end.  This also allows players to
      // top off their pet's feeding meter whenever they want.

      // take CARE tokens from owner
      uint paymentAmount = careTokensToPay * 10 ** 18;
      // Token must be approved from the CARE token's address by the owner
      CareToken.burn(msg.sender, paymentAmount);

      uint64 blockTimestamp = uint64(block.timestamp);

      // check if the pet was fed on time, if not, level down
      bool levelDownEventOccurred = false;
      if (cdFeed <= blockTimestamp) {
        levelDown(id);
        levelDownEventOccurred = true;
      }

      // set new time for feeding pet
      // if pet isn't starving yet, just add the time, otherwise set the time to now + tokens/5 days
      if (cdFeed > blockTimestamp) {
        uint64 newFeedTime = cdFeed + uint64(careTokensToPay/5 * 1 days);
        SOPv1.setPetCdFeed(id, newFeedTime);
        // Pet cannot be full for more than 3 days max
        if (newFeedTime > blockTimestamp + 3 days) {
          SOPv1.setPetCdFeed(id, blockTimestamp + 3 days);
        }
      } else {
        SOPv1.setPetCdFeed(id, uint64(blockTimestamp + (careTokensToPay/5 * 1 days))); //5 tokens per 24hrs up to 72hrs
      }

      emit FedPet(msg.sender, id, careTokensToPay, levelDownEventOccurred);
    }

    /**
    * @dev Cleaning your pet is a secondary way to earn CARE tokens.  If you don't clean
    * @dev your pet in time, your pet will level down.
    */
    function cleanPet(uint16 id) external {
      ( , , uint64 cdClean, , ) = SOPv1.getPetCooldowns(id);
      ( , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can clean it!");
      require(active, "Pet needs to be active to clean.");
      uint64 blockTimestamp = uint64(block.timestamp);
      require(cdClean <= blockTimestamp, "Pet is not dirty yet.");

      // send CARE tokens to owner
      CareToken.mintToApprovedContract(30 * 10 ** 18, msg.sender);

      // check if the pet was cleaned on time, if not, level down
      bool levelDownEventOccurred = false;
      if ((cdClean + _timeUntilLevelDown) <= blockTimestamp) {
        levelDown(id);
        levelDownEventOccurred = true;
      }

      SOPv1.setPetCdClean(id, blockTimestamp + 3 days - 1 hours);
      emit CleanedPet(msg.sender, id, levelDownEventOccurred);
    }

    /**
    * @dev Training your pet is the primary way to level it up.  You can do it once per
    * @dev day - 1 hour, 23 hours after activating it.
    */
    function trainPet(uint16 id) external notAtDaycare(id) {
      ( , uint64 cdFeed, uint64 cdClean, uint64 cdTrain, ) = SOPv1.getPetCooldowns(id);
      ( uint8 level, bool active) = SOPv1.getPetInfo(id);
      uint64 blockTimestamp = uint64(block.timestamp);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can train it!");
      require(active, "Pet needs to be active to train.");
      require(cdFeed >= blockTimestamp, "Pet is too hungry to train.");
      require(cdClean >= blockTimestamp, "Pet is too dirty to train.");
      require(cdTrain <= blockTimestamp, "Pet is too tired to train.");

      if (level < 30) {

        // take CARE tokens from owner
        uint paymentAmount = 10 * 10 ** 18;
        // Token must be approved from the CARE token's address by the owner
        CareToken.burn(msg.sender, paymentAmount);

        levelUp(id);
      } else {
        // send CARE tokens to owner
        CareToken.mintToApprovedContract(10 * 10 ** 18, msg.sender);
      }

      SOPv1.setPetCdTrain(id, blockTimestamp + 23 hours);
      emit TrainedPet(msg.sender, id);
    }

    /**
    * @dev Sending your pet to daycare is intended to freeze your pet's status if you
    * @dev plan to be away from it for a while. There is no refund for bringing your
    * @dev pet back early.
    */
    function sendToDaycare(uint16 id, uint daysToPayFor) external notAtDaycare(id) {
      (uint8 level , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can send it to daycare!");
      require(active, "Pet needs to be active to send it to daycare.");
      require(daysToPayFor >= 1, "Minimum 1 day of daycare required.");
      require(daysToPayFor <= 30, "You cannot send pet to daycare for that long.");

      // pet MUST NOT have a level-down event occuring; daycare would otherwise by-pass it
      require(getTrueLevel(id) == level, "Pet cannot go to daycare if it has been neglected.");

      // take CARE tokens from owner
      // each day is 10 whole CARE tokens
      uint paymentAmount = daysToPayFor * 10 * 10 ** 18;
      // Token must be approved from the CARE token's address by the owner
      CareToken.burn(msg.sender, paymentAmount);

      // calculate how many days to send pet to daycare
      uint timeToSendPet = daysToPayFor * 1 days;

      // set timer for daycare and caretaking activities
      uint64 timeToSetCareCooldowns = uint64(block.timestamp + timeToSendPet);
      SOPv1.setPetCdDaycare(id, timeToSetCareCooldowns);
      SOPv1.setPetCdPlay(id, timeToSetCareCooldowns);
      SOPv1.setPetCdFeed(id, timeToSetCareCooldowns);
      SOPv1.setPetCdClean(id, timeToSetCareCooldowns + 3 days - 1 hours);
      SOPv1.setPetCdTrain(id, timeToSetCareCooldowns);

      emit SentToDaycare(msg.sender, id, daysToPayFor);
    }

    /**
    * @dev Brings pet back from daycare. Funds are not refunded and cooldowns are
    * @dev reset as if from the state of activation again.
    */
    function retrieveFromDaycare(uint16 id) external {
      ( ,  ,  ,  , uint cdDaycare) = SOPv1.getPetCooldowns(id);
      ( , bool active) = SOPv1.getPetInfo(id);
      uint64 blockTimestamp = uint64(block.timestamp);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet send it to daycare!");
      require(active, "Pet needs to be active to retrieve it from daycare.");
      require(cdDaycare > blockTimestamp, "Cannot perform action if pet is not in daycare.");

      resetPetCooldowns(id);
      // Additional exceptions for daycare; allow play
      SOPv1.setPetCdDaycare(id, 0);
      SOPv1.setPetCdPlay(id, blockTimestamp);
    }

    /**
    * @dev Allows the user to rename their pet.  If the pet has a name already,
    * @dev it will cost 100 CARE tokens.
    * @dev The front-end can limit number of characters displayed from the output
    * @dev of getName
    */
    function namePet(uint16 id, string memory newName) external {
      ( , bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can name it!");
      require(active, "Pet needs to be active to name it.");
      require(keccak256(abi.encodePacked(newName)) != keccak256(abi.encodePacked(SOPv1.petName(id))), "Pet already has this name.");

      if (keccak256(abi.encodePacked(SOPv1.petName(id))) == keccak256(abi.encodePacked(""))) {
        SOPv1.setPetName(id, newName);
      } else {
        // take CARE tokens from owner
        uint paymentAmount = 100 * 10 ** 18;
        // Token must be approved from the CARE token's address by the owner
        CareToken.burn(msg.sender, paymentAmount);

        SOPv1.setPetName(id, newName);
      }
    }

    /*
    * @dev This is a secondary way to level up more quickly if you want to bypass the
    * @dev main way. It costs more CARE, but is not limited by time cooldowns.
    */
    function levelUpWithCare(uint16 id, uint levelsToGoUp) external notAtDaycare(id) {
      (uint8 level, bool active) = SOPv1.getPetInfo(id);
      require(SOPv1.ownerOf(id) == msg.sender, "Only the owner of the pet can level it up!");
      require(active, "Pet needs to be active to level up.");
      require(level < 30, "Pet is already at max level.");
      require(level + uint8(levelsToGoUp) <= 30, "This would make your pet exceed level 30 and waste tokens.");

      // take CARE tokens from owner
      // each level is 100 whole CARE tokens
      uint paymentAmount = levelsToGoUp * 100 * 10 ** 18;
      // Token must be approved from the CARE token's address by the owner
      CareToken.burn(msg.sender, paymentAmount);

      for (uint i = 0; i < levelsToGoUp; i++) {
        levelUp(id);
      }
    }

    function setCareToken(address careTokenAddress) external onlyOwner {
      CareToken = ICareToken(careTokenAddress);
    }

    function setSOPV1Contract(address sopv1Address) external onlyOwner {
      SOPv1 = ISpiritOrbPetsv1(sopv1Address);
    }

}

