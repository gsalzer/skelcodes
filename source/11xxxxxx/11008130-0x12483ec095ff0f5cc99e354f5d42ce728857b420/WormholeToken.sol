pragma solidity ^0.6.0;

import './ERC20.sol';
import './SafeMath.sol';

contract WormholeToken is ERC20 {
    using SafeMath for uint;
    address public wormholeMechanic;
    uint public totalWormholes;

    constructor(
        string memory name,
        string memory symbol,
        uint _totalWormholes
    ) public ERC20(name, symbol) {
        wormholeMechanic = msg.sender;
        totalWormholes = _totalWormholes;
        _mint(wormholeMechanic, _totalWormholes * 10**uint(super.decimals()));
    }

    function updateWormholeMechanic(address _replacementWormholeMechanic) external {
        require(msg.sender == wormholeMechanic, 'only the wormhole machanic may maintain');
        wormholeMechanic = _replacementWormholeMechanic;
    }

    function mint(uint256 amount) external {
        require(msg.sender == wormholeMechanic, 'only the wormhole machanic may maintain');
        uint totalSupply = totalSupply();
        require(
            totalSupply.add(amount) <= totalWormholes,
            'max wormholes reached'
        );
        _mint(wormholeMechanic, amount * 10**uint(super.decimals()));
    }
}
