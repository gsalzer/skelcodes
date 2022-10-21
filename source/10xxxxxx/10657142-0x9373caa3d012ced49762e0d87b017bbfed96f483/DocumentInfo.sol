/**
 *Submitted for verification at Etherscan.io on 2020-08-14
*/

pragma solidity ^0.4.25;
contract DocumentInfo {
    struct Document {
        string doc;
    }
    Document[] public documents;

    function addDocument(string doc, string verifier_email, string client_email, string doc_name,string verifier_myReflect_code, string client_myReflect_code, string request_status, string reason) public returns(uint) {
        documents.length++;
        documents[documents.length-1].doc = doc;
        return documents.length;
    }
      
    function getDocumentsCount() public constant returns(uint) {
        return documents.length;
    }

    function getDocument(uint index) public constant returns(string) {
        return (documents[index].doc);
    }
}
