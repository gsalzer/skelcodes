pragma solidity =0.5.10;

contract MJIB_CDBS {

    address owner;

    struct Evidence {
        bytes32 hash;
        uint time;
    }
    mapping (bytes32 => Evidence) evidenceList; 

    constructor() public {
        owner = msg.sender;
    }

    function createEvidence(bytes32 id, bytes32 hash) public {
        require(msg.sender == owner, "Permission Denied.");
        require(evidenceList[id].hash == 0x0, "Evidence exists.");
        require(evidenceList[id].time == 0, "Evidence exists.");
        evidenceList[id].hash = hash;
        evidenceList[id].time = now;
    }

    function getEvidence(bytes32 id) public view returns (bytes32, uint) {
        return (evidenceList[id].hash, evidenceList[id].time);
    }
}
