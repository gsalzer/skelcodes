// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./SafeDecimalMath.sol";
import "./EthReward.sol";
import './interface/IPriceFeed.sol';
import './interface/IEthVault.sol';
import "./AddressBook.sol";
import "./lib/AddressBookLib.sol";


contract LiquidationManager is VaultAccess, ILiquidationManager {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    function liquidate(  
            uint256 vauldId,
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward ) payable external virtual override  onlyVault {

    }
}



contract TestLiquidationManager is LiquidationManager {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    function liquidate(  
            uint256 vauldId,
            address addr,
            uint256 ethAmount,
            uint256 chickAmount,
            uint256 interest,
            uint256 reward ) payable external override  onlyVault {
        
                
    }
}


