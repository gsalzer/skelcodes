// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./interface/IAzimuth.sol";
import "./interface/IEcliptic.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract UrbitexExchange is Context, Ownable {

    //  azimuth: points state data store
    //
    IAzimuth public azimuth;
    
    // fee: exchange transaction fee 
    // 
    uint32 public fee;

    // priceMin: the minimum price allowed to be set for a point
    // 
    uint256 public priceMin;

    // ListedAsset: struct which stores the price and seller's address for a point listed in the marketplace
    // 
    struct ListedAsset {
        address addr;
        uint256 price;
    }

    // assets: registry which stores the ListedAsset entries
    //
    mapping(uint32 => ListedAsset) assets;

    // EVENTS

    event MarketPurchase(
        address indexed _from,
        address indexed _to,
        uint32 _point,
        uint256 _price
    );

    event ListingRemoved(
        uint32 _point
    );

    event ListingAdded(
        uint32 _point,
        uint256 _price 
    );

    // IMPLEMENTATION

    //  constructor(): configure the points data store, exchange fee, and minimum listing price.
    //
    constructor(IAzimuth _azimuth, uint32 _fee, uint256 _priceMin) 
        payable 
    {     
        azimuth = _azimuth;
        setFee(_fee);
        setPriceMin(_priceMin);
    }

    // setRegistryEntry(): utility function to add or remove entries in the registry
    function setRegistryEntry(uint32 _point, address _address, uint256 _price) internal
    {
        ListedAsset memory asset = assets[_point];

        asset = ListedAsset({
             addr: _address,
             price: _price
          });

        assets[_point] = asset;
    }

    //  purchase(): purchase and transfer point from the seller to the buyer
    //
    function purchase(uint32 _point)
        external
        payable
    {
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        
        // get the point's owner 
        address payable seller = payable(azimuth.getOwner(_point));

        // get the point's information from the registry
        ListedAsset memory asset = assets[_point];

        // check that the address in the registry matches the point's current owner
        require(asset.addr == seller, "seller address does not match registry");

        // buyer must pay the exact price as what's stored in the registry for that point
        require(msg.value == asset.price, "Amount transferred does not match price in registry");

        // in order to save on gas fees, a check that the seller has approved the exchange as a 
        // transfer proxy can happen off-chain. 

        // when all conditions are met, transfer the point from the seller to the buyer
        ecliptic.transferFrom(seller, _msgSender(), _point); 

        // set the price of the point in the registry to 0 and clear the associated address.
        // 'asset' already declared in memory so not using the utility function this time
        // 
        asset = ListedAsset({
             addr: address(0),
             price: 0
          });

        assets[_point] = asset;

        // deduct exchange fee and transfer remaining amount to the seller
        seller.transfer(msg.value/100000*(100000-fee));    

        emit MarketPurchase(seller, _msgSender(), _point, msg.value);
    }

    // addListing(): add a point to the registry, including its corresponding price and owner address
    //
    function addListing(uint32 _point, uint256 _price) external
    {
        // intentionally using isOwner() instead of canTransfer(), which excludes third-party proxy addresses.
        // this will ensure the exchange owner also cannot maliciously list an owner's points.
        // 
        require(azimuth.isOwner(_point, _msgSender()), "The message sender is not the point owner");
        
        // listed price must be greater than the minimum price set by the exchange
        require(priceMin < _price, "The listed price must exceed the minimum price set by the exchange");

        // add the price of the point and the seller address to the registry
        //         
        setRegistryEntry(_point, _msgSender(), _price);        
        
        emit ListingAdded(_point, _price);

    }

    // removeListing(): clear the information for this point in the registry. This function has also been made available
    // to the exchange owner to remove stale listings.
    //
    function removeListing(uint32 _point) external 
    {   
        require(azimuth.isOwner(_point, _msgSender()) || _msgSender() == owner(), "The message sender is not the point owner or the exchange owner");
        
        setRegistryEntry(_point, address(0), 0);

        emit ListingRemoved(_point);
    }

    // getPointInfo(): check the listed price and seller address of a point 
    // 
    function getPointInfo(uint32 _point) external view returns (address, uint256) {
        return (assets[_point].addr, assets[_point].price);
    }

    // EXCHANGE OWNER OPERATIONS
     
    // setFee(): the fee calculation is a percentage of the listed price.
    // for example, an input of 2500 here will be 2.5%
    // 
    function setFee(uint32 _fee) public onlyOwner  {
        require(100000 > _fee, "Input value must be less than 100000");
        fee = _fee;
    }
    // setPriceMin(): the minimum listed price allowed by the exchange
    function setPriceMin(uint256 _priceMin) public onlyOwner  {
        require(0 < _priceMin, "Minimum price must be greater than 0");
        priceMin = _priceMin;
    }
             
    function withdraw(address payable _target) external onlyOwner  {
        require(address(0) != _target);
        _target.transfer(address(this).balance);
    }

    function close(address payable _target) external onlyOwner  {
        require(address(0) != _target);
        selfdestruct(_target);
    }
}

