// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC777 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function granularity() external view returns (uint256);

    function defaultOperators() external view returns (address[] memory);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    function send(address to, uint256 amount, bytes calldata data) external;
    function operatorSend(address from, address to, uint256 amount, bytes calldata data, bytes calldata operatorData) external;

    function burn(uint256 amount, bytes calldata data) external;
    function operatorBurn(address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external;

    event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

contract BLOCKSMultiSender {

    function send(IERC777 _token, address[] memory _recipients, uint256 _amount, bytes memory _data) public {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _token.operatorSend(msg.sender, _recipients[i], _amount, _data, "");
        }
    }

    function sendAmounts(IERC777 _token, address[] memory _recipients, uint256[] memory _amounts, bytes memory _data) public {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _token.operatorSend(msg.sender, _recipients[i], _amounts[i], _data, "");
        }
    }
}
