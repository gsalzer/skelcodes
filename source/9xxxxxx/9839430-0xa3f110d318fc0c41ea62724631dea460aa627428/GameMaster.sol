pragma solidity ^0.5.16;


contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

interface ERC20 {
    function mint(address recipient, uint256 amount) external returns (bool);
}

contract GameMaster is MinterRole {
  address payable _gm;
  address payable _owner;
  uint256 _last_price;
  uint256 _price;
  uint256 _base_price;
  uint256 _earned;

  ERC20 Myth;

  event GameMasterReward(address indexed sender, uint game, uint256 amount);

  constructor() public {
    Myth = ERC20(0x79Ef5b79dC1E6B99fA9d896779E94aE659B494F2);

    _base_price = 0.1 ether;
    _gm = msg.sender;
    _owner = msg.sender;
    _last_price = 0;
    _price = _base_price;
  }

  function getGameMaster() public view returns (address game_master, uint price, uint256 earned) {
    return (_gm, _price, _earned);
  }

  function getGameMasterAddress() public view returns (address) {
    return _gm;
  }

  function mint(uint256 amount, uint8 game) public onlyMinter returns (bool success){
    Myth.mint(_gm, amount);
    _earned += amount;
    emit GameMasterReward(_gm, game, amount);
    return true;
  }

  function resetContract() public onlyMinter returns (bool success){
    _gm.transfer(address(this).balance-_base_price);
    _price = _base_price;
    _gm = _owner;
    return true;
  }

  function updateSettings(address _token) public returns (bool success) {
    require(msg.sender == _owner, "You cant do that.");
    Myth = ERC20(_token);
    return true;
  }

  function buyGameMaster() public payable returns (bool success){
    require(msg.value >= _price, "Not enough ETH");
    _gm.transfer(_last_price);
    _owner.transfer(_price - _last_price);
    _gm = msg.sender;
    _last_price = _price;
    _price = ((_price / 100 * 110) / 1000000000000000) * 1000000000000000;
    _earned = 0;
    return true;
  }
}
