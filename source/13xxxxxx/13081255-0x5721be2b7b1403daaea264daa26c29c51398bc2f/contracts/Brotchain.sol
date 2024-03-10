// SPDX-License-Identifier: UNLICENSED
// Copyright 2021 Arran Schlosberg / Twitter @divergence_art
// All Rights Reserved
pragma solidity >=0.8.0 <0.9.0;

/*

  ____            _       _           _       
 |  _ \          | |     | |         (_)      
 | |_) |_ __ ___ | |_ ___| |__   __ _ _ _ __  
 |  _ <| '__/ _ \| __/ __| '_ \ / _` | | '_ \ 
 | |_) | | | (_) | || (__| | | | (_| | | | | |
 |____/|_|  \___/ \__\___|_| |_|\__,_|_|_| |_|
                                              
                                              
"In-chain" generative art, Brots are BMP images generated and rendered entirely
by this contract. No externalities, no rendering dependencies—just 100%
Solidity.

                                .                               
                         ...............                        
                     .......................                    
                   ...........................                  
                 ...............................                
               ...................................              
              .....................................             
             .......................................            
           ...........................................          
          .............................................         
         ...............................................        
        .................................................       
        .................................................       
       ...................................................      
      ...................'''```'''.........................     
     ..................''''``^```'''........................    
     .................''''````",$''''.......................    
    ................''''''````"^``''''.......................   
    ...............''''''```"^$"^```'''......................   
   ...............'''''`````,$$$!````''.......................  
   ..............'''''``````:$$$l`````''......................  
  .............'''''``^^^`^^"$$$"^^```^''...................... 
  ............''''````^:,^Y$$$$$$/$^,^^`'......................
  ...........''```````^I$#$$$$$$$$$I$|"``'..................... 
  .........''````````^^,$$$$$$$$$$$$$$^``'..................... 
 ........''``````````"$$$$$$$$$$$$$$$_^``'......................
 .....'''```"````````:$$$$$$$$$$$$$$$$,!`''.....................
 ...''''````^,^^,"^^^}$$$$$$$$$$$$$$$$$^`''.....................
 .'''''`````^:$$$l:^"$$$$$$$$$$$$$$$$$$"`''.....................
 '''''``````")$$$$$<,$$$$$$$$$$$$$$$$$$``''.....................
 ''''`````^^,$$$$$$$;$$$$$$$$$$$$$$$$$,``''.....................
 ````````^,$}$$$$$$$<$$$$$$$$$$$$$$$$$```''.....................
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$^```''.....................
 ````````^,$}$$$$$$$<$$$$$$$$$$$$$$$$$```''.....................
 ''''`````^^,$$$$$$$;$$$$$$$$$$$$$$$$$,``''.....................
 '''''``````")$$$$$<,$$$$$$$$$$$$$$$$$$``''.....................
 .'''''`````^:$$$l:^"$$$$$$$$$$$$$$$$$$"`''.....................
 ...''''````^,^^,"^^^}$$$$$$$$$$$$$$$$$^`''.....................
 .....'''```"````````:$$$$$$$$$$$$$$$$,!`''.....................
 ........''``````````"$$$$$$$$$$$$$$$_^``'......................
  .........''````````^^,$$$$$$$$$$$$$$^``'..................... 
  ...........''```````^I$#$$$$$$$$$I$|"``'.....................
  ............''''````^:,^Y$$$$$$/$^,^^`'...................... 
  .............'''''``^^^`^^"$$$"^^```^''...................... 
   ..............'''''``````:$$$l`````''......................  
   ...............'''''`````,$$$!````''.......................  
    ...............''''''```"^$"^```'''......................   
    ................''''''````"^``''''.......................   
     .................''''````",$''''.......................    
     ..................''''``^```'''........................    
      ...................'''```'''.........................     
       ...................................................      
        .................................................       
        .................................................       
         ...............................................        
          .............................................         
           ...........................................          
             .......................................            
              .....................................             
               ...................................              
                 ...............................                
                   ...........................                  
                     .......................                    
                         ...............                        
*/

import "./BaseOpenSea.sol";
import "./BMP.sol";
import "./Mandelbrot.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/PullPayment.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

contract Brotchain is BaseOpenSea, ERC721Enumerable, ERC721Pausable, Ownable, PullPayment {
    /**
     * @dev A BMP pixel encoder, supporting arbitrary colour palettes.
     */
    BMP public immutable _bmp;

    /**
     * @dev A Mandelbrot-and-friends fractal generator.
     */
    Mandelbrot public immutable _brots;

    /**
     * @dev Maximum number of editions per series.
     */
    uint256 public constant MAX_PER_SERIES = 64;

    /**
     * @dev Mint price = pi/10.
     */
    uint256 public constant MINT_PRICE = (314159 ether) / 1000000;

    constructor(string memory name, string memory symbol, address brots, address openSeaProxyRegistry) ERC721(name, symbol) {
        _bmp = new BMP();
        _brots = Mandelbrot(brots);

        if (openSeaProxyRegistry != address(0)) {
            _setOpenSeaRegistry(openSeaProxyRegistry);
        }
    }

    /**
     * @dev Base config for pricing + all tokens in a series.
     */
    struct Series {
        uint256[] patches;
        uint256 numMinted;
        uint32 width;
        uint32 height;
        bytes defaultPalette;
        bool locked;
        string name;
        string description;
    }

    /**
     * @dev All existing series configs.
     */
    Series[] public seriesConfigs;

    /**
     * @dev Require that the series exists.
     */
    modifier seriesMustExist(uint256 seriesId) {
        require(seriesId < seriesConfigs.length, "Series doesn't exist");
        _;
    }

    /**
     * @dev Creates a new series of brots, based on the precomputed patches.
     *
     * The seriesId MUST be equal to seriesConfigs.length. This is a safety
     * measure for automated deployment of multiple series in case an earlier
     * transaction fails as series would otherwise be created out of order. This
     * effectively makes newSeries() idempotent.
     */
    function newSeries(uint256 seriesId, string memory name, string memory description, uint256[] memory patches, uint32 width, uint32 height) external onlyOwner {
        require(seriesId == seriesConfigs.length, "Invalid new series ID");
        
        seriesConfigs.push(Series({
            name: name,
            description: description,
            patches: patches,
            width: width,
            height: height,
            numMinted: 0,
            locked: false,
            defaultPalette: new bytes(0)
        }));
        emit SeriesPixelsChanged(seriesId);
    }

    /**
     * @dev Require that the series isn't locked to updates.
     */
    modifier seriesNotLocked(uint256 seriesId) {
        require(!seriesConfigs[seriesId].locked, "Series locked");
        _;
    }

    /**
     * @dev Permanently lock the series to changes in pixels.
     */
    function lockSeries(uint256 seriesId) external seriesMustExist(seriesId) onlyOwner {
        Series memory series = seriesConfigs[seriesId];
        uint256 length;
        for (uint i = 0; i < series.patches.length; i++) {
            length += _brots.cachedPatch(series.patches[i]).pixels.length;
        }
        require(series.width * series.height == length, "Invalid dimensions");
        
        seriesConfigs[seriesId].locked = true;
    }

    /**
     * @dev Emitted when a series' patches or dimensions change.
     */
    event SeriesPixelsChanged(uint256 indexed seriesId);

    /**
     * @dev Update the patches that govern series pixels.
     */
    function setSeriesPatches(uint256 seriesId, uint256[] memory patches) external seriesMustExist(seriesId) seriesNotLocked(seriesId) onlyOwner {
        seriesConfigs[seriesId].patches = patches;
        emit SeriesPixelsChanged(seriesId);
    }

    /**
     * @dev Update the dimensions of the series.
     */
    function setSeriesDimensions(uint256 seriesId, uint32 width, uint32 height) external seriesMustExist(seriesId) seriesNotLocked(seriesId) onlyOwner {
        seriesConfigs[seriesId].width = width;
        seriesConfigs[seriesId].height = height;
        emit SeriesPixelsChanged(seriesId);
    }

    /**
     * @dev Update the default palette for a series when the token doesn't have one.
     */
    function setSeriesDefaultPalette(uint256 seriesId, bytes memory palette) external seriesMustExist(seriesId) seriesNotLocked(seriesId) onlyOwner {
        require(palette.length == 768, "256 colours required");
        seriesConfigs[seriesId].defaultPalette = palette;
    }

    /**
     * @dev Update the series name.
     */
    function setSeriesName(uint256 seriesId, string memory name) external seriesMustExist(seriesId) onlyOwner {
        seriesConfigs[seriesId].name = name;
    }

    /**
     * @dev Update the series description.
     */
    function setSeriesDescription(uint256 seriesId, string memory description) external seriesMustExist(seriesId) onlyOwner {
        seriesConfigs[seriesId].description = description;
    }

    /**
     * @dev Token configuration such as series (pixels).
     */
    struct TokenConfig {
        uint256 paletteChanges;
        address paletteBy;
        address paletteApproval;
        // paletteReset is actually a boolean, but sized to align with a 256-bit
        // boundary for better storage. See resetPalette();
        uint192 paletteReset;
        bytes palette;
    }

    /**
     * @dev All existing token configs.
     */
    mapping(uint256 => TokenConfig) public tokenConfigs;
    
    /**
     * @dev Whether to limit minting only to those in _earlyAccess mapping.
     */
    bool public onlyEarlyAccess = true;

    /**
     * @dev Addresses with early minting access.
     */
    mapping(address => uint256) private _earlyAccess;

    /**
     * @dev Emitted when setOnlyEarlyAccess(to) is called.
     */
    event OnlyEarlyAccess();

    /**
     * @dev Set the onlyEarlyAccess flag.
     */
    function setOnlyEarlyAccess(bool to) external onlyOwner {
        onlyEarlyAccess = to;
        emit OnlyEarlyAccess();
    }

    /**
     * @dev Call parameter for early access because mapping()s are disallowed.
     */
    struct EarlyAccess {
        address addr;
        uint256 totalAllowed;
    }

    /**
     * @dev Set early-access granting or revocation for the addresses.
     *
     * The supply is not the amount left, but the total in the early-access
     * phase.
     */
    function setEarlyAccessGrants(EarlyAccess[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _earlyAccess[addresses[i].addr] = addresses[i].totalAllowed;
        }
    }

    /**
     * @dev Returns the total early-access allocation for the address.
     */
    function earlyAccessFor(address addr) public view returns (uint256) {
        return _earlyAccess[addr];
    }

    /**
     * @dev Max number that the contract owner can mint in a specific series.
     */
    uint256 public constant OWNER_ALLOCATION = 2;

    /**
     * @dev Allow minting of the genesis pieces.
     */
    function safeMintInSeries(uint256 seriesId) external seriesMustExist(seriesId) onlyOwner {
        require(seriesConfigs[seriesId].numMinted < OWNER_ALLOCATION, "Don't be greedy");
        _safeMintInSeries(seriesId);
    }

    /**
     * @dev Mint one edition, from a randomly selected series.
     *
     * # NB see the bug described in _safeMintInSeries().
     */
    function safeMint() external payable {
        require(msg.value >= MINT_PRICE, "Insufficient payment");
        _asyncTransfer(owner(), msg.value);

        uint256 numSeries = seriesConfigs.length;
        // We need some sort of randomness to choose which series is issued
        // next. sha3 is, by nature of being a cryptographic hash, a good PRNG.
        // Although this can technically be manipulated by someone in control of
        // block.timestamp, they're in a race against other blocks and also the
        // last minted (which is also random). If you can control this and care
        // enough to do so, then you deserve to choose which series you get!
        uint256 rand = uint256(keccak256(abi.encodePacked(
            _msgSender(),
            block.timestamp,
            lastTokenMinted
        ))) % numSeries; // uniform if numSeries is a power of 2 (it is)
        
        // Try each, starting from a random index, until a series with
        // capacity is found.
        for (uint256 i = 0; i < numSeries; i++) {
            uint256 seriesId = (rand + i) % numSeries;
            if (seriesConfigs[seriesId].numMinted < MAX_PER_SERIES) {
                _safeMintInSeries(seriesId);
                return;
            }
        }
        revert("All series sold out");
    }

    /**
     * @dev Last tokenId minted.
     *
     * This doesn't increment because the series could be different to the one
     * before. It's useful for randomly choosing the next token and for testing
     * too. Even at a gas price of 100, updating this only costs 0.0005 ETH.
     */
    uint256 public lastTokenMinted;

    /**
     * @dev Value by which seriesId is multiplied for the prefix of a tokenId.
     *
     * Series 0 will have tokens 0, 1, 2…; series 1 will have tokens 1000, 1001,
     * etc.
     */
    uint256 private constant _tokenIdSeriesMultiplier = 1e4;

    /**
     * @dev Returns the seriesId of a token. The token may not exist.
     */
    function tokenSeries(uint256 tokenId) public pure returns (uint256) {
        return tokenId / _tokenIdSeriesMultiplier;
    }

    /**
     * @dev Returns a token's edition within its series. The token may not exist.
     */
    function tokenEditionNum(uint256 tokenId) public pure returns (uint256) {
        return tokenId % _tokenIdSeriesMultiplier;
    }

    /**
     * @dev Mints the next token in the series.
     */
    function _safeMintInSeries(uint256 seriesId) internal seriesMustExist(seriesId) {
        /**
         * ################################
         * There is a bug in this code that we only discovered after deployment.
         * A minter can move their piece to a different wallet, reducing their
         * balance, and then mint again. See GermanBakery.sol for the fix.
         * ################################
         */
        if (_msgSender() != owner()) {
            if (onlyEarlyAccess) {
                require(balanceOf(_msgSender()) < _earlyAccess[_msgSender()], "Early access exhausted for wallet");
            } else {
                require(balanceOf(_msgSender()) < seriesConfigs.length, "Wallet cap reached");
            }
        }

        Series memory series = seriesConfigs[seriesId];
        uint256 tokenId = seriesId * _tokenIdSeriesMultiplier + series.numMinted;
        lastTokenMinted = tokenId;

        tokenConfigs[tokenId] = TokenConfig({
            paletteChanges: 0,
            paletteBy: address(0),
            paletteApproval: address(0),
            paletteReset: 0,
            palette: new bytes(0)
        });
        seriesConfigs[seriesId].numMinted++;

        _safeMint(_msgSender(), tokenId);
        emit TokenBMPChanged(tokenId);
    }

    /**
     * @dev Emitted when the address is approved to change a token's palette.
     */
    event PaletteApproval(uint256 indexed tokenId, address approved);

    /**
     * @dev Approve the address to change the token's palette.
     *
     * Set to 0x00 address to revoke. Token owner and ERC721 approved already
     * have palette approval. This is to allow someone else to modify a palette
     * without the risk of them transferring the token.
     *
     * Revoked upon token transfer.
     */
    function approveForPalette(uint256 tokenId, address approved) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Only owner or approver");
        address owner = ownerOf(tokenId);
        require(approved != owner, "Approving token owner");
        
       tokenConfigs[tokenId].paletteApproval = approved;
        emit PaletteApproval(tokenId, approved);
    }

    /**
     * @dev Emitted to signal changing of a token's BMP.
     */
    event TokenBMPChanged(uint256 indexed tokenId);

    /**
     * @dev Require that the message sender is approved for palette changes.
     */
    modifier approvedForPalette(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) ||
            tokenConfigs[tokenId].paletteApproval == _msgSender(),
            "Not approved for palette"
        );
        _;
    }

    /**
     * @dev Clear a token's palette, using the series default instead.
     *
     * Does not reset the paletteChanges count, but increments it.
     *
     * Emits TokenBMPChanged(tokenId);
     */
    function resetPalette(uint256 tokenId) approvedForPalette(tokenId) external {
        require(tokenConfigs[tokenId].paletteReset == 0, "Already reset");
        
        tokenConfigs[tokenId].paletteChanges++;
        tokenConfigs[tokenId].paletteBy = address(0);
        // Initial palette setting costs about 0.01 ETH at 30 gas but changes
        // are a little over 25% of that. Using a boolean for reset adds
        // negligible cost to the reset, in exchange for  greater savings on the
        // next setPalette() call.
        tokenConfigs[tokenId].paletteReset = 1;
        
        emit TokenBMPChanged(tokenId);
    }

    /**
     * @dev Set a token's palette if an owner or has approval.
     *
     * Emits TokenBMPChanged(tokenId).
     */
    function setPalette(uint256 tokenId, bytes memory palette) approvedForPalette(tokenId) external {
        require(palette.length == 768, "256 colours required");
        
        tokenConfigs[tokenId].palette = palette;
        tokenConfigs[tokenId].paletteChanges++;
        tokenConfigs[tokenId].paletteBy = _msgSender();
        tokenConfigs[tokenId].paletteReset = 0;
        
        emit TokenBMPChanged(tokenId);
    }

    /**
     * @dev Concatenates a series' patches into a single array.
     */
    function seriesPixels(uint256 seriesId) public view seriesMustExist(seriesId) returns (bytes memory) {
        return _brots.concatenatePatches(seriesConfigs[seriesId].patches);
    }

    /**
     * @dev Token equivalent of seriesPixels().
     */
    function pixelsOf(uint256 tokenId) public view returns (bytes memory) {
        require(_exists(tokenId), "Token doesn't exist");
        return seriesPixels(tokenSeries(tokenId));
    }

    /**
     * @dev Returns the effective token palette, considering resets.
     *
     * Boolean flag indicates whether it's the original palette; i.e. nothing is
     * set or the palette has been explicitly reset().
     */
    function _tokenPalette(uint256 tokenId) private view returns (bytes memory, bool) {
        TokenConfig memory token = tokenConfigs[tokenId];
        bytes memory palette = token.palette;
        bool original = token.paletteReset == 1 || palette.length == 0;
        
        if (original) {
            palette = seriesConfigs[tokenSeries(tokenId)].defaultPalette;
            if (palette.length == 0) {
                palette = _bmp.grayscale();
            }
        }
        
        return (palette, original);
    }

    /**
     * @dev Returns the BMP-encoded token image, scaling pixels in both dimensions.
     *
     * Scale of 0 is treated as 1.
     */
    function bmpOf(uint256 tokenId, uint32 scale) public view returns (bytes memory) {
        require(_exists(tokenId), "Token doesn't exist");
        Series memory series = seriesConfigs[tokenSeries(tokenId)];
        (bytes memory palette, ) = _tokenPalette(tokenId);
        
        bytes memory pixels = pixelsOf(tokenId);
        if (scale > 1) {
            return _bmp.bmp(
                _bmp.scalePixels(pixels, series.width, series.height, scale),
                series.width * scale,
                series.height * scale,
                palette
            );
        }
        return _bmp.bmp(pixels, series.width, series.height, palette);
    }

    /**
     * @dev Equivalent to bmpOf() but encoded as a data URI to view in a browser.
     */
    function bmpDataURIOf(uint256 tokenId, uint32 scale) public view returns (string memory) {
        return _bmp.bmpDataURI(bmpOf(tokenId, scale));
    }

    /**
     * @dev Renders the token as an ASCII brot.
     *
     * This is an homage to Robert W Brooks and Peter Matelski who were the
     * first to render the Mandelbrot, in this form.
     */
    function brooksMatelskiOf(uint256 tokenId, string memory characters) external view returns (string memory) {
        bytes memory charset = abi.encodePacked(characters);
        require(charset.length == 256, "256 characters");

        Series memory series = seriesConfigs[tokenSeries(tokenId)];
        // Include newlines except for the end.
        bytes memory ascii = new bytes((series.width+1)*series.height - 1);
        
        bytes memory pixels = pixelsOf(tokenId);

        uint col;
        uint a; // ascii index
        for (uint p = 0; p < pixels.length; p++) {
            ascii[a] = charset[uint8(pixels[p])];
            a++;
            col++;
            
            if (col == series.width && a < ascii.length) {
                ascii[a] = 0x0a; // Not compatible with Windows and typewriters.
                a++;
                col = 0;
            }
        }

        return string(ascii);
    }

    /**
     * @dev Base URL for external_url metadata field.
     */
    string private _baseExternalUrl = "https://brotchain.art/brot/";

    /**
     * @dev Set the base URL for external_url metadata field.
     */
    function setBaseExternalUrl(string memory url) public onlyOwner {
        _baseExternalUrl = url;
    }

    /**
     * @dev Returns data URI of token metadata.
     *
     * The BMP-encoded image is included in its own base64-encoded data URI.
     */
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        TokenConfig memory token = tokenConfigs[tokenId];
        Series memory series = seriesConfigs[tokenSeries(tokenId)];
        uint256 editionNum = tokenEditionNum(tokenId);

        bytes memory data = abi.encodePacked(
            'data:application/json,{',
                '"name":"', series.name, ' #', Strings.toString(editionNum) ,'",',
                '"description":"', series.description, '",'
                '"external_url":"', _baseExternalUrl, Strings.toString(tokenId),'",'
        );

        // Combining this packing with the one above would result in the stack
        // being too deep and a failure to compile.
        data = abi.encodePacked(
            data,
            '"attributes":['
                '{"value":"', series.name, '"},'
                '{',
                    '"trait_type":"Palette Changes",',
                    '"value":', Strings.toString(token.paletteChanges),
                '}'
        );

        if (token.paletteBy != address(0)) {
            data = abi.encodePacked(
                data,
                ',{',
                    '"trait_type":"Palette By",',
                    '"value":"', Strings.toHexString(uint256(uint160(token.paletteBy)), 20),'"',
                '}'
            );
        }

        (, bool original) = _tokenPalette(tokenId);
        if (original) {
            data = abi.encodePacked(
                data,
                ',{"value":"Original Palette"}'
            );
        }      
        if (editionNum == 0) {
            data = abi.encodePacked(
                data,
                ',{"value":"Genesis"}'
            );
        }

        return string(abi.encodePacked(
            data,
                '],',
                '"image":"', bmpDataURIOf(tokenId, 1), '"',
            '}'
        ));
    }

    /**
     * @dev Pause the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator) || isOwnersOpenSeaProxy(owner, operator);
    }

    /**
     * @dev OpenSea collection config.
     *
     * https://docs.opensea.io/docs/contract-level-metadata
     */
    function setContractURI(string memory contractURI) external onlyOwner {
        _setContractURI(contractURI);
    }

    /**
     * @dev Revoke palette approval upon token transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        tokenConfigs[tokenId].paletteApproval = address(0);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
