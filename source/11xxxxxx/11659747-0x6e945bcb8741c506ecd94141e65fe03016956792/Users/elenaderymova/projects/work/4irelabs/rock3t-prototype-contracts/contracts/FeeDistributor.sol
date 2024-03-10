// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract FeeDistributor is Ownable {
    using SafeMath for uint;

    IERC20 public R3Ttoken;

    address public liquidVault;
    address public secondaryAddress;

    uint256 public secondaryAddressShare;

    bool public initialized;

    modifier seeded {
        require(
            initialized,
            "R3T: Fees cannot be distributed until Distributor seeded."
        );
        _;
    }

    function seed(address r3t, address vault, address _secondaryAddress, uint256 _secondaryAddressShare) public onlyOwner {
        R3Ttoken = IERC20(r3t);
        liquidVault = vault;
        secondaryAddress = _secondaryAddress;
        secondaryAddressShare = _secondaryAddressShare;

        initialized = true;
    }

    function distributeFees() public seeded {
        uint balance = R3Ttoken.balanceOf(address(this));
        
        uint256 fees;

        if (secondaryAddressShare > 0) {
            fees = secondaryAddressShare.mul(balance).div(100);

            require(
                R3Ttoken.transfer(secondaryAddress, fees),
                "FeeDistributor: transfer to the secondary address failed"
            );
        }

        require(
            R3Ttoken.transfer(liquidVault, balance.sub(fees)),
            "FeeDistributor: transfer to LiquidVault failed"
        );  
    }
}
