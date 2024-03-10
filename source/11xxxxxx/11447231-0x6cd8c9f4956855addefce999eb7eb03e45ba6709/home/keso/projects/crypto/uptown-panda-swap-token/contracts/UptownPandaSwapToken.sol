// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract UptownPandaSwapToken is ERC721Burnable, Ownable {
    using SafeMath for uint256;

    event SwapTokenCreated(address indexed sender, uint256 tokenId, uint256 timestamp);
    event TokensWithdrawn(uint256 amount, uint256 timestamp);

    IERC20 public uptownPanda;

    struct SwapToken {
        uint256 amount;
    }

    SwapToken[] public swapTokens;
    bool public isSwapEnabled;

    constructor(address _uptownPanda) public ERC721("UptownPandaTokenSwap", "$UP-SWAP") {
        uptownPanda = IERC20(_uptownPanda);
        isSwapEnabled = true;
    }

    modifier swapEnabled() {
        require(isSwapEnabled, "Swapping is not enabled at the moment.");
        _;
    }

    function setIsSwapEnabled(bool _isSwapEnabled) external onlyOwner {
        isSwapEnabled = _isSwapEnabled;
    }

    function swap() external swapEnabled returns (uint256) {
        uint256 balance = uptownPanda.balanceOf(msg.sender);
        require(balance > 0, "You have no $UP tokens.");

        uint256 allowance = uptownPanda.allowance(msg.sender, address(this));
        require(allowance >= balance, "Increase allowance before swapping.");

        uptownPanda.transferFrom(msg.sender, address(this), balance);

        swapTokens.push(SwapToken(balance));
        uint256 tokenId = swapTokens.length.sub(1);
        _safeMint(msg.sender, tokenId);

        emit SwapTokenCreated(msg.sender, tokenId, block.timestamp);
    }

    function checkBalance(address sender) external view returns (uint256) {
        uint256 holderSwapTokensCount = balanceOf(sender);
        uint256 balance = 0;
        for (uint256 i = 0; i < holderSwapTokensCount; i++) {
            balance = balance.add(swapTokens[tokenOfOwnerByIndex(sender, i)].amount);
        }
        return balance;
    }

    function withdraw() external onlyOwner {
        uint256 balance = uptownPanda.balanceOf(address(this));
        require(balance > 0, "There's nothing to withdraw.");
        uptownPanda.transfer(msg.sender, balance);
        emit TokensWithdrawn(balance, block.timestamp);
    }
}

