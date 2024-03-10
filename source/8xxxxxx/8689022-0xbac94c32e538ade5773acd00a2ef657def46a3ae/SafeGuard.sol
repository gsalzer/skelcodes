pragma solidity 0.5.8;

import "./Ownable.sol";


/**
 * @title Safe Guard Contract
 * @author Panos
 */
contract SafeGuard is Ownable {

    event Transaction(address indexed destination, uint value, bytes data);

    /**
     * @dev Allows owner to execute a transaction.
     */
    function executeTransaction(address destination, uint value, bytes memory data)
    public
    onlyOwner
    {
        require(externalCall(destination, value, data.length, data));
        emit Transaction(destination, value, data);
    }

    /**
     * @dev call has been separated into its own function in order to take advantage
     *  of the Solidity's code generator to produce a loop that copies tx.data into memory.
     */
    function externalCall(address destination, uint value, uint dataLength, bytes memory data)
    private
    returns (bool) {
        bool result;
        assembly { // solhint-disable-line no-inline-assembly
        let x := mload(0x40)   // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
            sub(gas, 34710), // 34710 is the value that solidity is currently emitting
            // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
            // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
            destination,
            value,
            d,
            dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
            x,
            0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}


