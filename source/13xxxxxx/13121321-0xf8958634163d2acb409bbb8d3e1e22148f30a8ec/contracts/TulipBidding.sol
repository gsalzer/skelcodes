// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {EtherTulip} from "./EtherTulip.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract TulipBidding {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => EnumerableSet.AddressSet) private bidderSet;

    mapping(address => mapping(uint256 => uint256)) public bids;

    address public immutable feeRecipient;
    uint256 public immutable feeBps;
    address public immutable etherTulip;

    event BidPlaced(uint256 tulipNumber, address buyer, uint256 price);
    event BidRevoked(uint256 tulipNumber, address buyer);
    event BidClaimed(uint256 tulipNumber, address bot);

    constructor(
        address _feeRecipient,
        uint256 _feeBps,
        address _etherTulip
    ) {
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
        etherTulip = _etherTulip;
    }

    function getBidderCount(uint256 tulipNumber) external view returns (uint256 count) {
        return bidderSet[tulipNumber].length();
    }

    function getBidderAt(uint256 tulipNumber, uint256 bidderIndex)
        external
        view
        returns (address bidder)
    {
        return bidderSet[tulipNumber].at(bidderIndex);
    }

    function getBidders(uint256 tulipNumber) external view returns (address[] memory bidders) {
        return bidderSet[tulipNumber].values();
    }

    function placeBid(uint256 tulipNumber) external payable {
        // increase bid
        bids[msg.sender][tulipNumber] += msg.value;
        // add to bidder set
        bidderSet[tulipNumber].add(msg.sender);
        // emit event
        emit BidPlaced(tulipNumber, msg.sender, bids[msg.sender][tulipNumber]);
    }

    function revokeBid(uint256 tulipNumber) external {
        uint256 bid = bids[msg.sender][tulipNumber];
        // clear bid
        delete bids[msg.sender][tulipNumber];
        // remove from bidder set
        bidderSet[tulipNumber].remove(msg.sender);
        // return funds
        payable(msg.sender).transfer(bid);
        // emit event
        emit BidRevoked(tulipNumber, msg.sender);
    }

    function fillDirectBid(
        uint256 tulipNumber,
        address buyer,
        uint256 botFee
    ) external {
        uint256 value = bids[msg.sender][tulipNumber];
        uint256 marketFee = (value * feeBps) / 10000;
        uint256 price = value - botFee - marketFee;
        // clear bid
        delete bids[msg.sender][tulipNumber];
        // remove from bidder set
        bidderSet[tulipNumber].remove(msg.sender);
        // perform purchase
        EtherTulip(etherTulip).buyTulip{value: price}(tulipNumber);
        // transfer tulip to buyer
        EtherTulip(etherTulip).giftTulip(tulipNumber, buyer);
        // pay the fees
        payable(msg.sender).transfer(botFee);
        payable(feeRecipient).transfer(marketFee);
        // emit event
        emit BidClaimed(tulipNumber, msg.sender);
    }

    function fillIndirectBid(uint256 tulipNumber, address buyer) external {
        uint256 value = bids[msg.sender][tulipNumber];
        uint256 marketFee = (value * feeBps) / 10000;
        uint256 price = value - marketFee;
        // clear bid
        delete bids[msg.sender][tulipNumber];
        // remove from bidder set
        bidderSet[tulipNumber].remove(msg.sender);
        // transfer tulip to buyer
        IERC721(etherTulip).transferFrom(msg.sender, buyer, tulipNumber);
        // pay the fees
        payable(msg.sender).transfer(price);
        payable(feeRecipient).transfer(marketFee);
        // emit event
        emit BidClaimed(tulipNumber, msg.sender);
    }
}

