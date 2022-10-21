/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
pragma solidity 0.5.8;


import { IERC20 } from "./IERC20.sol";
import { ERC777RemoteBridge } from "./ERC777RemoteBridge.sol";


contract ERC777ERC20Compat is IERC20, ERC777RemoteBridge {
    bool internal mErc20compatible;

    mapping(address => mapping(address => uint256)) internal mAllowed;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _granularity,
        uint256 _totalSupply,
        address _initialOwner,
        address[] memory _defaultOperators
    )
    internal ERC777RemoteBridge(_name, _symbol, _granularity, _totalSupply, _initialOwner, _defaultOperators)
    {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", address(this));
    }

    /// @notice This modifier is applied to erc20 obsolete methods that are
    ///  implemented only to maintain backwards compatibility. When the erc20
    ///  compatibility is disabled, this methods will fail.
    modifier erc20 () {
        require(mErc20compatible, "ERC20 is disabled");
        _;
    }

    /// @notice For Backwards compatibility
    /// @return The decimals of the token. Forced to 18 in ERC777.
    function decimals() public erc20 view returns (uint8) { return uint8(18); }

    /// @notice ERC20 backwards compatible transfer.
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transfer(address _to, uint256 _amount) public erc20 returns (bool success) {
        doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible transferFrom.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return `true`, if the transfer can't be done, it should fail.
    function transferFrom(address _from, address _to, uint256 _amount) public erc20 returns (bool success) {
        uint256 allowance = balancesDB.getAllowance(_from, msg.sender);
        require(_amount <= allowance, "Not enough allowance.");

        // Cannot be after doSend because of tokensReceived re-entry
        require(balancesDB.decApprove(_from, msg.sender, _amount));
        doSend(msg.sender, _from, _to, _amount, "", "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible approve.
    ///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The number of tokens to be approved for transfer
    /// @return `true`, if the approve can't be done, it should fail.
    function approve(address _spender, uint256 _amount) public erc20 returns (bool success) {
        require(balancesDB.setApprove(msg.sender, _spender, _amount));
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice ERC20 backwards compatible allowance.
    ///  This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public erc20 view returns (uint256 remaining) {
        return balancesDB.getAllowance(_owner, _spender);
    }

    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData,
        bool _preventLocking
    )
    internal
    {
        super.doSend(_operator, _from, _to, _amount, _data, _operatorData, _preventLocking);
        if (mErc20compatible) { emit Transfer(_from, _to, _amount); }
    }

    function doBurn(
        address _operator,
        address _tokenHolder,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData
    )
    internal
    {
        super.doBurn(_operator, _tokenHolder, _amount, _data, _operatorData);
        if (mErc20compatible) { emit Transfer(_tokenHolder, address(0), _amount); }
    }
}


