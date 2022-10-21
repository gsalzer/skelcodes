// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./AuctionHouseV1.sol";

/// @author Guillaume Gonnaud 2018
/// @title Auction House Empty Logic Code
/// @notice Contain all the storage of the auction house declared in a way that generate getters for Logic Code use, but no code that changes memory
contract AuctionHouseEmptyV1 is VCProxyData, AuctionHouseHeaderV1, AuctionHouseStoragePublicV1 {

    //No functions, including no withdraw/catchall, in case of an exploit to the pending withdrawals array.
    //Any non "view" call will fail.

}
