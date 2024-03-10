pragma solidity ^0.5.8;

contract LuckyDrawBasic {
    function buyTicket(address addr, uint256 phase) external;
    function aggregateIcexWinners(uint256 phase) external;
    function getWinners(uint256 phase) external view returns(address[] memory);
}

contract LuckyDraw is LuckyDrawBasic {
    /*
     * STATES
     */
    address public master;
    address public caller;

    bool public paused;

    uint winnerCount = 10;
    mapping (uint256 => address[]) winnerList;
    mapping (uint256 => mapping(address => bool)) playerList;
    mapping (uint256 => uint256) playerNumbers;
    uint nonce = 0;

    /*
     * MODIFIERS
     */
    /// only master can call the function
    modifier onlyOwner {
        require(master == msg.sender, "only owner can call");
        _;
    }

    /// only master can call the function
    modifier onlyCaller {
        require(caller == msg.sender, "only caller can call");
        _;
    }

    /// function not paused
    modifier notPaused {
        require(paused == false, "function is paused");
        _;
    }

    constructor() public {
        master = msg.sender;
    }

    function setCaller(address who) external onlyOwner {
        caller = who;
    }

    function setOwner(address who) external onlyOwner {
        master = who;
    }

    function setPause(bool value) external onlyOwner {
        paused = value;
    }

    function buyTicket(address addr, uint256 phase) external onlyCaller notPaused {
        if (!playerList[phase][addr]){
            playerNumbers[phase]++;
            if (winnerList[phase].length < winnerCount){
                winnerList[phase].push(addr);
            }else {
                uint index = randomIndex(addr, playerNumbers[phase]);
                if (index < winnerCount){
                    winnerList[phase][index] = addr;
                }
            }
            playerList[phase][addr] = true;
        }
    }

    // costs a bit, but will only invoke once, and paid by operator
    function aggregateIcexWinners(uint256 phase) external onlyCaller notPaused {
        for(uint i = 0 ; i < phase; ++i) {
            address[] memory candidates = winnerList[i];
            for(uint j = 0; j < candidates.length; ++j) {
                if (!playerList[phase][candidates[j]]) {
                    if (winnerList[phase].length < winnerCount) {
                        winnerList[phase].push(candidates[j]);
                    } else {
                        uint index = randomIndex(candidates[j], winnerCount * (phase + 1));
                        if (index < winnerCount){
                            winnerList[phase][index] = candidates[j];
                        }
                    }
                }
            }
        }
    }

    function getWinners(uint256 phase) external view returns(address[] memory) {
        return winnerList[phase];
    }

    function randomIndex(address addr, uint number) internal returns (uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(now, addr, nonce))) % number;
        nonce++;
        return randomnumber;
    }
}

