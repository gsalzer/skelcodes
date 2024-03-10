// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// REMIX
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/proxy/UpgradeableProxy.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/access/Ownable.sol";

// TRUFFLE
import "@openzeppelin/contracts/proxy/UpgradeableProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// NFTProxy SMART CONTRACT
contract NFTProxy is UpgradeableProxy, Ownable {
    /**
     * NFTProxy Constructor
     *
     * @param _logic - Implementation/Logic Contract Address
     */
    constructor(address _logic)
        public
        UpgradeableProxy(_logic, abi.encodeWithSignature("initialize()"))
    {}

    /**
     * Get the current implementation contract address
     *
     */
    function implementation() external view returns (address) {
        return _implementation();
    }

    /**
     * Change the implementation contract address
     *
     * @param _logic - Implementation/Logic Contract Address
     */
    function upgradeTo(address _logic) public onlyOwner {
        _upgradeTo(_logic);
    }
}

