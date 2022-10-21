// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;


// 
// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library BoringMath {
    function add(uint a, uint b) internal pure returns (uint c) {require((c = a + b) >= b, "BoringMath: Add Overflow");}
    function sub(uint a, uint b) internal pure returns (uint c) {require((c = a - b) <= a, "BoringMath: Underflow");}
    function mul(uint a, uint b) internal pure returns (uint c) {require(a == 0 || (c = a * b)/b == a, "BoringMath: Mul Overflow");}
}

// 
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
// Edited by BoringCrypto
// - removed GSN context
// - removed comments (we all know this contract)
// - updated solidity version
// - made _owner public and renamed to owner
// - simplified code
// - onlyOwner modifier removed. Just copy the one line. Cheaper in gas, better readability and better error message.
// TODO: Consider using the version that requires acceptance from new owner
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function renounceOwnership() public virtual {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

// 
interface IOracle {
    // Each oracle should have a set function. The first parameter will be 'address pair' and any parameters can come after.
    // Setting should only be allowed ONCE for each pair.

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    function get(address pair) external returns (bool, uint256);

    // Check the last exchange rate without any state changes
    function peek(address pair) external view returns (uint256);
}

// 
interface IUniswapAnchoredView {
    function price(string memory symbol) external view returns (uint256);
}

contract CompoundOracle is IOracle {
    using BoringMath for uint256;

    struct PairInfo {
        string collateralSymbol;
        string assetSymbol;
        uint256 division;
    }

    mapping(address => PairInfo) pairs;

    function init(string calldata collateralSymbol, string calldata assetSymbol, uint256 division) public {
        // The rate can only be set once. It cannot be changed.
        if (bytes(pairs[msg.sender].collateralSymbol).length == 0) {
            pairs[msg.sender].collateralSymbol = collateralSymbol;
            pairs[msg.sender].assetSymbol = assetSymbol;
            pairs[msg.sender].division = division;
        }
    }

    function getInitData(string calldata collateralSymbol, string calldata assetSymbol, uint256 division) public pure returns (bytes memory) {
        return abi.encodeWithSignature("init(string,string,uint256)", collateralSymbol, assetSymbol, division);
    }

    function _get(string memory collateralSymbol, string memory assetSymbol, uint256 division) private view returns (uint256) {
        return uint256(1e36)
            .mul(IUniswapAnchoredView(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1).price(assetSymbol)) /
                IUniswapAnchoredView(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1).price(collateralSymbol) / division;
    }

    // Get the latest exchange rate
    function get(address pair) public override returns (bool, uint256) {
        return (true, _get(pairs[pair].collateralSymbol, pairs[pair].assetSymbol, pairs[pair].division));
    }

    // Check the last exchange rate without any state changes
    function peek(address pair) public view override returns (uint256) {
        return _get(pairs[pair].collateralSymbol, pairs[pair].assetSymbol, pairs[pair].division);
    }

    function test(string calldata collateralSymbol, string calldata assetSymbol, uint256 division) public view returns(uint256) {
        return _get(collateralSymbol, assetSymbol, division);
    }
}
