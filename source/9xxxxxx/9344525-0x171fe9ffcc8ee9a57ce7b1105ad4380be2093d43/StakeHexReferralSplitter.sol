pragma solidity ^0.5.12;

contract HEX {
    function xfLobbyEnter(address referrerAddr)
    external
    payable;

    function xfLobbyExit(uint256 enterDay, uint256 count)
    external;

    function xfLobbyPendingDays(address memberAddr)
    external
    view
    returns (uint256[2] memory words);

    function balanceOf (address account)
    external
    view
    returns (uint256);

    function transfer (address recipient, uint256 amount)
    external
    returns (bool);

    function currentDay ()
    external
    view
    returns (uint256);
}

contract StakeHexReferralSplitter {

    event DistributedShares(
        uint40 timestamp,
        address indexed memberAddress,
        uint256 amount
    );

    HEX internal hx = HEX(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);

    address payable public alpha = 0xE9DED01D21C6DDbec4D56c1822dE41E511EdfF34; // 12.5
    address payable public bravo = 0x5a952b3501c827Ef96412C5CA61418DF93d955C4; // 15
    address payable public charlie = 0x072297fC12fca02f184e6bD7B99697b7490e5aBf; // 5
    address payable public delta = 0xe551072153c02fa33d4903CAb0435Fb86F1a80cb; // 15
    address payable public echo = 0x5eCb4D3B4b451b838242c3CF8404ef18f5C486aB; // 5
    address payable public foxtrot = 0x7f4F3E2c70D4FEE9cf9798F3d57629B5a1B5AF46; // 35
    address payable public golf = 0xD30BC4859A79852157211E6db19dE159673a67E2; // 12.5

    function distribute ()
    public
    {
        uint256 balance = hx.balanceOf(address(this));
        uint256 fivePercent;
        if(balance > 99){
            fivePercent = balance / 20;
            hx.transfer(charlie, fivePercent); // 5%
            hx.transfer(echo, fivePercent); // 5%
            hx.transfer(delta, 3*fivePercent); // 15%
            hx.transfer(bravo, 3*fivePercent); // 15%
            hx.transfer(foxtrot, 7*fivePercent); // 40%
            balance = balance - (15 * fivePercent); // 100% - 15*5% = 25%
            hx.transfer(alpha, balance >> 1); // floor(12.5%)
            hx.transfer(golf, balance - (balance >> 1)); // ceil(12.5%)
        }
    }

    // Probably never used, but better safe than sorry
    function flushEth()
    public
    {
        uint256 balance = address(this).balance;
        uint256 fivePercent;
        if(address(this).balance > 99){
            fivePercent = balance / 20;
            charlie.transfer(fivePercent); // 5%
            echo.transfer(fivePercent); // 5%
            delta.transfer(3*fivePercent); // 15%
            bravo.transfer(3*fivePercent); // 15%
            foxtrot.transfer(7*fivePercent); // 40%
            balance = balance - (15 * fivePercent); // 100% - 15*5% = 25%
            alpha.transfer(balance >> 1); // floor(12.5%)
            golf.transfer(balance - (balance >> 1)); // ceil(12.5%)
        }
    }

    function updatealpha(address payable newalpha)
    public
    {
        require(msg.sender == alpha && newalpha != address(0), "Changing user address restricted to that user");
        alpha = newalpha;
    }

    function updatebravo(address payable newbravo)
    public
    {
        require(msg.sender == bravo && newbravo != address(0), "Changing user address restricted to that user");
        bravo = newbravo;
    }

    function updatecharlie(address payable newcharlie)
    public
    {
        require(msg.sender == charlie && newcharlie != address(0), "Changing user address restricted to that user");
        charlie = newcharlie;
    }

    function updatedelta(address payable newdelta)
    public
    {
        require(msg.sender == delta && newdelta != address(0), "Changing user address restricted to that user");
        delta = newdelta;
    }

    function updateecho(address payable newecho)
    public
    {
        require(msg.sender == echo && newecho != address(0), "Changing user address restricted to that user");
        echo = newecho;
    }

    function updatefoxtrot(address payable newfoxtrot)
    public
    {
        require(msg.sender == foxtrot && newfoxtrot != address(0), "Changing user address restricted to that user");
        foxtrot = newfoxtrot;
    }

    function updategolf(address payable newgolf)
    public
    {
        require(msg.sender == golf && newgolf != address(0), "Changing user address restricted to that user");
        golf = newgolf;
    }
}
