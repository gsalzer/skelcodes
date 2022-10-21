// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20VotesComp.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IToken.sol";

contract Token is Ownable, ERC20VotesComp, IToken {
    // Token name
    string internal constant NAME = "Chadverse Token";

    // Token symbol
    string internal constant SYMBOL = "ROIDZ";

    /// @notice Token initialization
    constructor() ERC20(NAME, SYMBOL) ERC20Permit(NAME) {
        //solhint-disable-previous-line no-empty-blocks
    }

    /// @inheritdoc IToken
    function distribute(Distribution[] calldata distributions) external override onlyOwner {
        if (totalSupply() != uint256(0)) revert NonZeroTotalSupply(totalSupply());

        for (uint256 i = 0; i < distributions.length; i++) {
            _mint(distributions[i].recipient, distributions[i].amount);
        }
    }
}

