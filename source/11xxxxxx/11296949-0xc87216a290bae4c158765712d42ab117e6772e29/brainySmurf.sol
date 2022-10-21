/**scroll DOWN   ,8"                                     `8,
*               dP'                                        8I
*             ,8"                           bg,_          ,P'
*            ,8'                              "Y8"Ya,,,,ad"
*           ,d"                            a,_ I8   `"""'
*          ,8'                              ""888
*          dP     __                           `Yb,
*         dP'  _,d8P::::Y8b,                     `Ya
*    ,adba8',d88P::;;::;;;:"b:::Ya,_               Ya
*   dP":::"Y88P:;P"""YP"""Yb;::::::"Ya,             "Y,
*   8:::::::Yb;d" _  "_    dI:::::::::"Yb,__,,gd88ba,db
*   Yb:::::::"8(,8P _d8   d8:::::::::::::Y88P"::::::Y8I
*   `Yb;:::::::""::"":b,,dP::::::::::::::::::;aaa;:::8(
*     `Y8a;:::::::::::::::::::::;;::::::::::8P""Y8)::8I
*       8b"ba::::::::::::::::;adP:::::::::::":::dP::;8'
*       `8b;::::::::::::;aad888P::::::::::::::;dP::;8'
*        `8b;::::::::""""88"  d::::::::::b;:::::;;dP'
*          "Yb;::::::::::Y8bad::::::::::;"8Paaa""'
*            `"Y8a;;;:::::::::::::;;aadP""
*                ``""Y88bbbdddd88P""8b,
*                         _,d8"::::::"8b,
*                       ,dP8"::::::;;:::"b,
*                     ,dP"8:::::::Yb;::::"b,
*                   ,8P:dP:::::::::Yb;::::"b,
*                _,dP:;8":::::::::::Yb;::::"b
*      ,aaaaaa,,d8P:::8":::::::::::;dP:::::;8
*   ,ad":;;:::::"::::8"::::::::::;dP::::::;dI
*  dP";adP":::::;:;dP;::::aaaad88"::::::adP:8b,___
* d8:::8;;;aadP"::8'Y8:d8P"::::::::::;dP";d"'`Yb:"b
* 8I:::;""":::::;dP I8P"::::::::::;a8"a8P"     "b:P
* Yb::::"8baa8"""'  8;:;d"::::::::d8P"'         8"
*  "YbaaP::8;P      `8;d::;a::;;;;dP           ,8
*     `"Y8P"'         Yb;;d::;aadP"           ,d'
*                      "YP:::"P'             ,d'
*                        "8bdP'    _        ,8'
*                       ,8"`""Yba,d"      ,d"
*                      ,P'     d"8'     ,d"
*                     ,8'     d'8'     ,P'
*                     (b      8 I      8,
*                      Y,     Y,Y,     `b,
*                ____   "8,__ `Y,Y,     `Y""b,
*            ,adP""""b8P""""""""Ybdb,        Y,
*          ,dP"    ,dP'            `""       `8
*         ,8"     ,P'                        ,P
*         8'      8)                        ,8'
*         8,      Yb                      ,aP'
*         `Ya      Yb                  ,ad"'
*           "Ya,___ "Ya             ,ad"'
*             ``""""""`Yba,,,,,,,adP"'
*
*/

//brainySmurf.sol ⓒ11.2020 Smurfs.finance

pragma solidity =0.6.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
