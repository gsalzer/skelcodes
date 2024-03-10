/**
* SPDX-License-Identifier: LicenseRef-Aktionariat
*
* MIT License with Automated License Fee Payments
*
* Copyright (c) 2020 Aktionariat AG (aktionariat.com)
*
* Permission is hereby granted to any person obtaining a copy of this software
* and associated documentation files (the "Software"), to deal in the Software
* without restriction, including without limitation the rights to use, copy,
* modify, merge, publish, distribute, sublicense, and/or sell copies of the
* Software, and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* - The above copyright notice and this permission notice shall be included in
*   all copies or substantial portions of the Software.
* - All automated license fee payments integrated into this and related Software
*   are preserved.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/
pragma solidity ^0.8.0;

import "./IRecoveryHub.sol";
import "./IRecoverable.sol";
import "../ERC20/IERC20.sol";

/**
 * @title Recoverable
 * In case of tokens that represent real-world assets such as shares of a company, one needs a way
 * to handle lost private keys. With physical certificates, courts can declare share certificates as
 * invalid so the company can issue replacements. Here, we want a solution that does not depend on
 * third parties to resolve such cases. Instead, when someone has lost a private key, he can use the
 * declareLost function to post a deposit and claim that the shares assigned to a specific address are
 * lost. To prevent front running, a commit reveal scheme is used. If he actually is the owner of the shares,
 * he needs to wait for a certain period and can then reclaim the lost shares as well as the deposit.
 * If he is an attacker trying to claim shares belonging to someone else, he risks losing the deposit
 * as it can be claimed at anytime by the rightful owner.
 * Furthermore, if "getClaimDeleter" is defined in the subclass, the returned address is allowed to
 * delete claims, returning the collateral. This can help to prevent obvious cases of abuse of the claim
 * function.
 */

contract RecoveryHub is IRecoveryHub {

    // A struct that represents a claim made
    struct Claim {
        address claimant; // the person who created the claim
        uint256 collateral; // the amount of collateral deposited
        uint256 timestamp;  // the timestamp of the block in which the claim was made
        address currencyUsed; // The currency (XCHF) can be updated, we record the currency used for every request
    }

    mapping(address => mapping (address => Claim)) public claims; // there can be at most one claim per token and claimed address
    mapping(address => bool) public recoveryDisabled; // disable claimability (e.g. for long term storage)

    event ClaimMade(address indexed token, address indexed lostAddress, address indexed claimant, uint256 balance);
    event ClaimCleared(address indexed token, address indexed lostAddress, uint256 collateral);
    event ClaimDeleted(address indexed token, address indexed lostAddress, address indexed claimant, uint256 collateral);
    event ClaimResolved(address indexed token, address indexed lostAddress, address indexed claimant, uint256 collateral);

    function setRecoverable(bool enabled) external override {
        recoveryDisabled[msg.sender] = !enabled;
    }

    /**
     * Some users might want to disable claims for their address completely.
     * For example if they use a deep cold storage solution or paper wallet.
     */
    function isRecoveryEnabled(address target) public view returns (bool) {
        return !recoveryDisabled[target];
    }

  /** Anyone can declare that the private key to a certain address was lost by calling declareLost
    * providing a deposit/collateral. There are three possibilities of what can happen with the claim:
    * 1) The claim period expires and the claimant can get the deposit and the shares back by calling recover
    * 2) The "lost" private key is used at any time to call clearClaim. In that case, the claim is deleted and
    *    the deposit sent to the shareholder (the owner of the private key). It is recommended to call recover
    *    whenever someone transfers funds to let claims be resolved automatically when the "lost" private key is
    *    used again.
    * 3) The owner deletes the claim and assigns the deposit to the claimant. This is intended to be used to resolve
    *    disputes. Generally, using this function implies that you have to trust the issuer of the tokens to handle
    *    the situation well. As a rule of thumb, the contract owner should assume the owner of the lost address to be the
    *    rightful owner of the deposit.
    * It is highly recommended that the owner observes the claims made and informs the owners of the claimed addresses
    * whenever a claim is made for their address (this of course is only possible if they are known to the owner, e.g.
    * through a shareholder register).
    */
    function declareLost(address token, address collateralType, address lostAddress) external {
        require(isRecoveryEnabled(lostAddress), "disabled");
        uint256 collateralRate = IRecoverable(token).getCollateralRate(collateralType);
        require(collateralRate > 0, "bad collateral");
        address claimant = msg.sender;
        uint256 balance = IERC20(token).balanceOf(lostAddress);
        uint256 collateral = balance * collateralRate;
        IERC20 currency = IERC20(collateralType);
        require(balance > 0, "empty");
        require(claims[token][lostAddress].collateral == 0, "already claimed");
        require(currency.transferFrom(claimant, address(this), collateral));

        claims[token][lostAddress] = Claim({
            claimant: claimant,
            collateral: collateral,
            timestamp: block.timestamp,
            currencyUsed: collateralType
        });

        IRecoverable(token).notifyClaimMade(lostAddress);
        emit ClaimMade(token, lostAddress, claimant, balance);
    }

    function getClaimant(address token, address lostAddress) external view returns (address) {
        return claims[token][lostAddress].claimant;
    }

    function getCollateral(address token, address lostAddress) external view returns (uint256) {
        return claims[token][lostAddress].collateral;
    }

    function getCollateralType(address token, address lostAddress) external view returns (address) {
        return claims[token][lostAddress].currencyUsed;
    }

    function getTimeStamp(address token, address lostAddress) external view returns (uint256) {
        return claims[token][lostAddress].timestamp;
    }

    /**
     * Clears a claim after the key has been found again and assigns the collateral to the "lost" address.
     * This is the price an adverse claimer pays for filing a false claim and makes it risky to do so.
     */
    function clearClaimFromToken(address holder) external override {
        clearClaim(msg.sender, holder);
    }

    function clearClaimFromUser(address token) external {
        clearClaim(token, msg.sender);
    }

    function clearClaim(address token, address holder) private {
        Claim memory claim = claims[token][holder];
        if (claim.collateral != 0) {
            IERC20 currency = IERC20(claim.currencyUsed);
            delete claims[token][holder];
            require(currency.transfer(address(this), claim.collateral), "could not return collateral");
            emit ClaimCleared(token, holder, claim.collateral);
            IRecoverable(token).notifyClaimDeleted(holder);
        }
    }

   /**
    * After the claim period has passed, the claimant can call this function to send the
    * tokens on the lost address as well as the collateral to himself.
    */
    function recover(address token, address lostAddress) external {
        Claim memory claim = claims[token][lostAddress];
        address claimant = claim.claimant;
        require(claimant == msg.sender, "not claimant");
        uint256 collateral = claim.collateral;
        IERC20 currency = IERC20(claim.currencyUsed);
        require(collateral != 0, "not found");
        require(claim.timestamp + IRecoverable(token).claimPeriod() <= block.timestamp, "too early");
        delete claims[token][lostAddress];
        IRecoverable(token).notifyClaimDeleted(lostAddress);
        require(currency.transfer(claimant, collateral));
        IRecoverable(token).recover(lostAddress, claimant);
        emit ClaimResolved(token, lostAddress, claimant, collateral);
    }

    /**
     * This function is to be executed by the claim deleter only in case a dispute needs to be resolved manually.
     */
    function deleteClaim(address lostAddress) external override {
        address token = msg.sender;
        Claim memory claim = claims[token][lostAddress];
        IERC20 currency = IERC20(claim.currencyUsed);
        require(claim.collateral != 0, "not found");
        delete claims[token][lostAddress];
        IRecoverable(token).notifyClaimDeleted(lostAddress);
        require(currency.transfer(claim.claimant, claim.collateral));
        emit ClaimDeleted(token, lostAddress, claim.claimant, claim.collateral);
    }

}
