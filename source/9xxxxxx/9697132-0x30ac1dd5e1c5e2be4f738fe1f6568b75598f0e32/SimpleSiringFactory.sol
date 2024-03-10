pragma solidity ^0.6.2;





/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <dete@axiomzen.co> (https://github.com/dete)
abstract contract ERC721 {
    // Required methods
    function totalSupply() virtual public view returns (uint256 total);
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) virtual external view returns (address owner);
    function approve(address _to, uint256 _tokenId) virtual external;
    function transfer(address _to, uint256 _tokenId) virtual external;
    function transferFrom(address _from, address _to, uint256 _tokenId) virtual external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    // function name() public view returns (string name);
    // function symbol() public view returns (string symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) virtual external view returns (bool);
}



abstract contract KittyCoreInterface is ERC721  {
    uint256 public autoBirthFee;
    address public saleAuction;
    address public siringAuction;

    function breedWithAuto(uint256 _matronId, uint256 _sireId) virtual public payable;
    function createSaleAuction(uint256 _kittyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) virtual external;
    function createSiringAuction(uint256 _kittyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) virtual external;
    function supportsInterface(bytes4 _interfaceID) virtual override external view returns (bool);
    function approve(address _to, uint256 _tokenId) virtual override external;
}



/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}





/**
 * @title AccessControl
 * @dev AccessControl contract sets roles and permissions
 * Owner - has full control over contract
 * Operator - has limited sub set of allowed actions over contract
 * Multiple operators can be added by owner to delegate a number of tasks in the contract
 */
contract AccessControl {
  address payable public owner;
  mapping(address => bool) public operators;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  event OperatorAdded(
    address indexed operator
  );

  event OperatorRemoved(
    address indexed operator
  );

  constructor(address payable _owner) public {
    if(_owner == address(0)) {
      owner = msg.sender;
    } else {
      owner = _owner;
    }
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'Invalid sender');
    _;
  }

  modifier onlyOwnerOrOperator() {
    require(msg.sender == owner || operators[msg.sender] == true, 'Invalid sender');
    _;
  }

  function transferOwnership(address payable _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address payable _newOwner) internal {
    require(_newOwner != address(0), 'Invalid address');
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function addOperator(address payable _operator) public onlyOwner {
    require(operators[_operator] != true, 'Operator already exists');
    operators[_operator] = true;

    emit OperatorAdded(_operator);
  }

  function removeOperator(address payable _operator) public onlyOwner {
    require(operators[_operator] == true, 'Operator already exists');
    delete operators[_operator];

    emit OperatorRemoved(_operator);
  }

  function destroy() public virtual onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address payable _recipient) public virtual onlyOwner {
    selfdestruct(_recipient);
  }
}



/**
 * @title Pausable
 * @dev The Pausable contract can be paused and started by owner
 */
contract Pausable is AccessControl {
    event Pause();
    event Unpause();

    bool public paused = false;

    constructor(address payable _owner) AccessControl(_owner) public {}

    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract should be paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}











abstract contract AuctionInterface {
    function cancelAuction(uint256 _tokenId) virtual external;
}



 /**
 * @title CKProxy
 * @dev CKProxy contract allows owner or operator to proxy call to CK Core contract to manage kitties owned by contract
 */

contract CKProxy is Pausable {
  KittyCoreInterface public kittyCore;
  AuctionInterface public saleAuction;
  AuctionInterface public siringAuction;

constructor(address payable _owner, address _kittyCoreAddress) Pausable(_owner) public {
    require(_kittyCoreAddress != address(0), 'Invalid Kitty Core contract address');
    kittyCore = KittyCoreInterface(_kittyCoreAddress);
    require(kittyCore.supportsInterface(0x9a20483d), 'Invalid Kitty Core contract');

    saleAuction = AuctionInterface(kittyCore.saleAuction());
    siringAuction = AuctionInterface(kittyCore.siringAuction());
  }

  /**
   * Owner or operator can transfer kitty
   */
  function transferKitty(address _to, uint256 _kittyId) external onlyOwnerOrOperator {
    kittyCore.transfer(_to, _kittyId);
  }

  /**
   * Owner or operator can transfer kittie in batched to optimize gas usage
   */
  function transferKittyBulk(address _to, uint256[] calldata _kittyIds) external onlyOwnerOrOperator {
    for(uint256 i = 0; i < _kittyIds.length; i++) {
      kittyCore.transfer(_to, _kittyIds[i]);
    }
  }

  /**
   * Owner or operator can transferFrom kitty
   */
  function transferKittyFrom(address _from, address _to, uint256 _kittyId) external onlyOwnerOrOperator {
    kittyCore.transferFrom(_from, _to, _kittyId);
  }

  /**
   * Owner or operator an approve kitty
   */
  function approveKitty(address _to, uint256 _kittyId) external  onlyOwnerOrOperator {
    kittyCore.approve(_to, _kittyId);
  }

  /**
   * Owner or operator can start sales auction for kitty owned by contract
   */
  function createSaleAuction(uint256 _kittyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external onlyOwnerOrOperator {
    kittyCore.createSaleAuction(_kittyId, _startingPrice, _endingPrice, _duration);
  }

  /**
   * Owner or operator can cancel sales auction for kitty owned by contract
   */
  function cancelSaleAuction(uint256 _kittyId) external onlyOwnerOrOperator {
    saleAuction.cancelAuction(_kittyId);
  }

  /**
   * Owner or operator can start siring auction for kitty owned by contract
   */
  function createSiringAuction(uint256 _kittyId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external onlyOwnerOrOperator {
    kittyCore.createSiringAuction(_kittyId, _startingPrice, _endingPrice, _duration);
  }

  /**
   * Owner or operator can cancel siring auction for kitty owned by contract
   */
  function cancelSiringAuction(uint256 _kittyId) external onlyOwnerOrOperator {
    siringAuction.cancelAuction(_kittyId);
  }
}




/**
 * @title SimpleSiring
 * @dev Simple siring contract allows dedicated operator to create siring auctions on behalf of owner, while owner retains control over kitties.
 * Breeder gets reward per each successful auction creation and share of successful sales. Breeder can create auctions when contract is not paused.
 * Owner should transfer kitties to contact to breeding starts and withdraw afterwards.
 * Funds transfered directly to the contract can be used for paying breeder's fee, but owner found be able to withdraw only his share from the contract
 * Breeder can only create auctions for kitties specified by owner (unless unverified auctions are allowed by owner) and owned by contract
 * Breeder can only withdraw its share of funds and cannot transfer kitties.
 */

contract SimpleSiring is CKProxy {
    address payable public breeder;
    uint256 public breederReward;
    uint256 public originalBreederReward;
    uint256 public breederCut;
    uint256 public breederSharesWithdrawn;
    uint256 public ownerSharesWithdrawn;
    uint256 public ownerVaultBalance;
    bool public allowUnverifiedAuctions;

    struct Auction {
      uint128 startingPrice;
      uint128 endingPrice;
      uint64 duration;
    }
    mapping(uint256 => Auction) public auctions;
    Auction public defaultAuction;

    event BreederRewardChange(
        uint256 oldBreederReward,
        uint256 newBreederReward
    );
    event AuctionSet(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration, bool isDefault);
    event AuctionReset(uint256 tokenId, bool isDefault);
    event AuctionStarted(address breeder, uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration, uint256 reward);
    event FundsWithdrawn(address receiver, uint256 amount);

    constructor(
        address payable _owner,
        address payable _breeder,
        address _kittyCoreAddress,
        uint256 _breederReward,
        uint256 _breederCut
    ) public CKProxy(_owner, _kittyCoreAddress) {
        require(_breeder != address(0), "Invalid breeder address");
        require(_breederCut < 10000, "Invalid breeder cut");
        breeder = _breeder;
        breederReward = _breederReward;
        originalBreederReward = _breederReward;
        breederCut = _breederCut;
    }

    /**
    * Owner or breeder can change breeder's reward if needed.
    * Breeder can lower reward to make more attractive offer, it cannot set more than was originally agreed.
    * Owner can increase reward to motivate breeder to breed during high gas price, it cannot set less than was set by breeder.
    */
    function setBreederReward(uint256 _breederReward) external {
        require(msg.sender == breeder || msg.sender == owner, "Invalid sender");

        if (msg.sender == owner) {
            require(
                _breederReward >= originalBreederReward ||
                    _breederReward > breederReward,
                "Reward value is less than required"
            );
        } else if (msg.sender == breeder) {
            require(
                _breederReward <= originalBreederReward,
                "Reward value is more than original"
            );
        }

        emit BreederRewardChange(breederReward, _breederReward);
        breederReward = _breederReward;
    }

    function _totalSharedBalance() private view returns(uint256) {
        uint256 currentBalance = address(this).balance;
        require(currentBalance >= ownerVaultBalance, "Invalid vault balance");
        return (currentBalance - ownerVaultBalance) + breederSharesWithdrawn + ownerSharesWithdrawn;
    }

    /**
    * Owner's balance = owner's total share minus fund's withdrawn by owner
    * Balance functions should not overflow as shares are less than total balance
    * also total share are always greater than amount withdrawn
    * rob = (b + bw + ow) * (1 - bc) - ow
    */
    function getOwnerShares() public view returns (uint256) {
        uint256 totalBalance = _totalSharedBalance();
        uint256 ownerShare = totalBalance * (10000 - breederCut) / 10000;
        uint256 remainingBalance = ownerShare - ownerSharesWithdrawn;
        return remainingBalance;
    }

    /**
    * Breeder's balance = breeder's total share minus fund's withdrawn by breeder
    * Balance functions should not overflow as shares are less than total balance
    * also total share are always greater than amount withdrawn
    * rbb = (b + bw + ow) * bc  - bw
    */
    function getBreederShares() public view returns (uint256) {
        uint256 totalBalance = _totalSharedBalance();
        uint256 breederShare = totalBalance * breederCut / 10000;
        uint256 remainingBalance = breederShare - breederSharesWithdrawn;
        return remainingBalance;
    }

    /**
    * Owner can withdraw owned funds from contract
    */
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= (getOwnerShares() + ownerVaultBalance), "Insufficient funds");
        if(ownerVaultBalance >= amount) {
            // withdraw from vault
            ownerVaultBalance -= amount;
        } else if(ownerVaultBalance > 0) {
            // withdraw from vault and shares
            // amount is always greater than vault balance here
            ownerSharesWithdrawn += (amount - ownerVaultBalance);
            // withdraw rest from vault
            ownerVaultBalance = 0;
        } else {
            // withdraw fully from shares if vault is empty
            ownerSharesWithdrawn += amount;
        }
        emit FundsWithdrawn(owner, amount);
        owner.transfer(amount);
    }

    /**
    * Breeder can withdraw owned funds from contract
    */
    function withdrawBreeder(uint256 amount) external {
        require(msg.sender == breeder, "Invalid sender");
        require(amount <= getBreederShares(), "Insufficient funds");
        breederSharesWithdrawn += amount;
        emit FundsWithdrawn(breeder, amount);
        breeder.transfer(amount);
    }

    /**
     * Owner can transfer funds to their vault
     * Funds in vault are exclusively controlled by owner
     * Breeder cannot withdraw funds from vault
     * Funds in vault can be used to pay breeder's reward on successful auction creation
     */
    function transferToOwnerVault() payable external {
        ownerVaultBalance += msg.value;
    }

    /**
     * Contract can receive funds from CK auction
     * All direct transfers to contract are shared between owner and breeder, if breederCut > 0
     * If owner transfers funds directly to contract, there is no way they can withdraw 100% of transfered funds
     * Owner should use transferToOwnerVault function to retain control of transfered funds
     */
    receive() payable external {
    }

    /**
    * Owner can allow breeder to create auction without on-chain verification
    */
    function setAllowUnverifiedAuctions(bool _allow) external onlyOwner {
        allowUnverifiedAuctions = _allow;
    }
    
    /**
     * Owner can set default auction parameters
     * Breeder can create auction with default parameters for all kitties owned by contract, that do not have specific auction created
     */
    function setDefaultAuction(uint128 startingPrice, uint128 endingPrice, uint64 duration) external onlyOwner {
      require(duration > 1 minutes, "Invalid duration");
      defaultAuction.startingPrice = startingPrice;
      defaultAuction.endingPrice = endingPrice;
      defaultAuction.duration = duration;
      emit AuctionSet(0, startingPrice, endingPrice, duration, true);
    }

    /**
     * Owner can reset default auction parameters
     * Breeder won't be able to create auctions with default parameters
     */
    function resetDefaultAuction() external onlyOwner {
      defaultAuction.startingPrice = 0;
      defaultAuction.endingPrice = 0;
      defaultAuction.duration = 0;
      emit AuctionReset(0, true);
    }

    /**
     * Owner can set auction parameters for kitty owned by contract
     * Breeder won't be able to create auction with other parameters for this kitty
     */
    function setAuction(uint256 kittyId, uint128 startingPrice, uint128 endingPrice, uint64 duration) external onlyOwner {
      require(duration > 1 minutes, "Invalid duration");
      require(kittyCore.ownerOf(kittyId) == address(this), 'Kitty not owned by contract');
      Auction memory auction = Auction(
        uint128(startingPrice),
        uint128(endingPrice),
        uint64(duration)
      );

      auctions[kittyId] = auction;
      emit AuctionSet(
        uint256(kittyId),
        uint256(startingPrice),
        uint256(endingPrice),
        uint256(duration),
        false
      );
    }

    /**
     * Owner can set auction parameters for kitty owned by contract
     * Breeder won't be able to create auction for kitty, unless there is default auction or unverified auctions allowed
     */
    function resetAuction(uint256 kittyId) external onlyOwner {
      require(auctions[kittyId].duration > 0, "Non-existing auction");
      delete auctions[kittyId];
      emit AuctionReset(
        kittyId,
        false
      );
    }

    /**
     * return's auction for specified kitty, if exitsts, or default auction
     */
    function _getAuctionForKitty(uint256 _kittyId) private view returns(Auction storage) {
        Auction storage auction = auctions[_kittyId];
        if(auction.duration == 0 && defaultAuction.duration > 0) {
            auction = defaultAuction;
        }
        return auction;
    }

    /**
     * Owner can pay breeders reward either from their vault or shared balance
     * Vault payments come first
     */
    function _ownerPays(uint256 amount) private returns(bool) {
        bool paid = true;
        if(ownerVaultBalance >= amount) {
            // owner pays reward from vault
            ownerVaultBalance -= amount;
        } else if(getOwnerShares() >= amount) {
            // owner pays from shared balance
            ownerSharesWithdrawn += amount;
        } else {
            // cannot pay reward;
            paid = false;
        }
        return paid;
    }

    /*
    * Breeder can call this function to create an auction on behalf of owner
    * Owner can call this function as well 
    */
    function createSireAuction(uint256 _kittyId)
        external
        whenNotPaused
    {
        require(msg.sender == breeder || msg.sender == owner, "Invalid sender");

        Auction storage auction = _getAuctionForKitty(_kittyId);
        require(auction.duration > 0, "No auction for kitty");

        kittyCore.createSiringAuction(
            _kittyId,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration);

        uint256 reward = 0;
        // breeder can reenter but that's OK, since breeder is payed per successful breed
        if (msg.sender == breeder) {
            reward = breederReward;
            require(_ownerPays(reward), "No funds to pay reward");
            breeder.transfer(reward);
        }

        emit AuctionStarted(
            msg.sender,
            _kittyId,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            reward
        );
    }

    /**
     * If allowed, breeder can start auction without auction parameters verification
     * Breeder will choose parameters off-chain in this case
     * Owner can call this function as well 
     */
    function createUnverifiedSireAuction(
        uint256 _kittyId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration)
        external
        whenNotPaused
    {
        require((msg.sender == breeder && allowUnverifiedAuctions) ||
            msg.sender == owner, "Cannot create unverified auction");

       kittyCore.createSiringAuction(_kittyId, startingPrice, endingPrice, duration);

        uint256 reward = 0;
        // caller can reenter but that seems fine
        if (msg.sender == breeder) {
            reward = breederReward;
            require(_ownerPays(reward), "No funds to pay reward");
            breeder.transfer(reward);
        }

        emit AuctionStarted(
            msg.sender,
            _kittyId,
            startingPrice,
            endingPrice,
            duration,
            reward
        );
    }

    /**
     * Owner can destroy contract only after breeder fully withdraws its share
     */
    function destroy() public override virtual onlyOwner {
        require(getBreederShares() == 0, "Breeder should withdraw first");
        require(kittyCore.balanceOf(address(this)) == 0, "Contract has tokens");
        selfdestruct(owner);
    }

    /**
     * Owner can destroy contract only after breeder fully withdraws its share
     */
    function destroyAndSend(address payable _recipient) public override virtual onlyOwner {
        require(getBreederShares() == 0, "Breeder should withdraw first");
        require(kittyCore.balanceOf(address(this)) == 0, "Contract has tokens");
        selfdestruct(_recipient);
    }
}



contract SimpleSiringFactory is Pausable {
    using SafeMath for uint256;

    KittyCoreInterface public kittyCore;
    uint256 public breederReward = 0.001 ether;
    uint256 public breederCut = 625;
    uint256 public commission = 0 wei;
    uint256 public provisionFee;
    mapping (bytes32 => address) public breederToContract;

    event ContractCreated(address contractAddress, address breeder, address owner);
    event ContractRemoved(address contractAddress);

    constructor(address _kittyCoreAddress) Pausable(address(0)) public {
        provisionFee = commission + breederReward;
        kittyCore = KittyCoreInterface(_kittyCoreAddress);
        require(kittyCore.supportsInterface(0x9a20483d), "Invalid contract");
    }

    /**
     * Owner can adjust breeder reward
     * Factory contract does not use breeder reward directly, but sets it to Breeding contracts during contract creation
     * Existing contracts won't be affected by the change
     */
    function setBreederReward(uint256 _breederReward) external onlyOwner {
        require(_breederReward > 0, "Breeder reward must be greater than 0");
        breederReward = _breederReward;
        provisionFee = uint256(commission).add(breederReward);
    }

    /**
     * Owner can adjust breeder cut
     * Factory contract does not use breeder cut directly, but sets it to Breeding contracts during contract creation
     * Existing contracts won't be affected by the change
     */
    function setBreederCut(uint256 _breederCut) external onlyOwner {
        require(_breederCut < 10000, "Breeder reward must be less than 10000");
        breederCut = _breederCut;
    }

    /**
     * Owner can set flat fee for contract creation
     */
    function setCommission(uint256 _commission) external onlyOwner {
        commission = _commission;
        provisionFee = uint256(commission).add(breederReward);
    }

    /**
     * Just in case owner can change address of Kitty Core contract
     * Factory contract does not user Kitty Core directly, but sets it to Breeding contracts during contract creation
     * Existing contracts won't be affected by the change
     */
    function setKittyCore(address _kittyCore) external onlyOwner {
        kittyCore = KittyCoreInterface(_kittyCore);
        require(kittyCore.supportsInterface(0x9a20483d), "Invalid contract");
    }

    receive() payable external {
    }

    /**
     * Owner can withdraw funds from contracts, if any
     * Contract can only gets funds from contraction creation commission
     */
    function withdraw(uint256 amount) external onlyOwner {
        owner.transfer(amount);
    }

    /**
     * Create new breeding contract for breeder. This function should be called by user during breeder enrollment process.
     * Message value should be greater than breeder reward + commission. Value excess wil be transfered to created contract.
     * Breeder reward amount is transfered to breeder's address so it can start sending transactions
     * Comission amount stays in the contract
     * When contract is created, provisioning script can get address its address from breederToContract mapping
     */
    function createContract(address payable _breederAddress) external payable whenNotPaused {
        require(msg.value >= provisionFee, "Invalid value");

        // owner's address and breeder's address should uniquely identify contract
        // also we need to avoid situation when existing contract address is overwritten by enrolling breeder by same owner twice,
        // or enrolling same breeder by different owner
        bytes32 key = keccak256(abi.encodePacked(_breederAddress, msg.sender));
        require(breederToContract[key] == address(0), "Breeder already enrolled");

        //transfer value excess to new contract, owner can widthdraw later or use it for breeding
        uint256 excess = uint256(msg.value).sub(provisionFee);
        SimpleSiring newContract = new SimpleSiring(msg.sender, _breederAddress, address(kittyCore), breederReward, breederCut);

        breederToContract[key] = address(newContract);
        if(excess > 0) {
            newContract.transferToOwnerVault.value(excess)();
        }

        //transfer 1st breeder reward to breeder
        _breederAddress.transfer(breederReward);

        emit ContractCreated(address(newContract), _breederAddress, msg.sender);
    }

    /**
     * In most cases it does not make sense to delete contract's address. If needed it can be done by owner of factory contract.
     * This will not destroy breeding contract, just remove it address from the mapping, so user can deploy new contract for same breeder
     */
    function removeContract(address _breederAddress, address _ownerAddress) external onlyOwner {
        bytes32 key = keccak256(abi.encodePacked(_breederAddress, _ownerAddress));
        address contractAddress = breederToContract[key];
        require(contractAddress != address(0), "Breeder not enrolled");
        delete breederToContract[key];

        emit ContractRemoved(contractAddress);
    }
}
