// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';
import "./INomStaker.sol";



contract NomStaker is ERC20Burnable, Ownable, IERC721Receiver, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet; 
    //addresses 
    address nullAddress = 0x0000000000000000000000000000000000000000;
    address public nomNomsAddress;

    //uint256's 
    uint256 public expiration; 
    //rate governs how often you receive $YUM
    uint256 public rate; 
  
    // mappings 
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    constructor(
      address _nomNoms,
      uint256 _rate,
      uint256 _expiration
    ) ERC20("Yum Yums", "YUM") 
    {
        nomNomsAddress = _nomNoms; 
        rate = _rate;
        expiration = block.number + _expiration;
    }
  /* yum token */
    uint256 public teamMintValue;
    mapping(address => bool) private whitelist;

    function setWhitelist(address[] calldata minters) external onlyOwner {
        for (uint256 i; i < minters.length; i++) {
            whitelist[minters[i]] = true;
        }

        whitelist[address(this)] = true;
    }

    function mint(address account, uint256 amount) external {
        require(whitelist[msg.sender], 'User is not whitelisted.');
        _mint(account, amount);
    }

    function teamMint(address account, uint256 amount) external onlyOwner {
        require((totalSupply() + amount) / (teamMintValue + amount) >= 10,'TOO MUCH STACK');
        _mint(account, amount);
        teamMintValue += amount;
    }

    //alter rate and expiration
    function setRateExpiration(uint256 _rate, uint256 _expiration) public onlyOwner() {
      rate = _rate; 
      expiration = _expiration;
    }
    
    function changeNomsAddress(address _nomNoms) public onlyOwner() {
        nomNomsAddress = _nomNoms;
    }

    //check deposit amount. 
    function depositsOf(address account)
      external 
      view 
      returns (uint256[] memory)
    {
      EnumerableSet.UintSet storage depositSet = _deposits[account];
      uint256[] memory tokenIds = new uint256[] (depositSet.length());

      for (uint256 i; i<depositSet.length(); i++) {
        tokenIds[i] = depositSet.at(i);
      }

      return tokenIds;
    }

    //reward amount by address/tokenIds[]
    function calculateRewards(address account, uint256[] memory tokenIds) 
      public 
      view 
      returns (uint256[] memory rewards) 
    {
      rewards = new uint256[](tokenIds.length);
    
      for (uint256 i; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        if (tokenId < 556) {
            rewards[i] = 
            rate * 
            (_deposits[account].contains(tokenId) ? 1 : 0) * 
            (Math.min(block.number, expiration) - 
            _depositBlocks[account][tokenId]);
        } else {
            rewards[i] = 
            (rate / 10) * 
            (_deposits[account].contains(tokenId) ? 1 : 0) * 
            (Math.min(block.number, expiration) - 
            _depositBlocks[account][tokenId]);
        }

        
      }

      return rewards;
    }

    //reward claim function 
    function claimRewards(uint256[] calldata tokenIds) public {
      uint256 reward; 
      uint256 block = Math.min(block.number, expiration);

      uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

      for (uint256 i; i < tokenIds.length; i++) {
        reward += rewards[i];
        _depositBlocks[msg.sender][tokenIds[i]] = block;
      }

      if (reward > 0) {
        _mint(msg.sender, reward);
      }
    }
    
    function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(nomNomsAddress));
		_burn(_from, _amount);
	}

    //deposit function. 
    function deposit(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(nomNomsAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );

            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    //withdrawal function.
    function withdraw(uint256[] calldata tokenIds) external nonReentrant() {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                'Staking: token not deposited'
            );

            _deposits[msg.sender].remove(tokenIds[i]);

            IERC721(nomNomsAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
        }
    }


    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
