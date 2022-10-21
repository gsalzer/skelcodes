pragma solidity 0.5.0;

import "./Ownable.sol";
import "./ERC20Detailed.sol";
import "./ERC20Mintable.sol";
import "./ERC20Pausable.sol";

/**
* @title CrowdliToken
*/
contract CrowdliToken is ERC20Detailed, ERC20Mintable, ERC20Pausable, Ownable {
	/**
	 * Holds the addresses of the investors
	 */
    address[] public investors;

    constructor (string memory _name, string memory _symbol, uint8 _decimals) ERC20Detailed(_name,_symbol,_decimals) public {
    }
    
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
         if (balanceOf(account) == 0) {
            investors.push(account);
         }
         return super.mint(account, amount);
    }
    
    
    function initToken(address _directorsBoard,address _crowdliSTO) external onlyOwner{
    	addMinter(_directorsBoard);
    	addMinter(_crowdliSTO);
    	addPauser(_directorsBoard);
    	addPauser(_crowdliSTO);
    }
    
}


