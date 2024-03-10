// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title BondDepository
 * @author solace.fi
 * @notice Factory and manager of [`Bond Tellers`](./IBondTeller).
 */
interface IBondDepository {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a teller is added.
    event TellerAdded(address indexed teller);
    /// @notice Emitted when a teller is removed.
    event TellerRemoved(address indexed teller);
    /// @notice Emitted when the params are set.
    event ParamsSet(address solace, address xsolace, address pool, address dao);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Native [**SOLACE**](./SOLACE) Token.
    function solace() external view returns (address solace_);

    /// @notice [**xSOLACE**](./xSOLACE) Token.
    function xsolace() external view returns (address xsolace_);

    /// @notice Underwriting pool contract.
    function underwritingPool() external view returns (address pool_);

    /// @notice The DAO.
    function dao() external view returns (address dao_);

    /// @notice Returns true if the address is a teller.
    function isTeller(address teller) external view returns (bool isTeller_);

    /***************************************
    TELLER MANAGEMENT FUNCTIONS
    ***************************************/

    /**
     * @notice Creates a new [`BondTeller`](./IBondTeller).
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param name The name of the bond token.
     * @param governance The address of the teller's [governor](/docs/protocol/governance).
     * @param impl The address of BondTeller implementation.
     * @param principal address The ERC20 token that users give.
     * @return teller The address of the new teller.
     */
    function createBondTeller(
        string memory name,
        address governance,
        address impl,
        address principal
    ) external returns (address teller);

    /**
     * @notice Creates a new [`BondTeller`](./IBondTeller).
     * @param name The name of the bond token.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param governance The address of the teller's [governor](/docs/protocol/governance).
     * @param impl The address of BondTeller implementation.
     * @param salt The salt for CREATE2.
     * @param principal address The ERC20 token that users give.
     * @return teller The address of the new teller.
     */
    function create2BondTeller(
        string memory name,
        address governance,
        address impl,
        bytes32 salt,
        address principal
    ) external returns (address teller);

    /**
     * @notice Adds a teller.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param teller The teller to add.
     */
    function addTeller(address teller) external;

    /**
     * @notice Adds a teller.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param teller The teller to remove.
     */
    function removeTeller(address teller) external;

    /**
     * @notice Sets the parameters to pass to new tellers.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param solace_ Address of [**SOLACE**](./solace).
     * @param xsolace_ Address of [**xSOLACE**](./xsolace).
     * @param pool_ Address of underwriting pool.
     * @param dao_ Address of the DAO.
     */
    function setAddresses(address solace_, address xsolace_, address pool_, address dao_) external;

    /***************************************
    FUND MANAGEMENT FUNCTIONS
    ***************************************/

    /**
     * @notice Sends **SOLACE** to the teller.
     * Can only be called by tellers.
     * @param amount The amount of **SOLACE** to send.
     */
    function pullSolace(uint256 amount) external;

    /**
     * @notice Sends **SOLACE** to an address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param dst Destination to send **SOLACE**.
     * @param amount The amount of **SOLACE** to send.
     */
    function returnSolace(address dst, uint256 amount) external;
}

