// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract Vault is Ownable {
    address public marsBaseOtc;

    modifier onlyMarsBaseOtc() {
        require(msg.sender == marsBaseOtc);
        _;
    }

    receive() external payable {}

    function tokenFallback(
        address,
        uint256,
        bytes calldata
    ) external {}

    function setMarsBaseOtc(address _marsBaseOtc) external onlyOwner {
        require(
            _marsBaseOtc != address(0),
            "Vault: MarsBaseOtc is zero address"
        );
        marsBaseOtc = _marsBaseOtc;
    }

    function withdraw(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyMarsBaseOtc {
        require(
            _receiver != address(0),
            "901"
        );
        if (_token == address(0)) {
            payable(_receiver).transfer(_amount);
        } else {
            require(
                IERC20(_token).transfer(_receiver, _amount),
                "901"
            );
        }
    }

    function withdrawForTwo(
        address _token,
        address _receiver1,
        uint256 _amount1,
        address _receiver2,
        uint256 _amount2
    ) external onlyMarsBaseOtc {
        if (_token == address(0)) {
            if (_receiver1 != address(0) && _amount1 > 0)
                payable(_receiver1).transfer(_amount1);
            if (_receiver2 != address(0) && _amount2 > 0)
                payable(_receiver2).transfer(_amount2);
        } else {
            if (_receiver1 != address(0) && _amount1 > 0) {
                require(
                    IERC20(_token).transfer(_receiver1, _amount1),
                    "901"
                );
            }
            if (_receiver2 != address(0) && _amount2 > 0) {
                require(
                    IERC20(_token).transfer(_receiver2, _amount2),
                    "901"
                );
            }
        }
    }
}

