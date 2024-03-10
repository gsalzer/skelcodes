pragma solidity ^0.5.3;

import './Utils.sol';

interface IUpgradeProxy {
    event OwnershipTransferred(address indexed from, address indexed to);
    event ProxyPaused();
    event ProxyUnpaused();
    event ProxyStartUpgrade(address indexed oldAddress, address indexed newAddress,
                            uint256 fromVersion, uint256 toVersion);
    event ProxyFinishUpgrade(address indexed oldAddress, address indexed newAddress,
                             uint256 fromVersion, uint256 toVersion);
    event ProxyCallMigration(address indexed oldAddress, address indexed newAddress,
                             uint256 fromVersion, uint256 toVersion);
    event ProxyForceVersionBump(address indexed oldAddress, address indexed newAddress,
                                uint256 fromVersion, uint256 toVersion);
    event ProxyCancelUpgrade(address indexed oldAddress, address indexed newAddress,
                             uint256 fromVersion, uint256 toVersion);

    function proxyTransferOwnership(address _newOwner) external;
    function proxyAcceptOwnership() external;
    function proxyPause() external;
    function proxyUnpause() external;
    function proxyStartUpgrade(address newLogicContract, uint256 newVersion) external;
    function proxyFinishUpgrade() external;
    function proxyCallMigration(bytes calldata data) external;

    // Undo proxyStartUpgrade without actually upgrading. Restores the old logic
    // contract. This is only safe to execute before doing a successful call to
    // proxyCallMigration, after which it is UNSAFE. This is meant as a recovery
    // mechanism in case a migration fails.
    function proxyCancelUpgrade() external;

    // Without this function it is possible to reach an unrecoverable state:
    // Call proxyStartUpgrade with a smart contract that does not have a
    // migration function that bumps it to the given version.
    //
    // This can be recovered by calling this function before calling
    // proxyFinishUpgrade, and then initiating a new upgrade before unpause.
    //
    // This is an emergency recovery mechanism that should never be used under
    // normal circumstances.
    function proxyForceVersionBump() external;

    function version() external view returns (uint256);
    function logicContract() external view returns (address);
    function upgradingFromVersion() external view returns (uint256);
    function upgradingToVersion() external view returns (uint256);
}

// Inherited by both proxy and logic contract, to avoid storage location overlaps
// and function signature hash collisions
//
// Rules for logic contracts:
//
// * Does not depend on constructor behaviour. Instead it should have a migrate_0_to_1
//   migration function that takes the arguments that the constructor would normally
//   have. In fact we have to ensure that there is no constructor in the entire
//   inheritance chain, because none of them will be actually called for the
//   proxy contract. This is automatically ensured by the compiler for
//   non-trivial constructors in case the logic contract has no constructor itself,
//   but this does not hold for trivial constructors (i.e. those with zero
//   parameters), so we still have to be careful.
//
// * No private functions, so that we can extend by inheritance
//
// * There must be no publicly accessible self-destruct functionality, or
//   if there is, it MUST carry the "onlyViaProxy" modifier
//
// * Logic contracts MUST NOT write to any of the variables defined in
//   SharedBetweenProxyAndLogic since these are managed by the proxy contract,
//   with the exception of the "version" variable, which must only be written
//   within migrations.
//   Ideally the variables should not be inspected either, unless from within the
//   "onlyViaProxy" and "migration" wrappers. The only exception is the "owner"
//   variable, which can be re-used by the logic contract so as to avoid adding
//   a second variable with essentially the same meaning.
//
// TODO investigate if we want a way to execute stateful things as the owner
// while the contract is paused. Probably it is not needed because we can call
// proxyUnpause() -> stateful action -> proxyPause() in a transaction? We should
// test this though
contract SharedBetweenProxyAndLogic is IUpgradeProxy {
    enum ProxyState {Normal, Paused, Upgrading, CallingMigrationFunction}

    // All of these state variables are managed by the proxy and MUST NOT
    // be written by
    address public owner;
    address public newOwner;
    ProxyState public proxyState;
    // Technically, this is redundant since for example
    // isProxy == logicContract != 0 || proxyState != 0.
    // Better be a bit more explicit though.
    bool isProxy;

    uint256 public upgradingFromVersion;
    uint256 public upgradingToVersion;
    address public logicContract;
    uint256 public version;

    address internal oldLogicContract;

    modifier onlyOwner {
        require(msg.sender == owner, "Sender must be owner");
        _;
    }
}

contract ContractLogic is SharedBetweenProxyAndLogic {
    // IUpgradeProxy fake implementation to make Solidity happy. It would be better
    // to just have these calls fall through, but this is not currently possible?
    function proxyTransferOwnership(address) external { revert(); }
    function proxyAcceptOwnership() external { revert(); }
    function proxyPause() external { revert(); }
    function proxyUnpause() external { revert(); }
    function proxyStartUpgrade(address, uint256) external { revert(); }
    function proxyCancelUpgrade() external { revert(); }
    function proxyFinishUpgrade() external { revert(); }
    function proxyCallMigration(bytes calldata) external { revert(); }
    function proxyForceVersionBump() external { revert(); }

    // General recommendation is to not accept funds if not required
    // (can still be forced via self-destruction)
    function () external payable { revert(); }

    // TODO currently unused and untested
    modifier onlyViaProxy() {
        // Must be called on the proxy, not the deployed logic contract
        require(isProxy);
        _;
    }

    modifier migration(uint256 fromVersion, uint256 toVersion) {
        // This is just a sanity check, the fact that we are in CallingMigrationFunction
        // state means that this function call was performed via proxyCallMigration
        assert(msg.sender == owner);

        assert(toVersion - fromVersion == 1);

        // Must be called on the proxy in the correct state, not the deployed
        // logic contract
        require(isProxy);
        require(proxyState == ProxyState.CallingMigrationFunction);

        // Make sure the migration version range is consistent with the
        // actual upgrade version range
        require(fromVersion >= upgradingFromVersion && toVersion <= upgradingToVersion);
        require(version == fromVersion);
        uint256 oldVersion = version;
        _;
        // Migration functions should be monotone in the version, and hold their
        // promise regarding the migrated version range
        assert(version >= oldVersion);
        assert(version <= toVersion);
        // This can be used by the caller to verify that a function with this
        // modifier was used
        proxyState = ProxyState.Upgrading;
    }
}

contract UpgradeProxy is SharedBetweenProxyAndLogic {
    constructor(address _owner) public {
        owner = _owner;
        newOwner = address(0);
        proxyState = ProxyState.Paused;
        logicContract = address(0);
        oldLogicContract = address(0);
        isProxy = true;
        version = 0;
        emit ProxyPaused();
    }

    function proxyTransferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function proxyAcceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function proxyPause() external onlyOwner {
        emit ProxyPaused();
        require(proxyState == ProxyState.Normal);
        proxyState = ProxyState.Paused;
    }

    function proxyUnpause() external onlyOwner {
        emit ProxyUnpaused();
        // Make sure the first unpause only happens after a logic contract was set
        require(Utils.isContract(logicContract));
        require(proxyState == ProxyState.Paused);
        proxyState = ProxyState.Normal;
    }

    function proxyStartUpgrade(address newLogicContract, uint256 newVersion)
        external onlyOwner
    {
        require(proxyState == ProxyState.Paused);
        require(version < newVersion);
        require(Utils.isContract(newLogicContract));

        upgradingFromVersion = version;
        upgradingToVersion = newVersion;
        oldLogicContract = logicContract;
        logicContract = newLogicContract;

        emit ProxyStartUpgrade(oldLogicContract, newLogicContract,
                               upgradingFromVersion, upgradingToVersion);
        proxyState = ProxyState.Upgrading;
    }

    function proxyCallMigration(bytes calldata data)
        external onlyOwner
    {
        require(proxyState == ProxyState.Upgrading);
        require(Utils.isContract(logicContract));

        emit ProxyCallMigration(oldLogicContract, logicContract,
                                upgradingFromVersion, upgradingToVersion);

        proxyState = ProxyState.CallingMigrationFunction;
        (bool result,) = logicContract.delegatecall(data);
        require(result);

        require(proxyState == ProxyState.Upgrading);
    }

    function proxyForceVersionBump()
        external onlyOwner
    {
        require(proxyState == ProxyState.Upgrading);
        emit ProxyForceVersionBump(oldLogicContract, logicContract,
                                   upgradingFromVersion, upgradingToVersion);
        version = upgradingToVersion;
    }

    function proxyFinishUpgrade()
        external onlyOwner
    {
        require(proxyState == ProxyState.Upgrading);
        require(version == upgradingToVersion);

        emit ProxyFinishUpgrade(oldLogicContract, logicContract,
                                upgradingFromVersion, upgradingToVersion);
        proxyState = ProxyState.Paused;

        // Clean up storage
        upgradingFromVersion = 0;
        upgradingToVersion = 0;
        oldLogicContract = address(0);
    }

    function proxyCancelUpgrade()
        external onlyOwner
    {
        require(proxyState == ProxyState.Upgrading);

        emit ProxyCancelUpgrade(oldLogicContract, logicContract,
                                upgradingFromVersion, upgradingToVersion);
        logicContract = oldLogicContract;

        // It would be safer to require(version == upgradingFromVersion), but
        // we give us a little bit of freedom here in case we really mess up badly.
        version = upgradingFromVersion;
        proxyState = ProxyState.Paused;

        // Clean up storage
        upgradingFromVersion = 0;
        upgradingToVersion = 0;
        oldLogicContract = address(0);
    }

    // from
    // https://github.com/zeppelinos/labs/blob/master/upgradeability_using_eternal_storage/contracts/Proxy.sol
    function () payable external {
        require(proxyState == ProxyState.Normal);

        // TODO check that the receiver has code
        // https://blog.trailofbits.com/2018/09/05/contract-upgrade-anti-patterns/
        // For now we don't do this for performance reasons
        //require(Utils.isContract(logicContract));
        address impl = logicContract;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

