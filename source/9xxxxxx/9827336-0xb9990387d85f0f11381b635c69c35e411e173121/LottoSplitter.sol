pragma solidity ^0.5.14;

interface HEX {
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

contract LottoSplitter {

    event DistributedShares(
        uint256 timestamp,
        address indexed senderAddress,
        uint256 totalDistributed
    );
    
    event DistributedEthDonation(
        uint256 timestamp,
        address indexed donatorAddress,
        uint256 totalDonated
    );

    HEX internal hx = HEX(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);

    address payable internal KYLE = 0xD30BC4859A79852157211E6db19dE159673a67E2;
    address payable internal MICHAEL = 0xe551072153c02fa33d4903CAb0435Fb86F1a80cb;
    address payable internal DONATOR = 0x723e82Eb1A1b419Fb36e9bD65E50A979cd13d341;
    address payable internal MARCO = 0xbf1984B12878c6A25f0921535c76C05a60bdEf39;
    address payable internal SWIFT = 0x88BA4dc5571660A1693E421D83EC97015B53580D;
    address payable internal MARK = 0x35e9034f47cc00b8A9b555fC1FDB9598b2c245fD;
    
    mapping(address => bool) contributors;
    
    modifier onlyContributors(){
        require(contributors[msg.sender], "not a contributor");
        _;
    }
    
    constructor() public {
        contributors[KYLE] = true;
        contributors[MICHAEL] = true;
        contributors[DONATOR] = true;
        contributors[MARCO] = true;
        contributors[SWIFT] = true;
        contributors[MARK] = true;
    }
    
    function distribute () public {
        //get balance    
        uint256 balance = hx.balanceOf(address(this));
        require(balance > 99, "balance too low to distribute");
        //distribute
        uint256 share = balance / 6;
        hx.transfer(KYLE, share);
        hx.transfer(DONATOR, share);
        hx.transfer(MARCO, share);
        hx.transfer(SWIFT, share); 
        hx.transfer(MARK, share);
        uint256 newbalance = hx.balanceOf(address(this));
        if(newbalance < share){
            share = newbalance;
        }
        hx.transfer(MICHAEL,  share);
        emit DistributedShares(now, msg.sender, balance);
    }
    
    
    //fallback for eth sent to contract - auto distribute as donation
    function() external payable{
        donate();    
    }
    
    function donate() public payable {
        require(msg.value > 0);
        uint256 balance = msg.value;
        uint256 share = balance / 6;
        KYLE.transfer(share);
        DONATOR.transfer(share);
        MARCO.transfer(share);
        SWIFT.transfer(share); 
        MARK.transfer(share);
        uint256 newbalance = address(this).balance;
        if(newbalance < share){
            share = newbalance;
        }
        MICHAEL.transfer(share);
        emit DistributedEthDonation(now, msg.sender, balance);
    }
}
