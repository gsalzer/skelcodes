//Be name khoda

//SPDX-License-Identifier: MIT
//Thank you DEA...
/* 

  ██████╗ ██████╗ ██╗███╗   ██╗██████╗  █████╗ ███████╗███████╗    ██╗██████╗  ██████╗ 
██╔════╝██╔═══██╗██║████╗  ██║██╔══██╗██╔══██╗██╔════╝██╔════╝    ██║██╔══██╗██╔═══██╗
██║     ██║   ██║██║██╔██╗ ██║██████╔╝███████║███████╗█████╗      ██║██████╔╝██║   ██║
██║     ██║   ██║██║██║╚██╗██║██╔══██╗██╔══██║╚════██║██╔══╝      ██║██╔═══╝ ██║   ██║
╚██████╗╚██████╔╝██║██║ ╚████║██████╔╝██║  ██║███████║███████╗    ██║██║     ╚██████╔╝
 ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝╚═╝      ╚═════╝ 
            
*/                                                                           


pragma solidity ^0.6.12;

import "./AccessControl.sol";
import "./ERC20.sol";

contract CoinbaseFutureToken is ERC20, AccessControl{

	

	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
	bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
	

	constructor() public ERC20("DEUS Synthetic Coinbase IOU", "wCOINBASE-IOU") {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);	
	}

	function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

	function burn(address from, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(from, amount);
    }


}

//...and thank you DEUS.
//Dar panah khoda
