// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import './SafeMath.sol';
import './Helpers.sol';

struct Buyer {
    uint256 eth; // Amount of sent ETH
    uint256 zapp; // Amount of bought ZAPP
}

struct EarlyAdopter {
    uint256 zapp; // Early adopter purchase amount
}

struct Referrer {
    bytes3 code; // Referral code
    uint256 time; // Time of code generation
    Referee[] referrals; // List of referrals
}

struct Referee {
    uint256 zapp; // Purchase amount
}

struct Hunter {
    bool verified; // Verified by Zappermint (after Token Sale)
    uint256 bonus; // Bounty bonus (after Token Sale)
}

struct Wallet {
    address payable addr; // Address of the wallet

    Buyer buyer; // Buyer data
    bool isBuyer; // Whether this wallet is a buyer
    
    EarlyAdopter earlyAdopter; // Early adopter data
    bool isEarlyAdopter; // Whether this wallet is an early adopter
    
    Referrer referrer; // Referrer data
    bool isReferrer; // Whether this wallet is a referrer
    
    Referee referee; // Referee data
    bool isReferee; // Whether this wallet is a referee
    
    Hunter hunter; // Hunter data
    bool isHunter; // Whether this wallet is a hunter
    
    bool claimed; // Whether ZAPP has been claimed
}

/**
 * Functionality for the Wallet struct
 */
library WalletInterface {
    using SafeMath for uint256;

    /**
     * @param self the wallet
     * @param referrerMin the minimum amount of ZAPP that has to be bought to be a referrer (for hunters)
     * @param checkVerified whether to check if the hunter is verified (set to false to show progress during token sale)
     * @return The amount of ZAPP bits that have been bought with the referrer's code (18 decimals)
     */
    function calculateReferredAmount(Wallet storage self, uint256 referrerMin, bool checkVerified) internal view returns (uint256) {
        // 0 if not a referrer
        if (!self.isReferrer) return 0;

        // 0 if unverified hunter without enough bought ZAPP
        if (checkVerified && self.isHunter && !self.hunter.verified && self.buyer.zapp < referrerMin) return 0;

        // Calculate the sum of all referrals
        uint256 amount = 0;
        for (uint256 i = 0; i < self.referrer.referrals.length; ++i) {
            amount = amount.add(self.referrer.referrals[i].zapp);
        }
        return amount;
    }

    /**
     * @param self the wallet
     * @param bonus the bonus percentage (8 decimals)
     * @return The amount of ZAPP bits the early adopter will get as bonus (18 decimals)
     */
    function getEarlyAdopterBonus(Wallet storage self, uint256 bonus) internal view returns (uint256) {
        if (!self.isEarlyAdopter) return 0;
        return Helpers.percentageOf(self.earlyAdopter.zapp, bonus);
    }

    /**
     * @param self the wallet
     * @param bonus the bonus percentage (8 decimals)
     * @param referrerMin the minimum amount of ZAPP a referrer must have bought to be eligible (18 decimals)
     * @param checkVerified whether to check if the hunter is verified
     * @return The amount of ZAPP bits the referrer will get as bonus (18 decimals)
     */
    function getReferrerBonus(Wallet storage self, uint256 bonus, uint256 referrerMin, bool checkVerified) internal view returns (uint256) {
        if (!self.isReferrer) return 0;
        return Helpers.percentageOf(calculateReferredAmount(self, referrerMin, checkVerified), bonus);
    }

    /**
     * @param self the wallet
     * @param bonus the bonus percentage (8 decimals)
     * @return The amount of ZAPP bits the referee will get as bonus (18 decimals)
     */
    function getRefereeBonus(Wallet storage self, uint256 bonus) internal view returns (uint256) {
        if (!self.isReferee) return 0;
        return Helpers.percentageOf(self.referee.zapp, bonus);
    }

    /**
     * @param self the wallet
     * @param checkVerified whether to check if the hunter is verified
     * @return The amount of ZAPP bits the hunter will get as bonus (18 decimals)
     */
    function getHunterBonus(Wallet storage self, bool checkVerified) internal view returns (uint256) {
        if (!self.isHunter) return 0;
        if (checkVerified && !self.hunter.verified) return 0;
        return self.hunter.bonus;
    }

    /**
     * @param self the wallet
     * @return The amount of ZAPP bits the buyer has bought (18 decimals)
     */
    function getBuyerZAPP(Wallet storage self) internal view returns (uint256) {
        if (!self.isBuyer) return 0;
        return self.buyer.zapp;
    }

    /**
     * Makes a purchase for the wallet
     * @param self the wallet
     * @param eth amount of sent ETH (18 decimals)
     * @param zapp amount of bought ZAPP (18 decimals)
     */
    function purchase(Wallet storage self, uint256 eth, uint256 zapp) internal {
        // Become buyer
        self.isBuyer = true;
        // Add ETH to buyer data
        self.buyer.eth = self.buyer.eth.add(eth);
        // Add ZAPP to buyer data
        self.buyer.zapp = self.buyer.zapp.add(zapp);
    } 

    /**
     * Adds early adoption bonus
     * @param self the wallet
     * @param zapp amount of bought ZAPP (18 decimals)
     * NOTE Doesn't check for early adoption end time
     */
    function earlyAdoption(Wallet storage self, uint256 zapp) internal {
        // Become early adopter
        self.isEarlyAdopter = true;
        // Add ZAPP to early adopter data
        self.earlyAdopter.zapp = self.earlyAdopter.zapp.add(zapp);
    }

    /**
     * Adds referral bonuses
     * @param self the wallet
     * @param zapp amount of bought ZAPP (18 decimals)
     * @param referrer referrer wallet
     * NOTE Doesn't check for minimum purchase amount
     */
    function referral(Wallet storage self, uint256 zapp, Wallet storage referrer) internal {
        // Become referee
        self.isReferee = true;
        // Add ZAPP to referee data
        self.referee.zapp = self.referee.zapp.add(zapp);
        // Add referral to referrer
        referrer.referrer.referrals.push(Referee(zapp));
    }

    /**
     * Register as hunter
     * @param self the wallet
     */
    function register(Wallet storage self, uint256 reward, mapping(bytes3 => address) storage codes) internal {
        // Become hunter
        self.isHunter = true;
        // Set initial bonus to the register reward
        self.hunter.bonus = reward;
        // Become referrer
        self.isReferrer = true;
        // Generate referral code
        generateReferralCode(self, codes);
    }

    /**
     * Verify hunter and add his rewards
     * @param self the wallet
     * @param bonus hunted bounties
     * NOTE Also becomes a hunter, even if unregistered
     */
    function verify(Wallet storage self, uint256 bonus) internal {
        // Become hunter
        self.isHunter = true;
        // Set data
        self.hunter.verified = true;
        self.hunter.bonus = self.hunter.bonus.add(bonus);
    }

    /**
     * Generates a new code to assign to the referrer
     * @param self the wallet
     * @param codes the code map to check for duplicates
     * @return Unique referral code
     */
    function generateReferralCode(Wallet storage self, mapping(bytes3 => address) storage codes) internal returns (bytes3) {
        // Only on referrers
        if (!self.isReferrer) return bytes3(0);

        // Only generate once
        if (self.referrer.code != bytes3(0)) return self.referrer.code;

        bytes memory enc = abi.encodePacked(self.addr);
        bytes3 code = bytes3(0);
        while (true) {
            bytes32 keccak = keccak256(enc);
            code = Helpers.keccak256ToReferralCode(keccak);
            if (code != bytes3(0) && codes[code] == address(0)) break;
            // If the code already exists, we hash the hash to generate a new code
            enc = abi.encodePacked(keccak);
        }

        // Save the code for the referrer and in the code map to avoid duplicates
        self.referrer.code = code;
        self.referrer.time = block.timestamp;
        codes[code] = self.addr;
        return code;
    }

}
