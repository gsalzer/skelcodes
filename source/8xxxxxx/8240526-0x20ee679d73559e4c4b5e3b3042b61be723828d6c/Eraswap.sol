
pragma solidity ^0.5.2;

import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";
import "./ERC20Pausable.sol";


contract Eraswap is ERC20Detailed,ERC20Burnable,ERC20Capped,ERC20Pausable {


    event NRTManagerAdded(address NRTManager);

    constructor()
        public
         ERC20Detailed ("Era Swap", "ES", 18) ERC20Capped(9100000000000000000000000000) {
             mint(msg.sender, 910000000000000000000000000);
        }

    int256 public timeMachineDepth;


    // gives the time machine time
    function mou() public view returns(uint256) {
        if(timeMachineDepth < 0) {
            return now - uint256(timeMachineDepth);
        } else {
            return now + uint256(timeMachineDepth);
        }
    }

    // sets the time machine depth
    function setTimeMachineDepth(int256 _timeMachineDepth) public {
        timeMachineDepth = _timeMachineDepth;
    }

    function goToFuture(uint256 _seconds) public {
        timeMachineDepth += int256(_seconds);
    }

    function goToPast(uint256 _seconds) public {
        timeMachineDepth -= int256(_seconds);
    }


    /**
    * @dev Function to add NRT Manager to have minting rights
    * It will transfer the minting rights to NRTManager and revokes it from existing minter
    * @param NRTManager Address of NRT Manager C ontract
    */
    function AddNRTManager(address NRTManager) public onlyMinter returns (bool) {
        addMinter(NRTManager);
        addPauser(NRTManager);
        renounceMinter();
        renouncePauser();
        emit NRTManagerAdded(NRTManager);
        return true;
      }

}

