// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/// @author: manifold.xyz
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./access/IAdminControl.sol";

interface INFT2ERC20 is IAdminControl, IERC20 {

    event Swapped(address indexed account, address indexed tokenContract, uint256[] args, string spec, uint256 rate);
    event RateEngineUpdated(address sender, address rateEngine);
    event TreasuryUpdated(address sender, address treasury, uint128 basisPoints);
    event TransferSpecUpdated(address sender, string spec, bytes4 transferFunction);
    
    /*
     * @dev sets the contract used to get NFT to ERC20 conversion rate values
     */
    function setRateEngine(address rateEngine) external;

    /*
     * @dev sets the amount of tokens the treasury gets on every burn
     */
    function setTreasury(address treasury, uint128 basisPoints) external;

    /*
     * @dev gets the treasury configuration
     */
    function getTreasury() external view returns(address, uint128);

    /*
     * @dev gets the rate engine
     */
    function getRateEngine() external view returns(address);

    /*
     * @dev sets the transfer function of a given spec
     */
    function setTransferFunction(string calldata spec, bytes4 transferFunction) external;

    /*
     * @dev burns an NFT token and gives the caller ERC20
     */
    function burnToken(address tokenContract, uint256[] calldata args, string calldata spec) external;

    /*
     * @dev burns an NFT token and gives the caller ERC20
     */
    function burnToken(address tokenContract, uint256[] calldata args, string calldata spec, address receiver) external;

    
}
