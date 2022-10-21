pragma solidity ^0.5.11;

import "./ownable.sol";
import "./AccessControl.sol";
//import "./GridOwnership.sol";
//import "./safemath.sol";
//import "./console.sol";

contract GridBase is Ownable, AccessControl {

    //using SafeMath for uint256;

    uint public levelUpFee = 0.01 ether;
    uint public limitGridsEachtime = 100;
    uint public discountGridsCount = 0;

    //uint fee;

    struct structGird {
        uint16 x;
        uint16 y;
        uint level;
        address payable owner;
        address payable inviter;
    }

    structGird[] public arr_struct_grid;

    mapping (address => uint) public mappingOwnerGridCount;
    mapping (uint16 => uint) public mappingPositionToGirdId;

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    address payable public authorAddress;
    address payable public foundationAddress;

    /// @notice Creates the main CryptoKitties smart contract instance.
    constructor () public {
        // Starts paused.
        paused = true;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;
        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It's up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewContractAddress(address _v2Address) external onlyCEO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    function setAuthorAddress(address payable _address) external onlyCEO whenPaused {
        require(_address != address(0), "authorAddress can not be empty");
        authorAddress = _address;
    }

    function setFoundationAddress(address payable _address) external onlyCEO whenPaused {
        require(_address != address(0), "foundationAddress can not be empty");
        foundationAddress = _address;
    }

    /*/// @notice Returns all the relevant information about a specific kitty.
    /// @param _id The ID of the kitty of interest.
    function getGrid(uint256 _id)
        external
        view
        returns (
        uint16 x,
        uint16 y,
        uint256 level
    ) {
        structGird memory _grid = arr_struct_grid[_id];

        x = uint16(_grid.x);
        y = uint16(_grid.y);
        level = uint256(_grid.level);
    }*/

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can't have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpause() public onlyCEO whenPaused {
        require(newContractAddress == address(0), "set newContractAddress first");
        require(authorAddress != address(0), "set authorAddress first");
        require(foundationAddress != address(0), "set foundationAddress first");

        // Actually unpause the contract.
        super.unpause();
    }

    function withdraw() external onlyOwner whenPaused {
        owner.transfer(address(this).balance);
    }

    function setLevelUpFee(uint _fee) external onlyCLevel whenPaused {
        levelUpFee = _fee;
    }

    function setlimitGridsEachtime(uint _limit) external onlyCLevel whenPaused {
        limitGridsEachtime = _limit;
    }


  function getContractStatus() external view onlyCLevel returns(uint, uint, uint) {
    return (levelUpFee, limitGridsEachtime, address(this).balance);
  }

  function getLevelUpFee() external view whenNotPaused returns(uint) {
    return levelUpFee;
  }

  function getLimitGridsEachtime() external view whenNotPaused returns(uint) {
    return limitGridsEachtime;
  }

  function getContractBalance() external view onlyCLevel returns(uint) {
    return address(this).balance;
  }
}

