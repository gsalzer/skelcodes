// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./CryptographKYCV1.sol";

/// @title Cryptograph KYC Logic Contract
/// @author Guillaume Gonnaud 2020
/// @notice Provides the logic code for the KYC of bidders
/// @dev Price feed is in ETH and NOT an oracle because it's a KYC price feed (We have to verify transaction above a certain GBP amount)
contract CryptographKYCLogicV1 is VCProxyData, CryptographKYCHeaderV1, CryptographKYCStoragePublicV1  {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall and hence its memory state is irrelevant
    constructor() public
    {
        //Self intialize (nothing)
    }

    modifier restrictedToOperators(){
        require((msg.sender == perpetualAltruism || authorizedOperators[msg.sender]), "Only operators can call this function");
        _;
    }

    /// @notice Init function of the KYC contract
    /// @dev Callable only once after deployment
    function init() external {
        require(perpetualAltruism == address(0), "Already initalized");
        perpetualAltruism = msg.sender;
        priceLimit = uint256(0) - uint256(1);
        emit PriceLimit(priceLimit);
    }

    /// @notice Used to allow other wallets to manage the KYC
    /// @dev Only callable by Perpetual Altruism/Other operators
    /// @param _operator The address of the operator
    /// @param _operating If the operator is allowed to operate
    function setOperator(address _operator, bool _operating) external restrictedToOperators(){
        authorizedOperators[_operator] = _operating;
    }


    /// @notice Used to set a price limit above which wallets need to be KYCed
    /// @dev Only callable by Perpetual Altruism/Other operators
    /// @param _newPrice The new price limit
    function setPriceLimit(uint256 _newPrice) external restrictedToOperators(){
        priceLimit = _newPrice;
        emit PriceLimit(_newPrice);
    }

    /// @notice Used to allow other wallets to manage the KYC
    /// @dev Only callable by Perpetual Altruism/Other operators
    /// @param _user The address of the user
    /// @param _kyc Is the user allowed to bid for any amount ?
    function setKyc(address _user, bool _kyc) external restrictedToOperators(){
        kycUsers[_user] = _kyc;
        emit KYCed(_user, _kyc);
    }


    /// @notice Check if a user is allowed to transact this amount
    /// @dev Anyone can check
    /// @param _user The address of the user
    /// @param _amount The amount of the bid
    function checkKyc(address _user, uint256 _amount) external view returns(bool){
        return (_amount <= priceLimit || kycUsers[_user]);
    }

}
