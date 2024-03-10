//SPDX-License-Identifier: MIT
/* solhint-disable func-order, code-complexity */
pragma solidity 0.7.5;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../BaseWithStorage/WithSuperOperators.sol";
import "../BaseWithStorage/WithMetaTransaction.sol";
import "../Interfaces/IERC721MandatoryTokenReceiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721BaseToken is IERC721, WithSuperOperators, WithMetaTransaction {
    using Address for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant _ERC721_BATCH_RECEIVED = 0x4b808c46;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;
    bytes4 internal constant ERC721_MANDATORY_RECEIVER = 0x5e8bf644;

    mapping(address => uint256) internal _numNFTPerAddress;
    mapping(uint256 => uint256) internal _owners;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    mapping(uint256 => address) internal _operators;

    constructor(address metaTransactionContract, address admin) {
        _admin = admin;
        _setMetaTransactionProcessor(metaTransactionContract, METATX_SANDBOX);
    }

    /// @notice Approve an operator to spend tokens on the senders behalf.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approve(address operator, uint256 id) external override {
        address owner = _ownerOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(
            owner == msg.sender || _superOperators[msg.sender] || _operatorsForAll[owner][msg.sender],
            "UNAUTHORIZED_APPROVAL"
        );
        _approveFor(owner, operator, id);
    }

    /// @notice Approve an operator to spend tokens on the sender behalf.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external {
        address owner = _ownerOf(id);
        require(sender != address(0), "ZERO_ADDRESS_SENDER");
        require(
            msg.sender == sender ||
                _isValidMetaTx(sender) ||
                _superOperators[msg.sender] ||
                _operatorsForAll[sender][msg.sender],
            "UNAUTHORIZED_APPROVAL"
        );
        require(owner == sender, "OWNER_NOT_SENDER");
        _approveFor(owner, operator, id);
    }

    /// @notice Transfer a token between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        bool metaTx = _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            require(_checkOnERC721Received(metaTx ? from : msg.sender, from, to, id, ""), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Transfer a token between 2 addresses letting the receiver know of the transfer.
    /// @param from The send of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external override {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Transfer many tokens between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external {
        _batchTransferFrom(from, to, ids, data, false);
    }

    /// @notice Transfer many tokens between 2 addresses, while
    /// ensuring the receiving contract has a receiver method.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external {
        _batchTransferFrom(from, to, ids, data, true);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender != address(0), "Invalid sender address");
        require(
            msg.sender == sender || _isValidMetaTx(sender) || _superOperators[msg.sender],
            "UNAUTHORIZED_APPROVE_FOR_ALL"
        );

        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAll(address operator, bool approved) external override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Burns token `id`.
    /// @param id The token which will be burnt.
    function burn(uint256 id) external virtual {
        _burn(msg.sender, _ownerOf(id), id);
    }

    /// @notice Burn token`id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id The token which will be burnt.
    function burnFrom(address from, uint256 id) external virtual {
        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(
            msg.sender == from ||
                _isValidMetaTx(from) ||
                (operatorEnabled && _operators[id] == msg.sender) ||
                _superOperators[msg.sender] ||
                _operatorsForAll[from][msg.sender],
            "UNAUTHORIZED_BURN"
        );
        _burn(from, owner, id);
    }

    /// @notice Get the number of tokens owned by an address.
    /// @param owner The address to look for.
    /// @return The number of tokens owned by the address.
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS_OWNER");
        return _numNFTPerAddress[owner];
    }

    /// @notice Get the owner of a token.
    /// @param id The id of the token.
    /// @return owner The address of the token owner.
    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "NONEXISTANT_TOKEN");
    }

    /// @notice Get the approved operator for a specific token.
    /// @param id The id of the token.
    /// @return The address of the operator.
    function getApproved(uint256 id) external view override returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    /// @notice Check if the sender approved the operator.
    /// @param owner The address of the owner.
    /// @param operator The address of the operator.
    /// @return isOperator The status of the approval.
    function isApprovedForAll(address owner, address operator) external view override returns (bool isOperator) {
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    /// @notice Transfer a token between 2 addresses letting the receiver knows of the transfer.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    /// @param data Additional data.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        bool metaTx = _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract()) {
            require(_checkOnERC721Received(metaTx ? from : msg.sender, from, to, id, data), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Check if the contract supports an interface.
    /// 0x01ffc9a7 is ERC-165.
    /// 0x80ac58cd is ERC-721
    /// @param id The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 id) public pure virtual override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd;
    }

    /// @dev See transferFrom.
    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        _numNFTPerAddress[from]--;
        _numNFTPerAddress[to]++;
        _owners[id] = uint256(to);
        emit Transfer(from, to, id);
    }

    /// @dev See approveFor.
    function _approveFor(
        address owner,
        address operator,
        uint256 id
    ) internal {
        if (operator == address(0)) {
            _owners[id] = _owners[id] & (2**255 - 1); // no need to resset the operator, it will be overriden next time
        } else {
            _owners[id] = _owners[id] | (2**255);
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    /// @dev See batchTransferFrom.
    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data,
        bool safe
    ) internal {
        bool metaTx = _isValidMetaTx(from);
        bool authorized = msg.sender == from ||
            metaTx ||
            _superOperators[msg.sender] ||
            _operatorsForAll[from][msg.sender];

        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        require(to != address(0), "NOT_TO_ZEROADDRESS");

        uint256 numTokens = ids.length;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 id = ids[i];
            (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
            require(owner == from, "BATCHTRANSFERFROM_NOT_OWNER");
            require(authorized || (operatorEnabled && _operators[id] == msg.sender), "NOT_AUTHORIZED");
            _owners[id] = uint256(to);
            emit Transfer(from, to, id);
        }
        if (from != to) {
            _numNFTPerAddress[from] -= numTokens;
            _numNFTPerAddress[to] += numTokens;
        }

        if (to.isContract() && (safe || _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER))) {
            require(
                _checkOnERC721BatchReceived(metaTx ? from : msg.sender, from, to, ids, data),
                "ERC721_BATCH_TRANSFER_REJECTED"
            );
        }
    }

    /// @dev See setApprovalForAll.
    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(!_superOperators[operator], "INVALID_APPROVAL_CHANGE");
        _operatorsForAll[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    /// @dev See burn.
    function _burn(
        address from,
        address owner,
        uint256 id
    ) internal {
        require(from == owner, "NOT_OWNER");
        _owners[id] = (_owners[id] & (2**255 - 1)) | (2**160); // record as non owner but keep track of last owner
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
    }

    /// @dev Check if receiving contract accepts erc721 transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The adddress we want to transfer to.
    /// @param tokenId The id of the token we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x150b7a02 is returned.
    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721Receiver(to).onERC721Received(operator, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /// @dev Check if receiving contract accepts erc721 batch transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The adddress we want to transfer to.
    /// @param ids The ids of the tokens we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x4b808c46 is returned.
    function _checkOnERC721BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721MandatoryTokenReceiver(to).onERC721BatchReceived(operator, from, ids, _data);
        return (retval == _ERC721_BATCH_RECEIVED);
    }

    /// @dev See ownerOf
    function _ownerOf(uint256 id) internal view virtual returns (address) {
        uint256 data = _owners[id];
        if ((data & (2**160)) == 2**160) {
            return address(0);
        }
        return address(data);
    }

    /// @dev Get the owner and operatorEnabled status of a token.
    /// @param id The token to query.
    /// @return owner The owner of the token.
    /// @return operatorEnabled Whether or not operators are enabled for this token.
    function _ownerAndOperatorEnabledOf(uint256 id) internal view returns (address owner, bool operatorEnabled) {
        uint256 data = _owners[id];
        if ((data & (2**160)) == 2**160) {
            owner = address(0);
        } else {
            owner = address(data);
        }
        operatorEnabled = (data / 2**255) == 1;
    }

    /// @dev Check whether a transfer is a meta Transaction or not.
    /// @param from The address who initiated the transfer (may differ from msg.sender).
    /// @param to The address recieving the token.
    /// @param id The token being transferred.
    /// @return isMetaTx Whether or not the transaction is a MetaTx.
    function _checkTransfer(
        address from,
        address to,
        uint256 id
    ) internal view returns (bool isMetaTx) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(owner == from, "CHECKTRANSFER_NOT_OWNER");
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        isMetaTx = _isValidMetaTx(from);
        if (msg.sender != from && !isMetaTx) {
            require(
                _superOperators[msg.sender] ||
                    _operatorsForAll[from][msg.sender] ||
                    (operatorEnabled && _operators[id] == msg.sender),
                "UNAUTHORIZED_TRANSFER"
            );
        }
    }

    /// @dev Check if there was enough gas.
    /// @param _contract The address of the contract to check.
    /// @param interfaceId The id of the interface we want to test.
    /// @return Whether or not this check succeeded.
    function _checkInterfaceWith10000Gas(address _contract, bytes4 interfaceId) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory callData = abi.encodeWithSelector(ERC165ID, interfaceId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let call_ptr := add(0x20, callData)
            let call_size := mload(callData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }
}

