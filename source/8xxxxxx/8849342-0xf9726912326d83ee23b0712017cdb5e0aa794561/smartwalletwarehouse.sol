//Copyright Octobase.co 2019
pragma solidity ^0.5.1;

import "./safemath.sol";
import "./statuscodes.sol";

interface ISmartWalletFactory {
    function produceSmartWallet(address _owner)
        external
        payable
        returns (StatusCodes.Status status, address signer, address vault);
}

interface ISigner {
    function init(address _owner,
            address _vault,
            uint _weiMaxLimit,
            uint _weiLimitStartDateUtc,
            uint _weiLimitWindowSeconds)
        external
        returns (StatusCodes.Status status);
}


contract SmartWalletWarehouse
{
    using SafeMath for uint256;

    struct StockItem {
        address signer;
        address vault;
    }
    address public owner;
    ISmartWalletFactory public smartWalletFactory;
    StockItem[] public smartWalletStock;
    uint public stockLevel;

    event Stock(address indexed signer, address indexed vault);
    event Claim(address indexed owner, address indexed signer, address indexed vault);

    constructor(address _owner, ISmartWalletFactory _smartWalletFactory)
        public
    {
        owner = _owner;
        smartWalletFactory = _smartWalletFactory;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function stock()
        external
    {
        (StatusCodes.Status produceStatus, address signer, address vault) = smartWalletFactory.produceSmartWallet(address(this));
        require(produceStatus == StatusCodes.Status.Success, "Smart wallet production failed");
        stockLevel = stockLevel.add(1);
        if (stockLevel > smartWalletStock.length) {
            smartWalletStock.push(StockItem(signer, vault));
        } else {
            StockItem storage stockItem = smartWalletStock[stockLevel-1];
            stockItem.signer = signer;
            stockItem.vault = vault;
        }

        emit Stock(signer, vault);
    }

    function claim(
            address _owner,
            uint256 _weiMaxLimit,
            uint256 _weiLimitStartDateUtc,
            uint256 _weiLimitWindowSeconds)
        external
        returns (address signer, address vault)
    {
        require(stockLevel > 0, "No stock");

        //peek
        StockItem storage stockItem = smartWalletStock[stockLevel-1];

        //pop
        stockLevel = stockLevel.sub(1);

        //init
        ISigner signerWrapper = ISigner(stockItem.signer);
        StatusCodes.Status initStatus = signerWrapper.init(_owner, stockItem.vault, _weiMaxLimit, _weiLimitStartDateUtc, _weiLimitWindowSeconds);
        require(initStatus == StatusCodes.Status.Success, "Smart wallet init failed");
    
        // //report
        emit Claim(_owner, stockItem.signer, stockItem.vault);
        return (stockItem.signer, stockItem.vault);
    }

    function packIndex()
        external
    {
        smartWalletStock.length = stockLevel;
    }

    function OctobaseType()
        external
        pure
        returns (uint16 octobaseType)
    {
        return 6;
    }

    function OctobaseTypeVersion()
        external
        pure
        returns (uint32 octobaseTypeVersion)
    {
        return 1;
    }
}
