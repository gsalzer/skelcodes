/**

  Source code of Opium Protocol: SwapRate IRS Logic
  Web https://swaprate.finance
  Telegram https://t.me/opium_network
  Twitter https://twitter.com/opium_network

 */

// File: LICENSE

/**

The software and documentation available in this repository (the "Software") is protected by copyright law and accessible pursuant to the license set forth below. Copyright © 2020 Blockeys BV. All rights reserved.

Permission is hereby granted, free of charge, to any person or organization obtaining the Software (the “Licensee”) to privately study, review, and analyze the Software. Licensee shall not use the Software for any other purpose. Licensee shall not modify, transfer, assign, share, or sub-license the Software or any derivative works of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: opium-contracts/contracts/Lib/LibDerivative.sol

pragma solidity ^0.5.4;
pragma experimental ABIEncoderV2;

/// @title Opium.Lib.LibDerivative contract should be inherited by contracts that use Derivative structure and calculate derivativeHash
contract LibDerivative {
    // Opium derivative structure (ticker) definition
    struct Derivative {
        // Margin parameter for syntheticId
        uint256 margin;
        // Maturity of derivative
        uint256 endTime;
        // Additional parameters for syntheticId
        uint256[] params;
        // oracleId of derivative
        address oracleId;
        // Margin token address of derivative
        address token;
        // syntheticId of derivative
        address syntheticId;
    }

    /// @notice Calculates hash of provided Derivative
    /// @param _derivative Derivative Instance of derivative to hash
    /// @return derivativeHash bytes32 Derivative hash
    function getDerivativeHash(Derivative memory _derivative) public pure returns (bytes32 derivativeHash) {
        derivativeHash = keccak256(abi.encodePacked(
            _derivative.margin,
            _derivative.endTime,
            _derivative.params,
            _derivative.oracleId,
            _derivative.token,
            _derivative.syntheticId
        ));
    }
}

// File: opium-contracts/contracts/Interface/IDerivativeLogic.sol

pragma solidity ^0.5.4;


/// @title Opium.Interface.IDerivativeLogic contract is an interface that every syntheticId should implement
contract IDerivativeLogic is LibDerivative {
    /// @notice Validates ticker
    /// @param _derivative Derivative Instance of derivative to validate
    /// @return Returns boolean whether ticker is valid
    function validateInput(Derivative memory _derivative) public view returns (bool);

    /// @notice Calculates margin required for derivative creation
    /// @param _derivative Derivative Instance of derivative
    /// @return buyerMargin uint256 Margin needed from buyer (LONG position)
    /// @return sellerMargin uint256 Margin needed from seller (SHORT position)
    function getMargin(Derivative memory _derivative) public view returns (uint256 buyerMargin, uint256 sellerMargin);

    /// @notice Calculates payout for derivative execution
    /// @param _derivative Derivative Instance of derivative
    /// @param _result uint256 Data retrieved from oracleId on the maturity
    /// @return buyerPayout uint256 Payout in ratio for buyer (LONG position holder)
    /// @return sellerPayout uint256 Payout in ratio for seller (SHORT position holder)
    function getExecutionPayout(Derivative memory _derivative, uint256 _result)	public view returns (uint256 buyerPayout, uint256 sellerPayout);

    /// @notice Returns syntheticId author address for Opium commissions
    /// @return authorAddress address The address of syntheticId address
    function getAuthorAddress() public view returns (address authorAddress);

    /// @notice Returns syntheticId author commission in base of COMMISSION_BASE
    /// @return commission uint256 Author commission
    function getAuthorCommission() public view returns (uint256 commission);

    /// @notice Returns whether thirdparty could execute on derivative's owner's behalf
    /// @param _derivativeOwner address Derivative owner address
    /// @return Returns boolean whether _derivativeOwner allowed third party execution
    function thirdpartyExecutionAllowed(address _derivativeOwner) public view returns (bool);

    /// @notice Returns whether syntheticId implements pool logic
    /// @return Returns whether syntheticId implements pool logic
    function isPool() public view returns (bool);

    /// @notice Sets whether thirds parties are allowed or not to execute derivative's on msg.sender's behalf
    /// @param _allow bool Flag for execution allowance
    function allowThirdpartyExecution(bool _allow) public;

    // Event with syntheticId metadata JSON string (for DIB.ONE derivative explorer)
    event MetadataSet(string metadata);
}

// File: opium-contracts/contracts/Helpers/ExecutableByThirdParty.sol

pragma solidity ^0.5.4;

/// @title Opium.Helpers.ExecutableByThirdParty contract helps to syntheticId development and responsible for getting and setting thirdparty execution settings
contract ExecutableByThirdParty {
    // Mapping holds whether position owner allows thirdparty execution
    mapping (address => bool) thirdpartyExecutionAllowance;

    /// @notice Getter for thirdparty execution allowance
    /// @param derivativeOwner Address of position holder that's going to be executed
    /// @return bool Returns whether thirdparty execution is allowed by derivativeOwner
    function thirdpartyExecutionAllowed(address derivativeOwner) public view returns (bool) {
        return thirdpartyExecutionAllowance[derivativeOwner];
    }

    /// @notice Sets third party execution settings for `msg.sender`
    /// @param allow Indicates whether thirdparty execution should be allowed or not
    function allowThirdpartyExecution(bool allow) public {
        thirdpartyExecutionAllowance[msg.sender] = allow;
    }
}

// File: opium-contracts/contracts/Helpers/HasCommission.sol

pragma solidity ^0.5.4;

/// @title Opium.Helpers.HasCommission contract helps to syntheticId development and responsible for commission and author address
contract HasCommission {
    // Address of syntheticId author
    address public author;
    // Commission is in Opium.Lib.LibCommission.COMMISSION_BASE base
    uint256 public commission = 25; // 0.25% of profit

    /// @notice Sets `msg.sender` as syntheticId author
    constructor() public {
        author = msg.sender;
    }

    /// @notice Getter for syntheticId author address
    /// @return address syntheticId author address
    function getAuthorAddress() public view returns (address) {
        return author;
    }

    /// @notice Getter for syntheticId author commission
    /// @return uint26 syntheticId author commission
    function getAuthorCommission() public view returns (uint256) {
        return commission;
    }
}

// File: contracts/Logic/CompoundSwapRate/CompoundSwapRateLogic.sol

pragma solidity ^0.5.4;

contract ERC20Token {
    uint public decimals;
}

contract CompoundSwapRateLogic is IDerivativeLogic, ExecutableByThirdParty, HasCommission {
    using SafeMath for uint256;

    uint256 constant YEAR_DAYS = 360 days;
    
    constructor() public {
        /*
        {
            "author": "DIB.ONE",
            "type": "swap",
            "subtype": "swaprate",
            "description": "SwapRate Compound logic contract"
        }
        */
        emit MetadataSet("{\"author\":\"DIB.ONE\",\"type\":\"swap\",\"subtype\":\"swaprate\",\"description\":\"SwapRate Compound logic contract\"}");
    }

    // LONG pays floating
    // params[0] - payFixed - SHOULD BE 0
    // params[1] - fixedRate
    // params[2] - 
    // params[3] - 
    // params[4] - 
    // params[5] - 
    // params[6] - 
    // params[7] - 
    // params[8] - 
    // params[9] - 

    // SHORT pays fixed
    // params[10] - payFixed - SHOULD BE 1
    // params[11] - fixedRate
    // params[12] - 
    // params[13] - 
    // params[14] - 
    // params[15] - 
    // params[16] - 
    // params[17] - 
    // params[18] - 
    // params[19] - 

    // Settlement params
    // params[20] - fixedRate - in base of 1e18
    // params[21] - initialParam (could be `borrowIndex` or `exchangeRate`)
    // params[22] - initialTimestamp
    // params[23] - margin
    function validateInput(Derivative memory _derivative) public view returns (bool) {
        return (
            // Derivative
            _derivative.endTime > now &&
            _derivative.params.length == 24 &&

            // LONG
            _derivative.params[0] == 0 && // longPayFixed == 0
            _derivative.params[1] <= _derivative.params[20] && // longPayFixed <= fixedRate

            // SHORT
            _derivative.params[10] == 1 && // shortPayFixed == 1
            _derivative.params[11] >= _derivative.params[20] && // shortFixedRate >= fixedRate

            // IRS
            _derivative.params[20] > 0 && // fixedRate > 0
            _derivative.params[21] > 0 && // initialParam > 0
            _derivative.params[22] <= now && // initialTimestamp <= now
            _derivative.params[23] > 0
        );
    }

    function getMargin(Derivative memory _derivative) public view returns (uint256 buyerMargin, uint256 sellerMargin) {
        uint256 margin = _derivative.params[23];
        buyerMargin = margin;
        sellerMargin = margin;
    }

    function getExecutionPayout(Derivative memory _derivative, uint256 _currentParam) public view returns (uint256 buyerPayout, uint256 sellerPayout) {
        uint256 nominal = 10 ** ERC20Token(_derivative.token).decimals();

        uint256 fixedRate = _derivative.params[20];
        uint256 initialParam = _derivative.params[21];
        uint256 initialTimestamp = _derivative.params[22];
        uint256 margin = _derivative.params[23];

        // timeElapsed = endTime - initialTimestamp
        uint256 timeElapsed = _derivative.endTime.sub(initialTimestamp);

        // fixedAmount = fixedRate * nominal * timeElapsed / YEAR_DAYS / 1e18 + nominal
        uint256 fixedAmount = fixedRate.mul(nominal).mul(timeElapsed).div(YEAR_DAYS).div(10**18).add(nominal);
        
        // accumulatedAmount = nominal * currentParam / initialParam
        uint256 accumulatedAmount = nominal.mul(_currentParam).div(initialParam);
        
        uint256 profit;
        if (fixedAmount > accumulatedAmount) { // Buyer earns
            profit = fixedAmount - accumulatedAmount;

            if (profit > margin) {
                buyerPayout = margin.mul(2);
                sellerPayout = 0;
            } else {
                buyerPayout = margin.add(profit);
                sellerPayout = margin.sub(profit);
            }
        } else { // Seller earns
            profit = accumulatedAmount - fixedAmount;

            if (profit > margin) {
                buyerPayout = 0;
                sellerPayout = margin.mul(2);
            } else {
                buyerPayout = margin.sub(profit);
                sellerPayout = margin.add(profit);
            }
        }
    }

    function isPool() public view returns (bool) {
        return false;
    }

    // Override
    function thirdpartyExecutionAllowed(address derivativeOwner) public view returns (bool) {
        derivativeOwner;
        return true;
    }
}
