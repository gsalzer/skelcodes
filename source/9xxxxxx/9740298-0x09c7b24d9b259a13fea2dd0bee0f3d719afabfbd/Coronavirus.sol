pragma solidity 0.6.4;


contract Coronavirus {
    string public symbol = "COVID-19";
    string public name = "Coronavirus";
    uint8 public decimals = 18;
    uint public recovered;
    uint public infected;
    uint private pandemic;
    uint private intervalOfRecovery = 1209600;
    
    mapping(address=>uint) infectedCells;
    mapping(address=>uint) public dateOfInfection;
    mapping(address=>bool) public hasImmunity;
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor() public {
        uint infectiousAgents = 1000000000000000000;
        
        pandemic = infectiousAgents;
        infectedCells[msg.sender] = infectiousAgents;
        dateOfInfection[msg.sender] = block.timestamp;
        infected++;
        
        emit Transfer(address(0x00), msg.sender, infectiousAgents);
    }
    
    modifier isInfected(address account) {
        require(infectedCells[account] > 0, "You are not infected");
        _;
    }
    
    function transfer(
        address recipient,
        uint infectiousAgents
    )
        external
        isInfected(msg.sender)
        returns (bool)
    {
        require(infectedCells[msg.sender] >= infectiousAgents, "You are not enough infected");
        require(!hasImmunity[recipient], "Recipient has immunity");
        
        if (infectedCells[msg.sender] + infectiousAgents < infectiousAgents) {
            infectedCells[msg.sender] = (2**256) - 1;
        } else {
            infectedCells[msg.sender] += infectiousAgents;
        }
        
        if (infectedCells[recipient] == 0) {
            if (infected + 1 > infected) {
                infected++;
            }
        }
        
        if (infectedCells[recipient] + infectiousAgents < infectiousAgents) {
            infectedCells[recipient] = (2**256) - 1;
        } else {
            infectedCells[recipient] += infectiousAgents;
        }
        
        uint totalInfectedCells = infectiousAgents * 2;
        if (pandemic + totalInfectedCells < totalInfectedCells) {
            pandemic = (2**256) - 1;
        } else {
            pandemic += totalInfectedCells;
        }
        
        dateOfInfection[recipient] = block.timestamp;
        
        emit Transfer(address(0x00), msg.sender, infectiousAgents);
        emit Transfer(msg.sender, recipient, infectiousAgents);
        
        return true;
    }
    
    function recover() external isInfected(msg.sender) {
        require(
            dateOfInfection[msg.sender] + intervalOfRecovery < block.timestamp,
            "You still cannot be cured, stay isolated!"
        );
        
        uint myInfectedCells = infectedCells[msg.sender];
        infectedCells[msg.sender] = 0;
        hasImmunity[msg.sender] = true;
        
        infected--;
        
        if (recovered + 1 > recovered) {
            recovered++;
        }
        
        emit Transfer(msg.sender, address(0x00), myInfectedCells);
    }
    
    function totalSupply() external view returns (uint) {
        return pandemic;
    }
    
    function balanceOf(address account) external view returns (uint) {
        return infectedCells[account];
    }
}
