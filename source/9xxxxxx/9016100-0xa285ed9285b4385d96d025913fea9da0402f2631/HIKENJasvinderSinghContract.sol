pragma solidity ^0.4.6;

contract HIKENJasvinderSinghContract {

    address public HikenContract;
    address public JasvinderSinghT;

    struct documentStruct {
        bool approvedByHikenContract;
        bool approvedByJasvinderSinghT;
    }

    // this data is all publicly explorable

    mapping(bytes32 => documentStruct) public documentStructs;
    bytes32[] public documentList; // all
    bytes32[] public approvedDocuments; // approved

    // for event listeners    

    event LogProposedDocument(address proposer, bytes32 docHash);
    event LogApprovedDocument(address approver, bytes32 docHash);

    // constructor needs to know who HikenContract & JasvinderSinghT are

    function HIKENJasvinderSinghContract(address addressA, address addressB) {
        HikenContract = 0xB85b310739f6ccf1aA439C8785Cdd4Bb716b8C18;
        JasvinderSinghT = 0xe6659A0504230AEb1559145a429Da78EE9C49269;
    }

    // for convenient iteration over both lists
    function getDocumentsCount() public constant returns(uint docCount) {
        return documentList.length;
    }

    function getApprovedCount() public constant returns(uint apprCount) {
        return approvedDocuments.length;
    }

    // propose / Approve

    function agreeDoc(bytes32 hash) public returns(bool success) {
        if(msg.sender != HikenContract && msg.sender != JasvinderSinghT) throw; // stranger. abort. 
        if(msg.sender == HikenContract) documentStructs[hash].approvedByHikenContract = true; // could do else. it's HikenContract or JasvinderSinghT.
        if(msg.sender == JasvinderSinghT) documentStructs[hash].approvedByJasvinderSinghT = true; 

        if(documentStructs[hash].approvedByHikenContract == true && documentStructs[hash].approvedByJasvinderSinghT == true) {
            uint docCount = documentList.push(hash);
            LogApprovedDocument(msg.sender, hash);
        } else {
            uint apprCount = approvedDocuments.push(hash);
            LogProposedDocument(msg.sender, hash);
        }
        return true;
    }
}
