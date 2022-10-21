// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SatoshiblesSpecialEdition is ERC721, Ownable {
    using SafeMath for uint256;

    /// The base URI for fetching token data
    string public baseURI = "https://api.satoshibles.com/token/special/";

    /// Setup the token counter
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /// Boom... Let's go!
    constructor() ERC721("Satoshibles: Special Edition", "SBLSE") {
        _mintTokens(2);
    }

    /**
     * @dev Mint a new number of tokens.
     */
    function mintTokens(uint numberOfTokens) public onlyOwner {
        _mintTokens(numberOfTokens);
    }

    /**
 * @dev The internal minting function.
 */
    function _mintTokens(uint numberOfTokens) private {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();

            uint256 id = totalSupply();

            _safeMint(msg.sender, id);
        }
    }

    /**
     * @dev Returns the current total supply derived from token count.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @dev Base URI for computing tokenURI.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
    * @dev Set the base URI.
    */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Gives ability to withdraw any ETH that may be sent to the contract.
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw");

        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev Gives ability to withdraw any other tokens that are sent to the smart contract. WARNING: Double check token is legit before calling this.
     */
    function withdrawOther(IERC20 token, address to, bool hasVerifiedToken) public onlyOwner {
        require(hasVerifiedToken, "Need to verify token");
        require(token.balanceOf(address(this)) > 0, "Nothing to withdraw");

        token.transfer(to, token.balanceOf(address(this)));
    }
}

