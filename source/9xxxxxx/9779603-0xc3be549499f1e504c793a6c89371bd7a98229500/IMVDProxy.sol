pragma solidity ^0.6.0;

interface IMVDProxy {

    function init(address votingTokenAddress, address stateHolderAddress, address functionalityModelsManagerAddress, address functionalityProposalManagerAddress, address functionalitiesManagerAddress) external;

    function getToken() external view returns(address);
    function setToken(address newAddress) external;
    function getStateHolderAddress() external view returns(address);
    function setStateHolderAddress(address newAddress) external;
    function getMVDFunctionalityProposalManagerAddress() external view returns(address);
    function setMVDFunctionalityProposalManagerAddress(address newAddress) external;
    function getMVDFunctionalityModelsManagerAddress() external view returns(address);
    function setMVDFunctionalityModelsManagerAddress(address newAddress) external;
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function setMVDFunctionalitiesManagerAddress(address newAddress) external;
    function changeProxy(address payable newAddress) external payable;
    function getFunctionalitiesAmount() external view returns(uint256);
    function isValidProposal(address proposal) external view returns (bool);
    function isValidFunctionality(address functionality) external view returns(bool);
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
    function getFunctionalityAddress(string calldata codeName) external view returns(address);
    function hasFunctionality(string calldata codeName) external view returns(bool);
    function functionalitiesToJSON() external view returns(string memory functionsJSONArray);
    function functionalitiesToJSON(uint256 start, uint256 l) external view returns(string memory functionsJSONArray);
    function getPendingProposal(string calldata codeName) external view returns(address proposalAddress, bool isPending);
    function newProposal(string calldata codeName, bool emergency, address sourceLocation, uint256 sourceLocationId, address location, bool submitable, string calldata methodSignature, string calldata returnParametersJSONArray, bool isInternal, bool needsSender, string calldata replaces) external returns(address proposalAddress);
    function startProposal(address proposalAddress) external;
    function disableProposal(address proposalAddress) external;
    function transfer(address receiver, uint256 value, address token) external;
    function setProposal() external;
    function read(string calldata codeName, bytes calldata data) external view returns(bytes memory returnData);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
    function callFromManager(address location, bytes calldata payload) external returns(bool, bytes memory);
    function emitFromManager(string calldata codeName, uint256 position, address proposal, string calldata replaced, address location, bool submitable, string calldata methodSignature, bool isInternal, bool needsSender, address proposalAddress, uint256 replacedPosition) external;

    function emitEvent(string calldata eventSignature, bytes calldata firstIndex, bytes calldata secondIndex, bytes calldata data) external;

    event TokenChanged(address indexed oldAddress, address indexed newAddress);
    event MVDFunctionalityProposalManagerChanged(address indexed oldAddress, address indexed newAddress);
    event MVDFunctionalityModelsManagerChanged(address indexed oldAddress, address indexed newAddress);
    event MVDFunctionalitiesManagerChanged(address indexed oldAddress, address indexed newAddress);
    event StateHolderChanged(address indexed oldAddress, address indexed newAddress);
    event ProxyChanged(address indexed newAddress);

    event PaymentReceived(address indexed sender, uint256 value);
    event Proposal(address proposal);
    event ProposalSet(address indexed proposal, bool success);
    event FunctionalitySet(string indexed codeName, uint256 position, address proposal, string indexed replaced, address replacedLocation, bool replacedWasSubmitable, string replacedMethodSignature, bool replacedWasInternal, bool replacedNeededSender, address replacedProposal, uint256 replacedPosition);

    event Event(string indexed key, bytes32 indexed firstIndex, bytes32 indexed secondIndex, bytes data);
}
