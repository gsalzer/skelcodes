pragma solidity >=0.4.21 <0.6.0;

import "./SafeMath.sol";

contract Earnings {
    using SafeMath for *;

    // -------------------- mapping ------------------------ //
    mapping(address => UserWithdraw) public userWithdraw; // record user withdraw reward information

    // -------------------- variate ------------------------ //
    uint8 constant internal percent = 100;
    uint8 constant internal remain = 20;       // Static and dynamic rewards returns remain at 20 percent

    address public resonanceAddress;
    address public owner;

    // -------------------- struct ------------------------ //
    struct UserWithdraw {
        uint256 withdrawStraight; // withdraw straight eth amount
        uint256 withdrawTeam;  // withdraw team eth amount
        uint256 withdrawStatic; // withdraw static eth amount
        uint256 withdrawTerminator;//withdraw terminator amount
        uint256 withdrawNode;  // withdraw node amount
        uint256 lockEth;      // user lock eth
        uint256 activateEth;  // record user activate eth
    }

    constructor()
    public{
        owner = msg.sender;
    }

    // -------------------- modifier ------------------------ //
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier onlyResonance (){
        require(msg.sender == resonanceAddress);
        _;
    }

    // -------------------- owner api ------------------------ //
    function allowResonance(address _addr) public onlyOwner() {
        resonanceAddress = _addr;
    }

    // -------------------- Resonance api ------------------------ //
    // calculate actual reinvest amount, include amount + lockEth
    function calculateReinvestAmount(
        address reinvestAddress,
        uint256 amount,
        uint256 userAmount,
        uint8 requireType)//type: 1 => straightEth, 2 => teamEth, 3 => withdrawStatic, 4 => withdrawNode
    public
    onlyResonance()
    returns (uint256)
    {
        if (requireType == 1) {
            require(amount.add((userWithdraw[reinvestAddress].withdrawStatic).mul(100).div(80)) <= userAmount);
        } else if (requireType == 2) {
            require(amount.add((userWithdraw[reinvestAddress].withdrawStraight).mul(100).div(80)) <= userAmount.add(amount));
        } else if (requireType == 3) {
            require(amount.add((userWithdraw[reinvestAddress].withdrawTeam).mul(100).div(80)) <= userAmount.add(amount));
        } else if (requireType == 5) {
            require(amount.add((userWithdraw[reinvestAddress].withdrawNode).mul(100).div(80)) <= userAmount);
        }

        //      userWithdraw[reinvestAddress].lockEth = userWithdraw[reinvestAddress].lockEth.add(amount.mul(remain).div(100));\
        uint256 _active = userWithdraw[reinvestAddress].lockEth - userWithdraw[reinvestAddress].activateEth;
        if (amount > _active) {
            userWithdraw[reinvestAddress].activateEth += _active;
            amount = amount.add(_active);
        } else {
            userWithdraw[reinvestAddress].activateEth = userWithdraw[reinvestAddress].activateEth.add(amount);
            amount = amount.mul(2);
        }

        return amount;
    }

    function routeAddLockEth(
        address withdrawAddress,
        uint256 amount,
        uint256 lockProfits,
        uint256 userRouteEth,
        uint256 routeType)
    public
    onlyResonance()
    {
        if (routeType == 1) {
            addLockEthStatic(withdrawAddress, amount, lockProfits, userRouteEth);
        } else if (routeType == 2) {
            addLockEthStraight(withdrawAddress, amount, userRouteEth);
        } else if (routeType == 3) {
            addLockEthTeam(withdrawAddress, amount, userRouteEth);
        } else if (routeType == 4) {
            addLockEthTerminator(withdrawAddress, amount, userRouteEth);
        } else if (routeType == 5) {
            addLockEthNode(withdrawAddress, amount, userRouteEth);
        }
    }

    function addLockEthStatic(address withdrawAddress, uint256 amount, uint256 lockProfits, uint256 userStatic)
    internal
    {
        require(amount.add(userWithdraw[withdrawAddress].withdrawStatic.mul(100).div(percent - remain)) <= userStatic);
        userWithdraw[withdrawAddress].lockEth += lockProfits;
        userWithdraw[withdrawAddress].withdrawStatic += amount.sub(lockProfits);
    }

    function addLockEthStraight(address withdrawAddress, uint256 amount, uint256 userStraightEth)
    internal
    {
        require(amount.add(userWithdraw[withdrawAddress].withdrawStraight.mul(100).div(percent - remain)) <= userStraightEth);
        userWithdraw[withdrawAddress].lockEth += amount.mul(remain).div(100);
        userWithdraw[withdrawAddress].withdrawStraight += amount.mul(percent - remain).div(100);
    }

    function addLockEthTeam(address withdrawAddress, uint256 amount, uint256 userTeamEth)
    internal
    {
        require(amount.add(userWithdraw[withdrawAddress].withdrawTeam.mul(100).div(percent - remain)) <= userTeamEth);
        userWithdraw[withdrawAddress].lockEth += amount.mul(remain).div(100);
        userWithdraw[withdrawAddress].withdrawTeam += amount.mul(percent - remain).div(100);
    }

    function addLockEthTerminator(address withdrawAddress, uint256 amount, uint256 withdrawAmount)
    internal
    {
        userWithdraw[withdrawAddress].lockEth += amount.mul(remain).div(100);
        userWithdraw[withdrawAddress].withdrawTerminator += withdrawAmount;
    }

    function addLockEthNode(address withdrawAddress, uint256 amount, uint256 userNodeEth)
    internal
    {
        require(amount.add(userWithdraw[withdrawAddress].withdrawNode.mul(100).div(percent - remain)) <= userNodeEth);
        userWithdraw[withdrawAddress].lockEth += amount.mul(remain).div(100);
        userWithdraw[withdrawAddress].withdrawNode += amount.mul(percent - remain).div(100);
    }


    function addActivateEth(address userAddress, uint256 amount)
    public
    onlyResonance()
    {
        uint256 _afterFounds = getAfterFounds(userAddress);
        if (amount > _afterFounds) {
            userWithdraw[userAddress].activateEth = userWithdraw[userAddress].lockEth;
        }
        else {
            userWithdraw[userAddress].activateEth += amount;
        }
    }

    function changeWithdrawTeamZero(address userAddress)
    public
    onlyResonance()
    {
        userWithdraw[userAddress].withdrawTeam = 0;
    }

    function getWithdrawStraight(address reinvestAddress)
    public
    view
    onlyResonance()
    returns (uint256)
    {
        return userWithdraw[reinvestAddress].withdrawStraight;
    }

    function getWithdrawStatic(address reinvestAddress)
    public
    view
    onlyResonance()
    returns (uint256)
    {
        return userWithdraw[reinvestAddress].withdrawStatic;
    }

    function getWithdrawTeam(address reinvestAddress)
    public
    view
    onlyResonance()
    returns (uint256)
    {
        return userWithdraw[reinvestAddress].withdrawTeam;
    }

    function getWithdrawNode(address reinvestAddress)
    public
    view
    onlyResonance()
    returns (uint256)
    {
        return userWithdraw[reinvestAddress].withdrawNode;
    }

    function getAfterFounds(address userAddress)
    public
    view
    onlyResonance()
    returns (uint256)
    {
        return userWithdraw[userAddress].lockEth - userWithdraw[userAddress].activateEth;
    }

    function getStaticAfterFounds(address reinvestAddress) public
    view
    onlyResonance()
    returns (uint256, uint256)
    {
        return (userWithdraw[reinvestAddress].withdrawStatic, userWithdraw[reinvestAddress].lockEth - userWithdraw[reinvestAddress].activateEth);
    }

    function getStaticAfterFoundsTeam(address userAddress) public
    view
    onlyResonance()
    returns (uint256, uint256, uint256)
    {
        return (userWithdraw[userAddress].withdrawStatic, userWithdraw[userAddress].lockEth - userWithdraw[userAddress].activateEth, userWithdraw[userAddress].withdrawTeam);
    }

    function getUserWithdrawInfo(address reinvestAddress) public
    view
    onlyResonance()
    returns (
        uint256 withdrawStraight,
        uint256 withdrawTeam,
        uint256 withdrawStatic,
        uint256 withdrawNode
    )
    {
        withdrawStraight = userWithdraw[reinvestAddress].withdrawStraight;
        withdrawTeam = userWithdraw[reinvestAddress].withdrawTeam;
        withdrawStatic = userWithdraw[reinvestAddress].withdrawStatic;
        withdrawNode = userWithdraw[reinvestAddress].withdrawNode;
    }

}

