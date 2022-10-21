// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity >=0.4.20;
import "./MainToken.sol";

contract  YF4StakingPool001{
    
    address public owner;
    address  a;
   
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    using SafeMath for uint256;
    using SafeMath for uint8;
    
    ERC20 public token;
    
    uint8 decimals;
    uint8 ERC20decimals;
    
    struct User{
        bool referred;
        address referred_by;
        uint256 total_invested_amount;
        uint256 referal_profit;
    }
    
    struct Referal_levels{
        uint256 level_1;
        uint256 level_2;
        uint256 level_3;
    }

    struct Panel_1{
        uint256 invested_amount;
        uint256 profit;
        uint256 profit_withdrawn;
        uint256 start_time;
        uint256 exp_time;
        bool time_started;
        uint256 remaining_inv_prof;
    }


    mapping(address => Panel_1) public panel_1;

    mapping(address => User) public user_info;
    mapping(address => Referal_levels) public refer_info;
    uint public totalcontractamount;

    
    mapping(address => uint256) public overall_profit;

    constructor() public {
        ERC20decimals = 18; //  Decimal places of ERC20 token
        token = ERC20(0x38ACeFAd338b870373fB8c810fE705569E1C7225);
    }

    function getContractERC20Balance() public view returns (uint256){
       return token.balanceOf(address(this));
    }



function invest_panel1(uint256 t_value) public {
        // 50,000,000 = 50 trx
        require(t_value >= 50 * (10 ** 18), 'Please Enter Amount no less than 100');
        require(t_value <= 1000 * (10 ** 18), 'Please Enter Amount no greater than 1000');
        
        if( panel_1[msg.sender].time_started == false){
            panel_1[msg.sender].start_time = now;
            panel_1[msg.sender].time_started = true;
            panel_1[msg.sender].exp_time = now + 210 days; //210*24*60*60  = 210 days
        }
            // // Approve to contract for taking tokens in
            // token.approve(address(this), t_value); // doesn't work external

            // transfer the tokens from user to contract
            totalcontractamount += t_value ;
            token.transferFrom(msg.sender, address(this), t_value);

            // assign token amount to bot accout
            panel_1[msg.sender].invested_amount += t_value;
            user_info[msg.sender].total_invested_amount += t_value; 
            
            referral_system(t_value);
            
            //neg
        if(panel1_days() <= 210){ //210
            panel_1[msg.sender].profit += ((t_value*1*(210 - panel1_days()))/(100)); // 210 - panel_days()
        }

    }

    function is_plan_completed_p1() public view returns(bool){

        uint256 local_overall_profit = overall_profit[msg.sender];
        uint256 local_current_profit = current_profit_p1();

        if(panel_1[msg.sender].exp_time != 0){

            if((local_current_profit + local_overall_profit) >= panel_1[msg.sender].profit){
                return true;
            }
            if(now >= panel_1[msg.sender].exp_time){
                return true;
            }
            if(now < panel_1[msg.sender].exp_time){
                return false;
            }
        }else{
            return false;
        }

    }

    function plan_completed_p1() public  returns(bool){
        uint256 local_overall_profit = overall_profit[msg.sender];
        uint256 local_current_profit = current_profit_p1();

        if( panel_1[msg.sender].exp_time != 0){

            if( (local_current_profit + local_overall_profit) >= panel_1[msg.sender].profit ){
                reset_panel_1();
                return true;
            }
            if(now >= panel_1[msg.sender].exp_time){
                reset_panel_1();
                return true;
            }
            if(now < panel_1[msg.sender].exp_time){
                return false;
            }

        }

    }

    function current_profit_p1() public view returns(uint256){
        uint256 local_profit ;

        if(now <= panel_1[msg.sender].exp_time){
            if((((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(210*(1 days))) > panel_1[msg.sender].profit_withdrawn){  // 210 * 1 days
                local_profit = (((panel_1[msg.sender].profit + panel_1[msg.sender].profit_withdrawn)*(now-panel_1[msg.sender].start_time))/(210*(1 days))) - panel_1[msg.sender].profit_withdrawn; // 210*24*60*60
                return local_profit;
            }else{
                return 0;
            }
        }
        if(now > panel_1[msg.sender].exp_time){
            return panel_1[msg.sender].profit;
        }

    }

    function panel1_days() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return ((now - panel_1[msg.sender].start_time)/(1 days)); // change to 24*60*60   1 days
        }
        else {
            return 0;
        }
    }
    
    function withdraw_profit_panel1(uint256 amount) public payable {
        uint256 current_profit = current_profit_p1();
        require(amount >= 10 * (10 ** 18), ' Amount sould be less than profit'); /////////change min withdrawal to 10YF4
        require(amount <= current_profit, ' Amount sould be less than profit');

        panel_1[msg.sender].profit_withdrawn = panel_1[msg.sender].profit_withdrawn + amount;
        //neg
        panel_1[msg.sender].profit = panel_1[msg.sender].profit - amount;
        token.transfer(msg.sender, (amount - ((5*amount)/100)));
        token.transfer(a, ((5*amount)/100));
    }

    function is_valid_time_p1() public view returns(bool){
        if(panel_1[msg.sender].time_started == true){
        return (now > l_l1())&&(now < u_l1());    
        }
        else {
            return true;
        }
    }

    function l_l1() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return (1 days)*panel1_days() + panel_1[msg.sender].start_time;     // 24*60*60 1 days
        }else{
            return now;
        }
    }
    
    function u_l1() public view returns(uint256){
        if(panel_1[msg.sender].time_started == true){
            return ((1 days)*panel1_days() + panel_1[msg.sender].start_time + 10 hours);    // 1 days  , 10 hours
        }else {
            return now + (10 hours);  // 10*60*60  8 hours
        }
    }

    function reset_panel_1() private{
        uint256 local_current_profit = current_profit_p1();

        panel_1[msg.sender].remaining_inv_prof = local_current_profit ;

        panel_1[msg.sender].invested_amount = 0;
        panel_1[msg.sender].profit = 0;
        panel_1[msg.sender].profit_withdrawn = 0;
        panel_1[msg.sender].start_time = 0;
        panel_1[msg.sender].exp_time = 0;
        panel_1[msg.sender].time_started = false;
        overall_profit[msg.sender] = 0;
    }  

    function withdraw_all_p1() public payable{

        token.transfer(msg.sender, panel_1[msg.sender].remaining_inv_prof);
        panel_1[msg.sender].remaining_inv_prof = 0;

    }


    


 //------------------- Referal System ------------------------

    function refer(address ref_add) public {
        require(user_info[msg.sender].referred == false, ' Already referred ');
        require(ref_add != msg.sender, ' You cannot refer yourself ');
        
        user_info[msg.sender].referred_by = ref_add;
        user_info[msg.sender].referred = true;        
        
        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;
        
        if( (level1 != msg.sender) && (level1 != address(0)) ){
            refer_info[level1].level_1 += 1;
        }
        if( (level2 != msg.sender) && (level2 != address(0)) ){
            refer_info[level2].level_2 += 1;
        }
        if( (level3 != msg.sender) && (level3 != address(0)) ){
            refer_info[level3].level_3 += 1;
        }
        
    }

    function referral_system(uint256 amount) private {
        
        address level1 = user_info[msg.sender].referred_by;
        address level2 = user_info[level1].referred_by;
        address level3 = user_info[level2].referred_by;

        if( (level1 != msg.sender) && (level1 != address(0)) ){
            user_info[level1].referal_profit += (amount*10)/(100);
            overall_profit[level1] += (amount*10)/(100);
        }
        if( (level2 != msg.sender) && (level2 != address(0)) ){
            user_info[level2].referal_profit += (amount*5)/(100);
            overall_profit[level2] += (amount*5)/(100);
        }
        if( (level3 != msg.sender) && (level3 != address(0)) ){
            user_info[level3].referal_profit += (amount*1)/(100);
            overall_profit[level3] += (amount*1)/(100);
        }

    }

    function referal_withdraw() public {
        uint256 t = user_info[msg.sender].referal_profit;
        user_info[msg.sender].referal_profit = 0;
        
        token.transfer(msg.sender, t);
    }  

}

 

//  YF4 Staking Yield Platform
// Daily ROI Reward 1%
// (Maximum get profit 210% from the daily reward including refferal bonus, after received 210% member must be reinvest to get more daily reward and refferal bonus)

// Minimum stake 100 YF4
// Maximum stake 1000 YF4

// Minimum Withdrawal 10 YF4 daily, Maximum Withdrawal Same amount of member deposit

// Refferal Bonus : 
// Level 01 - 10%
// Level 02 - 5%
// Level 03 - 1%
// (note: every member withdrwal the leader will be get refferal bonus automaticly)

// Fee withdrawal 5% going to owner wallet

