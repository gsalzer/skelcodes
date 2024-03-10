pragma solidity >=0.4.21 <0.6.0;

contract TeamRewards {

    // -------------------- mapping ------------------------ //
    mapping(address => UserSystemInfo) public userSystemInfo;// user system information mapping
    mapping(address => address[])      public whitelistAddress;   // Whitelist addresses defined at the beginning of the project

    // -------------------- array ------------------------ //
    address[5] internal admin = [address(0x8434750c01D702c9cfabb3b7C5AA2774Ee67C90D), address(0xD8e79f0D2592311E740Ff097FFb0a7eaa8cb506a), address(0x740beb9fa9CCC6e971f90c25C5D5CC77063a722D), address(0x1b5bbac599f1313dB3E8061A0A65608f62897B0C), address(0x6Fd6dF175B97d2E6D651b536761e0d36b33A9495)];

    // -------------------- variate ------------------------ //
    address public resonanceAddress;
    address public owner;
    bool    public whitelistTime;

    // -------------------- event ------------------------ //
    event TobeWhitelistAddress(address indexed user, address adminAddress);

    // -------------------- structure ------------------------ //
    // user system information
    struct UserSystemInfo {
        address userAddress;     // user address
        address straightAddress; // straight Address
        address whiteAddress;    // whiteList Address
        address adminAddress;    // admin Address
        bool whitelist;  // if whitelist
    }

    constructor()
    public{
        whitelistTime = true;
        owner = msg.sender;
    }

    // -------------------- modifier ------------------------ //
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin () {
        address adminAddress = msg.sender;
        require(adminAddress == admin[0] || adminAddress == admin[1] || adminAddress == admin[2] || adminAddress == admin[3] || adminAddress == admin[4]);
        _;
    }

    modifier mustAdmin (address adminAddress){
        require(adminAddress != address(0));
        require(adminAddress == admin[0] || adminAddress == admin[1] || adminAddress == admin[2] || adminAddress == admin[3] || adminAddress == admin[4]);
        _;
    }

    modifier onlyResonance (){
        require(msg.sender == resonanceAddress);
        _;
    }

    // -------------------- user api ----------------//
    function toBeWhitelistAddress(address adminAddress, address whitelist)
    public
    mustAdmin(adminAddress)
    onlyAdmin()
    payable
    {
        require(whitelistTime);
        require(!userSystemInfo[whitelist].whitelist);
        whitelistAddress[adminAddress].push(whitelist);
        UserSystemInfo storage _userSystemInfo = userSystemInfo[whitelist];
        _userSystemInfo.straightAddress = adminAddress;
        _userSystemInfo.whiteAddress = whitelist;
        _userSystemInfo.adminAddress = adminAddress;
        _userSystemInfo.whitelist = true;
        emit TobeWhitelistAddress(whitelist, adminAddress);
    }

    // -------------------- Resonance api ----------------//
    function referralPeople(address userAddress,address referralAddress)
    public
    onlyResonance()
    {
        UserSystemInfo storage _userSystemInfo = userSystemInfo[userAddress];
        _userSystemInfo.straightAddress = referralAddress;
        _userSystemInfo.whiteAddress = userSystemInfo[referralAddress].whiteAddress;
        _userSystemInfo.adminAddress = userSystemInfo[referralAddress].adminAddress;
    }

    function getUserSystemInfo(address userAddress)
    public
    view
    returns (
        address  straightAddress,
        address whiteAddress,
        address adminAddress,
        bool whitelist)
    {
        straightAddress = userSystemInfo[userAddress].straightAddress;
        whiteAddress = userSystemInfo[userAddress].whiteAddress;
        adminAddress = userSystemInfo[userAddress].adminAddress;
        whitelist    = userSystemInfo[userAddress].whitelist;
    }

    function getUserreferralAddress(address userAddress)
    public
    view
    onlyResonance()
    returns (address )
    {
        return userSystemInfo[userAddress].straightAddress;
    }

    // -------------------- Owner api ----------------//
    function allowResonance(address _addr) public onlyOwner() {
        resonanceAddress = _addr;
    }

    // -------------------- Admin api ---------------- //
    // set whitelist close
    function setWhitelistTime(bool off)
    public
    onlyAdmin()
    {
        whitelistTime = off;
    }

    function getWhitelistTime()
    public
    view
    returns (bool)
    {
        return whitelistTime;
    }

    // get all whitelist by admin address
    function getAdminWhitelistAddress(address adminx)
    public
    view
    returns (address[] memory)
    {
        return whitelistAddress[adminx];
    }

    // check if the user is whitelist
    function isWhitelistAddress(address user)
    public
    view
    returns (bool)
    {
        return userSystemInfo[user].whitelist;
    }

    function getStraightAddress (address userAddress)
    public
    view
    returns (address  straightAddress)
    {
        straightAddress = userSystemInfo[userAddress].straightAddress;
    }
}

