pragma solidity 0.4.24;

import './StandardTokenVesting.sol';
import './Ownable.sol';


/** @notice Factory is a software design pattern for creating instances of a class.
 * Using this pattern simplifies creating new vesting contracts and saves
 * transaction costs ("gas"). Instead of deploying a new TokenVesting contract
 * for each team member, we deploy a single instance of TokenVestingFactory
 * that ensures the creation of new token vesting contracts.
 */

contract FRSPTokenVestingFactory is Ownable {

    mapping(address => StandardTokenVesting) vestingContractAddresses;

    // The token being sold
    FRSPToken public token;

    event CreatedStandardVestingContract(StandardTokenVesting vesting);

    constructor(address _token) public {
        require(_token != address(0));
        owner = msg.sender;
        token = FRSPToken(_token);
    }

   /** @dev Deploy FRSPTokenVestingFactory, and use it to create vesting contracts
     * for founders, advisors and developers. after creation transfer FRSP tokens
     * to those addresses and vesting vaults will be initialised.
     */
    // function create(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable, uint256 noOfTokens) onlyOwner public returns(StandardTokenVesting) {
    function create(address _beneficiary, uint256 _cliff, uint256 _duration, bool _revocable, uint256 noOfTokens) public onlyOwner  returns(StandardTokenVesting) {
        StandardTokenVesting vesting = new StandardTokenVesting(_beneficiary, now , _cliff , _duration, _revocable);

        vesting.transferOwnership(msg.sender);
        vestingContractAddresses[_beneficiary] = vesting;
        emit CreatedStandardVestingContract(vesting);
        assert(token.transferFrom(owner, vesting, noOfTokens));

        return vesting;
    }

    function getVestingContractAddress(address _beneficiary) public view returns(address) {
        require(_beneficiary != address(0));
        require(vestingContractAddresses[_beneficiary] != address(0));

        return vestingContractAddresses[_beneficiary];
    }

    function releasableAmount(address _beneficiary) public view returns(uint256) {
        require(getVestingContractAddress( _beneficiary) != address(0));
        return vestingContractAddresses[_beneficiary].releasableAmount(token);
    }

    function vestedAmount(address _beneficiary) public view returns(uint256) {
        require(getVestingContractAddress(_beneficiary) != address(0));
        return vestingContractAddresses[_beneficiary].vestedAmount(token);
    }

    function release(address _beneficiary) public returns(bool) {
        require(getVestingContractAddress(_beneficiary) != address(0));
        return vestingContractAddresses[_beneficiary].release(token);
    }


}

