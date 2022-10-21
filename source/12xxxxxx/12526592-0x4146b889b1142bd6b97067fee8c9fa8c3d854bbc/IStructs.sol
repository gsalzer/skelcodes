// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;


interface Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
      Deposit,   // supply tokens
      Withdraw,  // borrow tokens
      Transfer,  // transfer balance between accounts
      Buy,       // buy an amount of some token (externally)
      Sell,      // sell an amount of some token (externally)
      Trade,     // trade tokens against another account
      Liquidate, // liquidate an undercollateralized or expiring account
      Vaporize,  // use excnt is denominated in wei
      Call       // send arbitrary data to an address
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    enum AssetDenomination { Wei, Par }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

