// File: contracts/thirdparty/Proxy.sol

// This code is taken from https://github.com/OpenZeppelin/openzeppelin-labs
// with minor modifications.

pragma solidity ^0.5.11;


/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return address of the implementation to which it will be delegated
  */
  function implementation() public view returns (address);

  /**
  * @dev Fallback function allowing to perform a delegatecall to the given implementation.
  * This function will return whatever the implementation call returns
  */
  function () payable external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

// File: contracts/thirdparty/Cloneable.sol

// This code is taken from https://gist.github.com/holiman/069de8d056a531575d2b786df3345665

pragma solidity ^0.5.11;


library Cloneable {
    function clone(address a)
        external
        returns (address)
    {

    /*
    Assembly of the code that we want to use as init-code in the new contract,
    along with stack values:
                    # bottom [ STACK ] top
     PUSH1 00       # [ 0 ]
     DUP1           # [ 0, 0 ]
     PUSH20
     <address>      # [0,0, address]
     DUP1           # [0,0, address ,address]
     EXTCODESIZE    # [0,0, address, size ]
     DUP1           # [0,0, address, size, size]
     SWAP4          # [ size, 0, address, size, 0]
     DUP1           # [ size, 0, address ,size, 0,0]
     SWAP2          # [ size, 0, address, 0, 0, size]
     SWAP3          # [ size, 0, size, 0, 0, address]
     EXTCODECOPY    # [ size, 0]
     RETURN

    The code above weighs in at 33 bytes, which is _just_ above fitting into a uint.
    So a modified version is used, where the initial PUSH1 00 is replaced by `PC`.
    This is one byte smaller, and also a bit cheaper Wbase instead of Wverylow. It only costs 2 gas.

     PC             # [ 0 ]
     DUP1           # [ 0, 0 ]
     PUSH20
     <address>      # [0,0, address]
     DUP1           # [0,0, address ,address]
     EXTCODESIZE    # [0,0, address, size ]
     DUP1           # [0,0, address, size, size]
     SWAP4          # [ size, 0, address, size, 0]
     DUP1           # [ size, 0, address ,size, 0,0]
     SWAP2          # [ size, 0, address, 0, 0, size]
     SWAP3          # [ size, 0, size, 0, 0, address]
     EXTCODECOPY    # [ size, 0]
     RETURN

    The opcodes are:
    58 80 73 <address> 80 3b 80 93 80 91 92 3c F3
    We get <address> in there by OR:ing the upshifted address into the 0-filled space.
      5880730000000000000000000000000000000000000000803b80938091923cF3
     +000000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx000000000000000000
     -----------------------------------------------------------------
      588073xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00000803b80938091923cF3

    This is simply stored at memory position 0, and create is invoked.
    */
        address retval;
        assembly{
            mstore(0x0, or (0x5880730000000000000000000000000000000000000000803b80938091923cF3 ,mul(a,0x1000000000000000000)))
            retval := create(0,0, 32)
        }
        return retval;
    }
}

// File: contracts/lib/Ownable.sol

/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.11;


/// @title Ownable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
        public
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// File: contracts/lib/Claimable.sol

/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.11;



/// @title Claimable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// File: contracts/lib/ReentrancyGuard.sol

/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.11;


/// @title ReentrancyGuard
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev Exposes a modifier that guards a function against reentrancy
///      Changing the value of the same storage value multiple times in a transaction
///      is cheap (starting from Istanbul) so there is no need to minimize
///      the number of times the value is changed
contract ReentrancyGuard
{
    //The default value must be 0 in order to work behind a proxy.
    uint private _guardValue;

    // Use this modifier on a function to prevent reentrancy
    modifier nonReentrant()
    {
        // Check if the guard value has its original value
        require(_guardValue == 0, "REENTRANCY");

        // Set the value to something else
        _guardValue = 1;

        // Function body
        _;

        // Set the value back
        _guardValue = 0;
    }
}

// File: contracts/iface/IExchange.sol

/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.11;





/// @title IExchange
/// @author Daniel Wang  - <daniel@loopring.org>
contract IExchange is Claimable, ReentrancyGuard
{
    string  public name = "";
    string  constant public version          = ""; // must override this
    bytes32 constant public genesisBlockHash = 0;  // must override this

    /// @dev Clone an exchange without any initialization
    /// @return  cloneAddress The address of the new exchange.
    function clone()
        external
        nonReentrant
        returns (address cloneAddress)
    {
        address origin = address(this);
        cloneAddress = Cloneable.clone(origin);

        assert(cloneAddress != origin);
        assert(cloneAddress != address(0));
    }
}

// File: contracts/iface/IProtocolRegistry.sol

/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.11;




/// @title IProtocalRegistry
/// @author Daniel Wang  - <daniel@loopring.org>
contract IProtocolRegistry is Claimable, ReentrancyGuard
{
    address     public lrcAddress;
    address     public defaultProtocol;
    address[]   public exchanges;

    event ExchangeForged (
        address indexed loopring,
        address indexed exchangeAddress,
        address         owner,
        bool            supportUpgradability,
        bool            onchainDataAvailability,
        uint            exchangeId,
        uint            amountLRCBurned
    );

    event ProtocolRegistered (
        address indexed protocol,
        address indexed implementation
    );

    event ProtocolUpgraded (
        address indexed protocol,
        address indexed newImplementation,
        address         oldImplementation
    );

    event DefaultProtocolChanged(
        address indexed newDefault,
        address         oldDefault
    );

    event ProtocolDisabled(
        address indexed protocol
    );

    event ProtocolEnabled(
        address indexed protocol
    );

    /// @dev Registers a new protocol
    /// @param protocol The protocol address.
    /// @param implementation The protocol's implementaion address.
    /// @return implementation The Protocol's implementation.
    function registerProtocol(
        address protocol,
        address implementation
        )
        external;

    /// @dev Updates a protocol with a new implementation
    /// @param protocol The protocol address.
    /// @param newImplementation The protocol's new implementation.
    /// @return oldImplementation The Protocol's previous implementation.
    function upgradeProtocol(
        address protocol,
        address newImplementation
        )
        external
        returns (address oldImplementation);

    /// @dev Disables a protocol.
    /// @param protocol The protocol to disable.
    function disableProtocol(
        address protocol
        )
        external;

    /// @dev Enables a protocol.
    /// @param protocol The protocol to re-enable.
    function enableProtocol(
        address protocol
        )
        external;

    /// @dev Sets the default protocol.
    /// @param protocol The address of the default protocol version.
    function setDefaultProtocol(
        address protocol
        )
        external;

    /// @dev Returns information regarding the default protocol.
    ///      This function throws if no default protocol is set.
    /// @return loopring The default protocol address.
    /// @return implementation The protocol's implementation.
    /// @return enabled Whether the protocol is enabled.
    function getDefaultProtocol()
        external
        view
        returns (
            address protocol,
            address implementation,
            bool    enabled
        );

    /// @dev Returns information regarding a protocol.
    /// @return protocol The protocol address.
    /// @return implementation The protocol's implementation.
    /// @return enabled Whether the protocol is enabled.
    function getProtocol(
        address protocol
        )
        external
        view
        returns (
            address implementation,
            bool    enabled
        );

    /// @dev Returns the protocol associated with an exchange.
    /// @param exchangeAddress The address of the exchange.
    /// @return protocol The protocol address.
    /// @return implementation The protocol's implementation.
    /// @return enabled Whether the protocol is enabled.
    function getExchangeProtocol(
        address exchangeAddress
        )
        external
        view
        returns (
            address protocol,
            address implementation,
            bool    enabled
        );

    /// @dev Create a new exchange using the default protocol with msg.sender
    ///      as owner and operator.
    /// @param exchangeName The name of the exchange.
    /// @param supportUpgradability True to indicate an ExchangeProxy shall be deploy
    ///        in front of the native exchange contract to support upgradability.
    /// @param onchainDataAvailability If the on-chain DA is on
    /// @return exchangeAddress The new exchange's  address.
    /// @return exchangeId The new exchange's ID.
    function forgeExchange(
        string  calldata exchangeName,
        bool    supportUpgradability,
        bool    onchainDataAvailability
        )
        external
        returns (
            address exchangeAddress,
            uint    exchangeId
        );

    /// @dev Create a new exchange using a specific protocol with msg.sender
    ///      as owner and operator.
    /// @param exchangeName The name of the exchange.
    /// @param protocol The protocol address.
    /// @param supportUpgradability True to indicate an ExchangeProxy shall be deploy
    ///        in front of the native exchange contract to support upgradability.
    /// @param onchainDataAvailability IF the on-chain DA is on
    /// @return exchangeAddress The new exchange's address.
    /// @return exchangeId The new exchange's ID.
    function forgeExchange(
        string  calldata exchangeName,
        address protocol,
        bool    supportUpgradability,
        bool    onchainDataAvailability
        )
        external
        returns (
            address exchangeAddress,
            uint    exchangeId
        );
}

// File: contracts/impl/ExchangeProxy.sol

/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.11;





/// @title ExchangeProxy
/// @dev This proxy is designed to support transparent upgradeability offered by a
///      IProtocolRegistry contract.
/// @author Daniel Wang  - <daniel@loopring.org>
contract ExchangeProxy is Proxy
{
    bytes32 private constant registryPosition = keccak256(
        "org.loopring.protocol.v3.registry"
    );

    constructor(address _registry)
        public
    {
        bytes32 position = registryPosition;
        assembly {
          sstore(position, _registry)
        }
    }

    function registry()
        public
        view
        returns (address _addr)
    {
        bytes32 position = registryPosition;
        assembly {
          _addr := sload(position)
        }
    }

    function protocol()
        public
        view
        returns (address _protocol)
    {
        IProtocolRegistry r = IProtocolRegistry(registry());
        (_protocol, , ) = r.getExchangeProtocol(address(this));
    }

    function implementation()
        public
        view
        returns (address impl)
    {
        IProtocolRegistry r = IProtocolRegistry(registry());
        (, impl, ) = r.getExchangeProtocol(address(this));
    }
}
