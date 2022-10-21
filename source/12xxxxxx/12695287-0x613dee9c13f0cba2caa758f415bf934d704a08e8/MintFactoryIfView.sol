
pragma solidity ^0.7.0;



import "./Ownable.sol";
import "./ccTokenControllerIf.sol";

/// @title MintFactoryIfView
abstract contract MintFactoryIfView {
    ccTokenControllerIf public controller;

    mapping(address => string) public custodianBtcAddressForMerchant;

    mapping(address => string) public btcDepositAddressOfMerchant;

    enum RequestStatus {PENDING, CANCELED, APPROVED, REJECTED}
    struct Request {
        address requester;
        uint amount;
        string btcAddress;
        string btcTxId;
        uint seq;
        uint requestBlockNo;
        uint confirmedBlockNo;
        RequestStatus status;
    }

    mapping(bytes32 => uint) public mintRequestSeqMap;

    mapping(bytes32 => uint) public burnRequestSeqMap;

    Request[] public mintRequests;

    Request[] public burnRequests;

    function getMintRequest(uint seq)
    external
    view
    virtual
    returns (
        uint requestSeq,
        address requester,
        uint amount,
        string memory btcAddress,
        string memory btcTxId,
        uint requestBlockNo,
        uint confirmedBlockNo,
        string  memory status,
        bytes32 requestHash
    );

    function getMintRequestsLength() virtual external view returns (uint length);

    function getBurnRequest(uint seq)
    external
    view
    virtual
    returns (
        uint requestSeq,
        address requester,
        uint amount,
        string memory btcAddress,
        string memory btcTxId,
        uint requestBlockNo,
        uint confirmedBlockNo,
        string  memory status,
        bytes32 requestHash
    );

    function getBurnRequestsLength() virtual external view returns (uint length);

    function getPendingMintRequestV(bytes32 _requestHash)
    virtual
    view public returns (
        uint requestSeq,
        address requester,
        uint amount,
        string memory btcAddress,
        string memory btcTxId,
        uint requestBlockNo,
        uint confirmedBlockNo,
        string  memory status);


}

