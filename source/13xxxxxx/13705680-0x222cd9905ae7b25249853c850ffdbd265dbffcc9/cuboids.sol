// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";


import "./cubix.sol";




contract Cuboids is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI;

    address addr_1 = 0xf0B042a067EE80CC245A1EB9e68423aA91B606a3;

    uint256 private _reserved = 100;
    uint256 private _price = 0.069 ether;
    uint256 private _generatorPrice = 0.00 ether;
    uint256 public _generatorStartCount = 10000;
    bool public _paused = true;
    bool public _generatorPaused = true;

    //rewards
    mapping(address => uint256) public balanceOG;
    YieldToken public yieldToken;

	//bio
	uint256 public BIO_CHANGE_PRICE = 100 ether;
	mapping(uint256 => string) public bio;
	event BioChange (uint256 indexed tokenId, string bio);


    constructor(string memory baseURI) ERC721("Cuboids", "CUBOIDS")  {
        setBaseURI(baseURI);
    }

    function preMint(uint256 _amount) external onlyOwner {
         uint256 supply = totalSupply();
        //pre-mint
        for(uint256 i; i < _amount; i++){
            _safeMint( addr_1, supply + i );
            yieldToken.updateRewardOnMint(msg.sender, 1);
		    balanceOG[msg.sender]++;
        }
    }


	function setYieldToken(address _yield) external onlyOwner {
		yieldToken = YieldToken(_yield);
	}

    function payReward() external {
		yieldToken.updateReward(msg.sender, address(0), 0);
		yieldToken.payReward(msg.sender);
	}

	function setBioChangePrice(uint256 _bioChangePrice) external onlyOwner {
		BIO_CHANGE_PRICE = _bioChangePrice;
	}

	function changeBio(uint256 _tokenId, string memory _bio) public {
		address owner = ownerOf(_tokenId);
		require(_msgSender() == owner, "ERC721: caller is not the owner");
		yieldToken.burn(msg.sender, BIO_CHANGE_PRICE);
		bio[_tokenId] = _bio;
		emit BioChange(_tokenId, _bio); 
	}

    function transferFrom(address from, address to, uint256 tokenId) public override {
		yieldToken.updateReward(from, to, tokenId);
		if (tokenId < 10001)
		{
			balanceOG[from]--;
			balanceOG[to]++;
		}
		ERC721.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
		yieldToken.updateReward(from, to, tokenId);
		if (tokenId < 10001)
		{
			balanceOG[from]--;
			balanceOG[to]++;
		}
		ERC721.safeTransferFrom(from, to, tokenId, _data);
	}





    function purchase(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( !_paused,                              "Sale paused" );
        require( num < 21,                              "You can purchase a maximum of 20 NFTs" );
        require( supply + num < 10000 - _reserved,      "Exceeds maximum NFTs supply" );
        require( msg.value >= _price * num,             "Ether sent is not correct" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
            yieldToken.updateRewardOnMint(msg.sender, 1);
		    balanceOG[msg.sender]++;
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function setGeneratorPrice(uint256 _newPrice) public onlyOwner() {
        _generatorPrice = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function getGeneratorPrice() public view returns (uint256){
        return _generatorPrice;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _reserved, "Exceeds reserved NFTs supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
            yieldToken.updateRewardOnMint(msg.sender, 1);
		    balanceOG[msg.sender]++;
        }

        _reserved -= _amount;
    }

    function _generateProcess() private  {
        require( _generatorStartCount + 1 < 15000,         "Exceeds maximum NFTs that can be created" );
        yieldToken.burn(msg.sender, _generatorPrice);

        _safeMint( msg.sender, _generatorStartCount + 1 );
        yieldToken.updateRewardOnMint(msg.sender, 1);
		balanceOG[msg.sender]++;
        _generatorStartCount = _generatorStartCount+1;
    }

    function sendGenerator(uint256 nft1, uint256 nft2) public {
        require( !_generatorPaused,                  "Generator is offline" );
        require(_exists(nft1),                    "sendGenerator: NFT 1 does not exist.");
        require(_exists(nft2),                    "sendGenerator: NFT 2 does not exist.");
        require(ownerOf(nft1) == _msgSender(),    "sendGenerator: NFT 1 caller is not token owner.");
        require(ownerOf(nft2) == _msgSender(),    "sendGenerator: NFT 2 caller is not token owner.");
        require( nft1 <=  10000,             "NFT 1 is not a genesis NFT" );
        require( nft2 <=  10000,             "NFT 2 is not a genesis NFT" );

        require(nft1 != nft2, "Both NFTs can't be the same ");
        _burn(nft1);
        _burn(nft2);
        _generateProcess();
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function pause(bool val) public onlyOwner {
        _paused = val;
    }

    function generatorPause(bool val) public onlyOwner {
        _generatorPaused = val;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 _all = address(this).balance;
        require(payable(addr_1).send(_all));
    }
}

