// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GoldzAirdrop is EIP712, Ownable {
    IERC20 goldz = IERC20(0x65831300D395E93065a7284f450B63293B640458);

    mapping(address => bool) public addressToClaimed;

    address _signerAddress;

    event GetAirdrop(uint amount, address receiver);
    
    constructor() EIP712("GoldzAirdrop", "1.0.0") {
        _signerAddress = 0x7bE647634A942e73F8492d15Ae492D867Ce5245c;
    }

    function claim(uint amount, bytes calldata signature) external {
        require(_signerAddress == recoverAddress(msg.sender, amount, signature), "invalid signature");
        require(addressToClaimed[msg.sender] == false, "airdrop already claimed");

        goldz.transfer(msg.sender, amount);
        addressToClaimed[msg.sender] = true;

        emit GetAirdrop(amount, msg.sender);
    }

     function _hash(address account, uint amount) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("AIRDROP(uint256 amount,address account)"),
                        amount,
                        account
                    )
                )
            );
    }

    function recoverAddress(address account, uint amount, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, amount), signature);
    }
    
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function withdrawGoldz() external onlyOwner {
        uint amount = goldz.balanceOf(address(this));
        goldz.transfer(msg.sender, amount);
    }
}


