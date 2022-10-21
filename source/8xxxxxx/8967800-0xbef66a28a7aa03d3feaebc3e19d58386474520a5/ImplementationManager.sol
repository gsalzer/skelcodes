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
    string constant public version = ""; // must override this

    event Cloned (address indexed clone);

    /// @dev Clones an exchange without any initialization
    /// @return cloneAddress The address of the new exchange.
    function clone()
        external
        nonReentrant
        returns (address cloneAddress)
    {
        address origin = address(this);
        cloneAddress = Cloneable.clone(origin);

        assert(cloneAddress != origin);
        assert(cloneAddress != address(0));

        emit Cloned(cloneAddress);
    }
}

// File: contracts/iface/ILoopring.sol

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




/// @title ILoopring
/// @author Daniel Wang  - <daniel@loopring.org>
contract ILoopring is Claimable, ReentrancyGuard
{
    string  constant public version = ""; // must override this

    uint    public exchangeCreationCostLRC;
    address public universalRegistry;
    address public lrcAddress;

    event ExchangeInitialized(
        uint    indexed exchangeId,
        address indexed exchangeAddress,
        address indexed owner,
        address         operator,
        bool            onchainDataAvailability
    );

    /// @dev Initializes and registers an exchange.
    ///      This function should only be callable by the UniversalRegistry contract.
    ///      Also note that this function can only be called once per exchange instance.
    /// @param  exchangeAddress The address of the exchange to initialize and register.
    /// @param  exchangeId The unique exchange id.
    /// @param  owner The owner of the exchange.
    /// @param  operator The operator of the exchange.
    /// @param  onchainDataAvailability True if "Data Availability" is turned on for this
    ///         exchange. Note that this value can not be changed once the exchange is initialized.
    /// @return exchangeId The id of the exchange.
    function initializeExchange(
        address exchangeAddress,
        uint    exchangeId,
        address owner,
        address payable operator,
        bool    onchainDataAvailability
        )
        external;
}

// File: contracts/iface/IImplementationManager.sol

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




/// @title IImplementationManager
/// @dev This contract manages implementation versions for a specific ILoopring
///      contract. The ILoopring contract can be considered as the "major" version
///      of a Loopring protocol and each IExchange implementation can be considered
///      as a "minor" version. Multiple IExchange contracts can use the same
///      ILoopring contracts.
///
/// @author Daniel Wang  - <daniel@loopring.org>
contract IImplementationManager is Claimable, ReentrancyGuard
{
    /// === Events ===

    event DefaultChanged (
        address indexed oldDefault,
        address indexed newDefault
    );

    event Registered (
        address indexed implementation,
        string          version
    );

    event Enabled (
        address indexed implementation
    );

    event Disabled (
        address indexed implementation
    );

    /// === Data ===

    address   public protocol;
    address   public defaultImpl;
    address[] public implementations;

    // version strings => IExchange addresses
    mapping (string => address) public versionMap;

    /// === Functions ===

    /// @dev Registers a new implementation.
    /// @param implementation The implemenation to add.
    function register(
        address implementation
        )
        external;

    /// @dev Sets the default implemenation.
    /// @param implementation The new default implementation.
    function setDefault(
        address implementation
        )
        external;

    /// @dev Enables an implemenation.
    /// @param implementation The implementation to be enabled.
    function enable(
        address implementation
        )
        external;

    /// @dev Disables an implemenation.
    /// @param implementation The implementation to be disabled.
    function disable(
        address implementation
        )
        external;

    /// @dev Returns version information.
    /// @return protocolVersion The protocol's version.
    /// @return defaultImplVersion The default implementation's version.
    function version()
        public
        view
        returns (
            string  memory protocolVersion,
            string  memory defaultImplVersion
        );

    /// @dev Returns the latest implemenation added.
    /// @param implementation The latest implemenation added.
    function latest()
        public
        view
        returns (address implementation);

    /// @dev Returns if an implementation has been registered.
    /// @param registered True if the implementation is registered.
    function isRegistered(
        address implementation
        )
        public
        view
        returns (bool registered);

    /// @dev Returns if an implementation has been registered and enabled.
    /// @param enabled True if the implementation is registered and enabled.
    function isEnabled(
        address implementation
        )
        public
        view
        returns (bool enabled);
}

// File: contracts/impl/ImplementationManager.sol

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





/// @title An Implementation of IImplementationManager.
/// @author Daniel Wang  - <daniel@loopring.org>
contract ImplementationManager is IImplementationManager
{
    struct Status
    {
        bool registered;
        bool enabled;
    }

    // IExchange addresses => Status
    mapping (address => Status) private statusMap;

    constructor(
        address _owner,
        address _protocol,
        address _implementation
        )
        public
    {
        require(_owner != address(0), "ZERO_ADDRESS");
        require(_protocol != address(0), "ZERO_PROTOCOL");

        owner = _owner;
        protocol = _protocol;
        defaultImpl = _implementation;

        registerInternal(_implementation);
    }

    /// === Functions ===

    function register(
        address implementation
        )
        external
        nonReentrant
        onlyOwner
    {
        registerInternal(implementation);
    }

    function setDefault(
        address implementation
        )
        external
        nonReentrant
        onlyOwner
    {
        require(implementation != defaultImpl, "SAME_IMPLEMENTATION");
        require(isEnabled(implementation), "INVALID_IMPLEMENTATION");

        address oldDefault = defaultImpl;
        defaultImpl = implementation;

        emit DefaultChanged(
            oldDefault,
            implementation
        );
    }

    function enable(
        address implementation
        )
        external
        nonReentrant
        onlyOwner
    {
        Status storage status = statusMap[implementation];
        require(status.registered && !status.enabled, "INVALID_IMPLEMENTATION");

        status.enabled = true;
        emit Enabled(implementation);
    }

    function disable(
        address implementation
        )
        external
        nonReentrant
        onlyOwner
    {
        require(implementation != defaultImpl, "FORBIDDEN");
        require(isEnabled(implementation), "INVALID_IMPLEMENTATION");

        statusMap[implementation].enabled = false;
        emit Disabled(implementation);
    }

    function version()
        public
        view
        returns (
            string  memory protocolVersion,
            string  memory defaultImplVersion
        )
    {
        protocolVersion = ILoopring(protocol).version();
        defaultImplVersion = IExchange(defaultImpl).version();
    }

    function latest()
        public
        view
        returns (address)
    {
        return implementations[implementations.length - 1];
    }

    function isRegistered(
        address implementation
        )
        public
        view
        returns (bool)
    {
        return statusMap[implementation].registered;
    }

    function isEnabled(
        address implementation
        )
        public
        view
        returns (bool)
    {
        return statusMap[implementation].enabled;
    }

    function registerInternal(
        address implementation
        )
        internal
    {
        require(implementation != address(0), "INVALID_IMPLEMENTATION");

        string memory _version = IExchange(implementation).version();
        require(bytes(_version).length >= 3, "INVALID_VERSION");
        require(versionMap[_version] == address(0), "VERSION_USED");
        require(!statusMap[implementation].registered, "ALREADY_REGISTERED");

        implementations.push(implementation);
        statusMap[implementation] = Status(true, true);
        versionMap[_version] = implementation;

        emit Registered(implementation, _version);
    }
}
