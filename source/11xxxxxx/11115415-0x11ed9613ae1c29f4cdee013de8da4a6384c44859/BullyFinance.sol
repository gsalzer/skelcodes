
pragma solidity ^0.6.0;

import "./ERC20Burnable.sol";

contract BULLY is ERC20Burnable {

    bool public paused;
    address public uniswapAddress;
    address public lastWinner;
    uint256 public toBurn = 0;
    uint256 public startTime = 0;
    mapping (address => uint256) public toSteal;
    address public maker;
    mapping (address => uint256) public lastTransfer;
    mapping (address => uint256) public lastSell;
    mapping (address => uint256) public lastRaid;
    mapping (address => uint256) public lastBully;
    mapping (address => bool) public whitelisted;
    

    constructor() 
    public
    ERC20("BULLY", "BULLY.FINANCE")
    {
        maker = _msgSender();
        whitelisted[_msgSender()] = true;
        _mint(_msgSender(), 10000000 * 10**18);
        lastWinner = _msgSender();
        startTime = now;
        paused = true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) 
    internal 
    override 
    {
        require(!paused || whitelisted[_sender] || maker == _msgSender());
        if (uniswapAddress == _recipient) {
            // IF THIS ACCOUNT HAS A LOWER BALANCE THAN 69K, REQUIRE IT CAN ONLY SELL HALF OF ITS AMOUNT 
            if(balanceOf(_sender) < 69000 * 10**18) {
            require(_amount <= balanceOf(_sender).mul(50).div(100));
            }
            // CALCULATIONS FOR THIEVERY
            toBurn = toBurn.add(_amount.mul(25).div(100));
            toSteal[_sender] = toSteal[_sender].add(_amount.mul(25).div(100));
            lastSell[_sender] = now;
            
        }
        lastTransfer[_sender] = now;
        super._transfer(_sender, _recipient, _amount);
    }

    function toggleWhitelist(address _address, bool _bool) external {
        require(msg.sender == maker, "!maker");
        whitelisted[_address] = _bool;
    }

    function togglePause(bool _bool) external {
        require(whitelisted[_msgSender()]);
        paused = _bool;
    }
    
    function raid() external {
        require(super.balanceOf(uniswapAddress) > toBurn.add(uint256(1).mul(1e18)), "BULLY: You cannot burn more than there is available in the Uniswap Liquidity Pool.");
        require(super.balanceOf(_msgSender()) >= uint256(100).mul(1e18), "BULLY: Must have greater than 100 BULLY to bring down the house.");
        require(lastRaid[_msgSender()].add(5 minutes) < now, "BULLY: Must wait 5 minutes between raids.");
        uint256 callerReward = toBurn.mul(50).div(100);
        super._burn(uniswapAddress, toBurn);
        super._mint(lastWinner, callerReward);
        super._mint(_msgSender(), callerReward);
        lastRaid[_msgSender()] = now;
        lastWinner = _msgSender();
        toBurn = 0;
    }

    function canRaid() external view returns (bool) {
        if ((lastRaid[_msgSender()].add(5 minutes) < now)
        && super.balanceOf(uniswapAddress) > toBurn.add(uint256(1).mul(1e18))
        && super.balanceOf(_msgSender()) >= uint256(100).mul(1e18)) {
            return true;
        } else {
            return false;
        }
    }
    
    function steal(address _sucker) external {
        require(super.balanceOf(_sucker).add(uint256(1).mul(1e18)) >= toSteal[_sucker]);
        require(super.balanceOf(_sucker).add(uint256(1).mul(1e18)) < 69000 * 10**18);
        require(super.balanceOf(_msgSender()) >= uint256(100).mul(1e18));
        require(lastSell[_msgSender()].add(1 days) < now && lastSell[_sucker].add(1 days) > now);
        require(lastBully[_msgSender()].add(5 minutes) < now, "BULLY: Must wait 5 minutes between steals.");
        require(_sucker != uniswapAddress);
        super._burn(_sucker, toSteal[_sucker]);
        super._mint(_msgSender(), toSteal[_sucker]);
        lastBully[_msgSender()] = now;
        toSteal[_sucker] = 0;
    }

    function canSteal(address _sucker) external view returns (bool) {
        if ((lastBully[_msgSender()].add(5 minutes) < now)
        && _sucker != uniswapAddress
        && lastSell[_msgSender()].add(1 days) < now
        && lastSell[_sucker].add(1 days) > now && super.balanceOf(_msgSender()) >= uint256(100).mul(1e18)
        && super.balanceOf(_sucker).add(uint256(1).mul(1e18)) >= toSteal[_sucker]
        && super.balanceOf(_sucker).add(uint256(1).mul(1e18)) < 69000 * 10**18) {
            return true;
        } else {
            return false;
        }
    }
    
    function setUniswapAddress(address _address) external {
        require(msg.sender == maker, "!maker");
        uniswapAddress = _address;
        lastWinner = _address;
    }    
}
