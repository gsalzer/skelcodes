/// hex-otc.sol
//
// This program is free software: you can redistribute it and/or modify it
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//

pragma solidity ^0.4.18;

import "./math.sol";
import "./erc20.sol";

contract EventfulMarket {

    event LogItemUpdate(uint id);

    event LogTrade(uint pay_amt, uint buy_amt, uint escrowType);

    event LogClose(
        bytes32  indexed  id,
        address  indexed  maker,
        uint           pay_amt,
        uint           buy_amt,
        uint64            timestamp,
        uint              escrowType
    );

    event LogMake(
        bytes32  indexed  id,
        address  indexed  maker,
        uint           pay_amt,
        uint           buy_amt,
        uint64            timestamp,
        uint              escrowType
    );

    event LogBump(
        bytes32  indexed  id,
        address  indexed  maker,
        uint           pay_amt,
        uint           buy_amt,
        uint64            timestamp,
        uint              escrowType
    );

    event LogTake(
        bytes32           id,
        address  indexed  maker,
        address  indexed  taker,
        uint          take_amt,
        uint           give_amt,
        uint64            timestamp,
        uint              escrowType
    );

    event LogKill(
        bytes32  indexed  id,
        address  indexed  maker,
        uint           pay_amt,
        uint           buy_amt,
        uint64            timestamp,
        uint              escrowType
    );
}

contract SimpleMarket is EventfulMarket, DSMath {

    ERC20 hexInterface;
    address constant hexAddress = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39;
    uint constant hexDecimals = 8;
    uint public last_offer_id;

    mapping (uint => OfferInfo) public offers;

    bool locked;

    struct OfferInfo {
        uint     pay_amt;
        uint     buy_amt;
        address  owner;
        uint64   timestamp;
        bytes32  offerId;
        uint   escrowType; //0 HEX - 1 ETH
    }

    modifier can_buy(uint id) {
        require(isActive(id), "cannot buy, offer ID not active");
        _;
    }

    modifier can_cancel(uint id) {
        require(isActive(id), "cannot cancel, offer ID not active");
        require(getOwner(id) == msg.sender, "cannot cancel, msg.sender not the same as offer maker");
        _;
    }

    modifier can_offer {
        _;
    }

    modifier synchronized {
        require(!locked, "Sync lock");
        locked = true;
        _;
        locked = false;
    }

    constructor() public{
            hexInterface = ERC20(hexAddress);
    }

    function isActive(uint id) public view returns (bool active) {
        return offers[id].timestamp > 0;
    }

    function getOwner(uint id) public view returns (address owner) {
        return offers[id].owner;
    }

    function getOffer(uint id) public view returns (uint, uint, bytes32) {
      var offer = offers[id];
      return (offer.pay_amt, offer.buy_amt, offer.offerId);
    }

    // ---- Public entrypoints ---- //

    function bump(bytes32 id_)
        public
        can_buy(uint256(id_))
    {
        uint256 id = uint256(id_);
        emit LogBump(
            id_,
            offers[id].owner,
            uint(offers[id].pay_amt),
            uint(offers[id].buy_amt),
            offers[id].timestamp,
            offers[id].escrowType
        );
    }

    // Accept given `quantity` of an offer. Transfers funds from caller to
    // offer maker, and from market to caller.
    function buyHEX(uint id, uint quantity) //quantiiy in wei
        public
        payable
        can_buy(id)
        synchronized
        returns (bool)
    {
        OfferInfo memory offer = offers[id];
        uint spend = mul(quantity, offer.buy_amt) / offer.pay_amt;
        require(offer.escrowType == 0, "Incorrect escrow type");
        require(msg.value > 0 && msg.value == spend, "msg.value error");

        // for backwards semantic compatibility.
        if (quantity == 0 || spend == 0 ||
            quantity > offer.pay_amt || spend > offer.buy_amt)
        {
            return false;
        }

        offers[id].pay_amt = sub(offer.pay_amt, quantity);
        offers[id].buy_amt = sub(offer.buy_amt, spend);

        offer.owner.transfer(msg.value);//send eth to offer maker (seller)
        require(hexInterface.transfer(msg.sender, quantity), "Transfer failed"); //send escrowed hex from contract to offer taker (buyer)

        emit LogItemUpdate(id);
        emit LogTake(
            bytes32(id),
            offer.owner,
            msg.sender,
            uint(quantity),
            uint(spend),
            uint64(now),
            offer.escrowType
        );
        emit LogTrade(quantity, spend, offer.escrowType);

        if (offers[id].pay_amt == 0) {
            emit LogClose(bytes32(id), offers[id].owner, offers[id].pay_amt, offers[id].buy_amt, uint64(now), offers[id].escrowType);
            delete offers[id];
        }

        return true;
    }

    // Accept given `quantity` of an offer. Transfers funds from caller to
    // offer maker, and from market to caller.
    function buyETH(uint id, uint quantity) // quantity in hearts
        public
        can_buy(id)
        synchronized
        returns (bool)
    {
        OfferInfo memory offer = offers[id];
        uint spend = mul(quantity, offer.buy_amt) / offer.pay_amt;
        require(offer.escrowType == 1, "Incorrect escrow type");
        require(hexInterface.balanceOf(msg.sender) >= spend, "Balance is less than requested spend amount");

        // for backwards semantic compatibility.
        if (quantity == 0 || spend == 0 ||
            quantity > offer.pay_amt || spend > offer.buy_amt)
        {
            return false;
        }

        offers[id].pay_amt = sub(offer.pay_amt, quantity);
        offers[id].buy_amt = sub(offer.buy_amt, spend);

        require(hexInterface.transferFrom(msg.sender, offer.owner, spend), "Transfer failed");//send HEX to offer maker (seller)
        msg.sender.transfer(quantity);//send ETH to offer taker (buyer)

        emit LogItemUpdate(id);
        emit LogTake(
            bytes32(id),
            offer.owner,
            msg.sender,
            uint(quantity),
            uint(spend),
            uint64(now),
            offer.escrowType
        );
        emit LogTrade(quantity, spend, offer.escrowType);

        if (offers[id].pay_amt == 0) {
            emit LogClose(bytes32(id), offers[id].owner, offers[id].pay_amt, offers[id].buy_amt, uint64(now), offers[id].escrowType);
            delete offers[id];
        }

        return true;
    }

    // cancel an offer, refunds offer maker.
    function cancel(uint id)
        public
        can_cancel(id)
        synchronized
        returns (bool success)
    {
        // read-only offer. Modify an offer by directly accessing offers[id]
        OfferInfo memory offer = offers[id];
        delete offers[id];
        if(offer.escrowType == 0){ //hex
            require(hexInterface.transfer(offer.owner, offer.pay_amt), "Transfer failed");
        }
        else{ //eth
            offer.owner.transfer(offer.pay_amt);
        }
        emit LogItemUpdate(id);
        emit LogKill(
            bytes32(id),
            offer.owner,
            uint(offer.pay_amt),
            uint(offer.buy_amt),
            uint64(now),
            offer.escrowType
        );

        success = true;
    }

    //cancel
    function kill(bytes32 id)
        public
    {
        require(cancel(uint256(id)), "Error on cancel order.");
    }

    //make
    function make(
        uint  pay_amt,
        uint  buy_amt
    )
        public
        payable
        returns (bytes32 id)
    {
        if(msg.value > 0){
            return bytes32(offerETH(pay_amt, buy_amt));
        }
        else{
            return bytes32(offerHEX(pay_amt, buy_amt));
        }
    }

    // make a new offer to sell ETH. Takes ETH funds from the caller into market escrow.
    function offerETH(uint pay_amt, uint buy_amt) //amounts in wei / hearts
        public
        payable
        can_offer
        synchronized
        returns (uint id)
    {
        require(pay_amt > 0, "pay_amt is 0");
        require(buy_amt > 0, "buy_amt is 0");
        require(pay_amt == msg.value, "pay_amt not equal to msg.value");
        newOffer(id, pay_amt, buy_amt, 1);
        emit LogItemUpdate(id);
        emit LogMake(
            bytes32(id),
            msg.sender,
            uint(pay_amt),
            uint(buy_amt),
            uint64(now),
            1
        );
    }

    // make a new offer to sell HEX. Takes HEX funds from the caller into market escrow.
    function offerHEX(uint pay_amt, uint buy_amt) //amounts in hearts / wei
        public
        can_offer
        synchronized
        returns (uint id)
    {
        require(hexInterface.balanceOf(msg.sender) >= pay_amt, "Insufficient balanceOf hex");
        require(pay_amt > 0, "pay_amt is 0");
        require(buy_amt > 0,  "buy_amt is 0");
        newOffer(id, pay_amt, buy_amt, 0);

        require(hexInterface.transferFrom(msg.sender, address(this), pay_amt), "Transfer failed");

        emit LogItemUpdate(id);
        emit LogMake(
            bytes32(id),
            msg.sender,
            uint(pay_amt),
            uint(buy_amt),
            uint64(now),
            0
        );
    }

    //formulate new offer
    function newOffer(uint id, uint pay_amt, uint buy_amt, uint escrowType)
        internal
    {
        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.buy_amt = buy_amt;
        info.owner = msg.sender;
        info.timestamp = uint64(now);
        info.escrowType = escrowType;
        id = _next_id();
        info.offerId = bytes32(id);
        offers[id] = info;
    }

    //take
    function take(bytes32 id, uint maxTakeAmount)
        public
        payable
    {
        if(msg.value > 0){
            require(buyHEX(uint256(id), maxTakeAmount), "Buy HEX failed");
        }
        else{
            require(buyETH(uint256(id), maxTakeAmount), "Sell HEX failed");
        }

    }

    //get next id
    function _next_id()
        internal
        returns (uint)
    {
        last_offer_id++;
        return last_offer_id;
    }
}
