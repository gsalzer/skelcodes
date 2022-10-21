// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';
import "./IStakedToadz.sol";

contract StackedStakedToadz is Ownable, IERC721Receiver, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.UintSet; 
    
    //addresses 
    address public stackerAddress;
    address public stakedToadzAddress;

    //uint256's 
    uint256 public expiration; 
    //rate governs how often you receive $STACK 
    uint256 public rate; 
  
    // mappings 
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    constructor(
      address _stacker,
      address _stakedToadz,
      uint256 _rate,
      uint256 _expiration
    )
    {
        stackerAddress = _stacker;
        stakedToadzAddress = _stakedToadz;
        rate = _rate;
        expiration = block.number + _expiration;
    }

/* STACKED FARM MECHANICS */


    //alter rate and expiration of the unstacked toad farm. 
    function setRateExpiration(uint256 _rate, uint256 _expiration) public onlyOwner() {
      rate = _rate; 
      expiration = _expiration;
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

        rewards[i] = 
          rate * 
          (_deposits[account].contains(tokenId) ? 1 : 0) * 
          (Math.min(block.number, expiration) - 
            _depositBlocks[account][tokenId]);
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
        IStakedToadz(stakedToadzAddress).mint(msg.sender, reward);
      }
    }

    //deposit function. 
    function deposit(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(stackerAddress).safeTransferFrom(
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

            IERC721(stackerAddress).safeTransferFrom(
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
