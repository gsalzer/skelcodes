// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./ERC20.sol";
import "./ERC721.sol";

contract TokenMultiCall {
    function getErc20Data(address addr)
        public
        view
        returns (string memory name, string memory symbol, uint256 totalSupply)
    {
        ERC20 erc20 = ERC20(addr);
        string memory _name = erc20.name();
        string memory _symbol = erc20.symbol();
        uint256 _totalSupply = erc20.totalSupply();

        return (_name, _symbol, _totalSupply);
    }

    function getErc721Data(address addr)
        public
        view
        returns (string memory name, string memory symbol)
    {
        ERC721 erc721 = ERC721(addr);
        string memory _name = erc721.name();
        string memory _symbol = erc721.symbol();

        return (_name, _symbol);
    }

    function getErc20And721Data(address erc20Addr, address erc721Addr)
        public
        view
        returns (
            string memory erc20Name,
            string memory erc20Symbol,
            uint256 erc20TotalSupply,
            string memory erc721name,
            string memory erc721symbol
        )
    {
        (string memory _erc20Name, string memory _erc20Symbol, uint256 _erc20TotalSupply) = getErc20Data(
            erc20Addr
        );
        (string memory _erc721Name, string memory _erc721Symbol) = getErc721Data(
            erc721Addr
        );

        return (
            _erc20Name,
            _erc20Symbol,
            _erc20TotalSupply,
            _erc721Name,
            _erc721Symbol
        );
    }

    function getDoubleErc20Data(address addr1, address addr2)
        public
        view
        returns (
            string memory name1,
            string memory symbol1,
            uint256 totalSupply1,
            string memory name2,
            string memory symbol2,
            uint256 totalSupply2
        )
    {
        (string memory _name1, string memory _symbol1, uint256 _totalSupply1) = getErc20Data(
            addr1
        );
        (string memory _name2, string memory _symbol2, uint256 _totalSupply2) = getErc20Data(
            addr2
        );

        return (
            _name1,
            _symbol1,
            _totalSupply1,
            _name2,
            _symbol2,
            _totalSupply2
        );
    }

}

