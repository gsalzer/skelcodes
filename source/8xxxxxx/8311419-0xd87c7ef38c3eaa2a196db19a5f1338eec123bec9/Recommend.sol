pragma solidity >=0.4.21 <0.6.0;

contract Recommend {
    // -------------------- mapping ------------------------ //
    mapping(address => RecommendRecord) internal recommendRecord;  // record straight reward information


    // -------------------- struct ------------------------ //
    struct RecommendRecord {
        uint256[] straightTime;  // this record start time, 3 days timeout
        address[] refeAddress; // referral address
        uint256[] ethAmount; // this record buy eth amount
        bool[] supported; // false means unsupported
    }

    // -------------------- variate ------------------------ //
    address public resonanceAddress;
    address public owner;

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

    // -------------------- Resonance api ----------------//
    function getRecommendByIndex(uint256 index, address userAddress)
    public
    view
//    onlyResonance() TODO
    returns (
        uint256 straightTime,
        address refeAddress,
        uint256 ethAmount,
        bool supported
    )
    {
        straightTime = recommendRecord[userAddress].straightTime[index];
        refeAddress = recommendRecord[userAddress].refeAddress[index];
        ethAmount = recommendRecord[userAddress].ethAmount[index];
        supported = recommendRecord[userAddress].supported[index];
    }

    function pushRecommend(
        address userAddress,
        address refeAddress,
        uint256 ethAmount
    )
    public
    onlyResonance()
    {
        RecommendRecord storage _recommendRecord = recommendRecord[userAddress];
        _recommendRecord.straightTime.push(block.timestamp);
        _recommendRecord.refeAddress.push(refeAddress);
        _recommendRecord.ethAmount.push(ethAmount);
        _recommendRecord.supported.push(false);
    }

    function setSupported(uint256 index, address userAddress, bool supported)
    public
    onlyResonance()
    {
        recommendRecord[userAddress].supported[index] = supported;
    }

    // -------------------- user api ------------------------ //
    // get current address's recommend record
    function getRecommendRecord()
    public
    view
    returns (
        uint256[] memory straightTime,
        address[] memory refeAddress,
        uint256[] memory ethAmount,
        bool[]    memory supported
    )
    {
        RecommendRecord memory records = recommendRecord[msg.sender];
        straightTime = records.straightTime;
        refeAddress = records.refeAddress;
        ethAmount = records.ethAmount;
        supported = records.supported;
    }

}

