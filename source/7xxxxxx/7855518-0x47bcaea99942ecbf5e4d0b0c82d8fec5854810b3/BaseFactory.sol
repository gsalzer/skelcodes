pragma solidity >=0.5.3 < 0.6.0;

contract BaseFactory {
    address internal admin_;
    mapping(address => bool) internal rootFactories_;

    constructor(address _rootFactory) public {
        rootFactories_[_rootFactory] = true;
        admin_ = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin_, "Not authorised");
        _;
    }

    modifier onlyRootFactory() {
        require(rootFactories_[msg.sender], "Not authorised");
        _;
    }

    function addRootFactory(address _newRoot) external onlyAdmin() {
        rootFactories_[_newRoot] = true;
    }

    function removeRootFactory(address _newRoot) external onlyAdmin() {
        rootFactories_[_newRoot] = false;
    }
}
