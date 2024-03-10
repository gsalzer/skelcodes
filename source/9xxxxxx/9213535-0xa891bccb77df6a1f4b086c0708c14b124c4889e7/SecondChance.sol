pragma solidity ^0.5.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


/** @title SecondChance Lottery Game
 * @author 
 */
contract SecondChance {
        
    using SafeMath for uint256;
    
    struct gameDetails{
        uint256 commisionAmount;
        uint256 totalAmount;
        uint256 noOfWinners;
        uint256 userCount;
        uint256[] userId;
        uint256[] winnerList;
        bool winCountStatus;
    }

    address public admin;
    uint256 public percentage;
    uint256 public maxAmount;
    
    mapping(uint256 => gameDetails) public games;
                                                                                                                                          
    event Participators(uint256 gameId,uint256 UserId,uint256 depType,uint256 depAmount, uint256 fiatAmount);
 
    constructor(address _admin, uint256 _percentage, uint256 _maxAmount) public {
        admin = _admin;
        percentage = _percentage;
        maxAmount = _maxAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == admin , "Only Owner Must call this Function");
        _;
    }
    
    /** @dev Set the Admin  Percentage.
     * @param _percentage - Percentage for Admin commision.
     * @return bool - Success.
     */
    function setAdminPercent(uint256 _percentage) onlyOwner public returns(bool) {
        percentage = _percentage;
        return true;
    }
     
    /** @dev Set the Maximum Winning Amount.
     * @param _maxAmount - Maximum Winning Amount.
     * @return bool - Success.
     */
    function setMaxAmount(uint256 _maxAmount) onlyOwner public returns(bool) {
        maxAmount = _maxAmount;
        return true;
    }

    /** @dev To Change the Admin Address.
     * @param _newAdmin - The new address for Admin.
     * @return bool - Success.
     */
    function changeAdmin(address _newAdmin) onlyOwner public returns(bool) {
        admin = _newAdmin;
        return true;
    }

    /** @dev Stores the Participator Details in Contract.
     * @param _gameid - Unique Id of the game.
     * @param _userid - The Bundle of userIds of the particular Game.
     * @param _amount - The Bundle of depositAmount which is ETH/BTC (both convert into wei) in the particular Game.
     * @param _type - The Bundle of Currency Type, If it is ETH then _type = 0 / If it is BTC then _type = 1.
     * @param _fiat - The Bundle of depositAmount which is  ETH/BTC (convert into USD).
     * @return bool - true.
     */
    function participate( uint256 _gameid,uint256[] memory _userid, uint256[] memory _amount, uint256[] memory _type, uint256[] memory _fiat) onlyOwner public returns(bool) {
        require(games[_gameid].winCountStatus == false, "Already game is completed");
        for(uint256 i=0 ; i<_userid.length ; i++ ){
            require(_type[i] == 0 || _type[i] == 1, "Invalid Type");
            games[_gameid].userId.push(_userid[i]);
            games[_gameid].totalAmount = games[_gameid].totalAmount.add(_fiat[i]);
            emit Participators(_gameid,_userid[i],_type[i],_amount[i],_fiat[i]); //event
        }
        games[_gameid].userCount = games[_gameid].userCount.add(uint256(_userid.length));
        return true;
    }

    /** @dev Performs the Winning Algorithm and get the number of winners.
     * @param _gameid - Id of the game.
     * @param _totalamount - The Total Amount of USD in the particular Game for cross check.
     * @param _userCount - The Total User Count of the particular Game for cross check.
     * @return uint256 - Total Count of Winners.
     */
    function winning_algorithm(uint256 _gameid,uint256 _totalamount, uint256 _userCount) onlyOwner public returns(uint256) {
        
        // requires for cross check
        require(_totalamount > 0 && games[_gameid].totalAmount > 0, "Total Fiat Amount Checking Failed");
        require(games[_gameid].totalAmount == _totalamount,"Total Amount mismatch");
        require(games[_gameid].userCount == _userCount,"User Count mismatch");
        require(games[_gameid].winCountStatus == false, "Already Done this Process");

        // deduct commision
        uint256 perc = uint256(100).mul(10**18);
        uint256 cAmount_ = (_totalamount.mul(percentage)).div(perc);
        games[_gameid].commisionAmount = games[_gameid].commisionAmount.add(cAmount_);
        games[_gameid].totalAmount =  games[_gameid].totalAmount.sub(games[_gameid].commisionAmount);
        
        
        // if less than maxAmount after deduction of commisionAmount
        if(games[_gameid].totalAmount < maxAmount){
             games[_gameid].noOfWinners = 1;
        }

        // calc no of winners and list
        else{
            games[_gameid].noOfWinners = (games[_gameid].totalAmount).div(maxAmount);
             
            uint256 balanceAmount = (games[_gameid].totalAmount).mod(maxAmount);
              
            // last amount for last winner
            if(balanceAmount>0)
               games[_gameid].noOfWinners = games[_gameid].noOfWinners.add(1);
                
            // usercount and winnercount checking
            if(games[_gameid].noOfWinners > games[_gameid].userCount)
               games[_gameid].noOfWinners = games[_gameid].userCount;
        }
        games[_gameid].winCountStatus = true;
        
        return(games[_gameid].noOfWinners);
    }

    /** @dev Performs the Random Selection and get the winners in the particular game.
     * @param _gId - Id of the game.
     * @param _time - The current Time (EPOCH) for random generaion.
     * @param _winnerCount - The Total Winner Count of the particular Game for cross check.
     * @return bool - Success.
     */
   function getWinner(uint256 _gId, uint256 _time, uint256 _winnerCount) onlyOwner public returns (bool) {
       require(games[_gId].noOfWinners == _winnerCount,"Invalid Winner Count");
       require(games[_gId].winCountStatus == true, "Pending Winning Count");
       
       uint256 NumberOfUsers = games[_gId].userCount;
       uint256 random = uint256(uint(keccak256(abi.encodePacked(block.timestamp + _time))) % NumberOfUsers +1);
       uint256 userId =  games[_gId].userId[random];
       games[_gId].winnerList.push(userId);
       
       return true;
       
    }
    
    /** @dev Getting the winning List and their winning amount for this particular game.
     * @param _gId - Id of the game.
     * @return uint256[] memory - array of winning List.
     */
    function getWinningList(uint256 _gId)  public view returns(uint256[] memory) {
        return (games[_gId].winnerList);
    }
 
}
