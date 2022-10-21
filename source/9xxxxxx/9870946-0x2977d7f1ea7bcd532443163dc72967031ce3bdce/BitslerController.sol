pragma solidity ^0.6.0;

abstract contract AbstractSweeper {
    function sweep(address token, uint amount) virtual external returns (bool);

    fallback() external {}

    BitslerController controller;

    constructor(address _controller) internal{
        controller = BitslerController(_controller);
    }

    modifier canSweep() {
        require((controller.isAuthorizedCaller(msg.sender) && msg.sender == controller.owner()) || msg.sender == controller.dev(), "unauthorized");
        require(!controller.halted(), "halted");
        _;
    }
}

contract Token {
    function balanceOf(address a) external pure returns (uint) {
        (a);
        return 0;
    }

    function transfer(address a, uint val) external pure returns (bool) {
        (a);
        (val);
        return false;
    }
}

contract DefaultSweeper is AbstractSweeper {
    constructor(address controller) public
             AbstractSweeper(controller) {}

    function sweep(address _token, uint _amount)
    override
    external
    canSweep
    returns (bool) {
        bool success = false;
        address payable destination = controller.destination();

        if (_token != address(0)) {
            Token token = Token(_token);
            uint amount = _amount;
            if (amount > token.balanceOf(address(this))) {
                return false;
            }
            token.transfer(destination, amount);
            success = true;
        }
        else {
            uint amountInWei = _amount;
            if (amountInWei > address(this).balance) {
                return false;
            }

            success = destination.send(amountInWei);
        }

        if (success) {
            controller.logSweep(address(this), destination, _token, _amount);
        }
        return success;
    }
}

contract UserWallet {
    AbstractSweeperList sweeperList;
    constructor(address _sweeperlist) public {
        sweeperList = AbstractSweeperList(_sweeperlist);
    }

    receive() external payable {}

    function tokenFallback(address _from, uint _value, bytes memory _data) public pure {
        (_from);
        (_value);
        (_data);
     }

    function sweep(address _token, uint _amount) external returns (bool) {
        (_amount);
        (bool success,) = sweeperList.sweeperOf(_token).delegatecall(msg.data);
        return success;
    }
}

abstract contract AbstractSweeperList {
    function sweeperOf(address _token) virtual external returns (address);
}

contract BitslerController is AbstractSweeperList {
    address public owner;
    address public dev;
    mapping (address => bool) authorizedCaller;
    address[] private authorizedCallerLists;
    address payable public destination;
    bool public halted;

    event LogNewWallet(address receiver);
    event LogSweep(address indexed from, address indexed to, address indexed token, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "unauthorized"); 
        _;
    }

    modifier onlyAuthorizedCaller() {
        require(msg.sender == dev || authorizedCaller[msg.sender] == true, "unauthorized"); 
        _;
    }

    modifier onlyAdmins() {
        require(msg.sender == dev || (authorizedCaller[msg.sender] == true && msg.sender == owner),"unauthorized"); 
        _;
    }

    constructor(address _dev) public
    {
        owner = msg.sender;
        destination = msg.sender;
        authorizedCaller[msg.sender] = true;
        authorizedCallerLists.push(msg.sender);
        dev = _dev;
    }

    function addAuthorizedCaller(address _newCaller) external onlyOwner {
        require(!authorizedCaller[_newCaller], "already added");
        authorizedCaller[_newCaller] == true;
        authorizedCallerLists.push(_newCaller);
    }

    function changeDestination(address payable _dest) external onlyOwner {
        destination = _dest;
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function makeWallet() external onlyAdmins returns (address wallet)  {
        wallet = address(new UserWallet(address(this)));
        emit LogNewWallet(wallet);
    }
    
    function isAuthorizedCaller(address _caller) external view returns(bool) {
        return authorizedCaller[_caller] || dev == _caller;
    }

    function _authorizedCallers() public view returns (address[] memory){
        return authorizedCallerLists;
    }
    
    function halt() external onlyAdmins {
        halted = true;
    }

    function start() external onlyOwner {
        halted = false;
    }

    address public defaultSweeper = address(new DefaultSweeper(address(this)));
    mapping (address => address) sweepers;

    function addSweeper(address _token, address _sweeper) external onlyOwner {
        sweepers[_token] = _sweeper;
    }

    function sweeperOf(address _token) override external returns (address) {
        address sweeper = sweepers[_token];
        if (sweeper == address(0)) sweeper = defaultSweeper;
        return sweeper;
    }

    function logSweep(address from, address to, address token, uint amount) external {
        emit LogSweep(from, to, token, amount);
    }
}
