pragma solidity 0.4.24;

import "./EIP721.sol";


contract Artifaqt is EIP721 {
    address public admin;

    // Bool to pause transfers
    bool transferResumed = false;

    // Array holding the sin hashes
    bytes32[] private sins;

    // Mapping from token ID to token type
    mapping(uint256 => uint256) internal typeOfToken;

    // Cutoff minting time
    uint256 cutoffMintingTime = 1541116800;

    /// @notice Contract constructor
    /// @dev Generates the keccak256 hashes of each sin that will be used
    /// when claiming tokens. Saves the admin. Sets a name and symbol.
    constructor() public {
        // Limbo
        sins.push(keccak256("Those who were never baptised."));
        // Lust
        sins.push(keccak256("Those who gave into pleasure."));
        // Gluttony
        sins.push(keccak256("Those who indulged in excess."));
        // Avarice
        sins.push(keccak256("Those who hoard and spend wastefully."));
        // Wrath
        sins.push(keccak256("Those consumed by anger and hatred."));
        // Heresy
        sins.push(keccak256("Those who worshipped false idols."));
        // Violence
        sins.push(keccak256("Those violent against others, one’s self, and God."));
        // Fraud
        sins.push(keccak256("Those who used lies and deception for personal gain."));
        // Treachery
        sins.push(keccak256("Those who have betrayed their loved ones."));

        // Set owner
        admin = msg.sender;

        // Default name and symbol
        name = "Artifaqt";
        symbol = "ATQ";
    }

    /// @notice Claim tokens by providing the sin payload
    /// @dev Reverts unless the payload was correctly created. Reverts after the party is over and no more tokens should be created.
    /// @param _sinPayload = keccak256(keccak256(sin) + playerAddress)
    /// sin must be one of strings hashed in the constructor that the player will find scattered across the DevCon4 conference
    function claimToken(
        bytes32 _sinPayload
    ) external mintingAllowed {
        // Make sure it's the correct sin
        uint256 tokenType;
        bool found = false;
        for(uint256 i = 0; i < 9; i++) {
            if (_sinPayload == keccak256(abi.encodePacked(sins[i], msg.sender))) {
                tokenType = i;
                found = true;
                break;
            }
        }
        require(found == true);

        // Make sure the user does not have this type of token
        require(ownerHasTokenType(msg.sender, tokenType) == false);

        // Create and add token
        uint256 tokenId = totalSupply();
        addToken(msg.sender, tokenId, tokenType);

        // Emit create event
        emit Transfer(0x0, msg.sender, tokenId);
    }

    /// @notice The admin can generate tokens for players
    /// @dev Reverts unless the user already has the token type. Reverts unless the minting happens withing the minting allowed time period.
    /// @param _to The player's address
    /// @param _tokenType A number from 0 to 8 representing the sin type
    function mintToken(
        address _to,
        uint256 _tokenType
    ) external onlyAdmin mintingAllowed {
        // Create and add token
        uint256 tokenId = totalSupply();
        addToken(_to, tokenId, _tokenType);

        // Emit create event
        emit Transfer(0x0, _to, tokenId);
    }

    /// @notice Returns the token id, owner and type
    /// @dev Throws unless _tokenId exists
    /// @param _tokenId The token by id
    /// @return
    /// - token index
    /// - owner of token
    /// - type of token
    function getToken(
        uint256 _tokenId
    ) external view returns (uint256, address, uint256) {
        return (
            allTokensIndex[_tokenId],
            ownerOfToken[_tokenId],
            typeOfToken[_tokenId]
        );
    }

    /// @notice Returns the claimed tokens for player
    /// @dev Returns an empty array if player does not have any claimed tokens
    /// @param _player The player's address
    function getTokenTypes(
        address _player
    ) external view returns (uint256[]) {
        uint256[] memory claimedTokens = new uint256[](ownedTokens[_player].length);

        for (uint256 i = 0; i < ownedTokens[_player].length; i++) {
            claimedTokens[i] = typeOfToken[ownedTokens[_player][i]];
        }

        return claimedTokens;
    }

    // TODO: Do not allow any kind of transfers if transfer is paused
    /// @notice Transfers the ownership of a token
    /// @dev Calls the parent function if transfers are not paused
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId, 
        bytes data
    ) public payable transferAllowed {
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Calls the parent function if transfers are not paused
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId
    ) public payable transferAllowed {
        super.safeTransferFrom(_from, _to, _tokenId);
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Calls the parent function if transfers are not paused
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _tokenId
    ) public payable transferAllowed {
        super.transferFrom(_from, _to, _tokenId);
    }

    /// @notice Enables or disables transfers
    /// @dev Set to `true` to enable transfers or `false` to disable transfers. 
    /// If it is set to `false` all functions that transfer tokens are paused and will revert.
    /// Functions that approve transfers (`approve()` and `setTransferForAll()`) still work 
    /// because they do not transfer tokens immediately.
    /// @param _resume This should be set to `true` if transfers should be enabled, `false` otherwise
    function allowTransfer(bool _resume) public onlyAdmin {
        transferResumed = _resume;
    }

    /// @notice Returns true of the `_player` has the requested `_tokenType`
    /// @dev
    /// @param _player The player's address
    /// @param _tokenType A number from 0 to 8 representing the sin type
    function ownerHasTokenType(
        address _player,
        uint256 _tokenType
    ) internal view returns (bool) {
        for (uint256 i = 0; i < ownedTokens[_player].length; i++) {
            if (typeOfToken[ownedTokens[_player][i]] == _tokenType) {
                return true;
            }
        }
        return false;
    }

    /// @notice Adds a token for the player
    /// @dev Calls the `super.addToken(address _to, uint256 _tokenId)` method and
    /// saves the token type also. The `_tokenId` must not already exist.
    /// @param _to The player's address
    /// @param _tokenId The new token id
    /// @param _tokenType A number from 0 to 8 representing the sin type
    function addToken(
        address _to,
        uint256 _tokenId,
        uint256 _tokenType
    ) internal {
        super.addToken(_to, _tokenId);

        // Save token type
        typeOfToken[_tokenId] = _tokenType;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier mintingAllowed() {
        require(block.timestamp <= cutoffMintingTime);
        _;
    }

    modifier transferAllowed() {
        require(transferResumed);
        _;
    }
}
