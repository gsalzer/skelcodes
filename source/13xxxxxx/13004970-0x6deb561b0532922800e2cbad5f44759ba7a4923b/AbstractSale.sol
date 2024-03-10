pragma solidity ^0.5.0;

import "./libs.sol";
import "./Roles.sol";
import "./ERC165.sol";

/// @title AbstractSale
/// @notice Base contract for `ERC721Sale` and `ERC1155Sale`.
contract AbstractSale is Ownable {
    using UintLibrary for uint256;
    using AddressLibrary for address;
    using StringLibrary for string;
    using SafeMath for uint256;

    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    /// @notice The amount of buyer's fee. Represented as percents * 100 (100% - 10000. 1% - 100).
    uint public buyerFee = 0;
    /// @notice The address to which all the fees are transfered.
    address payable public beneficiary;

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /// @notice The contract constructor.
    /// @param _beneficiary - The value for `beneficiary`.
    constructor(address payable _beneficiary) public {
        beneficiary = _beneficiary;
    }

    /// @notice Set new buyer fee value. Can only be called by the contract owner.
    ///         Fee value is represented as percents * 100 (100% - 10000. 1% - 100).
    /// @param _buyerFee - New fee value percents times 100 format.
    function setBuyerFee(uint256 _buyerFee) public onlyOwner {
        buyerFee = _buyerFee;
    }

    /// @notice Set new address as fee recipient. Can only be called by the contract owner.
    /// @param _beneficiary - New `beneficiary` address.
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function prepareMessage(address token, uint256 tokenId, uint256 price, uint256 fee, uint256 nonce) internal pure returns (string memory) {
        string memory result = string(strConcat(
                bytes(token.toString()),
                bytes(". tokenId: "),
                bytes(tokenId.toString()),
                bytes(". price: "),
                bytes(price.toString()),
                bytes(". nonce: "),
                bytes(nonce.toString())
            ));
        if (fee != 0) {
            return result.append(". fee: ", fee.toString());
        } else {
            return result;
        }
    }

    function strConcat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }

    function transferEther(IERC165 token, uint256 tokenId, address payable owner, uint256 total, uint256 sellerFee) internal {
        uint value = transferFeeToBeneficiary(total, sellerFee);
        if (token.supportsInterface(_INTERFACE_ID_FEES)) {
            HasSecondarySaleFees withFees = HasSecondarySaleFees(address(token));
            address payable[] memory recipients = withFees.getFeeRecipients(tokenId);
            uint[] memory fees = withFees.getFeeBps(tokenId);
            require(fees.length == recipients.length);
            for (uint256 i = 0; i < fees.length; i++) {
                (uint newValue, uint current) = subFee(value, total.mul(fees[i]).div(10000));
                value = newValue;
                recipients[i].transfer(current);
            }
        }
        owner.transfer(value);
    }

    function transferFeeToBeneficiary(uint total, uint sellerFee) internal returns (uint) {
        (uint value, uint sellerFeeValue) = subFee(total, total.mul(sellerFee).div(10000));
        uint buyerFeeValue = total.mul(buyerFee).div(10000);
        uint beneficiaryFee = buyerFeeValue.add(sellerFeeValue);
        if (beneficiaryFee > 0) {
            beneficiary.transfer(beneficiaryFee);
        }
        return value;
    }

    function subFee(uint value, uint fee) internal pure returns (uint newValue, uint realFee) {
        if (value > fee) {
            newValue = value - fee;
            realFee = fee;
        } else {
            newValue = 0;
            realFee = value;
        }
    }
}


