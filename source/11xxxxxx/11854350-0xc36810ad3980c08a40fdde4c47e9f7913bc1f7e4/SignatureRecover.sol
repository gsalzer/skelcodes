pragma solidity ^0.4.0;

contract SignatureRecover {
    uint256 constant chainId = 1;

    struct Unit {
        address to;
        uint256 value;
        uint256 fee;
        uint256 nonce;
    }

    string private constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    string private constant UNIT_TYPE = "Unit(address to,uint256 value,uint256 fee,uint256 nonce)";

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
    bytes32 private constant UNIT_TYPEHASH = keccak256(abi.encodePacked(UNIT_TYPE));

    bytes32 private DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("IRDT"),
            keccak256("1"),
            chainId,
            this
        ));

    function hashUnit(Unit memory unitobj) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    UNIT_TYPEHASH,
                    unitobj.to,
                    unitobj.value,
                    unitobj.fee,
                    unitobj.nonce
                ))
            ));
    }


    /**
    * recover '_from' address by signature
    */
    function testVerify(bytes32 s, bytes32 r, uint8 v, address _to, uint256 _value, uint256 _fee, uint256 _nonce) internal view returns (address) {
        Unit memory _msgobj = Unit({
        to : _to,
        value : _value,
        fee : _fee,
        nonce : _nonce
        });
        return ecrecover(hashUnit(_msgobj), v, r, s);
    }
}

