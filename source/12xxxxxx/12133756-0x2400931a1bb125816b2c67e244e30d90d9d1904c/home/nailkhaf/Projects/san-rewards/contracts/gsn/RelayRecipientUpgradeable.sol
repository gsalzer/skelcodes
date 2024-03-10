// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

abstract contract RelayRecipientUpgradeable is
    Initializable,
    ERC2771ContextUpgradeable
{
    function __RelayRecipientUpgradeable_init() internal initializer {
        __RelayRecipientUpgradeable_init_unchained();
    }

    function __RelayRecipientUpgradeable_init_unchained()
        internal
        initializer
    {}

    event TrustedForwarderChanged(address previous, address current);

    function _setTrustedForwarder(address trustedForwarder_) internal {
        address previousForwarder = _trustedForwarder;
        _trustedForwarder = trustedForwarder_;
        emit TrustedForwarderChanged(previousForwarder, trustedForwarder_);
    }
}

