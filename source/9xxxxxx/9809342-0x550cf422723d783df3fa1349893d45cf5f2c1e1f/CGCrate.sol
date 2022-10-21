pragma solidity ^0.5.0;
import "./Ownable.sol";

/**
 * @title CGCrate
 * @dev Smart Contract for Crate Reward
 */
contract CGCrate is  Ownable {

  // official CG site address to send ether
  address payable public officialSite;

  // start time for open sale
  uint256 public startTime;

  // CGC bounty ration, 0.01 ether = 1 CGC
  uint256 public bountyRatio = 10 finney;

  // price for each crate
  uint256[9] public cratePrice = [20 ether, 13 ether, 6 ether, 4 ether, 3 ether, 250 finney, 50 finney, 500 finney, 50 finney ];

  // remain crate counts
  uint[7] public crateSales = [12, 27, 52, 97, 25, 500, 2500];

  // should use this
  mapping(address => uint256) remains;

  // event for new crate
  event CrateOpen(address indexed user, uint crateType, uint256 bounty);

  constructor(address payable _officialSite, uint256 _startTime) public {
    officialSite = _officialSite;
    startTime = _startTime;
    owner = msg.sender;
  }

  /**
  * @dev update offical CG site wallet address
  * @param _officialSite address for new address
  */
  function updateOfficialSite(address payable _officialSite) public onlyOwnerOrController {
    require(_officialSite != address(0));
    officialSite = _officialSite;
  }

  /**
  * @dev update bounty ratio
  * @param _bountyRatio uint256 for new ratio
  */
  function updateBountyRatio(uint256 _bountyRatio) public onlyOwnerOrController {
    require(_bountyRatio != 0);
    bountyRatio = _bountyRatio;
  }

  /**
  * @dev get CrateSale counts
  */
  function getCratePrices() public view returns(uint[9] memory) {
    return cratePrice;
  }

  /**
  * @dev update CrateSale
  * @param _type uint256 for Crate Type
  * @param _price uint256 for Crate Price
  */
  function updateCratePrice(uint256 _type, uint256 _price) public onlyOwnerOrController {
    require(_type < 9);
    cratePrice[_type] = _price;
  }

  /**
  * @dev get CrateSale counts
  */
  function getCrateSales() public view returns(uint[7] memory) {
    return crateSales;
  }

  /**
  * @dev update CrateSale
  * @param _type uint256 for Crate Type
  * @param _count uint256 for Crate Count
  */
  function updateCrateSale(uint256 _type, uint256 _count) public onlyOwnerOrController {
    require(_type < 7);
    crateSales[_type] = _count;
  }

  /** update startTime
  * @dev update bounty ratio
  * @param _startTime uint256 for startTime
  */
  function updateStartTime(uint256 _startTime) public onlyOwnerOrController {
    startTime = _startTime;
  }

  /**
  * @dev Crate Open
  * @param crateType uint type of Crate
  */
  function openCrate(uint crateType) public payable {
    require(crateType < 9);
    require(cratePrice[crateType] == msg.value);
    require(now >= startTime);

    if(crateType< 7 && crateSales[crateType] == 0)
      revert();

    officialSite.transfer(msg.value);
    uint total = remains[msg.sender] + msg.value;
    uint bounty = total / bountyRatio;
    remains[msg.sender] = total % bountyRatio;

    if(crateType < 7)
      crateSales[crateType] --;

    emit CrateOpen(msg.sender, crateType, bounty);
  }
}
