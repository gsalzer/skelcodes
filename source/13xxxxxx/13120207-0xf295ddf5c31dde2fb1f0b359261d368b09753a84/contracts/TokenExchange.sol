// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./utils/IERC20.sol";

contract TokenExchange {
    address private _owner;
    address private _newToken;
    IERC20 private _oldToken;
    address[] private _exchangeList;
    constructor (address buffToken, address oldToken, address[] memory exchangeList) {
        require(buffToken != address(0), "Zero address");
        _owner = msg.sender;
        _newToken = buffToken;
        _oldToken = IERC20(oldToken);
        _exchangeList = exchangeList;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function exchangeOldToken() external onlyOwner returns (bool) {
        require(_exchangeList.length > 0, "ERR: no exchange list");
        for(uint k = 0; k < _exchangeList.length; k++) {
            uint balances = _oldToken.balanceOf(_exchangeList[k]);
            if(balances > 0) {
                bool transferCheck = IERC20(_newToken).transferFrom(_newToken, _exchangeList[k], balances);
                require(transferCheck, "Official BuffDoge transfer failed");
            }
        }
        return true;
    }

    function destroySmartContract(address payable _to) external onlyOwner {
        selfdestruct(_to);
    }
}
