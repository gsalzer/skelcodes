pragma solidity ^0.5.0;

// File: openzeppelin-solidity\contracts\math\Math.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts\HORSEMigrator.sol

contract IERC20Mintable is IERC20 {
    function mint(address account, uint256 amount) external returns (bool);
    function isMinter(address account) external view returns (bool);
    function renounceMinter() external;
}

contract IERC20Burnable is IERC20 {
    function burn(uint256 _value) external;
}

/// heavily inspired by ERC20Migrator in openzeppelin-solidity/contracts/drafts
contract HORSEMigrator {
    /// Address of the old token contract
    IERC20Burnable public legacyToken = IERC20Burnable(0x5B0751713b2527d7f002c0c4e2a37e1219610A6B);

    /// Address of the TRIBE token contract
    IERC20Mintable public TRIBEToken;

    /// Address of the DECENT token contract
    IERC20Mintable public DECENTToken;

    uint256 horseToTribeRatio = 0.1 ether; // you'll get 1 tribe for 10 horse
    uint256 horseToDecentRatio = 0.000001 ether; //you'll get 1 DECENT for 1M HORSE

    uint256 public migrationTime = 5 weeks;
    uint256 public migrationEnds;

    /**
     * @dev Begins the migration by setting both tokens to be
     * minted. This contract must be a minter for the new tokens.
     * @param tribeContract the tribe token to be minted
     * @param decentContract the decent token to be minted
     */
    function beginMigration(IERC20Mintable tribeContract, IERC20Mintable decentContract) public {
        require(migrationEnds == 0, "migration already started");
        require((address(tribeContract) != address(0)) && (address(decentContract) != address(0)), "new token is the zero address");

        require(tribeContract.isMinter(address(this)), "not a minter for tribe");
        require(decentContract.isMinter(address(this)), "not a minter for decent");

        migrationEnds = now + migrationTime;

        TRIBEToken = tribeContract;
        DECENTToken = decentContract;
    }

    /**
     * @dev Transfers part of an account's balance in the old token to this
     * contract, and mints the corrent amount of new tokens for that account.
     * @param account whose tokens will be migrated
     * @param amount amount of tokens to be migrated
     */
    function migrate(address account, uint256 amount) notEnded() public {
        require(address(TRIBEToken) != address(0), "migration not started");
        legacyToken.transferFrom(account, address(this), amount);
        legacyToken.burn(amount);
        TRIBEToken.mint(account, amount * horseToTribeRatio / 1 ether);
        DECENTToken.mint(account, amount * horseToDecentRatio / 1 ether);
    }

    /**
     * @dev Transfers all of an account's allowed balance in the old token to
     * this contract, and mints the same amount of new tokens for that account.
     * @param account whose tokens will be migrated
     */
    function migrateAll(address account) public {
        uint256 balance = legacyToken.balanceOf(account);
        uint256 allowance = legacyToken.allowance(account, address(this));
        uint256 amount = Math.min(balance, allowance);
        migrate(account, amount);
    }

    modifier notEnded() {
        require(now < migrationEnds, "Swapping ended");
        _;
    }
}
