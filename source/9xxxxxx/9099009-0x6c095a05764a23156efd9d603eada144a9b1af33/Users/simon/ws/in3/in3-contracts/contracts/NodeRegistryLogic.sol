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

import "./BlockhashRegistry.sol";
import "./NodeRegistryData.sol";
import "./IERC20.sol";


/// @title Registry for IN3-nodes
contract NodeRegistryLogic {

    /// node has been registered
    event LogNodeRegistered(string url, uint192 props, address signer, uint deposit);

    /// a node was convicted
    event LogNodeConvicted(address signer);

    /// a Node is removed
    event LogNodeRemoved(string url, address signer);

    /// a node has been updated
    event LogNodeUpdated(string url, uint192 props, address signer, uint deposit);

    /// the ownership of a node changed
    event LogOwnershipChanged(address signer, address oldOwner, address newOwner);

    /// a new logic contract got proposed
    event LogNewPendingContract(address newPendingContract);

    /// deposit has been returned
    event LogDepositReturned(address signer, address owner, uint deposit, address erc20Token);

    /// Different Stages a node can have
    enum Stages {
        NotInUse,                           /// node is not in use, so a new node with the same address can be registered
        Active,                             /// node is active, so a new node with the same address cannot be registered
        Convicted,                          /// node is convited, so he is inactive, but cannot be registered anymore
        DepositNotWithdrawn                 /// node is not in use anymore, but still has some deposit stored within the contract
    }

    /// add your additional storage here. If you add information before this line you will break in3 nodelist
    /// blockhash registry address
    BlockhashRegistry public blockRegistry;

    /// address for the data of the nodeRegistry
    NodeRegistryData public nodeRegistryData;

    /// timestamp until the unregisterKey is active
    uint public timestampAdminKeyActive;

    /// admin-key to remove some server, only usable within the 1st year
    address public adminKey;

    /// timestamp when an update of the logic-contract can be applied
    uint public updateTimeout;

    /// address of an updated logic contract to be applied
    address public pendingNewLogic;

    /// capping the max deposit timeout on 1 year
    uint constant internal YEAR_DEFINITION = 1 days * 365;

    /// limit for ether per node in the 1st year
    uint public maxDepositFirstYear;

    /// min deposit required for registering a node
    uint public minDeposit;

    /// version: major minor fork(000) date(yyyy/mm/dd)
    uint constant public VERSION = 12300020190709;

    modifier onlyAdmin {
        require(msg.sender == adminKey, "not the admin");
        _;
    }

    /// @notice constructor
    /// @param _blockRegistry address of a BlockhashRegistry-contract
    /// @param _nodeRegistryData address of the nodeRegistryData-contract
    /// @dev cannot be deployed in a genesis block
    constructor(BlockhashRegistry _blockRegistry, NodeRegistryData _nodeRegistryData, uint _minDeposit) public {

        require(address(_blockRegistry) != address(0x0), "no blockRegistry address provided");
        blockRegistry = _blockRegistry;

        // solium-disable-next-line security/no-block-members
        timestampAdminKeyActive = block.timestamp + YEAR_DEFINITION;  // solhint-disable-line not-rely-on-time
        adminKey = msg.sender;
        require(address(_nodeRegistryData) != address(0x0), "no nodeRegistry address provided");
        nodeRegistryData = _nodeRegistryData;

        minDeposit = _minDeposit;
        maxDepositFirstYear = 2000 * minDeposit;
    }

    /// @notice applies the pending update
    /// @dev this will remove the current contract as owner of the NodeRegistryData
    /// @dev only callable after 47 since the new logicContract has been registered
    function activateNewLogic() external {
        require(updateTimeout != 0, "no timeout set");
        // solium-disable-next-line security/no-block-members
        require(block.timestamp > updateTimeout, "timeout not yet over"); // solhint-disable-line not-rely-on-time

        nodeRegistryData.adminSetLogic(pendingNewLogic);
    }

    /// @notice removes an in3-server from the registry
    /// @param _signer the signer-address of the in3-node
    /// @dev only callable by the adminKey-account
    /// @dev only callable in the 1st year after deployment
    function adminRemoveNodeFromRegistry(address _signer)
        external
        onlyAdmin
    {
        // solium-disable-next-line security/no-block-members
        require(block.timestamp <= timestampAdminKeyActive, "only in 1st year"); // solhint-disable-line not-rely-on-time

        NodeRegistryData.SignerInformation memory si = nodeRegistryData.getSignerInformation(_signer);
        require(si.stage == uint(Stages.Active), "wrong stage");
        NodeRegistryData.In3Node memory in3Node = nodeRegistryData.getIn3NodeInformation(si.index);

        nodeRegistryData.unregisteringNode(_signer);
        nodeRegistryData.adminSetStage(_signer, uint(Stages.DepositNotWithdrawn));

        emit LogNodeRemoved(in3Node.url, _signer);

    }

    /// @notice sets the address for a new (pending) logic
    ///         the update can only be applied after 47 days,
    ///         giving all the nodes enough time to unregister their node if they dislike the update
    /// @dev only callable by the owner of the contract
    /// @param _newLogic the address of the new logic contract
    function adminUpdateLogic(address _newLogic) external onlyAdmin {
        require(_newLogic != address(0x0), "0x address not supported");

        // solium-disable-next-line security/no-block-members
        updateTimeout = block.timestamp + 47 days; // solhint-disable-line not-rely-on-time
        pendingNewLogic = _newLogic;

        emit LogNewPendingContract(_newLogic);
    }

    /// @notice commits a blocknumber and a hash
    /// @notice must be called before revealConvict
    /// @param _hash keccak256(wrong blockhash, msg.sender, v, r, s); used to prevent frontrunning.
    /// @dev The v,r,s paramaters are from the signature of the wrong blockhash that the node provided
    function convict(bytes32 _hash) external {
        nodeRegistryData.setConvict(_hash, msg.sender);
    }

    /// @notice register a new node with the sender as owner
    /// @dev the supported tokens have to be approved by the owner first
    /// @param _url the url of the node, has to be unique
    /// @param _props properties of the node
    /// @param _weight how many requests per second the node is able to handle
    /// @param _deposit the deposit in erc20 tokens
    function registerNode(
        string calldata _url,
        uint192 _props,
        uint64 _weight,
        uint _deposit
    )
        external
    {

        _registerNodeInternal(
            _url,
            _props,
            msg.sender,
            msg.sender,
            _deposit,
            _weight
        );
    }

    /// @notice register a new node as a owner using a different signer address
    /// @dev the supported tokens have to be approved by the owner first
    /// @param _url the url of the node, has to be unique
    /// @param _props properties of the node
    /// @param _signer the signer of the in3-node
    /// @param _weight how many requests per second the node is able to handle
    /// @param _depositAmount deposit in erc20 tokens
    /// @param _v v of the signed message
    /// @param _r r of the signed message
    /// @param _s s of the signed message
    /// @dev will call the registerNodeInteral function
    /// @dev in order to prove that the owner has controll over the signer-address he has to sign a message
    /// @dev which is calculated by the hash of the url, properties, weight and the owner
    /// @dev will revert when a wrong signature has been provided
    function registerNodeFor(
        string calldata _url,
        uint192 _props,
        address _signer,
        uint64 _weight,
        uint _depositAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 tempHash = keccak256(
            abi.encodePacked(
                _url,
                _props,
                _weight,
                msg.sender
            )
        );
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, tempHash));

        require(_v == 27 || _v == 28, "invalid signature");

        address signer = ecrecover(
            prefixedHash,
            _v,
            _r,
            _s
        );

        require(_signer == signer, "not the correct signature of the signer provided");

        _registerNodeInternal(
            _url,
            _props,
            _signer,
            msg.sender,
            _depositAmount,
            _weight
        );
    }

    /// @notice returns the deposit of a former node after the timeout has passed
    /// @dev only callable by the owner of the former signer
    /// @param _signer the former signer
    function returnDeposit(address _signer) external {
        NodeRegistryData.SignerInformation memory si = nodeRegistryData.getSignerInformation(_signer);
        require(si.owner == msg.sender, "not the owner of the node");
        require(si.stage == uint(Stages.DepositNotWithdrawn), "wrong stage");
        // solium-disable-next-line security/no-block-members
        require(si.lockedTime <= block.timestamp, "deposit still locked"); // solhint-disable-line not-rely-on-time

        uint depositAmount = si.depositAmount;

        si.lockedTime = 0;
        si.owner = address(0x0);
        si.stage = 0;
        si.depositAmount = 0;
        si.index = 0;

        nodeRegistryData.adminSetSignerInfo(_signer, si);
        nodeRegistryData.adminTransferDeposit(msg.sender, depositAmount);

        emit LogDepositReturned(
            _signer,
            msg.sender,
            depositAmount,
            address(nodeRegistryData.supportedToken())
        );
    }

    /// @notice reveals the wrongly provided blockhash, so that the node-owner will lose its deposit
    /// @param _signer the address that signed the wrong blockhash
    /// @param _blockhash the wrongly provided blockhash
    /// @param _blockNumber number of the wrongly provided blockhash
    /// @param _v v of the signature
    /// @param _r r of the signature
    /// @param _s s of the signature
    /// @dev reverts if a block with that number cannot be found in either the latest 256 blocks or the blockhash registry
    /// @dev reverts when tryin to convict someone with a correct blockhash
    /// @dev reverts when trying to reveal immediately after calling convict
    /// @dev reverts when the _signer did not sign the block
    /// @dev reverts when the wrong convict hash (see convict-function) is used
    function revealConvict(
        address _signer,
        bytes32 _blockhash,
        uint _blockNumber,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(_v == 27 || _v == 28, "wrong signature");

        // solium-disable-next-line security/no-block-members
        bytes32 evmBlockhash = blockhash(_blockNumber);

        if (evmBlockhash == 0x0) {
            evmBlockhash = blockRegistry.blockhashMapping(_blockNumber);
        }

        require(evmBlockhash != 0x0, "block not found");

        // if the blockhash is correct you cannot convict the node
        require(evmBlockhash != _blockhash, "you try to convict with a correct hash");

        bytes32 wrongBlockHashIdent = keccak256(
            abi.encodePacked(
                _blockhash, msg.sender, _v, _r, _s
            )
        );

        uint convictBlockNumber = nodeRegistryData.convictMapping(msg.sender, wrongBlockHashIdent);
        // as we cannot deploy the contract at block 0, a convicting at block 0 is also impossible
        // and as 0 is the standard value this also means that the convict hash is also wrong
        require(convictBlockNumber != 0, "wrong convict hash");

        require(block.number > convictBlockNumber + 2, "revealConvict still locked");
        require(
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        _blockhash,
                        _blockNumber,
                        nodeRegistryData.registryId()
                    )
                ),
                _v, _r, _s) == _signer,
            "the block was not signed by the signer of the node");
        NodeRegistryData.SignerInformation memory si = nodeRegistryData.getSignerInformation(_signer);
        require(si.stage == uint(Stages.Active) || si.stage == uint(Stages.DepositNotWithdrawn), "wrong stage");

        uint deposit = 0;
        if (si.stage == uint(Stages.Active)) {
            NodeRegistryData.In3Node memory in3Node = nodeRegistryData.getNodeInfromationBySigner(_signer);
            deposit = in3Node.deposit;
            nodeRegistryData.adminSetNodeDeposit(_signer, 0);
            nodeRegistryData.adminRemoveNodeFromRegistry(_signer);
            nodeRegistryData.adminSetStage(_signer, uint(Stages.Convicted));
            emit LogNodeRemoved(in3Node.url, _signer);

        } else {
            deposit = si.depositAmount;

            si.stage = uint(Stages.Convicted);
            si.depositAmount = 0;
            nodeRegistryData.adminSetSignerInfo(_signer, si);
        }

        nodeRegistryData.adminTransferDeposit(msg.sender, deposit/2);
        emit LogNodeConvicted(_signer);

    }

    /// @notice changes the ownership of an in3-node
    /// @param _signer the signer-address of the in3-node, used as an identifier
    /// @param _newOwner the new owner
    /// @dev reverts when trying to change ownership of an inactive node
    /// @dev reverts when trying to pass ownership to 0x0
    /// @dev reverts when the sender is not the current owner
    function transferOwnership(address _signer, address _newOwner)
        external
    {
        require(_newOwner != address(0x0), "0x0 not allowed");
        NodeRegistryData.SignerInformation memory si = nodeRegistryData.getSignerInformation(_signer);
        require(si.stage == uint(Stages.Active), "wrong stage");
        require(si.owner == msg.sender, "not the owner");

        NodeRegistryData.In3Node memory in3Node = nodeRegistryData.getIn3NodeInformation(si.index);
        require(in3Node.signer == _signer, "wrong signer");

        nodeRegistryData.transferOwnership(_signer, _newOwner);

        emit LogOwnershipChanged(_signer, msg.sender, _newOwner);
    }

    /// @notice a node owner can unregister a node, removing it from the nodeList
    /// @notice doing so will also lock his deposit for the timeout of the node
    /// @param _signer the signer of the in3-node
    /// @dev reverts when the provided address is not an in3-signer
    /// @dev reverts when not called by the owner of the node
    /// @dev reverts when the node is not active
    function unregisteringNode(address _signer)
        external
    {
        NodeRegistryData.SignerInformation memory si = nodeRegistryData.getSignerInformation(_signer);
        require(si.stage == uint(Stages.Active), "wrong stage");
        require(si.owner == msg.sender, "not the owner");

        NodeRegistryData.In3Node memory in3Node = nodeRegistryData.getIn3NodeInformation(si.index);
        require(in3Node.signer == _signer, "wrong signer");

        nodeRegistryData.unregisteringNode(_signer);

        nodeRegistryData.adminSetStage(_signer, uint(Stages.DepositNotWithdrawn));

        emit LogNodeRemoved(in3Node.url, _signer);

    }

    /// @notice updates a node by changing its props
    /// @dev if there is an additional deposit the owner has to approve the tokenTransfer before
    /// @param _signer the signer-address of the in3-node, used as an identifier
    /// @param _url the url, will be changed if different from the current one
    /// @param _props the new properties, will be changed if different from the current onec
    /// @param _weight the amount of requests per second the node is able to handle
    /// @param _additionalDeposit the additional deposit in erc20-token
    /// @dev reverts when the sender is not the owner of the node
    /// @dev reverts when the signer does not own a node
    /// @dev reverts when trying to change the url to an already existing one
    function updateNode(
        address _signer,
        string calldata _url,
        uint192 _props,
        uint64 _weight,
        uint _additionalDeposit
    )
        external
    {

        NodeRegistryData.SignerInformation memory si = nodeRegistryData.getSignerInformation(_signer);
        require(si.stage == uint(Stages.Active), "wrong stage");
        require(si.owner == msg.sender, "not the owner");

        NodeRegistryData.In3Node memory node = nodeRegistryData.getNodeInfromationBySigner(_signer);
        require(node.signer == _signer, "wrong signer");

        uint deposit = node.deposit;
        _checkNodePropertiesInternal(deposit);

        if (_additionalDeposit > 0) {
            IERC20 supportedToken = nodeRegistryData.supportedToken();
            require(supportedToken.transferFrom(msg.sender, address(nodeRegistryData), _additionalDeposit), "ERC20 token transfer failed");
            deposit += _additionalDeposit;
        }

        nodeRegistryData.updateNode(
            _signer,
            _url,
            _props,
            _weight,
            deposit
        );

        emit LogNodeUpdated(
            node.url,
            _props,
            _signer,
            deposit
        );
    }

    /// @notice returns the supported ERC20 token for registering a node
    /// @return the supported ERC20 token
    function supportedToken() external view returns (IERC20) {
        return nodeRegistryData.supportedToken();
    }

    /// @notice length of the nodelist
    /// @return the number of total in3-nodes
    function totalNodes() external view returns (uint) {
        return nodeRegistryData.totalNodes();
    }

    /// @notice function to check whether the allowed amount of deposit per server has been reached
    /// @param _deposit the new amount of deposit a server has
    /// @dev will fail when the deposit is greater than the maxDepositFirstYear in the 1st year
    /// @dev will fail when the deposit is less than the minDeposit
    function _checkNodePropertiesInternal(uint256 _deposit) internal view {

        require(_deposit >= minDeposit, "not enough deposit");

        // solium-disable-next-line security/no-block-members
        if (block.timestamp < timestampAdminKeyActive) { // solhint-disable-line not-rely-on-time
            require(_deposit < maxDepositFirstYear, "Limit of 50 ETH reached");
        }
    }

    /// @notice helper function for registering a node
    /// @param _url the url of the node
    /// @param _props the properties of the node
    /// @param _signer the signer of the node
    /// @param _owner the owner of the node
    /// @param _deposit the deposit of the node
    /// @param _weight the weight of the node (# of requests per second he is able to handle)
    function _registerNodeInternal (
        string memory _url,
        uint192 _props,
        address _signer,
        address _owner,
        uint _deposit,
        uint64 _weight
    )
        internal
    {
        _checkNodePropertiesInternal(_deposit);

        IERC20 supportedERC20Token = nodeRegistryData.supportedToken();

        require(supportedERC20Token.transferFrom(_owner, address(nodeRegistryData), _deposit), "ERC20 token transfer failed");

        NodeRegistryData.SignerInformation memory si = nodeRegistryData.getSignerInformation(_signer);
        bytes32 urlHash = keccak256(bytes(_url));

        (bool _used,) = nodeRegistryData.urlIndex(urlHash);

        require(!_used, "url already in use");

        require(si.stage == uint(Stages.NotInUse), "signer already in use");

        nodeRegistryData.registerNodeFor(
            _url,
            _props,
            _signer,
            _weight,
            _owner,
            _deposit,
            uint(Stages.Active)
        );

        emit LogNodeRegistered(
            _url,
            _props,
            _signer,
            _deposit
        );

    }

}

