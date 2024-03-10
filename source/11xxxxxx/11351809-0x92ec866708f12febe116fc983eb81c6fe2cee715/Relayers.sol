pragma solidity 0.5.17;
	
import "./Ownable.sol";

contract Relayers is Ownable {

	struct Relayer {
		string name;
		string url;
	}
	Relayer[] public relayers;

	function removeRelayer(uint index) public onlyOwner {
        if (index >= relayers.length) return;

        for (uint i = index; i<relayers.length-1; i++){
            relayers[i] = relayers[i+1];
        }
        relayers.length--;
    }

    function addRelayer(string memory name, string memory url) public onlyOwner {
    	relayers.push(Relayer({
    		name:name,
    		url: url
    	}));
    }

    function relayersLength() external view returns (uint) {
    	return relayers.length;
    }
}
