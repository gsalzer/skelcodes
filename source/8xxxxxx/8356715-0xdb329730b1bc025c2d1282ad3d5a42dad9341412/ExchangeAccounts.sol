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

/// @title Utility Functions for uint
/// @author Daniel Wang - <daniel@loopring.org>
library MathUint
{
    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function decodeFloat(
        uint f
        )
        internal
        pure
        returns (uint value)
    {
        uint numBitsMantissa = 23;
        uint exponent = f >> numBitsMantissa;
        uint mantissa = f & ((1 << numBitsMantissa) - 1);
        value = mantissa * (10 ** exponent);
    }
}

/// @title IAddressWhitelist
/// @author Daniel Wang - <daniel@loopring.org>
contract IAddressWhitelist
{
    /// @dev Check if a address is whitelisted.
    /// @param user The user to check if being whitelisted.
    /// @param permission An arbitrary data from caller to indicate permission.
    /// @return true if the address is whitelisted
    function isWhitelisted(
        address user,
        bytes   memory permission
        )
        public
        returns (bool);
}

/// @title Poseidon hash function
///        See: https://eprint.iacr.org/2019/458.pdf
///        Code auto-generated by generate_poseidon_EVM_code.py
/// @author Brecht Devos - <brecht@loopring.org>
library Poseidon
{
    function hash_t5f6p52(
        uint t0,
        uint t1,
        uint t2,
        uint t3,
        uint t4
        )
        internal
        pure
        returns (uint)
    {
        uint q = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        // Make sure the inputs can be stored in the SNARK field
        require(t0 < q, "INVALID_INPUT");
        require(t1 < q, "INVALID_INPUT");
        require(t2 < q, "INVALID_INPUT");
        require(t3 < q, "INVALID_INPUT");
        require(t4 < q, "INVALID_INPUT");

        assembly {
            function mix(t0, t1, t2, t3, t4, q) -> nt0, nt1, nt2, nt3, nt4 {
                nt0 := mulmod(t0, 4977258759536702998522229302103997878600602264560359702680165243908162277980, q)
                nt0 := addmod(nt0, mulmod(t1, 19167410339349846567561662441069598364702008768579734801591448511131028229281, q), q)
                nt0 := addmod(nt0, mulmod(t2, 14183033936038168803360723133013092560869148726790180682363054735190196956789, q), q)
                nt0 := addmod(nt0, mulmod(t3, 9067734253445064890734144122526450279189023719890032859456830213166173619761, q), q)
                nt0 := addmod(nt0, mulmod(t4, 16378664841697311562845443097199265623838619398287411428110917414833007677155, q), q)
                nt1 := mulmod(t0, 107933704346764130067829474107909495889716688591997879426350582457782826785, q)
                nt1 := addmod(nt1, mulmod(t1, 17034139127218860091985397764514160131253018178110701196935786874261236172431, q), q)
                nt1 := addmod(nt1, mulmod(t2, 2799255644797227968811798608332314218966179365168250111693473252876996230317, q), q)
                nt1 := addmod(nt1, mulmod(t3, 2482058150180648511543788012634934806465808146786082148795902594096349483974, q), q)
                nt1 := addmod(nt1, mulmod(t4, 16563522740626180338295201738437974404892092704059676533096069531044355099628, q), q)
                nt2 := mulmod(t0, 13596762909635538739079656925495736900379091964739248298531655823337482778123, q)
                nt2 := addmod(nt2, mulmod(t1, 18985203040268814769637347880759846911264240088034262814847924884273017355969, q), q)
                nt2 := addmod(nt2, mulmod(t2, 8652975463545710606098548415650457376967119951977109072274595329619335974180, q), q)
                nt2 := addmod(nt2, mulmod(t3, 970943815872417895015626519859542525373809485973005165410533315057253476903, q), q)
                nt2 := addmod(nt2, mulmod(t4, 19406667490568134101658669326517700199745817783746545889094238643063688871948, q), q)
                nt3 := mulmod(t0, 2953507793609469112222895633455544691298656192015062835263784675891831794974, q)
                nt3 := addmod(nt3, mulmod(t1, 19025623051770008118343718096455821045904242602531062247152770448380880817517, q), q)
                nt3 := addmod(nt3, mulmod(t2, 9077319817220936628089890431129759976815127354480867310384708941479362824016, q), q)
                nt3 := addmod(nt3, mulmod(t3, 4770370314098695913091200576539533727214143013236894216582648993741910829490, q), q)
                nt3 := addmod(nt3, mulmod(t4, 4298564056297802123194408918029088169104276109138370115401819933600955259473, q), q)
                nt4 := mulmod(t0, 8336710468787894148066071988103915091676109272951895469087957569358494947747, q)
                nt4 := addmod(nt4, mulmod(t1, 16205238342129310687768799056463408647672389183328001070715567975181364448609, q), q)
                nt4 := addmod(nt4, mulmod(t2, 8303849270045876854140023508764676765932043944545416856530551331270859502246, q), q)
                nt4 := addmod(nt4, mulmod(t3, 20218246699596954048529384569730026273241102596326201163062133863539137060414, q), q)
                nt4 := addmod(nt4, mulmod(t4, 1712845821388089905746651754894206522004527237615042226559791118162382909269, q), q)
            }

            function ark(t0, t1, t2, t3, t4, q, c) -> nt0, nt1, nt2, nt3, nt4 {
                nt0 := addmod(t0, c, q)
                nt1 := addmod(t1, c, q)
                nt2 := addmod(t2, c, q)
                nt3 := addmod(t3, c, q)
                nt4 := addmod(t4, c, q)
            }

            function sbox_full(t0, t1, t2, t3, t4, q) -> nt0, nt1, nt2, nt3, nt4 {
                nt0 := mulmod(t0, t0, q)
                nt0 := mulmod(nt0, nt0, q)
                nt0 := mulmod(t0, nt0, q)
                nt1 := mulmod(t1, t1, q)
                nt1 := mulmod(nt1, nt1, q)
                nt1 := mulmod(t1, nt1, q)
                nt2 := mulmod(t2, t2, q)
                nt2 := mulmod(nt2, nt2, q)
                nt2 := mulmod(t2, nt2, q)
                nt3 := mulmod(t3, t3, q)
                nt3 := mulmod(nt3, nt3, q)
                nt3 := mulmod(t3, nt3, q)
                nt4 := mulmod(t4, t4, q)
                nt4 := mulmod(nt4, nt4, q)
                nt4 := mulmod(t4, nt4, q)
            }

            function sbox_partial(t, q) -> nt {
                nt := mulmod(t, t, q)
                nt := mulmod(nt, nt, q)
                nt := mulmod(t, nt, q)
            }

            // round 0
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14397397413755236225575615486459253198602422701513067526754101844196324375522)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 1
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10405129301473404666785234951972711717481302463898292859783056520670200613128)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 2
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 5179144822360023508491245509308555580251733042407187134628755730783052214509)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 3
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9132640374240188374542843306219594180154739721841249568925550236430986592615)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 4
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20360807315276763881209958738450444293273549928693737723235350358403012458514)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 5
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17933600965499023212689924809448543050840131883187652471064418452962948061619)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 6
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 3636213416533737411392076250708419981662897009810345015164671602334517041153)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 7
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2008540005368330234524962342006691994500273283000229509835662097352946198608)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 8
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16018407964853379535338740313053768402596521780991140819786560130595652651567)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 9
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20653139667070586705378398435856186172195806027708437373983929336015162186471)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 10
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17887713874711369695406927657694993484804203950786446055999405564652412116765)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 11
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4852706232225925756777361208698488277369799648067343227630786518486608711772)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 12
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8969172011633935669771678412400911310465619639756845342775631896478908389850)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 13
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20570199545627577691240476121888846460936245025392381957866134167601058684375)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 14
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16442329894745639881165035015179028112772410105963688121820543219662832524136)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 15
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20060625627350485876280451423010593928172611031611836167979515653463693899374)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 16
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16637282689940520290130302519163090147511023430395200895953984829546679599107)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 17
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15599196921909732993082127725908821049411366914683565306060493533569088698214)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 18
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16894591341213863947423904025624185991098788054337051624251730868231322135455)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 19
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 1197934381747032348421303489683932612752526046745577259575778515005162320212)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 20
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6172482022646932735745595886795230725225293469762393889050804649558459236626)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 21
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 21004037394166516054140386756510609698837211370585899203851827276330669555417)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 22
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15262034989144652068456967541137853724140836132717012646544737680069032573006)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 23
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15017690682054366744270630371095785995296470601172793770224691982518041139766)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 24
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15159744167842240513848638419303545693472533086570469712794583342699782519832)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 25
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 11178069035565459212220861899558526502477231302924961773582350246646450941231)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 26
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 21154888769130549957415912997229564077486639529994598560737238811887296922114)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 27
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20162517328110570500010831422938033120419484532231241180224283481905744633719)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 28
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2777362604871784250419758188173029886707024739806641263170345377816177052018)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 29
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15732290486829619144634131656503993123618032247178179298922551820261215487562)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 30
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6024433414579583476444635447152826813568595303270846875177844482142230009826)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 31
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17677827682004946431939402157761289497221048154630238117709539216286149983245)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 32
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10716307389353583413755237303156291454109852751296156900963208377067748518748)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 33
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14925386988604173087143546225719076187055229908444910452781922028996524347508)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 34
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8940878636401797005293482068100797531020505636124892198091491586778667442523)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 35
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 18911747154199663060505302806894425160044925686870165583944475880789706164410)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 36
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8821532432394939099312235292271438180996556457308429936910969094255825456935)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 37
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20632576502437623790366878538516326728436616723089049415538037018093616927643)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 38
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 71447649211767888770311304010816315780740050029903404046389165015534756512)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 39
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2781996465394730190470582631099299305677291329609718650018200531245670229393)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 40
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 12441376330954323535872906380510501637773629931719508864016287320488688345525)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 41
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2558302139544901035700544058046419714227464650146159803703499681139469546006)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 42
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10087036781939179132584550273563255199577525914374285705149349445480649057058)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 43
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4267692623754666261749551533667592242661271409704769363166965280715887854739)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 44
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4945579503584457514844595640661884835097077318604083061152997449742124905548)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 45
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17742335354489274412669987990603079185096280484072783973732137326144230832311)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 46
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6266270088302506215402996795500854910256503071464802875821837403486057988208)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 47
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2716062168542520412498610856550519519760063668165561277991771577403400784706)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 48
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 19118392018538203167410421493487769944462015419023083813301166096764262134232)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 49
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9386595745626044000666050847309903206827901310677406022353307960932745699524)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 50
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9121640807890366356465620448383131419933298563527245687958865317869840082266)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 51
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 3078975275808111706229899605611544294904276390490742680006005661017864583210)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 52
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 7157404299437167354719786626667769956233708887934477609633504801472827442743)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 53
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14056248655941725362944552761799461694550787028230120190862133165195793034373)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 54
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14124396743304355958915937804966111851843703158171757752158388556919187839849)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 55
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 11851254356749068692552943732920045260402277343008629727465773766468466181076)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 56
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9799099446406796696742256539758943483211846559715874347178722060519817626047)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 57
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10156146186214948683880719664738535455146137901666656566575307300522957959544)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
        }
        return t0;
    }
}

/// @title ExchangeBalances.
/// @author Daniel Wang  - <daniel@loopring.org>
/// @author Brecht Devos - <brecht@loopring.org>
library ExchangeBalances
{
    using MathUint  for uint;

    function verifyAccountBalance(
        uint     merkleRoot,
        uint24   accountID,
        uint16   tokenID,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] calldata accountMerkleProof,
        uint[12] calldata balanceMerkleProof
        )
        external
        pure
    {
        bool isCorrect = isAccountBalanceCorrect(
            merkleRoot,
            accountID,
            tokenID,
            pubKeyX,
            pubKeyY,
            nonce,
            balance,
            tradeHistoryRoot,
            accountMerkleProof,
            balanceMerkleProof
        );
        require(isCorrect, "INVALID_MERKLE_TREE_DATA");
    }

    function isAccountBalanceCorrect(
        uint     merkleRoot,
        uint24   accountID,
        uint16   tokenID,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] memory accountMerkleProof,
        uint[12] memory balanceMerkleProof
        )
        public
        pure
        returns (bool isCorrect)
    {
        // Verify data
        uint calculatedRoot = getBalancesRoot(
            tokenID,
            balance,
            tradeHistoryRoot,
            balanceMerkleProof
        );
        calculatedRoot = getAccountInternalsRoot(
            accountID,
            pubKeyX,
            pubKeyY,
            nonce,
            calculatedRoot,
            accountMerkleProof
        );
        isCorrect = (calculatedRoot == merkleRoot);
    }

    function getBalancesRoot(
        uint16   tokenID,
        uint     balance,
        uint     tradeHistoryRoot,
        uint[12] memory balanceMerkleProof
        )
        private
        pure
        returns (uint)
    {
        uint balanceItem = hashImpl(balance, tradeHistoryRoot, 0, 0);
        uint _id = tokenID;
        for (uint depth = 0; depth < 4; depth++) {
            if (_id & 3 == 0) {
                balanceItem = hashImpl(
                    balanceItem,
                    balanceMerkleProof[depth * 3],
                    balanceMerkleProof[depth * 3 + 1],
                    balanceMerkleProof[depth * 3 + 2]
                );
            } else if (_id & 3 == 1) {
                balanceItem = hashImpl(
                    balanceMerkleProof[depth * 3],
                    balanceItem,
                    balanceMerkleProof[depth * 3 + 1],
                    balanceMerkleProof[depth * 3 + 2]
                );
            } else if (_id & 3 == 2) {
                balanceItem = hashImpl(
                    balanceMerkleProof[depth * 3],
                    balanceMerkleProof[depth * 3 + 1],
                    balanceItem,
                    balanceMerkleProof[depth * 3 + 2]
                );
            } else if (_id & 3 == 3) {
                balanceItem = hashImpl(
                    balanceMerkleProof[depth * 3],
                    balanceMerkleProof[depth * 3 + 1],
                    balanceMerkleProof[depth * 3 + 2],
                    balanceItem
                );
            }
            _id = _id >> 2;
        }
        return balanceItem;
    }

    function getAccountInternalsRoot(
        uint24   accountID,
        uint     pubKeyX,
        uint     pubKeyY,
        uint     nonce,
        uint     balancesRoot,
        uint[30] memory accountMerkleProof
        )
        private
        pure
        returns (uint)
    {
        uint accountItem = hashImpl(pubKeyX, pubKeyY, nonce, balancesRoot);
        uint _id = accountID;
        for (uint depth = 0; depth < 10; depth++) {
            if (_id & 3 == 0) {
                accountItem = hashImpl(
                    accountItem,
                    accountMerkleProof[depth * 3],
                    accountMerkleProof[depth * 3 + 1],
                    accountMerkleProof[depth * 3 + 2]
                );
            } else if (_id & 3 == 1) {
                accountItem = hashImpl(
                    accountMerkleProof[depth * 3],
                    accountItem,
                    accountMerkleProof[depth * 3 + 1],
                    accountMerkleProof[depth * 3 + 2]
                );
            } else if (_id & 3 == 2) {
                accountItem = hashImpl(
                    accountMerkleProof[depth * 3],
                    accountMerkleProof[depth * 3 + 1],
                    accountItem,
                    accountMerkleProof[depth * 3 + 2]
                );
            } else if (_id & 3 == 3) {
                accountItem = hashImpl(
                    accountMerkleProof[depth * 3],
                    accountMerkleProof[depth * 3 + 1],
                    accountMerkleProof[depth * 3 + 2],
                    accountItem
                );
            }
            _id = _id >> 2;
        }
        return accountItem;
    }

    function hashImpl(
        uint t0,
        uint t1,
        uint t2,
        uint t3
        )
        private
        pure
        returns (uint)
    {
        return Poseidon.hash_t5f6p52(t0, t1, t2, t3, 0);
    }
}

/// @title IBlockVerifier
/// @author Brecht Devos - <brecht@loopring.org>
contract IBlockVerifier
{
    // -- Events --

    event CircuitRegistered(
        uint8  indexed blockType,
        bool           onchainDataAvailability,
        uint16         blockSize,
        uint8          blockVersion
    );

    event CircuitDisabled(
        uint8  indexed blockType,
        bool           onchainDataAvailability,
        uint16         blockSize,
        uint8          blockVersion
    );

    // -- Public functions --

    /// @dev Sets the verifying key for the specified circuit.
    ///      Every block permutation needs its own circuit and thus its own set of
    ///      verification keys. Only a limited number of block sizes per block
    ///      type are supported.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param vk The verification key
    function registerCircuit(
        uint8    blockType,
        bool     onchainDataAvailability,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external;

    /// @dev Disables the use of the specified circuit.
    ///      This will stop NEW blocks from using the given circuit, blocks that were already committed
    ///      can still be verified.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    function disableCircuit(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external;

    /// @dev Verify blocks with the given public data and proofs.
    ///      Verifying a block makes sure all requests handled in the block
    ///      are correctly handled by the operator.
    /// @param blockType The type of block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param publicInputs The hash of all the public data of the blocks
    /// @param proofs The ZK proofs proving that the blocks are correct
    /// @return True if the block is valid, false otherwise
    function verifyProofs(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        view
        returns (bool);

    /// @dev Checks if a circuit with the specified parameters is registered.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is registered, false otherwise
    function isCircuitRegistered(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool);

    /// @dev Checks if a circuit can still be used to commit new blocks.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is enabled, false otherwise
    function isCircuitEnabled(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool);
}

/// @title ILoopring
/// @author Daniel Wang  - <daniel@loopring.org>
contract ILoopring is Claimable, ReentrancyGuard
{
    address public protocolRegistry;
    address public lrcAddress;
    uint    public exchangeCreationCostLRC;

    event ExchangeInitialized(
        uint    indexed exchangeId,
        address indexed exchangeAddress,
        address indexed owner,
        address         operator,
        bool            onchainDataAvailability
    );

    /// @dev Initialize and register an exchange.
    ///      This function should only be callabled by the protocolRegistry contract.
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

/// @title ILoopringV3
/// @author Brecht Devos - <brecht@loopring.org>
/// @author Daniel Wang  - <daniel@loopring.org>
contract ILoopringV3 is ILoopring
{
    // == Events ==

    event ExchangeStakeDeposited(
        uint    indexed exchangeId,
        uint            amount
    );

    event ExchangeStakeWithdrawn(
        uint    indexed exchangeId,
        uint            amount
    );

    event ExchangeStakeBurned(
        uint    indexed exchangeId,
        uint            amount
    );

    event ProtocolFeeStakeDeposited(
        uint    indexed exchangeId,
        uint            amount
    );

    event ProtocolFeeStakeWithdrawn(
        uint    indexed exchangeId,
        uint            amount
    );

    event SettingsUpdated(
        uint            time
    );

    // == Public Variables ==
    struct Exchange
    {
        address exchangeAddress;
        uint    exchangeStake;
        uint    protocolFeeStake;
    }

    mapping (uint => Exchange) internal exchanges;

    uint    public totalStake;

    address public wethAddress;
    address public exchangeDeployerAddress;
    address public blockVerifierAddress;
    address public downtimeCostCalculator;
    uint    public maxWithdrawalFee;
    uint    public withdrawalFineLRC;
    uint    public tokenRegistrationFeeLRCBase;
    uint    public tokenRegistrationFeeLRCDelta;
    uint    public minExchangeStakeWithDataAvailability;
    uint    public minExchangeStakeWithoutDataAvailability;
    uint    public revertFineLRC;
    uint8   public minProtocolTakerFeeBips;
    uint8   public maxProtocolTakerFeeBips;
    uint8   public minProtocolMakerFeeBips;
    uint8   public maxProtocolMakerFeeBips;
    uint    public targetProtocolTakerFeeStake;
    uint    public targetProtocolMakerFeeStake;

    address payable public protocolFeeVault;

    // == Public Functions ==
    /// @dev Update the global exchange settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateSettings(
        address payable _protocolFeeVault,   // address(0) not allowed
        address _blockVerifierAddress,       // address(0) not allowed
        address _downtimeCostCalculator,     // address(0) allowed
        uint    _exchangeCreationCostLRC,
        uint    _maxWithdrawalFee,
        uint    _tokenRegistrationFeeLRCBase,
        uint    _tokenRegistrationFeeLRCDelta,
        uint    _minExchangeStakeWithDataAvailability,
        uint    _minExchangeStakeWithoutDataAvailability,
        uint    _revertFineLRC,
        uint    _withdrawalFineLRC
        )
        external;

    /// @dev Update the global protocol fee settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateProtocolFeeSettings(
        uint8 _minProtocolTakerFeeBips,
        uint8 _maxProtocolTakerFeeBips,
        uint8 _minProtocolMakerFeeBips,
        uint8 _maxProtocolMakerFeeBips,
        uint  _targetProtocolTakerFeeStake,
        uint  _targetProtocolMakerFeeStake
        )
        external;

    /// @dev Returns whether the Exchange has staked enough to commit blocks
    ///      Exchanges with on-chain data-availaiblity need to stake at least
    ///      minExchangeStakeWithDataAvailability, exchanges without
    ///      data-availability need to stake at least
    ///      minExchangeStakeWithoutDataAvailability.
    /// @param exchangeId The id of the exchange
    /// @param onchainDataAvailability True if the exchange has on-chain
    ///        data-availability, else false
    /// @return True if the exchange has staked enough, else false
    function canExchangeCommitBlocks(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (bool);

    /// @dev Get the amount of staked LRC for an exchange.
    /// @param exchangeId The id of the exchange
    /// @return stakedLRC The amount of LRC
    function getExchangeStake(
        uint exchangeId
        )
        public
        view
        returns (uint stakedLRC);

    /// @dev Burn a certain amount of staked LRC for a specific exchange.
    ///      This function is meant to be called only from exchange contracts.
    /// @param  exchangeId The id of the exchange
    /// @return burnedLRC The amount of LRC burned. If the amount is greater than
    ///         the staked amount, all staked LRC will be burned.
    function burnExchangeStake(
        uint exchangeId,
        uint amount
        )
        external
        returns (uint burnedLRC);

    /// @dev Stake more LRC for an exchange.
    /// @param  exchangeId The id of the exchange
    /// @param  amountLRC The amount of LRC to stake
    /// @return stakedLRC The total amount of LRC staked for the exchange
    function depositExchangeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    /// @dev Withdraw a certain amount of staked LRC for an exchange to the given address.
    ///      This function is meant to be called only from within exchange contracts.
    /// @param  exchangeId The id of the exchange
    /// @param  recipient The address to receive LRC
    /// @param  requestedAmount The amount of LRC to withdraw
    /// @return stakedLRC The amount of LRC withdrawn
    function withdrawExchangeStake(
        uint    exchangeId,
        address recipient,
        uint    requestedAmount
        )
        external
        returns (uint amount);

    /// @dev Stake more LRC for an exchange.
    /// @param  exchangeId The id of the exchange
    /// @param  amountLRC The amount of LRC to stake
    /// @return stakedLRC The total amount of LRC staked for the exchange
    function depositProtocolFeeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    /// @dev Withdraw a certain amount of staked LRC for an exchange to the given address.
    ///      This function is meant to be called only from within exchange contracts.
    /// @param  exchangeId The id of the exchange
    /// @param  recipient The address to receive LRC
    /// @param  amount The amount of LRC to withdraw
    function withdrawProtocolFeeStake(
        uint    exchangeId,
        address recipient,
        uint    amount
        )
        external;

    /// @dev Get the protocol fee values for an exchange.
    /// @param exchangeId The id of the exchange
    /// @param onchainDataAvailability True if the exchange has on-chain
    ///        data-availability, else false
    /// @return takerFeeBips The protocol taker fee
    /// @return makerFeeBips The protocol maker fee
    function getProtocolFeeValues(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (
            uint8 takerFeeBips,
            uint8 makerFeeBips
        );

    /// @dev Returns the exchange's protocol fee stake.
    /// @param  exchangeId The exchange's id.
    /// @return protocolFeeStake The exchange's protocol fee stake.
    function getProtocolFeeStake(
        uint exchangeId
        )
        external
        view
        returns (uint protocolFeeStake);
}

/// @title ExchangeData
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Daniel Wang  - <daniel@loopring.org>
/// @author Brecht Devos - <brecht@loopring.org>
library ExchangeData
{
    // -- Enums --
    enum BlockType
    {
        RING_SETTLEMENT,
        DEPOSIT,
        ONCHAIN_WITHDRAWAL,
        OFFCHAIN_WITHDRAWAL,
        ORDER_CANCELLATION,
        TRANSFER
    }

    enum BlockState
    {
        // This value should never be seen onchain, but we want to reserve 0 so the
        // relayer can use this as the default for new blocks.
        NEW,            // = 0

        // The default state when a new block is included onchain.
        COMMITTED,      // = 1

        // A valid ZK proof has been submitted for this block.
        // The genesis block is VERIFIED by default.
        VERIFIED        // = 2
    }

    // -- Structs --
    struct Account
    {
        address owner;

        // pubKeyX and pubKeyY put together is the EdDSA public trading key. Users or their
        // wallet software are supposed to manage the corresponding private key for signing
        // orders and offchain requests.
        //
        // We use EdDSA because it is more circuit friendly than ECDSA. In later versions
        // we may switch back to ECDSA, then we will not need such a dedicated tradig key-pair.
        //
        // We split the public key into two uint to make it more circuit friendly.
        uint    pubKeyX;
        uint    pubKeyY;
    }

    struct Token
    {
        address token;
        bool    depositDisabled;
    }

    struct ProtocolFeeData
    {
        uint32 timestamp;
        uint8 takerFeeBips;
        uint8 makerFeeBips;
        uint8 previousTakerFeeBips;
        uint8 previousMakerFeeBips;
    }

    // This is the (virtual) block an operator needs to submit onchain to maintain the
    // per-exchange (virtual) blockchain.
    struct Block
    {
        // The merkle root of the offchain data stored in a merkle tree. The merkle tree
        // stores balances for users using an account model.
        bytes32 merkleRoot;

        // The hash of all the public data sent in commitBlock. Committing a block
        // is decoupled from the verification of a block, but we don't want to send
        // the (often) large amount of data (certainly with onchain data availability) again
        // when verifying the proof, so we hash all that data onchain in commitBlock so that we
        // can use it in verifyBlock to verify the block. This also makes the verification cheaper
        // onchain because we only have this single public input.
        bytes32 publicDataHash;

        // The current state of the block. See @BlockState for more information.
        BlockState state;

        // The type of the block (i.e. what kind of requests were processed).
        // See @BlockType for more information.
        BlockType blockType;

        // The number of requests processed in the block. Only a limited number of permutations
        // are available for each block type (because each will need a different circuit
        // and thus different verification key onchain). Use IBlockVerifier.canVerify to find out if
        // the block is supported.
        uint16 blockSize;

        // The block version (i.e. what circuit version needs to be used to verify the block).
        uint8  blockVersion;

        // The time the block was created.
        uint32 timestamp;

        // The number of onchain deposit requests that have been processed
        // up to and including this block.
        uint32 numDepositRequestsCommitted;

        // The number of onchain withdrawal requests that have been processed
        // up to and including this block.
        uint32 numWithdrawalRequestsCommitted;

        // Stores whether the fee earned by the operator for processing onchain requests
        // is withdrawn or not.
        bool   blockFeeWithdrawn;

        // Number of withdrawals distributed using `distributeWithdrawals`
        uint16 numWithdrawalsDistributed;

        // The approved withdrawal data. Needs to be stored onchain so this data is available
        // once the block is finalized and the funds can be withdrawn using the info stored
        // in this data.
        // For every withdrawal (there are 'blockSize' withdrawals),
        // stored sequentially after each other:
        //    - Token ID: 1 bytes
        //    - Account ID: 2,5 bytes
        //    - Amount: 3,5 bytes
        bytes  withdrawals;
    }

    // Represents the post-state of an onchain deposit/withdrawal request. We can visualize
    // a deposit request-chain and a withdrawal request-chain, each of which is
    // composed of such Request objects. Please refer to the design doc for more details.
    struct Request
    {
        bytes32 accumulatedHash;
        uint    accumulatedFee;
        uint32  timestamp;
    }

    // Represents an onchain deposit request.  `tokenID` being `0x0` means depositing Ether.
    struct Deposit
    {
        uint24 accountID;
        uint16 tokenID;
        uint96 amount;
    }

    function SNARK_SCALAR_FIELD() internal pure returns (uint) {
        // This is the prime number that is used for the alt_bn128 elliptic curve, see EIP-196.
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function MAX_PROOF_GENERATION_TIME_IN_SECONDS() internal pure returns (uint32) { return 1 hours; }
    function MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS() internal pure returns (uint32) { return 2500; }
    function MAX_OPEN_DEPOSIT_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_OPEN_WITHDRAWAL_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_AGE_UNFINALIZED_BLOCK_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 1 days; }
    function MAX_AGE_REQUEST_UNTIL_FORCED() internal pure returns (uint32) { return 15 minutes; }
    function MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 1 days; }
    function MAX_TIME_IN_SHUTDOWN_BASE() internal pure returns (uint32) { return 1 days; }
    function MAX_TIME_IN_SHUTDOWN_DELTA() internal pure returns (uint32) { return 15 seconds; }
    function TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS() internal pure returns (uint32) { return 10 minutes; }
    function MAX_NUM_TOKENS() internal pure returns (uint) { return 2 ** 8; }
    function MAX_NUM_ACCOUNTS() internal pure returns (uint) { return 2 ** 20 - 1; }
    function MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 2 hours; }
    function FEE_BLOCK_FINE_START_TIME() internal pure returns (uint32) { return 5 minutes; }
    function FEE_BLOCK_FINE_MAX_DURATION() internal pure returns (uint32) { return 30 minutes; }
    function MIN_GAS_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 60000; }
    function MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED() internal pure returns (uint32) { return 1 days; }
    function GAS_LIMIT_SEND_TOKENS() internal pure returns (uint32) { return 30000; }

    // Represents the entire exchange state except the owner of the exchange.
    struct State
    {
        uint    id;
        uint    exchangeCreationTimestamp;
        address payable operator; // The only address that can submit new blocks.
        bool    onchainDataAvailability;

        ILoopringV3    loopring;
        IBlockVerifier blockVerifier;

        address lrcAddress;

        uint    totalTimeInMaintenanceSeconds;
        uint    numDowntimeMinutes;
        uint    downtimeStart;

        address addressWhitelist;
        uint    accountCreationFeeETH;
        uint    accountUpdateFeeETH;
        uint    depositFeeETH;
        uint    withdrawalFeeETH;

        Block[]     blocks;
        Token[]     tokens;
        Account[]   accounts;
        Deposit[]   deposits;
        Request[]   depositChain;
        Request[]   withdrawalChain;

        // A map from the account owner to accountID + 1
        mapping (address => uint24) ownerToAccountId;
        mapping (address => uint16) tokenToTokenId;

        // A map from an account owner to a token to if the balance is withdrawn
        mapping (address => mapping (address => bool)) withdrawnInWithdrawMode;

        // A map from token address to their accumulated balances
        mapping (address => uint) tokenBalances;

        // A block's state will become FINALIZED when and only when this block is VERIFIED
        // and all previous blocks in the chain have become FINALIZED.
        // The genesis block is FINALIZED by default.
        uint numBlocksFinalized;

        // Cached data for the protocol fee
        ProtocolFeeData protocolFeeData;

        // Time when the exchange was shutdown
        uint shutdownStartTime;
    }
}

/// @title ExchangeAccounts.
/// @author Daniel Wang  - <daniel@loopring.org>
/// @author Brecht Devos - <brecht@loopring.org>
library ExchangeAccounts
{
    using MathUint          for uint;
    using ExchangeBalances  for ExchangeData.State;

    event AccountCreated(
        address indexed owner,
        uint24  indexed id,
        uint            pubKeyX,
        uint            pubKeyY
    );

    event AccountUpdated(
        address indexed owner,
        uint24  indexed id,
        uint            pubKeyX,
        uint            pubKeyY
    );

    // == Public Functions ==
    function getAccount(
        ExchangeData.State storage S,
        address owner
        )
        external
        view
        returns (
            uint24 accountID,
            uint   pubKeyX,
            uint   pubKeyY
        )
    {
        accountID = getAccountID(S, owner);
        ExchangeData.Account storage account = S.accounts[accountID];
        pubKeyX = account.pubKeyX;
        pubKeyY = account.pubKeyY;
    }

    function createOrUpdateAccount(
        ExchangeData.State storage S,
        uint  pubKeyX,
        uint  pubKeyY,
        bytes calldata permission
        )
        external
        returns (
            uint24 accountID,
            bool   isAccountNew,
            bool   isAccountUpdated
        )
    {
        isAccountNew = (S.ownerToAccountId[msg.sender] == 0);
        if (isAccountNew) {
            if (S.addressWhitelist != address(0)) {
                require(
                    IAddressWhitelist(S.addressWhitelist).isWhitelisted(msg.sender, permission),
                    "ADDRESS_NOT_WHITELISTED"
                );
            }
            accountID = createAccount(S, pubKeyX, pubKeyY);
            isAccountUpdated = false;
        } else {
            (accountID, isAccountUpdated) = updateAccount(S, pubKeyX, pubKeyY);
        }
    }

    function getAccountID(
        ExchangeData.State storage S,
        address owner
        )
        public
        view
        returns (uint24 accountID)
    {
        accountID = S.ownerToAccountId[owner];
        require(accountID != 0, "ADDRESS_HAS_NO_ACCOUNT");

        accountID = accountID - 1;
    }

    function createAccount(
        ExchangeData.State storage S,
        uint pubKeyX,
        uint pubKeyY
        )
        private
        returns (uint24 accountID)
    {
        require(S.accounts.length < ExchangeData.MAX_NUM_ACCOUNTS(), "ACCOUNTS_FULL");
        require(S.ownerToAccountId[msg.sender] == 0, "ACCOUNT_EXISTS");

        accountID = uint24(S.accounts.length);
        ExchangeData.Account memory account = ExchangeData.Account(
            msg.sender,
            pubKeyX,
            pubKeyY
        );

        S.accounts.push(account);
        S.ownerToAccountId[msg.sender] = accountID + 1;

        emit AccountCreated(
            msg.sender,
            accountID,
            pubKeyX,
            pubKeyY
        );
    }

    function updateAccount(
        ExchangeData.State storage S,
        uint pubKeyX,
        uint pubKeyY
        )
        private
        returns (
            uint24 accountID,
            bool   isAccountUpdated
        )
    {
        require(S.ownerToAccountId[msg.sender] != 0, "ACCOUNT_NOT_EXIST");

        accountID = S.ownerToAccountId[msg.sender] - 1;
        ExchangeData.Account storage account = S.accounts[accountID];

        isAccountUpdated = (account.pubKeyX != pubKeyX || account.pubKeyY != pubKeyY);
        if (isAccountUpdated) {
            account.pubKeyX = pubKeyX;
            account.pubKeyY = pubKeyY;

            emit AccountUpdated(
                msg.sender,
                accountID,
                pubKeyX,
                pubKeyY
            );
        }
    }
}
