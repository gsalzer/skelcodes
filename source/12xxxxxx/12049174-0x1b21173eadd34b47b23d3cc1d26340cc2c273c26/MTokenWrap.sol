//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental SMTChecker;
import "./ERC20If.sol";
import "./Ownable.sol";
import "./CanReclaimToken.sol";
import "./SafeMathLib.sol";

contract MTokenWrap is Ownable, CanReclaimToken {
    using SafeMath for uint256;
    ERC20If public mtoken;
    string public nativeCoinType;
    address public mtokenRepository;
    uint256 public wrapSeq;
    mapping(bytes32 => uint256) public wrapSeqMap;

    // bool public checkSignature = true;

    uint256 constant rate_precision = 1e10;

    // function _checkSignature(bool _b) public onlyOwner {
    //     checkSignature = _b;
    // }

    function _mtokenRepositorySet(address newMtokenRepository)
        public
        onlyOwner
    {
        require(newMtokenRepository != (address)(0), "invalid addr");
        mtokenRepository = newMtokenRepository;
    }

    function wrapHash(string memory nativeCoinAddress, string memory nativeTxId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(nativeCoinAddress, nativeTxId));
    }

    event SETUP(
        address _mtoken,
        string _nativeCoinType,
        address _mtokenRepository
    );

    function setup(
        address _mtoken,
        string memory _nativeCoinType,
        address _mtokenRepository,
        address _initOwner
    )
        public
        returns (
            //onlyOwner   一次setup，不鉴权了
            bool
        )
    {
        if (wrapSeq <= 0) {
            wrapSeq = 1;
            mtoken = (ERC20If)(_mtoken);
            nativeCoinType = _nativeCoinType;
            mtokenRepository = _mtokenRepository;
            owner = _initOwner;
            emit SETUP(_mtoken, _nativeCoinType, _mtokenRepository);
            emit OwnershipTransferred(_owner(), _initOwner);
            return true;
        }
        return false;
    }

    function uintToString(uint256 _i) public pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }

    function toHexString(bytes memory data)
        public
        pure
        returns (string memory)
    {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function toHexString(address account) public pure returns (string memory) {
        return toHexString(abi.encodePacked(account));
    }

    function calcMTokenAmount(
        uint256 amt,
        uint256 fee,
        uint256 rate
    ) public pure returns (uint256) {
        return amt.sub(fee).mul(rate).div(rate_precision);
    }

    function encode(
        address receiveMTokenAddress,
        string memory nativeCoinAddress,
        uint256 amt,
        uint256 fee,
        uint256 rate,
        uint64 deadline //TODO  暂时设置为public
    ) public view returns (bytes memory) {
        return
            abi.encodePacked(
                "wrap ",
                nativeCoinType,
                "\nto:",
                toHexString(receiveMTokenAddress),
                "\namt:",
                uintToString(amt),
                "\nfee:",
                uintToString(fee),
                "\nrate:",
                uintToString(rate),
                "\ndeadline:",
                uintToString(deadline),
                "\naddr:",
                nativeCoinAddress
            );
    }

    function personalMessage(bytes memory _msg)
        public
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                uintToString(_msg.length),
                _msg
            );
    }

    function recoverPersonalSignature(
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory text
    ) public pure returns (address) {
        bytes32 h = keccak256(personalMessage(text));
        return ecrecover(h, v, r, s);
    }

    function wrap(
        address ethAccount,
        address receiveMTokenAddress,
        string memory nativeCoinAddress,
        string memory nativeTxId,
        uint256 amt,
        uint256 fee,
        uint256 rate,
        uint64 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public onlyOwner returns (bool) {
        uint256 mtokenAmount = calcMTokenAmount(amt, fee, rate);
        // if (checkSignature) 
        {
            bytes memory text =
                encode(
                    receiveMTokenAddress,
                    nativeCoinAddress,
                    amt,
                    fee,
                    rate,
                    deadline
                );

            address addr = recoverPersonalSignature(r, s, v, text);
            require(addr == ethAccount, "invalid signature");
        }
        require(
            wrapSeqMap[wrapHash(nativeCoinAddress, nativeTxId)] <= 0,
            "wrap dup."
        );
        wrapSeqMap[wrapHash(nativeCoinAddress, nativeTxId)] = wrapSeq;
        wrapSeq = wrapSeq + 1;

        require(
            mtoken.transferFrom(
                mtokenRepository,
                receiveMTokenAddress,
                mtokenAmount
            ),
            "transferFrom failed"
        );
        emit WRAP_EVENT(
            wrapSeq,
            ethAccount,
            receiveMTokenAddress,
            nativeCoinAddress,
            nativeTxId,
            amt,fee,rate,
            deadline,
            r,
            s,
            v
        );

        return true;
    }

    event WRAP_EVENT(
        uint256 indexed wrapSeq,
        address ethAccount,
        address receiveMTokenAddress,
        string nativeCoinAddress,
        string nativeTxId,
        uint256 amt,
        uint256 fee,
        uint256 rate,
        uint64 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    );
}

