pragma solidity ^0.5.0;

import "./IRobe.sol";
import "./IRobeSyntaxChecker.sol";
import "./IERC721Receiver.sol";

/**
  * @title General Purpose implementation of the Robe Interface
  * @author Marco Vasapollo <ceo@metaring.com>
  * @author Alessandro Mario Lagana Toschi <alet@risepic.com>
  * @author The OpenZeppelin ERC721 Implementation for the safeTransferFrom method. Thank you guys!
*/
contract Robe is IRobe {

    address private _voidAddress = address(0);

    address private _myAddress;

    address private _syntaxCheckerAddress;
    IRobeSyntaxChecker private _syntaxChecker;

    //Registers the owner of each NFT
    mapping(uint256 => address) private _owner;

    //Registers the balance for each owner
    mapping(address => uint256) private _balance;

    //Registers the approved operators that can transfer the ownership of a specific NFT
    mapping(uint256 => address) private _tokenOperator;

    //Registers the approved operators that can transfer the ownership of all the NFTs of a specific owner
    mapping(address => address) private _ownerOperator;

    //Registers the chain of composed NFT
    mapping(uint256 => uint256[]) private _chain;

    //Registers the position of the NFT in its chain
    mapping(uint256 => uint256) private _positionInChain;

    //Registers the root NFT of each NFT
    mapping(uint256 => uint256) private _root;

    //The content of each NFT
    bytes[] private _data;

    constructor(address syntaxCheckerAddress) public {
        _myAddress = address(this);
        if(syntaxCheckerAddress != _voidAddress) {
            _syntaxCheckerAddress = syntaxCheckerAddress;
            _syntaxChecker = IRobeSyntaxChecker(_syntaxCheckerAddress);
        }
    }

    function() external payable {
        revert("ETH not accepted");
    }

    /**
      * Creates a new ERC 721 NFT
      * @return a unique tokenId
      */
    function mint(bytes memory payload) public returns(uint256) {
        return _mintAndOrAttach(_data.length, payload, msg.sender);
    }

    /**
      * Attaches a new ERC 721 NFT to an already-existing Token
      * to create a composed NFT
      * @return a unique tokenId
      */
    function mint(uint256 rootTokenId, bytes memory payload) public returns(uint256) {
        return _mintAndOrAttach(rootTokenId, payload, msg.sender);
    }

    function _mintAndOrAttach(uint256 rootTokenId, bytes memory payload, address owner) private returns(uint256) {
        uint256 newTokenId = _data.length;
        if(rootTokenId != newTokenId) {
            require(_owner[rootTokenId] == owner, "Extend an already-existing chain of someone else is forbidden");
        }
        if(_syntaxCheckerAddress != _voidAddress) {
            require(_syntaxChecker.check(rootTokenId, newTokenId, owner, payload, _myAddress), "Invalid payload Syntax");
        }
        _data.push(payload);
        if(rootTokenId == newTokenId) {
            _owner[rootTokenId] = owner;
        }
        _balance[owner] = _balance[owner] + 1;
        _root[newTokenId] = rootTokenId;
        _positionInChain[newTokenId] = _chain[rootTokenId].length;
        _chain[rootTokenId].push(newTokenId);
        return newTokenId;
    }

    /**
      * @return all the tokenIds that composes the givend NFT
      */
    function getChain(uint256 tokenId) public view returns(uint256[] memory) {
        return _chain[_root[tokenId]];
    }

    /**
      * @return the root NFT of this tokenId
      */
    function getRoot(uint256 tokenId) public view returns(uint256) {
        return _root[tokenId];
    }

    /**
     * @return the content of a NFT
     */
    function getContent(uint256 tokenId) public view returns(bytes memory) {
        return _data[tokenId];
    }

    /**
     * @return the position in the chain of this NFT
     */
    function getPositionOf(uint256 tokenId) public view returns(uint256) {
        return _positionInChain[tokenId];
    }

    /**
     * @return the tokenId of the passed NFT at the given position
     */
    function getTokenIdAt(uint256 tokenId, uint256 position) public view returns(uint256) {
        return _chain[tokenId][position];
    }

    /**
     * Syntactic sugar
     * @return the position in the chain, the owner's address and content of the given NFT
     */
    function getCompleteInfo(uint256 tokenId) public view returns(uint256, address, bytes memory) {
        return (_positionInChain[tokenId], _owner[_root[tokenId]], _data[tokenId]);
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balance[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        return _owner[_root[tokenId]];
    }

    function approve(address to, uint256 tokenId) public {
        require(_root[tokenId] == tokenId, "Only root NFTs can be approved");
        require(msg.sender == _owner[tokenId], "Only owner can approve operators");
        _tokenOperator[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address operator) {
        require(_root[tokenId] == tokenId, "Only root NFTs can be approved");
        operator = _tokenOperator[tokenId];
        if(operator == _voidAddress) {
            operator = _ownerOperator[_owner[tokenId]];
        }
    }

    function setApprovalForAll(address operator, bool _approved) public {
        if(!_approved && operator == _ownerOperator[msg.sender]) {
            _ownerOperator[msg.sender] = _voidAddress;
        }
        if(_approved) {
            _ownerOperator[msg.sender] = operator;
        }
        emit ApprovalForAll(msg.sender, operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _ownerOperator[owner] == operator;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transferFrom(msg.sender, from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _safeTransferFrom(msg.sender, from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        _safeTransferFrom(msg.sender, from, to, tokenId, data);
    }

    function _transferFrom(address sender, address from, address to, uint256 tokenId) private {
        require(_root[tokenId] == tokenId, "Only root NFTs can be transfered");
        require(_owner[tokenId] == from, "Given from is not the owner of given tokenId");
        require(from == sender || getApproved(tokenId) == sender, "Sender not allowed to transfer this tokenId");
        _owner[tokenId] = to;
        _balance[from] = _balance[from] - 1;
        _balance[to] = _balance[to] + 1;
        _tokenOperator[tokenId] = _voidAddress;
        emit Transfer(from, to, tokenId);
    }

    function _safeTransferFrom(address sender, address from, address to, uint256 tokenId, bytes memory data) public {
        _transferFrom(sender, from, to, tokenId);
        uint256 size;
        assembly { size := extcodesize(to) }
        require(size <= 0, "Receiver address is not a contract");
        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
        require(retval == 0x150b7a02, "Receiver address does not support the onERC721Received method");
    }
}
