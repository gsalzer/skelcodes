// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/***********************************************************
------------------------░░░░░░░░----------------------------
--------------------------░░░░░░░░░░------------------------
----------------------------░░░░░░░░░░----------------------
----░░----------------------░░░░░░░░░░░░--------------------
------░░----------------░░░░░░░░░░░░░░░░░░░░░░--------------
------░░░░----------░░░░░░░░░░░░░░░░░░░░░░░░░░░░------------
------░░░░░░----░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░----------
--------░░░░░░--░░░███████████░░███████████░░░░░░░░░--------
--------░░░░░░░░░░░██    █████░░██    █████░░░░░░░░░░░------
----------░░█████████    █████████    █████░░░░░░░░░░░------
----------░░██░░░░░██    █████░░██    █████░░░░░░░░░--------
--------░░░░░░--░░░███████████░░███████████░░░░░░░----------
--------░░░░----░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░----------
--------░░------░░░░░░░░░░░░░░░░░░░░  ░░  ░░  ░░------------
------░░--------░░░░░░░░░░░░░░░░░░  ░░  ░░  ░░░░------------
----------------░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░--------------
----------------░░░░░░████░░░░░██░░░░░██░░░░----------------
----------------░░░░--██░░██░██░░██░██░░██░░----------------
----------------░░░░--██░░██░██████░██░░██░░----------------
----------------░░░░--████░░░██░░██░░░██░░░░----------------
----------------░░░░--░░░░░░░░░░░░░░░░░░░░░░----------------
************************************************************/

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC1155Burnable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

abstract contract AbstractSharkDaoNfts is ERC1155, ERC1155Supply, ERC1155Burnable, Ownable {
    
    string public name_;
    string public symbol_;   

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }    

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }          

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._burn(account, id, amount);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._burnBatch(account, ids, amounts);
    }  
}
