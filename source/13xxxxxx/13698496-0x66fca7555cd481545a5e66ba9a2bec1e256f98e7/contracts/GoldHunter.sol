// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGGold {
    function balanceOf(address owner) external view returns (uint);
    function burn(address account, uint amount) external;
}

interface ITreasureIsland {
    function randomPirateOwner() external returns (address);
    function addTokensToStake(address account, uint16[] calldata tokenIds) external;
}

contract GoldHunter is ERC721, Ownable {
    uint public MAX_TOKENS = 50000;
    uint constant public MINT_PER_TX_LIMIT = 20;

    uint public tokensMinted = 0;
    uint16 public phase = 1;
    uint16 public pirateStolen = 0;
    uint16 public goldMinerStolen = 0;
    uint16 public pirateMinted = 0;

    bool private _paused = true;

    mapping(uint16 => uint) public phasePrice;

    ITreasureIsland public treasureIsland;
    IGGold public gold;

    string private _apiURI = "https://gold-hunt.herokuapp.com/token/";
    mapping(uint16 => bool) private _isPirate;
    
    uint16[] private _availableTokens;
    uint16 private _randomIndex = 0;
    uint private _randomCalls = 0;

    mapping(uint16 => address) private _randomSource;

    event TokenStolen(address owner, uint16 tokenId, address thief);

    constructor() ERC721("GoldHunter", "GOLDH") {
        _safeMint(msg.sender, 0);
        tokensMinted += 1;

        // Phase 1 is available in the beginning
        switchToSalePhase(1, true);

        // Set default price for each phase
        phasePrice[1] = 0.07 ether;
        phasePrice[2] = 20000 ether;
        phasePrice[3] = 40000 ether;
        phasePrice[4] = 80000 ether;
        
        // Fill random source addresses
        _randomSource[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _randomSource[1] = 0x3cD751E6b0078Be393132286c442345e5DC49699;
        _randomSource[2] = 0xb5d85CBf7cB3EE0D56b3bB207D5Fc4B82f43F511;
        _randomSource[3] = 0xC098B2a3Aa256D2140208C3de6543aAEf5cd3A94;
        _randomSource[4] = 0x28C6c06298d514Db089934071355E5743bf21d60;
        _randomSource[5] = 0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2;
        _randomSource[6] = 0x267be1C1D684F78cb4F6a176C4911b741E4Ffdc0;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function setPaused(bool _state) external onlyOwner {
        _paused = _state;
    }

    function addAvailableTokens(uint16 _from, uint16 _to) public onlyOwner {
        internalAddTokens(_from, _to);
    }

    function internalAddTokens(uint16 _from, uint16 _to) internal {
        for (uint16 i = _from; i <= _to; i++) {
            _availableTokens.push(i);
        }
    }

    function switchToSalePhase(uint16 _phase, bool _setTokens) public onlyOwner {
        phase = _phase;

        if (!_setTokens) {
            return;
        }

        if (phase == 1) {
            internalAddTokens(1, 9999);
        } else if (phase == 2) {
            internalAddTokens(10000, 20000);
        } else if (phase == 3) {
            internalAddTokens(20001, 40000);
        } else if (phase == 4) {
            internalAddTokens(40001, 49999);
        }
    }

    function giveAway(uint _amount, address _address) public onlyOwner {
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        require(_availableTokens.length > 0, "All tokens for this Phase are already sold");

        for (uint i = 0; i < _amount; i++) {
            uint16 tokenId = getTokenToBeMinted();
            _safeMint(_address, tokenId);
        }
    }

    function mint(uint _amount, bool _stake) public payable whenNotPaused {
        require(tx.origin == msg.sender, "Only EOA");
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        require(_amount > 0 && _amount <= MINT_PER_TX_LIMIT, "Invalid mint amount");
        require(_availableTokens.length > 0, "All tokens for this Phase are already sold");

        uint totalPennyCost = 0;
        if (phase == 1) {
            // Paid mint
            require(mintPrice(_amount) == msg.value, "Invalid payment amount");
        } else {
            // Mint via Penny token burn
            require(msg.value == 0, "Now minting is done via Penny");
            totalPennyCost = mintPrice(_amount);
            require(gold.balanceOf(msg.sender) >= totalPennyCost, "Not enough Penny");
        }

        if (totalPennyCost > 0) {
            gold.burn(msg.sender, totalPennyCost);
        }

        tokensMinted += _amount;
        uint16[] memory tokenIds = _stake ? new uint16[](_amount) : new uint16[](0);
        for (uint i = 0; i < _amount; i++) {
            address recipient = selectRecipient();
            if (phase != 1) {
                updateRandomIndex();
            }

            uint16 tokenId = getTokenToBeMinted();

            if (isPirate(tokenId)) {
                pirateMinted += 1;
            }

            if (recipient != msg.sender) {
                isPirate(tokenId) ? pirateStolen += 1 : goldMinerStolen += 1;
                emit TokenStolen(msg.sender, tokenId, recipient);
            }
            
            if (!_stake || recipient != msg.sender) {
                _safeMint(recipient, tokenId);
            } else {
                _safeMint(address(treasureIsland), tokenId);
                tokenIds[i] = tokenId;
            }
        }
        if (_stake) {
            treasureIsland.addTokensToStake(msg.sender, tokenIds);
        }
    }

    function selectRecipient() internal returns (address) {
        if (phase == 1) {
            return msg.sender; // During ETH sale there is no chance to steal NTF
        }

        // 10% chance to steal NTF
        if (getSomeRandomNumber(pirateMinted, 100) >= 10) {
            return msg.sender; // 90%
        }

        address thief = treasureIsland.randomPirateOwner();
        if (thief == address(0x0)) {
            return msg.sender;
        }
        return thief;
    }

    function mintPrice(uint _amount) public view returns (uint) {
        return _amount * phasePrice[phase];
    }

    function isPirate(uint16 id) public view returns (bool) {
        return _isPirate[id];
    }

    function getTokenToBeMinted() private returns (uint16) {
        uint random = getSomeRandomNumber(_availableTokens.length, _availableTokens.length);
        uint16 tokenId = _availableTokens[random];

        _availableTokens[random] = _availableTokens[_availableTokens.length - 1];
        _availableTokens.pop();

        return tokenId;
    }
    
    function updateRandomIndex() internal {
        _randomIndex += 1;
        _randomCalls += 1;
        if (_randomIndex > 6) _randomIndex = 0;
    }

    function getSomeRandomNumber(uint _seed, uint _limit) internal view returns (uint16) {
        uint extra = 0;
        for (uint16 i = 0; i < 7; i++) {
            extra += _randomSource[_randomIndex].balance;
        }

        uint random = uint(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender,
                    tokensMinted,
                    extra,
                    _randomCalls,
                    _randomIndex
                )
            )
        );

        return uint16(random % _limit);
    }

    function shuffleSeeds(uint _seed, uint _max) external onlyOwner {
        uint shuffleCount = getSomeRandomNumber(_seed, _max);
        _randomIndex = uint16(shuffleCount);
        for (uint i = 0; i < shuffleCount; i++) {
            updateRandomIndex();
        }
    }

    function setPirateId(uint16 id, bool special) external onlyOwner {
        _isPirate[id] = special;
    }

    function setPirateIds(uint16[] calldata ids) external onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            _isPirate[ids[i]] = true;
        }
    }

    function setTreasureIsland(address _island) external onlyOwner {
        treasureIsland = ITreasureIsland(_island);
    }

    function setGold(address _gold) external onlyOwner {
        gold = IGGold(_gold);
    }

    function changePhasePrice(uint16 _phase, uint _weiPrice) external onlyOwner {
        phasePrice[_phase] = _weiPrice;
    }

    function transferFrom(address from, address to, uint tokenId) public virtual override {
        // Hardcode the Manager's approval so that users don't have to waste gas approving
        if (_msgSender() != address(treasureIsland))
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function totalSupply() external view returns (uint) {
        return tokensMinted;
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _apiURI = uri;
    }

    function changeRandomSource(uint16 _id, address _address) external onlyOwner {
        _randomSource[_id] = _address;
    }

    function withdraw(address to) external onlyOwner {
        uint balance = address(this).balance;
        uint share = (balance * 20) / 100;
        payable(address(0xCA305c7bbE3f54650fB4AeeCc57255e1DD020f2a)).transfer(share);
        payable(to).transfer(balance - share);
    }
}



