pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMathLib.sol";
import "./FITHTokenSale.sol";

/**
 * @dev Fiatech FITH token sale contract.
 */
contract FITHTokenSaleReferrals is FITHTokenSale
{
	using SafeMathLib for uint;
	
	uint public referralPercent = 5; // x is x%
	uint public referralTokensSpent = 0; // total referral tokens given away
	
	// referral tokens bought event raised when buyer purchases tokens via referral link
    event ReferralTokens(address indexed _buyer, address indexed _referer, uint256 _refererTokens);
	
	// referral token percent update event
	event ReferralTokenPercentUpdate(address _admin, uint256 _referralPercent);
	
	
	
	/**
	 * @dev Constructor
	 */
    constructor(IERC20 _tokenContract, uint256 _tokenPrice)
		FITHTokenSale(_tokenContract, _tokenPrice)
		public
	{
    }
	
	modifier onlyOwner() {
        require(msg.sender == owner, "Owner required");
        _;
    }
	
	
	
	//referer is address instead of string
	function _buyTokens(uint256 _numberOfTokens, address refererAddress) internal returns(bool) {
		
		require(super._buyTokens(_numberOfTokens), "_buyTokens base failed!");
		
		// only send referral tokens if buyer has a valid referer
		if (refererAddress > address(0)) {
			
			address referer = refererAddress;
			
			// self-referrer check
			require(referer != msg.sender, "Referer is sender");
			uint refererTokens = _numberOfTokens.mul(referralPercent).div(100);
			
			// bonus for referrer
			require(tokensAvailable() >= refererTokens, "insufficient referral tokens");
			require(tokenContract.transfer(referer, refererTokens), "Transfer tokens to referer failed");
			
			referralTokensSpent += refererTokens;
			
			emit ReferralTokens(msg.sender, referer, refererTokens);
		}
		return true;
    }
	
	function updateReferralPercent(uint256 _referralPercent) public onlyOwner {
        require(_referralPercent > 0 && _referralPercent <= 100 && _referralPercent != referralPercent, "Referral percent must be in (0,100] range and different than current");
        
		referralPercent = _referralPercent;
		emit ReferralTokenPercentUpdate(owner, _referralPercent);
    }
	
	/*function buyTokens(uint256 _numberOfTokens, address refererAddress) public payable {
        require(msg.value == (_numberOfTokens * tokenPrice), "Incorrect number of tokens");
		_buyTokens(_numberOfTokens, refererAddress);
    }*/
	
	
	
	/**
	 * Accept ETH for tokens
	 */
    function () external payable {
		uint tks = (msg.value).div(tokenPrice);
		
		// (c, d) = abi.decode(msg.data[4:], (uint256, uint256));
		//address refererAddress = abi.decode(msg.data[4:], (address));
		
		address refererAddress = address(0);
		bytes memory msgData = msg.data;
		// 4 bytes for signature
		if (msgData.length > 4) {
			assembly {
				refererAddress := mload(add(msgData, 20))
			}
		}
		
		_buyTokens(tks, refererAddress);
    }
}
