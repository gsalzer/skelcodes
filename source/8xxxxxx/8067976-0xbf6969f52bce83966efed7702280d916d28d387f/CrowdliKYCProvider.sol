
pragma solidity 0.5.0;

import "./Pausable.sol";
import "./WhitelistAdminRole.sol";

contract CrowdliKYCProvider is Pausable, WhitelistAdminRole {

	/**
	 * The verification levels supported by this ICO
	 */
	enum VerificationTier { None, KYCAccepted, VideoVerified, ExternalTokenAgent } 
    
    /**
     * Defines the max. amount of tokens an investor can purchase for a given verification level (tier)
     */
	mapping (uint => uint) public maxTokenAmountPerTier; 
    
    /**
    * Dictionary that maps addresses to investors which have successfully been verified by the external KYC process
    */
    mapping (address => VerificationTier) public verificationTiers;

    /**
    * This event is fired when a user has been successfully verified by the external KYC verification process
    */
    event LogKYCConfirmation(address indexed sender, VerificationTier verificationTier);

	/**
	 * This constructor initializes a new  CrowdliKYCProvider initializing the provided token amount threshold for the supported verification tiers
	 */
    constructor(address _kycConfirmer, uint _maxTokenForKYCAcceptedTier, uint _maxTokensForVideoVerifiedTier, uint _maxTokensForExternalTokenAgent) public {
        addWhitelistAdmin(_kycConfirmer);
        // Max token amount for non-verified investors
        maxTokenAmountPerTier[uint(VerificationTier.None)] = 0;
        
        // Max token amount for auto KYC auto verified investors
        maxTokenAmountPerTier[uint(VerificationTier.KYCAccepted)] = _maxTokenForKYCAcceptedTier;
        
        // Max token amount for auto KYC video verified investors
        maxTokenAmountPerTier[uint(VerificationTier.VideoVerified)] = _maxTokensForVideoVerifiedTier;
        
        // Max token amount for external token sell providers
        maxTokenAmountPerTier[uint(VerificationTier.ExternalTokenAgent)] = _maxTokensForExternalTokenAgent;
    }

    function confirmKYC(address _addressId, VerificationTier _verificationTier) public onlyWhitelistAdmin whenNotPaused {
        emit LogKYCConfirmation(_addressId, _verificationTier);
        verificationTiers[_addressId] = _verificationTier;
    }

    function hasVerificationLevel(address _investor, VerificationTier _verificationTier) public view returns (bool) {
        return (verificationTiers[_investor] == _verificationTier);
    }
    
    function getMaxChfAmountForInvestor(address _investor) public view returns (uint) {
        return maxTokenAmountPerTier[uint(verificationTiers[_investor])];
    }    
}
