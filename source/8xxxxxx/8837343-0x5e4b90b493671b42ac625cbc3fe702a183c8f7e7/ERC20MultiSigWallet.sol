pragma solidity ^0.5.0;

import "./MultiSigWallet.sol";
import "./ERC20.sol";


contract ERC20MultiSigWallet is MultiSigWallet {

    constructor(address[] memory _owners, uint256 _required) public MultiSigWallet(_owners, _required) {

    }

    /// @dev Withdraws token balance from the wallet
    /// @param _token Address of ERC20 token to withdraw.
    /// @param _to Address of receiver
    /// @param _amount Amount to withdraw
    function withdraw(address _token, address _to, uint256 _amount) public onlyWallet {
        require(_token != address(0), "Token address cannot be 0");
        require(_to != address(0), "recipient address cannot be 0");
        require(_amount > 0, "amount cannot be 0");
        require(ERC20(_token).balanceOf(address(this)) > 0, "Contract does not have any balance");
        require(ERC20(_token).balanceOf(address(this)) > _amount, "Contract does not have such balance");
        ERC20(_token).transfer(_to, _amount);
    }
}
