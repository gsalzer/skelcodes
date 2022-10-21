pragma solidity >=0.4.21 <0.7.0;

contract Besunray {
  address payable public owner;
  struct User { //Used to store user details
    uint uid;
    address payable wallet;
    uint package;
    uint256 etherValue;
    address payable refferer;
    uint level;
    bool status;
    uint commissions;
  }
  struct Plan { //Used to store commission configuration
    uint level;
    uint package;
    uint percentage;
  }
  struct Qualification{
    uint status;
    uint level_1;
    uint level_2;
    uint level_3;
    uint level_4;
    uint level_5;
    uint level_6;
    uint level_7;
    uint level_8;
    uint level_9;
    uint level_10;
  }
  mapping(address => User) public users;
  mapping(address => Qualification) public qualifications;
  mapping(uint => Plan) public plans;

  event DistributeCommission(
    address to,
    address from,
    uint amount
  );
  event UserRegistration(
    uint uid,
    address wallet,
    address refferer,
    uint package,
    uint256 etherValue,
    uint256 commissions
  );
  event EmQualification(
    address wallet,
    uint level
  );
  /**
  * @dev Constructor sets admin.
  *
  * This is public constructor.
  *
  *
  * Requirements:
  *
  * -
  */
  constructor() public {
    owner = msg.sender;
    plans[1] = Plan(1, 200, 10);
    plans[2] = Plan(2, 200, 6);
    plans[3] = Plan(3, 200, 4);
    plans[4] = Plan(4, 200, 2);
    plans[5] = Plan(5, 500, 2);
    plans[6] = Plan(6, 500, 2);
    plans[7] = Plan(7, 500, 1);
    plans[8] = Plan(8, 500, 1);
    plans[9] = Plan(9, 1000, 1);
    plans[10] = Plan(10, 1000, 1);
  }
/**
  * @dev fallback for .
  *
  * This is public fallback.
  *
  *
  * Requirements:
  *
  * -
  */
  function() external payable {}
  /**
  * @dev access modifier.
  *
  * restrict access this enables sensitive information available only for admin.
  *
  *
  * Requirements:
  *
  * - `msg.sender` must be an admin.
  */
  modifier onlyAdmin() { //Admin modifier
    require(
      msg.sender == owner,
      "This function can only invoked by admin"
      );
      _;
  }
  /**
  * @dev register users in to blockchain.
  *
  * This is public function.
  *
  *
  * Requirements:
  *
  * - `msg.sender` must be admin.
  * - `_wallet` must be a valid address.
  * - `_package` must be a valid address.
  * - `_etherValue` must be a valid address.
  * - `_status` must be a valid address.
  */
  function registerUser(
    uint _uid,
    address payable _wallet,
    uint _package,
    uint256 _etherValue,
    address payable _refferer,
    bool _status
    ) public onlyAdmin {
    require(users[_wallet].wallet != _wallet,"User is already registered");
    uint level = users[_refferer].level + 1;
    users[_wallet] = User(_uid, _wallet, _package,_etherValue, _refferer, level, _status, 0);
    emit UserRegistration(_uid, _wallet, _refferer, _package, _etherValue, 0);
  }
  /**
  * @dev Deactivate user
  *
  * This is public function onlyAdmin.
  *
  *
  * Requirements:
  *
  * - `_wallet` should be a registered user.
  */
  function deactivateUser(address _wallet) public onlyAdmin {
    require(users[_wallet].wallet == _wallet,"User is not registered in blockchain");
    users[_wallet].status = false;
  }
  /**
  * @dev Activate user
  *
  * This is public function onlyAdmin.
  *
  *
  * Requirements:
  *
  * - `_wallet` should be a registered user.
  */
  function activateUser(address _wallet) public onlyAdmin {
    require(users[_wallet].wallet == _wallet,"User is not registered in blockchain");
    users[_wallet].status = true;
  }
  /**
  * @dev Upgrade user package
  * Access modified with OnlyAdmin
  *
  *
  * Requirements:
  *
  * - `_wallet` should be a registered user.
  * - `_package` should be a registered user.
  */
  function upgradePackage(address _wallet, uint _package) public onlyAdmin {
    require(users[_wallet].wallet == _wallet,"User is not registered in blockchain");
    require(users[_wallet].package < _package, 'perform upgarde only');
    users[_wallet].package = _package;
  }
  /**
  * @dev Enables admin to set compensation plan.
  *
  * This is public function.
  ** Access modified with OnlyAdmin
  *
  * Requirements:
  *
  * - `_level` cannot be the zero.
  * - `_package` cannot be the zero.
  * - `_percentage` cannot be the zero.
  */
  function setPlan(uint _level, uint _package, uint _percentage) public onlyAdmin {
    plans[_level] = Plan(_level, _package, _percentage);
  }
  /**
  * @dev Withdraws contract balance to owner waller
  *
  ** Access modified with OnlyAdmin
  *
  * Requirements:
  *
  */
  function withdraw() public onlyAdmin {
        owner.transfer(address(this).balance);
  }
  /**
  * @dev Sets user qualification.
  *
  * Access modified with OnlyAdmin
  * This is public function.
  *
  *
  * Requirements:
  *
  * - `_level` cannot be the zero.
  * - `_wallet` cannot be the zero.
  */
  function setQualification(address _wallet,uint _level) public onlyAdmin{
    require(users[_wallet].status == true, 'User is not active or not registered');
    if(qualifications[_wallet].status <= 0 && _level == 1){
        qualifications[_wallet] = Qualification(1,1,0,0,0,0,0,0,0,0,0);
    }else{
      if(_level == 1){
        qualifications[_wallet].level_1 = 1;
      }
      if(_level == 2){
        qualifications[_wallet].level_2 = 1;
      }
      if(_level == 3){
        qualifications[_wallet].level_3 = 1;
      }
      if(_level == 4){
        qualifications[_wallet].level_4 = 1;
      }
      if(_level == 5){
        qualifications[_wallet].level_5 = 1;
      }
      if(_level == 6){
        qualifications[_wallet].level_6 = 1;
      }
      if(_level == 7){
        qualifications[_wallet].level_7 = 1;
      }
      if(_level == 8){
        qualifications[_wallet].level_8 = 1;
      }
      if(_level == 9){
        qualifications[_wallet].level_9 = 1;
      }
      if(_level == 10){
        qualifications[_wallet].level_10 = 1;
      }
    }
    emit EmQualification(_wallet, _level);
  }
/**
  * @dev gets user qualification.
  *
  * Access modified with OnlyAdmin
  * This is public function.
  *
  *
  * Requirements:
  *
  * - `_level` cannot be the zero.
  * - `_wallet` cannot be the zero.
  */
  function getQualification(address _wallet, uint _level) public view returns(uint) {
      uint qualified;
      if(_level == 1){
        qualified = qualifications[_wallet].level_1;
      }
      if(_level == 2){
        qualified = qualifications[_wallet].level_2;
      }
      if(_level == 3){
        qualified = qualifications[_wallet].level_3;
      }
      if(_level == 4){
        qualified = qualifications[_wallet].level_4;
      }
      if(_level == 5){
        qualified = qualifications[_wallet].level_5;
      }
      if(_level == 6){
        qualified = qualifications[_wallet].level_6;
      }
      if(_level == 7){
        qualified = qualifications[_wallet].level_7;
      }
      if(_level == 8){
        qualified = qualifications[_wallet].level_8;
      }
      if(_level == 9){
        qualified = qualifications[_wallet].level_9;
      }
      if(_level == 10){
        qualified = qualifications[_wallet].level_10;
      }
      return qualified;
  }
  /**
  * @dev calculates commission for uplines.
  *
  * Access modified with OnlyAdmin
  *
  *
  * Requirements:
  *
  * - `_wallet` cannot be the zero.
  */
  function calculateLevelCommission(address payable _wallet) public onlyAdmin {
    address payable parentWallet = users[_wallet].refferer;
    uint256 etherValue = users[_wallet].etherValue;
    uint256 expValue = (etherValue * 30)/100;
    require(address(this).balance > expValue,"Unable to execute please contact admin");
    uint level = 1;
    while(level <= 10)
    {
        uint256 amount = 0;
        User memory parent = users[parentWallet];
        if(parentWallet == parent.refferer){
          break;
        }
        //checks user have package
        if(parent.package <= 0){
          break;
        }
        Plan memory levelCommission = plans[level];
        uint qualified = this.getQualification(parentWallet, level);
        if(parent.package >= levelCommission.package && parent.status && qualified > 0){
          amount = etherValue * levelCommission.percentage / 100;
          uint256 maxCommission = (parent.etherValue * 2) - parent.commissions;
          if(maxCommission <= amount )
          {
            amount = maxCommission;
          }
          amount = amount;
          parent.wallet.transfer(amount);
          users[parent.wallet].commissions += amount;
          emit DistributeCommission(parent.wallet, _wallet, amount);
        }
        if(parent.status){
          level++;
        }
         parentWallet = parent.refferer;
    }
    }
}
