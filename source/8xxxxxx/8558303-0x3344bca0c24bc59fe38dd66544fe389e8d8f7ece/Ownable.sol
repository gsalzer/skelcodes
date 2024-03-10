pragma solidity >=0.4.24 <0.6.0;
import "./IERC20Token.sol";
contract Ownable {
    address private _owner;
    mapping (address=>bool) private _managers;
    event OwnershipTransferred(address indexed prevOwner,address indexed newOwner);
    event WithdrawEtherEvent(address indexed receiver,uint256 indexed amount,uint256 indexed atime);
    //管理者处理事件
    event ManagerChange(address indexed manager,bool indexed isMgr);
    //modifier
    modifier onlyOwner{
        require(msg.sender == _owner, "sender not eq owner");
        _;
    }

    modifier onlyManager{
        require(_managers[msg.sender] == true, "不是管理员");
        _;
    }
    constructor() internal{
        _owner = msg.sender;
        _managers[msg.sender] = true;
    }

    function owner() public view returns(address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "newOwner can't be empty!");
        address prevOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(prevOwner,newOwner);
    }

    //管理员
    function changeManager(address account,bool isManager) public onlyOwner {
        _managers[account] = isManager;
        emit ManagerChange(account,isManager);
    }
    function isManager(address account) public view returns(bool) {
        return _managers[account];
    }

    /**
     * @dev Rescue compatible ERC20 Token
     *
     * @param tokenAddr ERC20 The address of the ERC20 token contract
     * @param receiver The address of the receiver
     * @param amount uint256
     */
    function rescueTokens(IERC20Token tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20Token _token = IERC20Token(tokenAddr);
        require(receiver != address(0),"receiver can't be empty!");
        uint256 balance = _token.balanceOf(address(this));
        require(balance >= amount,"balance is not enough!");
        require(_token.transfer(receiver, amount),"transfer failed!!");
    }

    /**
     * @dev Withdraw ether
     */
    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0),"address can't be empty");
        uint256 balance = address(this).balance;
        require(balance >= amount,"this balance is not enough!");
        to.transfer(amount);
       emit WithdrawEtherEvent(to,amount,now);
    }


}
