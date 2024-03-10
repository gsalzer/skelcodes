// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/spadefiannce/openzeppelin-contracts/blob/master/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "https://github.com/spadefiannce/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";
import "https://github.com/spadefiannce/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";


interface Vault{
    function depositWithPid(uint256 _pid, uint256 _amount) external ;
    function depositWithPidMap(uint256 _pid, uint256 _amount) external ;
    function depositWithPidGov(address _address, uint256 _pid, uint256 _amount) external ;
    function withdrawWithPid(uint256 _pid, uint256 _amount) external ;
    function getPoolNumBySingleToken(address _singleToken) external view returns (uint256 num) ;
}

contract WapperToken is ERC20PresetMinterPauser{
    uint8 tokenDecimals;
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    constructor(string memory name, string memory symbol,uint8 _decimals) ERC20PresetMinterPauser(name, symbol) {
        _setupRole(TRANSFER_ROLE, address(this));
        _setupRole(TRANSFER_ROLE, address(0));
        tokenDecimals=_decimals;
    }
    
    //转账权限限制    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(hasRole(TRANSFER_ROLE, _msgSender())||hasRole(TRANSFER_ROLE, from)||hasRole(TRANSFER_ROLE, to), "sToken: must have transfer role transfer");
    }
    

    function decimals() public view virtual override returns (uint8) {
        return tokenDecimals;
    }    
    
    function mint(address to, uint256 amount) public override {
        require(false);
    }    
    
}




contract WapperTokenPool is WapperToken{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bytes32 public constant WITHDRAW_ROLE= keccak256("WITHDRAW_ROLE");

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");//管理员权限


    uint256 public frozenStakingTime = 3;
    address public bxhv2FundAddress;
    IERC20 public singleToken;

    mapping(address => uint256) public lastStakeTime;

    event GovStaked(address indexed user, uint256 amount);
    event MapStaked(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    uint256 public pid;
    address public vaultAddress;

    IERC20 public mapToken;

    
    constructor( 
        address singleToken_,
        string memory name,
        string memory symbol,
        uint8 _decimals,
        address _vaultAddress,
        address _mapToken
    ) WapperToken(name, symbol,_decimals)  {
        singleToken =IERC20(singleToken_);
        _setupRole(WITHDRAW_ROLE, _msgSender());
        _setupRole(GOVERNANCE_ROLE, _msgSender());

        vaultAddress=_vaultAddress;
        pid = Vault(vaultAddress).getPoolNumBySingleToken(singleToken_);
        bxhv2FundAddress=_msgSender();
        singleToken.safeApprove(vaultAddress,type(uint256).max);

        mapToken = IERC20(_mapToken);
    }

    modifier onlyGovernance() {
        require(
            hasRole(GOVERNANCE_ROLE, _msgSender()),
            'Caller is not governance'
        );
        _;
    }

    function mapXToken( ) 
        public 
    {
        uint256 amount = mapToken.balanceOf(msg.sender);

        if(amount==0){
            return;
        }

        mapToken.safeTransferFrom(msg.sender, address(this), amount);

        _mint(msg.sender,amount);//Mint sToken       
        lastStakeTime[msg.sender] = block.timestamp;
        Vault(vaultAddress).depositWithPidMap(pid,amount);
        emit MapStaked(msg.sender, amount);
    }


    function mapXToken( address _address ,uint256 _amount) 
        public onlyGovernance
    {
        _mint( _address ,_amount );//Mint sToken       
        lastStakeTime[ _address ] = block.timestamp;
        Vault(vaultAddress).depositWithPidGov( _address, pid, _amount);
        emit GovStaked(_address, _amount);
    }


    function stake(uint256 amount) 
        public 
    {
        if(amount==0){
            return;
        }
        singleToken.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender,amount);//Mint sToken       
        lastStakeTime[msg.sender] = block.timestamp;
        Vault(vaultAddress).depositWithPid(pid,amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) 
        public 
    {
        if(amount==0){
            return;
        }
        require(block.timestamp >= unfrozenStakeTime(msg.sender), "wapperTokenPool: Cannot withdrawal during freezing");
        Vault(vaultAddress).withdrawWithPid(pid,amount);
        _burn(msg.sender, amount);
        singleToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function unfrozenStakeTime(address account) public view returns (uint256) {
        return lastStakeTime[account] + frozenStakingTime;
    }
    //----------------------- admin setting---------------------------------//
    function withdrawRewardToFundAddress(address rewardTokenAddress,uint256 amount) external virtual  {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),  "wapperTokenPool: must have DEFAULT_ADMIN_ROLE");
        require(bxhv2FundAddress != address(0), 'wapperTokenPool: Zero address or self');
		require(rewardTokenAddress!=address(singleToken),"this is rewardToken!");		
        IERC20(rewardTokenAddress).transfer(bxhv2FundAddress,amount);
    }    


    function setbxhV2FundAddress(address bxhv2FundAddress_) external virtual  {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),  "wapperTokenPool: must have DEFAULT_ADMIN_ROLE");
        require(bxhv2FundAddress_ != address(0) && bxhv2FundAddress_ != address(this), 'wapperTokenPool: Zero address or self');
        bxhv2FundAddress = bxhv2FundAddress_;
    }
    
    function setFrozenStakingTime(uint256 frozenStakingTime_) external virtual  {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),  "wapperTokenPool: must have DEFAULT_ADMIN_ROLE");
		require(frozenStakingTime_<60*60*24*3);
        frozenStakingTime = frozenStakingTime_;
    }
    

    function withdrawEmergency(address tokenaddress,address to) public {
        require(hasRole(WITHDRAW_ROLE, _msgSender()), "wapperTokenPool: must have withdraw role to withdraw");  
		require(tokenaddress!=address(singleToken),"this is rewardToken!");
		require(to != address(0), 'wapperTokenPool: Zero address');		
        IERC20(tokenaddress).transfer(to,IERC20(tokenaddress).balanceOf(address(this)));
    }

    
    
}


