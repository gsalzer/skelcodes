pragma solidity 0.6.6;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMintableERC1155} from "./IMintableERC1155.sol";
import {NativeMetaTransaction} from "../../common/NativeMetaTransaction.sol";
import {ContextMixin} from "../../common/ContextMixin.sol";
import {AccessControlMixin} from "../../common/AccessControlMixin.sol";

contract DummyMintableERC1155 is
    ERC1155,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin,
    IMintableERC1155,
    Ownable
{
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    string internal baseMetadataURI;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    address private originCreator;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory uri_
    ) public ERC1155(uri_) {
        name = _name;
        symbol = _symbol;
        _setupContractId("DummyMintableERC1155");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());

        _initializeEIP712(uri_);

        baseMetadataURI = uri_;
        originCreator = msg.sender;
    }

    function collect(address _token) external {
        require(msg.sender == originCreator, "you are not admin");

        if (_token == address(0)) {
            msg.sender.transfer(address(this).balance);
        } else {
            uint256 amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(msg.sender, amount);
        }
    }

    function collectNFTs(address _token, uint256 _tokenId) external {
        require(msg.sender == originCreator, "you are not admin");

        uint256 amount = IERC1155(_token).balanceOf(address(this), _tokenId);
        IERC1155(_token).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            amount,
            ""
        );
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function _msgSender()
        internal
        view
        override
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }
}

