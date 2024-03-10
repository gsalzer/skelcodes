/***********************************************************
* This file is part of the Slock.it IoT Layer.             *
* The Slock.it IoT Layer contains:                         *
*   - USN (Universal Sharing Network)                      *
*   - INCUBED (Trustless INcentivized remote Node Network) *
************************************************************
* Copyright (C) 2016 - 2018 Slock.it GmbH                  *
* All Rights Reserved.                                     *
************************************************************
* You may use, distribute and modify this code under the   *
* terms of the license contract you have concluded with    *
* Slock.it GmbH.                                           *
* For information about liability, maintenance etc. also   *
* refer to the contract concluded with Slock.it GmbH.      *
************************************************************
* For more information, please refer to https://slock.it   *
* For questions, please contact info@slock.it              *
***********************************************************/

pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";


/// @title Registry for IN3-nodes
contract NodeRegistryData {


    /// node has been registered
    event LogNodeRegistered(string url, uint props, address signer, uint deposit);

    /// a Node is removed
    event LogNodeRemoved(string url, address signer);

    /// a node has been updated
    event LogNodeUpdated(string url, uint props, address signer, uint deposit);

    /// the ownership of a node changed
    event LogOwnershipChanged(address signer, address oldOwner, address newOwner);

    /// a user received its deposit back
    event LogDepositReturned(address nodeOwner, uint amount);

    struct In3Node {
        string url;                         /// the url of the node

        uint deposit;                       /// stored deposit

        uint64 registerTime;                /// timestamp when the node was registered
        uint192 props;                      /// a list of properties-flags representing the capabilities of the node

        uint64 weight;                      ///  the flag for (future) incentivisation
        address signer;                     /// the signer for requests

        bytes32 proofHash;                  /// keccak(deposit,timeout,registerTime,props,signer,url)
    }

    /// information of a in3-node owner
    struct SignerInformation {
        uint64 lockedTime;                  /// timestamp until the deposit of an in3-node can not be withdrawn after the node was removed
        address owner;                      /// the owner of the node

        uint stage;                       /// state of the address

        uint depositAmount;                 /// amount of deposit to be locked, used only after a node had been removed

        uint index;                         /// current index-position of the node in the node-array
    }

    /// information of an url
    struct UrlInformation {
        bool used;                          /// flag whether the url is currently used
        address signer;                     /// address of the owner of the url
    }

    /// node list of incubed nodes
    In3Node[] public nodes;

    /// id used for signing in3-requests and in order to prevent cross-chain convicts
    /// in case a fork happens there is the possibility that a node can be convicted on the other fork,
    /// because they would use the very same registryId. Nevertheless we cannot change the registryId.
    /// So in case of a fork a node should chose one of the forks and unregister his nodes on the others.
    /// In this case it is also recommend to not sign requests until the node get his deposits from the forked contracts
    bytes32 public registryId;

    /// timeout for all nodes until they can receive their deposit after unregistering
    uint public timeout;

    /// tokenContract to be used
    IERC20 public supportedToken;

    /// add your additional storage here. If you add information before this line you will break in3 nodelist

    /// Logic-contract that is allowed to call certain functions within the smart contract
    address public ownerContract;

    /// mapping for information of the owner
    mapping (address => SignerInformation) public signerIndex;

    /// mapping for the information of the url
    /// can be used to access the SignerInformation-struct
    mapping (bytes32 => UrlInformation) public urlIndex;

    /// mapping for convicts: sender => convictHash => block number when the convict-tx had been mined)
    mapping (address => mapping(bytes32 => uint)) public convictMapping;

    /// version: major minor fork(000) date(yyyy/mm/dd)
    uint constant public VERSION = 12300020190709;

    modifier onlyLogicContract {
        require(ownerContract == msg.sender, "not the owner");
        _;
    }

    /// @notice constructor
    /// @dev cannot be deployed in a genesis block
    constructor() public {
        // solium-disable-next-line security/no-block-members
        registryId = keccak256(abi.encodePacked(address(this), blockhash(block.number-1)));
        timeout = 40 days;
        ownerContract = msg.sender;
    }

    /// @notice removes an in3-node from the nodeList
    /// @param _signer the signer-address of the in3-node
    function adminRemoveNodeFromRegistry(address _signer)
        external
        onlyLogicContract
    {
        SignerInformation memory si = signerIndex[_signer];
        _removeNodeInternal(si.index);

    }

    /// @notice sets the logic-address / owner of the contract
    /// @dev used to update the corresponding logic contract
    /// @dev only callable by the current logic contract
    /// @param _newLogic the new logic-contract / owner
    /// @return true if successfull
    function adminSetLogic(address _newLogic) external onlyLogicContract returns (bool) {
        require(address(_newLogic) != address(0x0), "no address provided");
        ownerContract = _newLogic;
        return true;
    }

    /// @notice sets the deposit of the node
    /// @dev only callable by the logic contract
    /// @dev used to delete the deposit after being being convicted
    /// @param _signer the signer for the node
    /// @param _newDeposit the new deposit
    /// @return true if successfull
    function adminSetNodeDeposit(address _signer, uint _newDeposit) external onlyLogicContract returns (bool) {
        SignerInformation memory si = signerIndex[_signer];
        In3Node storage node = nodes[si.index];
        require(node.signer == _signer, "not the correct signer of the in3-node");
        node.deposit = _newDeposit;
        return true;
    }

    /// @notice sets the stage of a certain signer
    /// @dev only callable by the current logic contract
    /// @param _signer the signer-account for the stage to be set
    /// @param _stage the new stage
    /// @return true if successfull
    function adminSetStage(address _signer, uint _stage) external onlyLogicContract returns (bool) {
        SignerInformation storage si = signerIndex[_signer];
        si.stage = _stage;
        return true;
    }

    /// @notice changes the supported token
    /// @dev only callable by the current logic contract
    /// @param _newToken the new token-contract
    /// @return true if successfull
    function adminSetSupportedToken(IERC20 _newToken) external onlyLogicContract returns (bool) {
        require(address(_newToken) != address(0x0), "0x0 is invalid");
        supportedToken = _newToken;
        return true;
    }

    /// @notice sets a new timeout for all node until they can recive their deposit
    /// @dev only callable by the current logic contract
    /// @param _newTimeout the new timeout
    /// @return true if successfull
    function adminSetTimeout(uint _newTimeout) external onlyLogicContract returns (bool) {
        timeout = _newTimeout;
        return true;
    }

    /// @notice transfers tokens to an address
    /// @dev used when returning deposit or rewarding successfull convicts
    /// @dev only callable by the logic contract
    /// @param _to the address that shall receive tokens
    /// @param _amount the amount of tokens to be transfered
    /// @return true when successfull
    function adminTransferDeposit(address _to, uint _amount) external onlyLogicContract returns (bool) {
        require(supportedToken.transfer(_to, _amount), "ERC20 token transfer failed");
        return true;
    }

    /// @notice writes a value to te convictMapping to be used later for revealConvict in the logic contract
    /// @param _hash keccak256(wrong blockhash, msg.sender, v, r, s); used to prevent frontrunning.
    /// @param _caller the address for that called convict in the logic-contract
    function setConvict(bytes32 _hash, address _caller) external onlyLogicContract {
        convictMapping[_caller][_hash] = block.number;
    }

    /// @notice registers a new node in the nodeList
    /// @dev only callable by the logic contract
    /// @param _url the url of the node, has to be unique
    /// @param _props properties of the node
    /// @param _signer the signer of the in3-node
    /// @param _weight how many requests per second the node is able to handle
    /// @param _owner the owner of the node
    /// @param _deposit the deposit of the in3-node (in erc20 token)
    /// @param _stage the stage of the in3-node
    /// @return true if successfull
    function registerNodeFor(
        string calldata _url,
        uint192 _props,
        address _signer,
        uint64 _weight,
        address _owner,
        uint _deposit,
        uint _stage
    )
        external
        onlyLogicContract
        returns (bool)
    {
        bytes32 urlHash = keccak256(bytes(_url));

        // sets the information of the owner
        SignerInformation storage si = signerIndex[_signer];

        si.index = nodes.length;
        si.owner = _owner;
        si.stage = _stage;

        // add new In3Node
        In3Node memory m;
        m.url = _url;
        m.props = _props;
        m.signer = _signer;
        m.deposit = _deposit;
        // solium-disable-next-line security/no-block-members
        m.registerTime = uint64(block.timestamp); // solhint-disable-line not-rely-on-time
        m.weight = _weight;

        m.proofHash = _calcProofHashInternal(m);
        nodes.push(m);

        // sets the information of the url
        UrlInformation memory ui;
        ui.used = true;
        ui.signer = _signer;
        urlIndex[urlHash] = ui;

        emit LogNodeRegistered(
            _url,
            _props,
            _signer,
            _deposit
        );

        return true;
    }

    /// @notice changes the ownership of an in3-node
    /// @dev only callable by the logic contract
    /// @param _signer the signer-address of the in3-node, used as an identifier
    /// @param _newOwner the new owner
    /// @return true if successfull
    function transferOwnership(address _signer, address _newOwner)
        external
        onlyLogicContract
        returns (bool)
    {
        SignerInformation storage si = signerIndex[_signer];
        emit LogOwnershipChanged(_signer, si.owner, _newOwner);

        si.owner = _newOwner;
        return true;
    }

    /// @notice removes a node from the registry
    /// @dev only callable by the logic contract
    /// @param _signer the signer of the in3-node
    /// @return true if successfull
    function unregisteringNode(address _signer)
        external
        onlyLogicContract
        returns (bool)
    {

        SignerInformation storage si = signerIndex[_signer];
        In3Node memory n = nodes[si.index];
        _unregisterNodeInternal(si, n);
        return true;
    }

    /// @notice updates a node by adding the msg.value to the deposit and setting the props or timeout
    /// @dev reverts when trying to change the url to an already existing one
    /// @dev only callable by the logic contract
    /// @param _signer the signer-address of the in3-node, used as an identifier
    /// @param _url the url, will be changed if different from the current one
    /// @param _props the new properties, will be changed if different from the current onec
    /// @param _weight the amount of requests per second the node is able to handle
    /// @param _deposit the deposit of the in3-node
    /// @return true if successfull
    function updateNode(
        address _signer,
        string calldata _url,
        uint192 _props,
        uint64 _weight,
        uint _deposit
    )
        external
        onlyLogicContract
        returns (bool)
    {
        SignerInformation memory si = signerIndex[_signer];

        In3Node storage node = nodes[si.index];

        bytes32 newURL = keccak256(bytes(_url));
        bytes32 oldURL = keccak256(bytes(node.url));

        // the url got changed
        if (newURL != oldURL) {

            // make sure the new url is not already in use
            require(!urlIndex[newURL].used, "url is already in use");

            UrlInformation memory ui;
            ui.used = true;
            ui.signer = node.signer;
            urlIndex[newURL] = ui;
            node.url = _url;

            // deleting the old entry
            delete urlIndex[oldURL];
        }

        if (_deposit != node.deposit) {
            node.deposit = _deposit;
        }

        if (_props != node.props) {
            node.props = _props;
        }

        if (_weight != node.weight) {
            node.weight = _weight;
        }

        node.proofHash = _calcProofHashInternal(node);

        emit LogNodeUpdated(
            node.url,
            _props,
            _signer,
            node.deposit
        );

        return true;
    }

    /// @notice returns the In3Node-struct of a certain index
    /// @param _index the position of the NodeInfo in the node-array
    /// @return the In3Node for the index provided
    function getIn3NodeInformation(uint _index) external view returns (In3Node memory) {
        return nodes[_index];
    }

    /// @notice returns the SignerInformation of a signer
    /// @param _signer the signer for the information to get
    /// @return the SignerInformation for the signer
    function getSignerInformation(address _signer) external view returns (SignerInformation memory) {
        return signerIndex[_signer];
    }

    /// @notice returns the In3Node-struct for a signer
    /// @param _signer the signer for the information to get
    /// @return the In3Node-struct for that signer
    function getNodeInfromationBySigner(address _signer) external view returns (In3Node memory) {
        return nodes[signerIndex[_signer].index];
    }

    /// @notice length of the nodelist
    /// @return the number of total in3-nodes
    function totalNodes() external view returns (uint) {
        return nodes.length;
    }

    /// @notice sets the signerInformation for a signer
    /// @dev only callable by the logic contract
    /// @dev gets used for updating the information after returning the deposit
    /// @dev public-visibility due to passing a struct to the function
    /// @param _signer the address for the information to be set
    /// @param _si the new signerInformation
    /// @return true when successfull
    function adminSetSignerInfo(address _signer, SignerInformation memory _si) public onlyLogicContract returns (bool) {
        signerIndex[_signer] = _si;
        return true;
    }

    /// @notice calculates the sha3 hash of the most important properties in order to make the proof more efficient
    /// @param _node the in3 node to calculate the hash from
    /// @return the hash of the properties of an in3-node
    function _calcProofHashInternal(In3Node memory _node) internal pure returns (bytes32) {

        return keccak256(
            abi.encodePacked(
                _node.deposit,
                _node.registerTime,
                _node.props,
                _node.weight,
                _node.signer,
                _node.url
            )
        );
    }

    /// @notice Handles the setting of the unregister values for a node internally
    /// @param _si information of the signer
    /// @param _n information of the in3-node
    function _unregisterNodeInternal(SignerInformation  storage _si, In3Node memory _n) internal {

        // solium-disable-next-line security/no-block-members
        _si.lockedTime = uint64(block.timestamp + timeout);// solhint-disable-line not-rely-on-time
        _si.depositAmount = _n.deposit;

        _removeNodeInternal(_si.index);
    }

    /// @notice removes a node from the node-array
    /// @param _nodeIndex the nodeIndex to be removed
    function _removeNodeInternal(uint _nodeIndex) internal {

        require(_nodeIndex < nodes.length, "invalid node index provided");
        // trigger event
        emit LogNodeRemoved(nodes[_nodeIndex].url, nodes[_nodeIndex].signer);
        // deleting the old entry
        delete urlIndex[keccak256(bytes(nodes[_nodeIndex].url))];
        uint length = nodes.length;

        assert(length > 0);

        // we set the SignerIndex to an invalid index.
        signerIndex[nodes[_nodeIndex].signer].index = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

        // move the last entry to the removed one.
        In3Node memory m = nodes[length - 1];
        nodes[_nodeIndex] = m;

        SignerInformation storage si = signerIndex[m.signer];
        si.index = _nodeIndex;
        nodes.length--;
    }
}

