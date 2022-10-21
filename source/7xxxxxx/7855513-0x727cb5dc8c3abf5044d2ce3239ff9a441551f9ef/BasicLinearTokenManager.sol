pragma solidity >=0.5.3 < 0.6.0;

import { BaseTokenManager } from "./BaseTokenManager.sol";
import { IERC20 } from "./IERC20.sol";

/// @author Ben, Veronica & Ryan of Linum Labs
/// @author Ryan N.                 RyRy79261
/// @title Basic Linear Token Manager
contract BasicLinearTokenManager is BaseTokenManager {
    constructor(
        string memory _name,
        string memory _symbol,
        address _reserveToken,
        address _proteaAccount,
        address _publisher,
        uint256 _contributionRate,
        address _membershipManager
    ) 
        public
        BaseTokenManager(_name, _symbol, _reserveToken, _proteaAccount, _publisher, _contributionRate, _membershipManager)
    {
    }

    // [Bonding curve functions]

    /// @dev                Selling tokens back to the bonding curve for collateral
    /// @param _numTokens   The number of tokens that you want to burn
    function burn(uint256 _numTokens) external returns(bool) {
        require(balances[msg.sender] >= _numTokens, "Not enough tokens available");

        uint256 rewardForTokens = rewardForBurn(_numTokens);
        totalSupply_ = totalSupply_.sub(_numTokens);
        balances[msg.sender] = balances[msg.sender].sub(_numTokens);
        poolBalance_ = poolBalance_.sub(rewardForTokens);
        require(
            IERC20(reserveToken_).transfer(msg.sender, rewardForTokens), 
            "Require transferFrom to succeed"
        );

        emit Transfer(msg.sender, address(0), _numTokens);

        return true;
    }

    /// @dev                Mint new tokens with ether
    /// @param _to          :address Address to mint tokens to
    /// @param _numTokens   :uint256 The number of tokens you want to mint
    /// @dev                We have modified the minting function to divert a portion of the purchase tokens
    // Rough gas usage 153,440 
    function mint(address _to, uint256 _numTokens) external returns(bool) {
        uint256 priceForTokens = priceToMint(_numTokens);
        require(
            IERC20(reserveToken_).transferFrom(msg.sender, address(this), priceForTokens), 
            "Require transferFrom to succeed"
        );
        require(
            IERC20(reserveToken_).transfer(proteaAccount_, priceForTokens.div(101)), // This takes the 1 percent out of the total price
            "Protea contribution must succeed"
        );

        uint256 comContribution = _numTokens.div(100).mul(contributionRate_);
        totalSupply_ = totalSupply_.add(_numTokens);
        poolBalance_ = poolBalance_.add(priceForTokens.sub(priceForTokens.div(101))); // Minus amount sent to Protea
        balances[msg.sender] = balances[msg.sender].add(_numTokens.sub(comContribution)); // Minus amount sent to Revenue target

        balances[revenueTarget_] = balances[revenueTarget_].add(comContribution); // Minus amount sent to Revenue target

        emit Transfer(address(0), _to, _numTokens);
        return true;
    }

    // [ERC20 functions]

   

    /// @dev                        Transfer ownership token from msg.sender to a specified address
    /// @param _to                  : address The address to transfer to.
    /// @param _value               : uint256 The amount to be transferred.
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Insufficient funds");
        require(_to != address(0), "Target account invalid");

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev                Transfer tokens from one address to another
    /// @param _from        :address The address which you want to send tokens from
    /// @param _to          :address The address which you want to transfer to
    /// @param _value       :uint256 the amount of tokens to be transferred
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from], "Requested amount exceeds balance");
        
        // This is to allow the membership manager elevated access for managing tokens
        if(msg.sender != membershipManager_){
            require(_value <= allowed[_from][msg.sender], "Allowance exceeded");
            require(_to != address(0), "Target account invalid");
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        if(msg.sender != membershipManager_){
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        }
        
        emit Transfer(_from, _to, _value);
        return true;
    } 


    /// @dev                Returns the gradient for the communities curve
    /// @return             :uint256 The gradient for the communities curve
    function gradientDenominator() external view returns(uint256) {
        return gradientDenominator_;
    }

    // [Pricing functions]
    
    /// @dev                Returns the required collateral amount for a volume of bonding curve tokens
    /// @return             :uint256 Required collateral corrected for decimals
    function priceToMint(uint256 _numTokens) public view returns(uint256) {
        // return curveIntegral(totalSupply_.add(_numTokens)).sub(poolBalance_);
        uint256 rawDai = curveIntegral(totalSupply_.add(_numTokens)).sub(poolBalance_);
        return rawDai.add(rawDai.div(100)); // Adding 1 percent 
    }

    /// @dev                Returns the required collateral amount for a volume of bonding curve tokens
    /// @return             Potential return collateral corrected for decimals
    function rewardForBurn(uint256 _numTokens) public view returns(uint256) {
        return poolBalance_.sub(curveIntegral(totalSupply_.sub(_numTokens)));
    }

    // [Inverse pricing functions]
    /// @dev                This function returns the amount of tokens one can receive for a specified amount of collateral token
    ///                     Including Protea & Community contributions
    /// @param  _colateralTokenOffered  :uint256 Amount of reserve token offered for purchase
    function colateralToTokenBuying(uint256 _colateralTokenOffered) external view returns(uint256) {
        uint256 correctedForContribution = _colateralTokenOffered.sub(_colateralTokenOffered.div(101)); // Removing 1 percent
        return inverseCurveIntegral(curveIntegral(totalSupply_).add(correctedForContribution)).sub(totalSupply_);
    }

    /// @dev                 This function returns the amount of tokens needed to be burnt to withdraw a specified amount of reserve token
    ///                                 Including Protea & Community contributions
    /// @param  _collateralTokenNeeded  :uint256 Amount of dai to be withdraw
    function colateralToTokenSelling(uint256 _collateralTokenNeeded) external view returns(uint256) {
        return uint256(
            totalSupply_.sub(
                inverseCurveIntegral(curveIntegral(totalSupply_).sub(_collateralTokenNeeded))
            )
        );
    }

    /// @dev                Calculate the integral from 0 to x tokens supply
    /// @param _x            The number of tokens supply to integrate to
    /// @return             The total supply in tokens, not wei
    function curveIntegral(uint256 _x) internal view returns (uint256) {
        /** This is the formula for the curve
            f(x) = gradient*(x + b) + c
            f(x) indicates it is a function of x, where x is the token supply
            the gradient is the gradient of the curve i.e. the change in price over the change in token supply
            c is the y-offset, which is set to 0 for now.
            For more information visit:
            https://en.wikipedia.org/wiki/Linear_function
        */

        uint256 c = 0;

        /* The gradient of a curve is the rate at which it increases its slope.
	    	For example, to increase at a value of 5 DAI for every 1 token,
	    	our gradient would be (change in y)/(change in x) = 5/1 = 5 DAI/Token
	    	Remember that contracts deal with uint256 integers with 18 decimal points, not floating points, so:
	    	to represent our gradient of 0.0005 DAI/Token, we simply divide by the denominator, to avoid floating points,
	    	so we end up with 1/0.0005 = 2000 as our denominator.
	    */

        /* We need to calculate the definite integral from zero to the defined token supply, x.
	    	A definite integral is essentially the area under the curve, from zero to the defined token supply.
	    	The area under the curve is equivalent to the value of the tokens up until that point.
	    	The integral of the linear curve, f(x), is calculated as:
	    	gradient*0.5*x^2 + cx; where c = 0
	    	Because we are essentially squaring the decimal scaling in the calculation,
	    	we need to divide the result by the scaling factor before returning - this hurt my mind a bit, but mathematically holds true.
	    */
        return ((_x**2).div(2*gradientDenominator_).add(c.mul(_x)).div(10**decimals_));
    }
    
    /// @dev                Inverse integral to convert the incoming colateral value to token volume
    /// @param _x           :uint256 The volume to identify the root off
    function inverseCurveIntegral(uint256 _x) internal view returns(uint256){
        return sqrt(2*_x*gradientDenominator_*(10**decimals_));
    }

    /// @dev                Babylonian square rooting using while loops
    /// @param _x           :uint256 The number to identify the root off
    function sqrt(uint256 _x) internal pure returns (uint256) {
        if (_x == 0) return 0;
        else if (_x <= 3) return 1;
        uint256 z = (_x + 1) / 2;
        uint256 y = _x;
        while (z < y)
        /// @why3 invariant { to_int !_z = div ((div (to_int arg_x) (to_int !_y)) + (to_int !_y)) 2 }
        /// @why3 invariant { to_int arg_x < (to_int !_y + 1) * (to_int !_y + 1) }
        /// @why3 invariant { to_int arg_x < (to_int !_z + 1) * (to_int !_z + 1) }
        /// @why3 variant { to_int !_y }
        {
            y = z;
            z = (_x / z + z) / 2;
        }
        return y;
    }

    /// Not needed in this iteration 
    /// @dev                Bakhashali square rooting using while loops, this increases accuracy for each itteration
    // function sqrtBakhshali(uint256 x) public pure returns(uint256) {
    //     uint256 n = sqrt(x);
    //     for(uint i = 0; i <= 5; i++) {
    //         n = ((n**2)*(n**2 + 6*x) + x**2)/(4*n*(n**2 + x));
    //     }
    //     return n;
    // }
}
