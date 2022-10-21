// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract CRT is Ownable, IERC721Receiver {
    function execute(
        IERC721 token,
        uint256 tokenId,
        uint256 blockNumber
    ) external payable onlyOwner {
        require(blockNumber >= block.number, "CRT_BLOCK_TARGET_EXCEEDED");

        CRTMC instance = new CRTMC(token, owner());
        token.transferFrom(address(this), address(instance), tokenId);
        instance.execute{value: msg.value}(tokenId);
    }

    function withdrawBalance(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "CRT_BALANCE_TRANSFER_FAILURE");
    }

    function withdrawERC721(
        IERC721 token,
        address receiver,
        uint256 tokenId
    ) external onlyOwner {
        token.transferFrom(address(this), receiver, tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract CRTMC is Ownable, IERC721Receiver {
    IERC721 private token;
    address private receiver;

    uint256 private constant PRICE = 0.088 ether;
    IMC private constant TARGET =
        IMC(0xA4631A191044096834Ce65d1EE86b16b171D8080);

    constructor(IERC721 _token, address _receiver) {
        token = _token;
        receiver = _receiver;
    }

    function execute(uint256 tokenId) external payable onlyOwner {
        require(msg.value % PRICE == 0, "CRTMC_INVALID_PRICE");
        TARGET.mint{value: PRICE}(address(this), 1);
        token.transferFrom(address(this), owner(), tokenId);
        selfdestruct(payable(receiver));
    }

    function onERC721Received(
        address operator,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        if (address(TARGET) == msg.sender) {
            IERC721 sender = IERC721(msg.sender);
            sender.transferFrom(operator, receiver, tokenId);

            if (address(this).balance > 0) {
                TARGET.mint{value: PRICE}(address(this), 1);
            }
        }

        return this.onERC721Received.selector;
    }
}

interface IMC {
    function mint(address, uint256) external payable;
}

