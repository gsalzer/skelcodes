pragma solidity 0.5.12;
pragma experimental ABIEncoderV2;

import "../Ownable.sol";
import "../MinterRole.sol";
import "../ERC1155.sol";
import "../WhitelistAdminRole.sol";
import "../ERC1155Metadata.sol";
import "../ERC1155MintBurn.sol";
import "../Strings.sol";
import "../ProxyRegistry.sol";

/**
 * @title ERC1155Tradable
 * ERC1155Tradable - ERC1155 contract that whitelists an operator address, 
 * has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155Minter is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable, MinterRole, WhitelistAdminRole {
    using Strings for string;

    struct Participant {
        uint128 nftId;
        uint64 x;
        uint64 y;
        address participant;
    }

    Participant [] internal _participants;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    function init(string memory _name, string memory _symbol) public onlyOwner {
        require((bytes(name)).length == 0, 'Already initiated');

        name = _name;
        symbol = _symbol;
        _addMinter(_msgSender());
        _addWhitelistAdmin(_msgSender());
        _setBaseMetadataURI("https://lambo.hcore.finance/spot-the-ball-win/#home");
    }

    function removeWhitelistAdmin(address account) public onlyOwner {
        _removeWhitelistAdmin(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    /**
     * @dev Will update the base URL of token's URI
     * @param _newBaseMetadataURI New base URL of token's URI
     */
    function setBaseMetadataURI(string memory _newBaseMetadataURI) public onlyWhitelistAdmin {
        _setBaseMetadataURI(_newBaseMetadataURI);
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @param _initialSupply Optional amount to supply the first owner
     * @param _id attemptId
     * @param _data Optional data to pass if receiver is contract
     * @return The newly created token ID
     */
    function create(
        address _creator,
        uint256 _maxSupply,
        uint256 _initialSupply,
        uint256 _id,
        uint64 _x,
        uint64 _y,
        bytes calldata _data
    ) external onlyMinter returns (uint256) {
        require(!_exists(_id), "Id already used");
        require(_initialSupply <= _maxSupply, "Initial supply cannot be more than max supply");
        creators[_id] = _creator;

        if (_initialSupply != 0) _mint(_creator, _id, _initialSupply, _data);
        tokenSupply[_id] = _initialSupply;
        tokenMaxSupply[_id] = _maxSupply;
        _participants.push(Participant(uint128(_id), _x, _y, _creator));
        return _id;
    }

    function getParticipantsCount() public view returns (uint) {
        return _participants.length;
    }

    function getParticipantById(uint _id) public view returns (uint128, uint64, uint64, address) {
        Participant storage participant = _participants[_id];
        return (participant.nftId, participant.x, participant.y, participant.participant);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator
     * @param _id uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

}
