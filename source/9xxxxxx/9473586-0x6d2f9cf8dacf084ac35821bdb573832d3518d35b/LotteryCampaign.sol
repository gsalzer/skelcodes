pragma solidity >= 0.5.3 < 0.6.0;

import "./SafeMath.sol";
import "./TimestampMonthConv.sol";
import "./ERC20Interface.sol";

contract Ownership {
    address private _owner;
    
    event OwnerOwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    
    // Returns contract owner address
    function owner() public view returns (address){
        return _owner;
    }
    
    // Check if caller is owner account
    function isOwner() public view returns (bool){
        return (msg.sender == _owner);
    }
    
    // Modifier for function restricted to owner only
    modifier onlyOwner() {
        require(isOwner(), "Ownership: the caller is not the owner address");
        _;
    }
    
    // Transfer owner's ownership to new address
    // # param newOwner: address of new owner to be transferred
    function transferOwnerOwnership(address newOwner) public onlyOwner {
        _transferOwnerOwnership(newOwner);
    }
    
    // ==== internal functions ====

    function _transferOwnerOwnership(address newOwner) internal {
        require (newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnerOwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function _setupOwnership(address own) internal {
        require (own != address(0), "Ownable: owner is zero address");
        _owner = own;
        
        emit OwnerOwnershipTransferred(address(0), own);
    }
}

interface LockupInterface {
    function isRegisteredParticipant(address userAddress) external view returns (bool);
    function getParticipantLockAmount(address userAddress) external view returns (uint256);
}

contract LotteryCampaign is Ownership {
    using TimestampMonthConv for uint256;
    using SafeMath for uint256;

    enum Tiers {TIER1, TIER2, TIER3, TIER4}
    enum LotteryStatus {NULL, JOINED, SELECTED, CLAIMED}
    enum LotteryAvailability {CLOSED, OPEN}
    LotteryAvailability lottOpen;
    
    struct Participants {
        Tiers tier;
        LotteryStatus status;
    }
    
    uint8 decimal;
    uint256 nonce;
    uint256 public endTime;
    bool internal t1_transfer = false;
    bool internal t2_transfer = false;
    bool internal t3_transfer = false;
    bool internal t4_transfer = false;
    address internal lockupContract;
    
    address[] participantsTier1;
    address[] participantsTier2;
    address[] participantsTier3;
    address[] participantsTier4;

    address[] selectedTier1;
    address[] selectedTier2;
    address[] selectedTier3;
    address[] selectedTier4;
    
    mapping (address => Participants) participantList;

    event Active(uint256 timestamp);
    event Inactive(uint256 timestamp);
    event Supply(uint256 indexed owner, uint256 amount);
    event Return(uint256 indexed owner, uint256 amount);
    event RegisterLottery(address indexed user, Tiers tier, uint256 timestamp);
    event SelectedLottery(address indexed user, Tiers tier);
    event RewardLottery(address indexed user, uint256 amountEth, uint256 timestamp);
    event EndTimeShifted(uint256 oldTime, uint256 newTime);
    
    constructor(address owner, uint8 WWB_decimals, address lockupCampaign) public {
        _setupOwnership(owner);
        decimal = WWB_decimals;
        lockupContract = lockupCampaign;
    }

    // --------------- Main lottery function ---------------

    // Change the lottery contract's active state to `open` and adds 1 month for closing
    function startLotteryPeriod() public onlyOwner {
        lottOpen = LotteryAvailability.OPEN;
        endTime = now.addMonths(1);
        emit Active(now);
    }
    
    // Change the end time **Note: should not input time later than current timestamp
    function changeEndPeriod(uint256 timestamp) public onlyOwner {
        require(timestamp > now, "LotteryCampaign: Input time invalid, time should be greater than current time");
        emit EndTimeShifted(endTime, timestamp);
        endTime = timestamp;
    }

    // Terminates the contract
    function killContract() public onlyOwner {
        selfdestruct(address(uint160(owner())));
    }
    
    // Checks whether the lottery is active
    function isOpen() public view returns (bool) {
        return(lottOpen == LotteryAvailability.OPEN);
    }

    // Updates the period of lottery activeness
    function updatePeriod() public {
        if(now > endTime) {
            lottOpen = LotteryAvailability.CLOSED;
            emit Inactive(now);
        }
    }
    
    // Fallback for supplying ETH
    function () external payable{
        require(msg.sender == owner(), "LotteryCampaign: only owner can send ETH in this contract");
    }
    
    // Checks ETH balance in this contract
    function balance() public view onlyOwner returns (uint256){
        return address(this).balance;
    }
    
    // Send back remaining ETH balance to owner
    function sendBackBalance() public onlyOwner returns (uint256){
        address payable own = address(uint160(owner()));
        own.transfer(balance());
    }

    // Registers users for lottery selection. Only applies for users who registers for WWB lockup campaign
    // # params user: address of the user participated on WWB lockup campaign
    function register(address user) public returns (bool stat){
        updatePeriod();
        require(isOpen(), "LotteryCampaign: lottery is closed");
        require(participantList[user].status == LotteryStatus.NULL, "LotteryCampaign: user already registered");
        _verify(user);
        stat = _checkTier(user);
    }

    // Retrieve information of successfully registered user
    // # params user: address of the user participated on WWB lockup campaign
    // * returns (Tiers): enum of which Tiers is registered
    // * returns (LotteryStatus): enum of the user status
    function getInfo(address user) public view returns(Tiers, LotteryStatus) {
        return(participantList[user].tier, participantList[user].status);
    }

    // Retrieve all participating users for Tier 1
    function getTier1List() public view returns (address[] memory){
        return participantsTier1;
    }

    // Retrieve all participating users for Tier 2
    function getTier2List() public view returns (address[] memory){
        return participantsTier2;
    }

    // Retrieve all participating users for Tier 3
    function getTier3List() public view returns (address[] memory){
        return participantsTier3;
    }

    // Retrieve all participating users for Tier 4
    function getTier4List() public view returns (address[] memory){
        return participantsTier4;
    }

    // Insert the selected users for Tier 1 to selected list. **lottery is handled on other location due to security reason
    // # params user: address of the selected user participated on WWB lockup campaign
    function insertSelectionTier1(address user) public onlyOwner{
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        require(participantList[user].status != LotteryStatus.NULL, "LotteryCampaign: user does not exists in lottey");
        
        _insertSelection(user, selectedTier1, 50);
    }

    // Insert the selected users for Tier 1 to selected list by bulk. **lottery is handled on other location due to security reason
    // # params users: array of addresses of selected user participated on WWB lockup campaign in Tier 1
    function insertBulkTier1(address[] memory users) public onlyOwner {
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        selectedTier1 = users;

        _bulkChecks(users, Tiers.TIER1);
    }

    // Insert the selected users for Tier 2 to selected list. **lottery is handled on other location due to security reason
    // # params user: address of the selected user participated on WWB lockup campaign
    function insertSelectionTier2(address user) public {
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        require(participantList[user].status != LotteryStatus.NULL, "LotteryCampaign: user does not exists in lottey");
        
        _insertSelection(user, selectedTier2, 30);
    }

    // Insert the selected users for Tier 2 to selected list by bulk. **lottery is handled on other location due to security reason
    // # params users: array of addresses of selected user participated on WWB lockup campaign in Tier 2
    function insertBulkTier2(address[] memory users) public onlyOwner {
        require(lottOpen == LotteryAvailability.CLOSED, "LotteryCampaign: lottery is still open");
        selectedTier2 = users;

        _bulkChecks(users, Tiers.TIER2);
    }

    // Insert the selected users for Tier 3 to selected list. **lottery is handled on other location due to security reason
    // # params user: address of the selected user participated on WWB lockup campaign
    function insertSelectionTier3(address user) public {
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        require(participantList[user].status != LotteryStatus.NULL, "LotteryCampaign: user does not exists in lottey");
        
        _insertSelection(user, selectedTier3, 20);
    }

    // Insert the selected users for Tier 3 to selected list by bulk. **lottery is handled on other location due to security reason
    // # params users: array of addresses of selected user participated on WWB lockup campaign in Tier 3
    function insertBulkTier3(address[] memory users) public onlyOwner {
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        selectedTier3 = users;

        _bulkChecks(users, Tiers.TIER3);
    }

    // Insert the selected users for Tier 4 to selected list. **lottery is handled on other location due to security reason
    // # params user: address of the selected user participated on WWB lockup campaign
    function insertSelectionTier4(address user) public {
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        require(participantList[user].status != LotteryStatus.NULL, "LotteryCampaign: user does not exists in lottey");
        
        _insertSelection(user, selectedTier4, 10);
    }

    // Insert the selected users for Tier 4 to selected list by bulk. **lottery is handled on other location due to security reason
    // # params users: array of addresses of selected user participated on WWB lockup campaign in Tier 4
    function insertBulkTier4(address[] memory users) public onlyOwner {
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        selectedTier4 = users;

        _bulkChecks(users, Tiers.TIER4);
    }

    // Transfer the ETH to the user address that have been selected for respective Tier.
    // # params user: address of the selected user participated on WWB lockup campaign
    function transferSelectedUsers(address user) public {
        updatePeriod();
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        require(participantList[user].status == LotteryStatus.SELECTED, "LotteryCampaign: user is not selected in lottey");

        _transferOut(user);
    }

    // Send out ETH to selected users by bulk for Tier 1
    function bulkTransferSelectionTier1() public onlyOwner{
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        require(t1_transfer != true, "LotteryCampaign: ETH have been given out for Tier 1");
        
        _bulkTransferOut(selectedTier1, 100000000000000000);
        t1_transfer = true;
    }

    // Send out ETH to selected users by bulk for Tier 2
    function bulkTransferSelectionTier2() public onlyOwner{
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        require(t2_transfer != true, "LotteryCampaign: ETH have been given out for Tier 2");
        
        _bulkTransferOut(selectedTier2, 500000000000000000);
        t2_transfer = true;
    }

    // Send out ETH to selected users by bulk for Tier 3
    function bulkTransferSelectionTier3() public onlyOwner{
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        require(t3_transfer != true, "LotteryCampaign: ETH have been given out for Tier 3");
        
        _bulkTransferOut(selectedTier3, 1500000000000000000);
        t3_transfer = true;
    }

    // Send out ETH to selected users by bulk for Tier 4
    function bulkTransferSelectionTier4() public onlyOwner{
        require(!isOpen(), "LotteryCampaign: lottery is still open");
        require(t4_transfer != true, "LotteryCampaign: ETH have been given out for Tier 4");
        
        _bulkTransferOut(selectedTier3, 10000000000000000000);
        t4_transfer = true;
    }
    
    // --------------- internal functions ---------------

    function _verify(address user) internal view {
        bool result = LockupInterface(lockupContract).isRegisteredParticipant(user);
        require(result, "LotteryCampaign: user does not participate in LockupCampaing yet");
    }

    function _checkTier(address user) internal returns (bool stat){
        uint256 amt = LockupInterface(lockupContract).getParticipantLockAmount(user);
        Participants memory userP;

        // test: re-edit the amt values
        if(amt >= 100000 * 10**uint256(decimal) && amt < 500000 * 10**uint256(decimal)){
            participantsTier1.push(user);
            userP = Participants(Tiers.TIER1, LotteryStatus.JOINED);
            participantList[user] = userP;
            emit RegisterLottery(user, Tiers.TIER1, now);
            stat = true;
        } else if(amt >= 500000 * 10**uint256(decimal) && amt < 1000000 * 10**uint256(decimal)){
            participantsTier2.push(user);
            userP = Participants(Tiers.TIER2, LotteryStatus.JOINED);
            participantList[user] = userP;
            emit RegisterLottery(user, Tiers.TIER2, now);
            stat = true;
        } else if(amt >= 1000000 * 10**uint256(decimal) && amt < 5000000 * 10**uint256(decimal)){
            participantsTier3.push(user);
            userP = Participants(Tiers.TIER3, LotteryStatus.JOINED);
            participantList[user] = userP;
            emit RegisterLottery(user, Tiers.TIER3, now);
            stat = true;
        } else if(amt >= 5000000 * 10**uint256(decimal)){
            participantsTier4.push(user);
            userP = Participants(Tiers.TIER4, LotteryStatus.JOINED);
            participantList[user] = userP;
            emit RegisterLottery(user, Tiers.TIER4, now);
            stat = true;
        } else {
            stat = false;
        }
    }
    
    function _insertSelection(address usr, address[] storage selected, uint256 max) internal {
        require(selected.length <= max, "LotteryCampaign: Selected list for this tier is full");
        selected.push(usr);
        participantList[usr].status != LotteryStatus.SELECTED;
     
        emit SelectedLottery(usr, participantList[usr].tier);
    }

    function _rand(uint256 maxcount) internal returns (uint256) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % maxcount;
        //randomnumber = randomnumber + 100;
        nonce++;
        return randomnumber;
    }

    function _transferOut(address user) internal{
        address payable p_user = address(uint160(user));
        if(participantList[user].tier == Tiers.TIER1){
            p_user.transfer(100000000000000000);
            emit RewardLottery(user, 100000000000000000, now);
        } else if (participantList[user].tier == Tiers.TIER2){
            p_user.transfer(500000000000000000);
            emit RewardLottery(user, 500000000000000000, now);
        } else if (participantList[user].tier == Tiers.TIER3){
            p_user.transfer(1500000000000000000);
            emit RewardLottery(user, 1500000000000000000, now);
        } else if (participantList[user].tier == Tiers.TIER3){
            p_user.transfer(10000000000000000000);
            emit RewardLottery(user, 10000000000000000000, now);
        }
        participantList[user].status != LotteryStatus.CLAIMED;
    }
    
    function _bulkTransferOut(address[] storage selected, uint256 weiAmount) internal {
        for(uint i = 0; i < selected.length; i++){
            address payable user = address(uint160(selected[i]));
            user.transfer(weiAmount);
            participantList[selected[i]].status != LotteryStatus.CLAIMED;
            
            emit RewardLottery(selected[i], weiAmount, now);
        }
    }

    function _bulkChecks (address[] memory users, Tiers tier) internal {
        for(uint i = 0; i < users.length; i++){
            participantList[users[i]].status != LotteryStatus.SELECTED;
            emit SelectedLottery(users[i], tier);
        }
    }
}
