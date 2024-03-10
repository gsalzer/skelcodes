/**
Author: Loopring Foundation (Loopring Project Ltd)
*/

pragma solidity ^0.5.11;


library MathUint {
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

contract IAddressWhitelist {
    
    
    
    
    function isAddressWhitelisted(
        address addr,
        bytes   memory permission
        )
        public
        view
        returns (bool);
}

library Poseidon {
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

            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14397397413755236225575615486459253198602422701513067526754101844196324375522)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10405129301473404666785234951972711717481302463898292859783056520670200613128)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 5179144822360023508491245509308555580251733042407187134628755730783052214509)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9132640374240188374542843306219594180154739721841249568925550236430986592615)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20360807315276763881209958738450444293273549928693737723235350358403012458514)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17933600965499023212689924809448543050840131883187652471064418452962948061619)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 3636213416533737411392076250708419981662897009810345015164671602334517041153)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2008540005368330234524962342006691994500273283000229509835662097352946198608)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16018407964853379535338740313053768402596521780991140819786560130595652651567)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20653139667070586705378398435856186172195806027708437373983929336015162186471)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17887713874711369695406927657694993484804203950786446055999405564652412116765)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4852706232225925756777361208698488277369799648067343227630786518486608711772)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8969172011633935669771678412400911310465619639756845342775631896478908389850)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20570199545627577691240476121888846460936245025392381957866134167601058684375)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16442329894745639881165035015179028112772410105963688121820543219662832524136)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20060625627350485876280451423010593928172611031611836167979515653463693899374)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16637282689940520290130302519163090147511023430395200895953984829546679599107)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15599196921909732993082127725908821049411366914683565306060493533569088698214)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16894591341213863947423904025624185991098788054337051624251730868231322135455)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 1197934381747032348421303489683932612752526046745577259575778515005162320212)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6172482022646932735745595886795230725225293469762393889050804649558459236626)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 21004037394166516054140386756510609698837211370585899203851827276330669555417)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15262034989144652068456967541137853724140836132717012646544737680069032573006)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15017690682054366744270630371095785995296470601172793770224691982518041139766)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15159744167842240513848638419303545693472533086570469712794583342699782519832)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 11178069035565459212220861899558526502477231302924961773582350246646450941231)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 21154888769130549957415912997229564077486639529994598560737238811887296922114)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20162517328110570500010831422938033120419484532231241180224283481905744633719)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2777362604871784250419758188173029886707024739806641263170345377816177052018)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15732290486829619144634131656503993123618032247178179298922551820261215487562)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6024433414579583476444635447152826813568595303270846875177844482142230009826)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17677827682004946431939402157761289497221048154630238117709539216286149983245)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10716307389353583413755237303156291454109852751296156900963208377067748518748)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14925386988604173087143546225719076187055229908444910452781922028996524347508)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8940878636401797005293482068100797531020505636124892198091491586778667442523)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 18911747154199663060505302806894425160044925686870165583944475880789706164410)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8821532432394939099312235292271438180996556457308429936910969094255825456935)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20632576502437623790366878538516326728436616723089049415538037018093616927643)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 71447649211767888770311304010816315780740050029903404046389165015534756512)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2781996465394730190470582631099299305677291329609718650018200531245670229393)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 12441376330954323535872906380510501637773629931719508864016287320488688345525)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2558302139544901035700544058046419714227464650146159803703499681139469546006)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10087036781939179132584550273563255199577525914374285705149349445480649057058)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4267692623754666261749551533667592242661271409704769363166965280715887854739)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4945579503584457514844595640661884835097077318604083061152997449742124905548)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17742335354489274412669987990603079185096280484072783973732137326144230832311)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6266270088302506215402996795500854910256503071464802875821837403486057988208)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2716062168542520412498610856550519519760063668165561277991771577403400784706)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 19118392018538203167410421493487769944462015419023083813301166096764262134232)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9386595745626044000666050847309903206827901310677406022353307960932745699524)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9121640807890366356465620448383131419933298563527245687958865317869840082266)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 3078975275808111706229899605611544294904276390490742680006005661017864583210)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 7157404299437167354719786626667769956233708887934477609633504801472827442743)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14056248655941725362944552761799461694550787028230120190862133165195793034373)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14124396743304355958915937804966111851843703158171757752158388556919187839849)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 11851254356749068692552943732920045260402277343008629727465773766468466181076)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9799099446406796696742256539758943483211846559715874347178722060519817626047)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10156146186214948683880719664738535455146137901666656566575307300522957959544)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
        }
        return t0;
    }
}

library ExchangeBalances {
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

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
    
    constructor()
        public
    {
        owner = msg.sender;
    }

    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    
    
    
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

contract Claimable is Ownable
{
    address public pendingOwner;

    
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    
    
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract IBlockVerifier is Claimable
{
    

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

    

    
    
    
    
    
    
    
    
    
    
    function registerCircuit(
        uint8    blockType,
        bool     onchainDataAvailability,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external;

    
    
    
    
    
    
    
    
    function disableCircuit(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external;

    
    
    
    
    
    
    
    
    
    
    
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

    
    
    
    
    
    
    
    function isCircuitRegistered(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool);

    
    
    
    
    
    
    
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

contract ReentrancyGuard {
    
    uint private _guardValue;

    
    modifier nonReentrant()
    {
        
        require(_guardValue == 0, "REENTRANCY");

        
        _guardValue = 1;

        
        _;

        
        _guardValue = 0;
    }
}

contract ILoopring is Claimable, ReentrancyGuard
{
    string  constant public version = ""; 

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

    
    
    
    
    
    
    
    
    
    
    function initializeExchange(
        address exchangeAddress,
        uint    exchangeId,
        address owner,
        address payable operator,
        bool    onchainDataAvailability
        )
        external;
}

contract ILoopringV3 is ILoopring
{
    

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

    
    struct Exchange
    {
        address exchangeAddress;
        uint    exchangeStake;
        uint    protocolFeeStake;
    }

    mapping (uint => Exchange) internal exchanges;

    string  constant public version = "3.1";

    address public wethAddress;
    uint    public totalStake;
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

    
    
    
    
    
    
    function updateSettings(
        address payable _protocolFeeVault,   
        address _blockVerifierAddress,       
        address _downtimeCostCalculator,     
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

    
    
    
    
    
    function updateProtocolFeeSettings(
        uint8 _minProtocolTakerFeeBips,
        uint8 _maxProtocolTakerFeeBips,
        uint8 _minProtocolMakerFeeBips,
        uint8 _maxProtocolMakerFeeBips,
        uint  _targetProtocolTakerFeeStake,
        uint  _targetProtocolMakerFeeStake
        )
        external;

    
    
    
    
    
    
    
    
    
    function canExchangeCommitBlocks(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (bool);

    
    
    
    function getExchangeStake(
        uint exchangeId
        )
        public
        view
        returns (uint stakedLRC);

    
    
    
    
    
    function burnExchangeStake(
        uint exchangeId,
        uint amount
        )
        external
        returns (uint burnedLRC);

    
    
    
    
    function depositExchangeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    
    
    
    
    
    
    function withdrawExchangeStake(
        uint    exchangeId,
        address recipient,
        uint    requestedAmount
        )
        external
        returns (uint amount);

    
    
    
    
    function depositProtocolFeeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    
    
    
    
    
    function withdrawProtocolFeeStake(
        uint    exchangeId,
        address recipient,
        uint    amount
        )
        external;

    
    
    
    
    
    
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

    
    
    
    function getProtocolFeeStake(
        uint exchangeId
        )
        external
        view
        returns (uint protocolFeeStake);
}

library ExchangeData {
    
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
        
        
        NEW,            

        
        COMMITTED,      

        
        
        VERIFIED        
    }

    
    struct Account
    {
        address owner;

        
        
        
        
        
        
        
        
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

    
    
    struct Block
    {
        
        
        bytes32 merkleRoot;

        
        
        
        
        
        
        bytes32 publicDataHash;

        
        BlockState state;

        
        
        BlockType blockType;

        
        
        
        
        uint16 blockSize;

        
        uint8  blockVersion;

        
        uint32 timestamp;

        
        
        uint32 numDepositRequestsCommitted;

        
        
        uint32 numWithdrawalRequestsCommitted;

        
        
        bool   blockFeeWithdrawn;

        
        uint16 numWithdrawalsDistributed;

        
        
        
        
        
        
        
        
        bytes  withdrawals;
    }

    
    
    
    struct Request
    {
        bytes32 accumulatedHash;
        uint    accumulatedFee;
        uint32  timestamp;
    }

    
    struct Deposit
    {
        uint24 accountID;
        uint16 tokenID;
        uint96 amount;
    }

    function SNARK_SCALAR_FIELD() internal pure returns (uint) {
        
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function MAX_PROOF_GENERATION_TIME_IN_SECONDS() internal pure returns (uint32) { return 14 days; }
    function MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS() internal pure returns (uint32) { return 1000; }
    function MAX_OPEN_DEPOSIT_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_OPEN_WITHDRAWAL_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_AGE_UNFINALIZED_BLOCK_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 21 days; }
    function MAX_AGE_REQUEST_UNTIL_FORCED() internal pure returns (uint32) { return 14 days; }
    function MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 15 days; }
    function MAX_TIME_IN_SHUTDOWN_BASE() internal pure returns (uint32) { return 30 days; }
    function MAX_TIME_IN_SHUTDOWN_DELTA() internal pure returns (uint32) { return 1 seconds; }
    function TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS() internal pure returns (uint32) { return 7 days; }
    function MAX_NUM_TOKENS() internal pure returns (uint) { return 2 ** 8; }
    function MAX_NUM_ACCOUNTS() internal pure returns (uint) { return 2 ** 20 - 1; }
    function MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 14 days; }
    function MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS_SHUTDOWN_MODE() internal pure returns (uint32) {
        return MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS() * 10;
    }
    function FEE_BLOCK_FINE_START_TIME() internal pure returns (uint32) { return 6 hours; }
    function FEE_BLOCK_FINE_MAX_DURATION() internal pure returns (uint32) { return 6 hours; }
    function MIN_GAS_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 150000; }
    function MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED() internal pure returns (uint32) { return 1 days; }
    function GAS_LIMIT_SEND_TOKENS() internal pure returns (uint32) { return 60000; }

    
    struct State
    {
        uint    id;
        uint    exchangeCreationTimestamp;
        address payable operator; 
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

        
        mapping (address => uint24) ownerToAccountId;
        mapping (address => uint16) tokenToTokenId;

        
        mapping (address => mapping (address => bool)) withdrawnInWithdrawMode;

        
        mapping (address => uint) tokenBalances;

        
        
        
        uint numBlocksFinalized;

        
        ProtocolFeeData protocolFeeData;

        
        uint shutdownStartTime;
    }
}

library ExchangeAccounts {
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
                    IAddressWhitelist(S.addressWhitelist)
                        .isAddressWhitelisted(msg.sender, permission),
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

contract ERC20 {
    function totalSupply()
        public
        view
        returns (uint);

    function balanceOf(
        address who
        )
        public
        view
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        view
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        returns (bool);
}

contract BurnableERC20 is ERC20
{
    function burn(
        uint value
        )
        public
        returns (bool);

    function burnFrom(
        address from,
        uint value
        )
        public
        returns (bool);
}

library ERC20SafeTransfer {
    function safeTransferAndVerify(
        address token,
        address to,
        uint    value
        )
        internal
    {
        safeTransferWithGasLimitAndVerify(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferWithGasLimit(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferWithGasLimitAndVerify(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        require(
            safeTransferWithGasLimit(token, to, value, gasLimit),
            "TRANSFER_FAILURE"
        );
    }

    function safeTransferWithGasLimit(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        
        
        

        
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (bool success, ) = token.call.gas(gasLimit)(callData);
        return checkReturnValue(success);
    }

    function safeTransferFromAndVerify(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
    {
        safeTransferFromWithGasLimitAndVerify(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFromWithGasLimitAndVerify(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        bool result = safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasLimit
        );
        require(result, "TRANSFER_FAILURE");
    }

    function safeTransferFromWithGasLimit(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        
        
        

        
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (bool success, ) = token.call.gas(gasLimit)(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
        )
        internal
        pure
        returns (bool)
    {
        
        
        
        if (success) {
            assembly {
                switch returndatasize()
                
                case 0 {
                    success := 1
                }
                
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                
                default {
                    success := 0
                }
            }
        }
        return success;
    }
}

contract IDowntimeCostCalculator {
    
    
    
    
    
    
    
    function getDowntimeCostLRC(
        uint  totalTimeInMaintenanceSeconds,
        uint  totalDEXLifeTimeSeconds,
        uint  numDowntimeMinutes,
        uint  exchangeStakedLRC,
        uint  durationToPurchaseMinutes
        )
        external
        view
        returns (uint cost);
}

library ExchangeMode {
    using MathUint  for uint;

    function isInWithdrawalMode(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (bool result)
    {
        result = false;
        ExchangeData.Block storage currentBlock = S.blocks[S.blocks.length - 1];

        
        if (currentBlock.numDepositRequestsCommitted < S.depositChain.length) {
            uint32 requestTimestamp = S.depositChain[currentBlock.numDepositRequestsCommitted].timestamp;
            result = requestTimestamp < now.sub(ExchangeData.MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE());
        }

        
        if (result == false && currentBlock.numWithdrawalRequestsCommitted < S.withdrawalChain.length) {
            uint32 requestTimestamp = S.withdrawalChain[currentBlock.numWithdrawalRequestsCommitted].timestamp;
            result = requestTimestamp < now.sub(ExchangeData.MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE());
        }

        
        if (result == false) {
            result = isAnyUnfinalizedBlockTooOld(S);
        }

        
        if (result == false && isShutdown(S) && !isInInitialState(S)) {
            
            
            uint maxTimeInShutdown = ExchangeData.MAX_TIME_IN_SHUTDOWN_BASE();
            maxTimeInShutdown = maxTimeInShutdown.add(S.accounts.length.mul(ExchangeData.MAX_TIME_IN_SHUTDOWN_DELTA()));
            result = now > S.shutdownStartTime.add(maxTimeInShutdown);
        }
    }

    function isShutdown(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (bool)
    {
        return S.shutdownStartTime > 0;
    }

    function isInMaintenance(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (bool)
    {
        return S.downtimeStart != 0 && getNumDowntimeMinutesLeft(S) > 0;
    }

    function isInInitialState(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (bool)
    {
        ExchangeData.Block storage firstBlock = S.blocks[0];
        ExchangeData.Block storage lastBlock = S.blocks[S.blocks.length - 1];
        return (S.blocks.length == S.numBlocksFinalized) &&
            (lastBlock.numDepositRequestsCommitted == S.depositChain.length) &&
            (lastBlock.merkleRoot == firstBlock.merkleRoot);
    }

    function areUserRequestsEnabled(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (bool)
    {
        
        
        return !isInMaintenance(S) && !isShutdown(S) && !isInWithdrawalMode(S);
    }

    function isAnyUnfinalizedBlockTooOld(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (bool)
    {
        if (S.numBlocksFinalized < S.blocks.length) {
            uint32 blockTimestamp = S.blocks[S.numBlocksFinalized].timestamp;
            return blockTimestamp < now.sub(ExchangeData.MAX_AGE_UNFINALIZED_BLOCK_UNTIL_WITHDRAW_MODE());
        } else {
            return false;
        }
    }

    function getNumDowntimeMinutesLeft(
        ExchangeData.State storage S
        )
        internal 
        view
        returns (uint)
    {
        if (S.downtimeStart == 0) {
            return S.numDowntimeMinutes;
        } else {
            
            uint numDowntimeMinutesUsed = now.sub(S.downtimeStart) / 60;
            if (S.numDowntimeMinutes > numDowntimeMinutesUsed) {
                return S.numDowntimeMinutes.sub(numDowntimeMinutesUsed);
            } else {
                return 0;
            }
        }
    }
}

library ExchangeAdmins {
    using MathUint          for uint;
    using ERC20SafeTransfer for address;
    using ExchangeMode      for ExchangeData.State;

    event OperatorChanged(
        uint    indexed exchangeId,
        address         oldOperator,
        address         newOperator
    );

    event AddressWhitelistChanged(
        uint    indexed exchangeId,
        address         oldAddressWhitelist,
        address         newAddressWhitelist
    );

    event FeesUpdated(
        uint    indexed exchangeId,
        uint            accountCreationFeeETH,
        uint            accountUpdateFeeETH,
        uint            depositFeeETH,
        uint            withdrawalFeeETH
    );

    function setOperator(
        ExchangeData.State storage S,
        address payable _operator
        )
        external
        returns (address payable oldOperator)
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(address(0) != _operator, "ZERO_ADDRESS");
        oldOperator = S.operator;
        S.operator = _operator;

        emit OperatorChanged(
            S.id,
            oldOperator,
            _operator
        );
    }

    function setAddressWhitelist(
        ExchangeData.State storage S,
        address _addressWhitelist
        )
        external
        returns (address oldAddressWhitelist)
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(S.addressWhitelist != _addressWhitelist, "SAME_ADDRESS");

        oldAddressWhitelist = S.addressWhitelist;
        S.addressWhitelist = _addressWhitelist;

        emit AddressWhitelistChanged(
            S.id,
            oldAddressWhitelist,
            _addressWhitelist
        );
    }

    function setFees(
        ExchangeData.State storage S,
        uint _accountCreationFeeETH,
        uint _accountUpdateFeeETH,
        uint _depositFeeETH,
        uint _withdrawalFeeETH
        )
        external
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(
            _withdrawalFeeETH <= S.loopring.maxWithdrawalFee(),
            "AMOUNT_TOO_LARGE"
        );

        S.accountCreationFeeETH = _accountCreationFeeETH;
        S.accountUpdateFeeETH = _accountUpdateFeeETH;
        S.depositFeeETH = _depositFeeETH;
        S.withdrawalFeeETH = _withdrawalFeeETH;

        emit FeesUpdated(
            S.id,
            _accountCreationFeeETH,
            _accountUpdateFeeETH,
            _depositFeeETH,
            _withdrawalFeeETH
        );
    }

    function startOrContinueMaintenanceMode(
        ExchangeData.State storage S,
        uint durationMinutes
        )
        external
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(!S.isShutdown(), "INVALID_MODE");
        require(durationMinutes > 0, "INVALID_DURATION");

        uint numMinutesLeft = S.getNumDowntimeMinutesLeft();

        
        if (S.downtimeStart != 0 && numMinutesLeft == 0) {
            stopMaintenanceMode(S);
        }

        
        
        
        if (numMinutesLeft < durationMinutes) {
            uint numMinutesToPurchase = durationMinutes.sub(numMinutesLeft);
            uint costLRC = getDowntimeCostLRC(S, numMinutesToPurchase);
            if (costLRC > 0) {
                address feeVault = S.loopring.protocolFeeVault();
                S.lrcAddress.safeTransferFromAndVerify(msg.sender, feeVault, costLRC);
            }
            S.numDowntimeMinutes = S.numDowntimeMinutes.add(numMinutesToPurchase);
        }

        
        if (S.downtimeStart == 0) {
            S.downtimeStart = now;
        }
    }

    function getRemainingDowntime(
        ExchangeData.State storage S
        )
        external
        view
        returns (uint duration)
    {
        return S.getNumDowntimeMinutesLeft();
    }

    function withdrawExchangeStake(
        ExchangeData.State storage S,
        address recipient
        )
        external
        returns (uint)
    {
        ExchangeData.Block storage lastBlock = S.blocks[S.blocks.length - 1];

        
        require(S.isShutdown(), "EXCHANGE_NOT_SHUTDOWN");
        
        require(S.blocks.length == S.numBlocksFinalized, "BLOCK_NOT_FINALIZED");
        
        require(
            lastBlock.numDepositRequestsCommitted == S.depositChain.length,
            "DEPOSITS_NOT_PROCESSED"
        );
        
        
        require(S.isInInitialState(), "MERKLE_ROOT_NOT_REVERTED");

        
        
        
        require(
            now > lastBlock.timestamp + ExchangeData.MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS_SHUTDOWN_MODE(),
            "TOO_EARLY"
        );

        
        uint amount = S.loopring.getExchangeStake(S.id);
        return S.loopring.withdrawExchangeStake(S.id, recipient, amount);
    }

    function withdrawTokenNotOwnedByUsers(
        ExchangeData.State storage S,
        address token,
        address payable recipient
        )
        external
        returns (uint amount)
    {
        require(token != address(0), "ZERO_ADDRESS");
        require(recipient != address(0), "ZERO_VALUE");

        uint totalBalance = ERC20(token).balanceOf(address(this));
        uint userBalance = S.tokenBalances[token];

        assert(totalBalance >= userBalance);
        amount = totalBalance - userBalance;

        if (amount > 0) {
            token.safeTransferAndVerify(recipient, amount);
        }
    }

    function stopMaintenanceMode(
        ExchangeData.State storage S
        )
        public
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(!S.isShutdown(), "INVALID_MODE");
        require(S.downtimeStart != 0, "NOT_IN_MAINTENANCE_MODE");

        
        S.totalTimeInMaintenanceSeconds = getTotalTimeInMaintenanceSeconds(S);

        
        S.numDowntimeMinutes = S.getNumDowntimeMinutesLeft();

        
        
        
        if (S.numDowntimeMinutes > 0) {
            S.numDowntimeMinutes -= 1;
        }

        
        S.downtimeStart = 0;
    }

    function getDowntimeCostLRC(
        ExchangeData.State storage S,
        uint durationMinutes
        )
        public
        view
        returns (uint)
    {
        if (durationMinutes == 0) {
            return 0;
        }

        address costCalculatorAddr = S.loopring.downtimeCostCalculator();
        if (costCalculatorAddr == address(0)) {
            return 0;
        }

        return IDowntimeCostCalculator(costCalculatorAddr).getDowntimeCostLRC(
            S.totalTimeInMaintenanceSeconds,
            now - S.exchangeCreationTimestamp,
            S.numDowntimeMinutes,
            S.loopring.getExchangeStake(S.id),
            durationMinutes
        );
    }

    function getTotalTimeInMaintenanceSeconds(
        ExchangeData.State storage S
        )
        public
        view
        returns (uint time)
    {
        time = S.totalTimeInMaintenanceSeconds;
        if (S.downtimeStart != 0) {
            if (S.getNumDowntimeMinutesLeft() > 0) {
                time = time.add(now.sub(S.downtimeStart));
            } else {
                time = time.add(S.numDowntimeMinutes.mul(60));
            }
        }
    }
}

library BytesUtil {
    function bytesToBytes32(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (bytes32)
    {
        return bytes32(bytesToUintX(b, offset, 32));
    }

    function bytesToUint(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (uint)
    {
        return bytesToUintX(b, offset, 32);
    }

    function bytesToAddress(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (address)
    {
        return address(bytesToUintX(b, offset, 20) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function bytesToUint16(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (uint16)
    {
        return uint16(bytesToUintX(b, offset, 2) & 0xFFFF);
    }

    function bytesToBytes4(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (bytes4 data)
    {
        return bytes4(bytesToBytesX(b, offset, 4) & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000);
    }

    function bytesToBytesX(
        bytes memory b,
        uint  offset,
        uint  numBytes
        )
        private
        pure
        returns (bytes32 data)
    {
        require(b.length >= offset + numBytes, "INVALID_SIZE");
        assembly {
            data := mload(add(b, add(32, offset)))
        }
    }

    function bytesToUintX(
        bytes memory b,
        uint  offset,
        uint  numBytes
        )
        private
        pure
        returns (uint data)
    {
        require(b.length >= offset + numBytes, "INVALID_SIZE");
        assembly {
            data := mload(add(add(b, numBytes), offset))
        }
    }

    function subBytes(
        bytes memory b,
        uint  offset
        )
        internal
        pure
        returns (bytes memory data)
    {
        require(b.length >= offset + 32, "INVALID_SIZE");
        assembly {
            data := add(add(b, 32), offset)
        }
    }

    function fastSHA256(
        bytes memory data
        )
        internal
        view
        returns (bytes32)
    {
        bytes32[] memory result = new bytes32[](1);
        bool success;
        assembly {
             let ptr := add(data, 32)
             success := staticcall(sub(gas, 2000), 2, ptr, mload(data), add(result, 32), 32)
        }
        require(success, "SHA256_FAILED");
        return result[0];
    }
}

contract IDecompressor {
    
    
    
    function decompress(
        bytes calldata data
        )
        external
        pure
        returns (bytes memory decompressedData);
}

library ExchangeBlocks {
    using BytesUtil         for bytes;
    using MathUint          for uint;
    using ExchangeMode      for ExchangeData.State;

    event BlockCommitted(
        uint    indexed blockIdx,
        bytes32 indexed publicDataHash
    );

    event BlockFinalized(
        uint    indexed blockIdx
    );

    event BlockVerified(
        uint    indexed blockIdx
    );

    event Revert(
        uint    indexed blockIdx
    );

    event ProtocolFeesUpdated(
        uint8 takerFeeBips,
        uint8 makerFeeBips,
        uint8 previousTakerFeeBips,
        uint8 previousMakerFeeBips
    );

    function commitBlock(
        ExchangeData.State storage S,
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        bytes  calldata data,
        bytes  calldata 
        )
        external
    {
        commitBlockInternal(
            S,
            ExchangeData.BlockType(blockType),
            blockSize,
            blockVersion,
            data
        );
    }

    function verifyBlocks(
        ExchangeData.State storage S,
        uint[] calldata blockIndices,
        uint[] calldata proofs
        )
        external
    {
        
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        
        require(blockIndices.length > 0, "INVALID_INPUT_ARRAYS");
        require(proofs.length % 8 == 0, "INVALID_PROOF_ARRAY");
        require(proofs.length / 8 == blockIndices.length, "INVALID_INPUT_ARRAYS");

        uint[] memory publicInputs = new uint[](blockIndices.length);
        uint16 blockSize;
        ExchangeData.BlockType blockType;
        uint8 blockVersion;

        for (uint i = 0; i < blockIndices.length; i++) {
            uint blockIdx = blockIndices[i];

            require(blockIdx < S.blocks.length, "INVALID_BLOCK_IDX");
            ExchangeData.Block storage specifiedBlock = S.blocks[blockIdx];
            require(
                specifiedBlock.state == ExchangeData.BlockState.COMMITTED,
                "BLOCK_VERIFIED_ALREADY"
            );

            
            
            
            require(
                blockIdx < S.numBlocksFinalized + ExchangeData.MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS(),
                "PROOF_TOO_EARLY"
            );

            
            require(
                now <= specifiedBlock.timestamp + ExchangeData.MAX_PROOF_GENERATION_TIME_IN_SECONDS(),
                "PROOF_TOO_LATE"
            );

            
            
            publicInputs[i] = uint(specifiedBlock.publicDataHash) >> 3;
            if (i == 0) {
                blockSize = specifiedBlock.blockSize;
                blockType = specifiedBlock.blockType;
                blockVersion = specifiedBlock.blockVersion;
            } else {
                
                require(blockType == specifiedBlock.blockType, "INVALID_BATCH_BLOCK_TYPE");
                require(blockSize == specifiedBlock.blockSize, "INVALID_BATCH_BLOCK_SIZE");
                require(blockVersion == specifiedBlock.blockVersion, "INVALID_BATCH_BLOCK_VERSION");
            }
        }

        
        require(
            S.blockVerifier.verifyProofs(
                uint8(blockType),
                S.onchainDataAvailability,
                blockSize,
                blockVersion,
                publicInputs,
                proofs
            ),
            "INVALID_PROOF"
        );

        
        for (uint i = 0; i < blockIndices.length; i++) {
            uint blockIdx = blockIndices[i];
            ExchangeData.Block storage specifiedBlock = S.blocks[blockIdx];
            
            require(
                specifiedBlock.state == ExchangeData.BlockState.COMMITTED,
                "BLOCK_VERIFIED_ALREADY"
            );
            specifiedBlock.state = ExchangeData.BlockState.VERIFIED;
            emit BlockVerified(blockIdx);
        }

        
        
        
        
        uint idx = S.numBlocksFinalized;
        while (idx < S.blocks.length &&
            S.blocks[idx].state == ExchangeData.BlockState.VERIFIED) {
            emit BlockFinalized(idx);
            idx++;
        }
        S.numBlocksFinalized = idx;
    }

    function revertBlock(
        ExchangeData.State storage S,
        uint blockIdx
        )
        external
    {
        
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        require(blockIdx < S.blocks.length, "INVALID_BLOCK_IDX");
        ExchangeData.Block storage specifiedBlock = S.blocks[blockIdx];
        require(specifiedBlock.state == ExchangeData.BlockState.COMMITTED, "INVALID_BLOCK_STATE");

        
        require(blockIdx >= S.numBlocksFinalized, "FINALIZED_BLOCK_REVERT_PROHIBITED");

        
        uint fine = S.loopring.revertFineLRC();
        S.loopring.burnExchangeStake(S.id, fine);

        
        S.blocks.length = blockIdx;

        emit Revert(blockIdx);
    }

    
    function commitBlockInternal(
        ExchangeData.State storage S,
        ExchangeData.BlockType blockType,
        uint16 blockSize,
        uint8  blockVersion,
        bytes  memory data  
                            
                            
                            
        )
        private
    {
        
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        
        require(
            S.loopring.canExchangeCommitBlocks(S.id, S.onchainDataAvailability),
            "INSUFFICIENT_EXCHANGE_STAKE"
        );

        
        require(
            S.blockVerifier.isCircuitEnabled(
                uint8(blockType),
                S.onchainDataAvailability,
                blockSize,
                blockVersion
            ),
            "CANNOT_VERIFY_BLOCK"
        );

        
        uint32 exchangeIdInData = 0;
        assembly {
            exchangeIdInData := and(mload(add(data, 4)), 0xFFFFFFFF)
        }
        require(exchangeIdInData == S.id, "INVALID_EXCHANGE_ID");

        
        ExchangeData.Block storage prevBlock = S.blocks[S.blocks.length - 1];

        
        bytes32 merkleRootBefore;
        bytes32 merkleRootAfter;
        assembly {
            merkleRootBefore := mload(add(data, 36))
            merkleRootAfter := mload(add(data, 68))
        }
        require(merkleRootBefore == prevBlock.merkleRoot, "INVALID_MERKLE_ROOT");
        require(uint256(merkleRootAfter) < ExchangeData.SNARK_SCALAR_FIELD(), "INVALID_MERKLE_ROOT");

        uint32 numDepositRequestsCommitted = uint32(prevBlock.numDepositRequestsCommitted);
        uint32 numWithdrawalRequestsCommitted = uint32(prevBlock.numWithdrawalRequestsCommitted);

        
        
        
        
        if (S.isShutdown()) {
            if (numDepositRequestsCommitted < S.depositChain.length) {
                require(blockType == ExchangeData.BlockType.DEPOSIT, "SHUTDOWN_DEPOSIT_BLOCK_FORCED");
            } else {
                require(blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL, "SHUTDOWN_WITHDRAWAL_BLOCK_FORCED");
            }
        }

        
        
        
        if (isWithdrawalRequestForced(S, numWithdrawalRequestsCommitted)) {
            require(blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL, "WITHDRAWAL_BLOCK_FORCED");
        } else if (isDepositRequestForced(S, numDepositRequestsCommitted)) {
            require(blockType == ExchangeData.BlockType.DEPOSIT, "DEPOSIT_BLOCK_FORCED");
        }

        if (blockType == ExchangeData.BlockType.RING_SETTLEMENT) {
            require(S.areUserRequestsEnabled(), "SETTLEMENT_SUSPENDED");
            uint32 inputTimestamp;
            uint8 protocolTakerFeeBips;
            uint8 protocolMakerFeeBips;
            assembly {
                inputTimestamp := and(mload(add(data, 72)), 0xFFFFFFFF)
                protocolTakerFeeBips := and(mload(add(data, 73)), 0xFF)
                protocolMakerFeeBips := and(mload(add(data, 74)), 0xFF)
            }
            require(
                inputTimestamp > now - ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS() &&
                inputTimestamp < now + ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS(),
                "INVALID_TIMESTAMP"
            );
            require(
                validateAndUpdateProtocolFeeValues(S, protocolTakerFeeBips, protocolMakerFeeBips),
                "INVALID_PROTOCOL_FEES"
            );
        } else if (blockType == ExchangeData.BlockType.DEPOSIT) {
            uint startIdx = 0;
            uint count = 0;
            assembly {
                startIdx := and(mload(add(data, 136)), 0xFFFFFFFF)
                count := and(mload(add(data, 140)), 0xFFFFFFFF)
            }
            require (startIdx == numDepositRequestsCommitted, "INVALID_REQUEST_RANGE");
            require (count <= blockSize, "INVALID_REQUEST_RANGE");
            require (startIdx + count <= S.depositChain.length, "INVALID_REQUEST_RANGE");

            bytes32 startingHash = S.depositChain[startIdx - 1].accumulatedHash;
            bytes32 endingHash = S.depositChain[startIdx + count - 1].accumulatedHash;
            
            for (uint i = count; i < blockSize; i++) {
                endingHash = sha256(
                    abi.encodePacked(
                        endingHash,
                        uint24(0),
                        uint(0),
                        uint(0),
                        uint8(0),
                        uint96(0)
                    )
                );
            }
            bytes32 inputStartingHash = 0x0;
            bytes32 inputEndingHash = 0x0;
            assembly {
                inputStartingHash := mload(add(data, 100))
                inputEndingHash := mload(add(data, 132))
            }
            require(inputStartingHash == startingHash, "INVALID_STARTING_HASH");
            require(inputEndingHash == endingHash, "INVALID_ENDING_HASH");

            numDepositRequestsCommitted += uint32(count);
        } else if (blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL) {
            uint startIdx = 0;
            uint count = 0;
            assembly {
                startIdx := and(mload(add(data, 136)), 0xFFFFFFFF)
                count := and(mload(add(data, 140)), 0xFFFFFFFF)
            }
            require (startIdx == numWithdrawalRequestsCommitted, "INVALID_REQUEST_RANGE");
            require (count <= blockSize, "INVALID_REQUEST_RANGE");
            require (startIdx + count <= S.withdrawalChain.length, "INVALID_REQUEST_RANGE");

            if (S.isShutdown()) {
                require (count == 0, "INVALID_WITHDRAWAL_COUNT");
                
                
            } else {
                require (count > 0, "INVALID_WITHDRAWAL_COUNT");
                bytes32 startingHash = S.withdrawalChain[startIdx - 1].accumulatedHash;
                bytes32 endingHash = S.withdrawalChain[startIdx + count - 1].accumulatedHash;
                
                for (uint i = count; i < blockSize; i++) {
                    endingHash = sha256(
                        abi.encodePacked(
                            endingHash,
                            uint24(0),
                            uint8(0),
                            uint96(0)
                        )
                    );
                }
                bytes32 inputStartingHash = 0x0;
                bytes32 inputEndingHash = 0x0;
                assembly {
                    inputStartingHash := mload(add(data, 100))
                    inputEndingHash := mload(add(data, 132))
                }
                require(inputStartingHash == startingHash, "INVALID_STARTING_HASH");
                require(inputEndingHash == endingHash, "INVALID_ENDING_HASH");
                numWithdrawalRequestsCommitted += uint32(count);
            }
        } else if (
            blockType != ExchangeData.BlockType.OFFCHAIN_WITHDRAWAL &&
            blockType != ExchangeData.BlockType.ORDER_CANCELLATION &&
            blockType != ExchangeData.BlockType.TRANSFER) {
            revert("UNSUPPORTED_BLOCK_TYPE");
        }

        
        bytes32 publicDataHash = data.fastSHA256();

        
        bytes memory withdrawals = new bytes(0);
        if (blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL ||
            blockType == ExchangeData.BlockType.OFFCHAIN_WITHDRAWAL) {
            uint start = 4 + 32 + 32;
            if (blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL) {
                start += 32 + 32 + 4 + 4;
            }
            uint length = 7 * blockSize;
            assembly {
                withdrawals := add(data, start)
                mstore(withdrawals, length)
            }
        }

        
        ExchangeData.Block memory newBlock = ExchangeData.Block(
            merkleRootAfter,
            publicDataHash,
            ExchangeData.BlockState.COMMITTED,
            blockType,
            blockSize,
            blockVersion,
            uint32(now),
            numDepositRequestsCommitted,
            numWithdrawalRequestsCommitted,
            false,
            0,
            withdrawals
        );

        S.blocks.push(newBlock);

        emit BlockCommitted(S.blocks.length - 1, publicDataHash);
    }

    function validateAndUpdateProtocolFeeValues(
        ExchangeData.State storage S,
        uint8 takerFeeBips,
        uint8 makerFeeBips
        )
        private
        returns (bool)
    {
        ExchangeData.ProtocolFeeData storage data = S.protocolFeeData;
        if (now > data.timestamp + ExchangeData.MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED()) {
            
            data.previousTakerFeeBips = data.takerFeeBips;
            data.previousMakerFeeBips = data.makerFeeBips;
            
            (data.takerFeeBips, data.makerFeeBips) = S.loopring.getProtocolFeeValues(
                S.id,
                S.onchainDataAvailability
            );
            data.timestamp = uint32(now);

            bool feeUpdated = (data.takerFeeBips != data.previousTakerFeeBips) ||
                (data.makerFeeBips != data.previousMakerFeeBips);

            if (feeUpdated) {
                emit ProtocolFeesUpdated(
                    data.takerFeeBips,
                    data.makerFeeBips,
                    data.previousTakerFeeBips,
                    data.previousMakerFeeBips
                );
            }
        }
        
        return (takerFeeBips == data.takerFeeBips && makerFeeBips == data.makerFeeBips) ||
            (takerFeeBips == data.previousTakerFeeBips && makerFeeBips == data.previousMakerFeeBips);
    }

    function isDepositRequestForced(
        ExchangeData.State storage S,
        uint numRequestsCommitted
        )
        private
        view
        returns (bool)
    {
        if (numRequestsCommitted == S.depositChain.length) {
            return false;
        } else {
            return S.depositChain[numRequestsCommitted].timestamp < now.sub(
                ExchangeData.MAX_AGE_REQUEST_UNTIL_FORCED());
        }
    }

    function isWithdrawalRequestForced(
        ExchangeData.State storage S,
        uint numRequestsCommitted
        )
        private
        view
        returns (bool)
    {
        if (numRequestsCommitted == S.withdrawalChain.length) {
            return false;
        } else {
            return S.withdrawalChain[numRequestsCommitted].timestamp < now.sub(
                ExchangeData.MAX_AGE_REQUEST_UNTIL_FORCED());
        }
    }
}

library AddressUtil {
    using AddressUtil for *;

    function isContract(
        address addr
        )
        internal
        view
        returns (bool)
    {
        uint32 size;
        assembly { size := extcodesize(addr) }
        return (size > 0);
    }

    function toPayable(
        address addr
        )
        internal
        pure
        returns (address payable)
    {
        return address(uint160(addr));
    }

    
    
    function sendETH(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        if (amount == 0) {
            return true;
        }
        address payable recipient = to.toPayable();
        
        (success, ) = recipient.call.value(amount).gas(gasLimit)("");
    }

    
    
    function sendETHAndVerify(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        success = to.sendETH(amount, gasLimit);
        require(success, "TRANSFER_FAILURE");
    }
}

library ExchangeTokens {
    using MathUint          for uint;
    using ERC20SafeTransfer for address;
    using ExchangeMode      for ExchangeData.State;

    event TokenRegistered(
        address indexed token,
        uint16  indexed tokenId
    );

    function registerToken(
        ExchangeData.State storage S,
        address tokenAddress
        )
        external
        returns (uint16 tokenID)
    {
        tokenID = registerToken(
            S,
            tokenAddress,
            getLRCFeeForRegisteringOneMoreToken(S)
        );
    }

    function getTokenAddress(
        ExchangeData.State storage S,
        uint16 tokenID
        )
        external
        view
        returns (address)
    {
        require(tokenID < S.tokens.length, "INVALID_TOKEN_ID");
        return S.tokens[tokenID].token;
    }

    function getLRCFeeForRegisteringOneMoreToken(
        ExchangeData.State storage S
        )
        public
        view
        returns (uint feeLRC)
    {
        return S.loopring.tokenRegistrationFeeLRCBase().add(
            S.loopring.tokenRegistrationFeeLRCDelta().mul(S.tokens.length)
        );
    }

    function registerToken(
        ExchangeData.State storage S,
        address tokenAddress,
        uint    amountToBurn
        )
        public
        returns (uint16 tokenID)
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(S.tokenToTokenId[tokenAddress] == 0, "TOKEN_ALREADY_EXIST");
        require(S.tokens.length < ExchangeData.MAX_NUM_TOKENS(), "TOKEN_REGISTRY_FULL");

        if (amountToBurn > 0) {
            address feeVault = S.loopring.protocolFeeVault();
            S.lrcAddress.safeTransferFromAndVerify(msg.sender, feeVault, amountToBurn);
        }

        ExchangeData.Token memory token = ExchangeData.Token(tokenAddress, false);
        S.tokens.push(token);
        tokenID = uint16(S.tokens.length - 1);
        S.tokenToTokenId[tokenAddress] = tokenID + 1;

        emit TokenRegistered(tokenAddress, tokenID);
    }

    function getTokenID(
        ExchangeData.State storage S,
        address tokenAddress
        )
        public
        view
        returns (uint16 tokenID)
    {
        tokenID = S.tokenToTokenId[tokenAddress];
        require(tokenID != 0, "TOKEN_NOT_FOUND");
        tokenID = tokenID - 1;
    }

    function disableTokenDeposit(
        ExchangeData.State storage S,
        address tokenAddress
        )
        external
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        require(tokenAddress != address(0), "ETHER_CANNOT_BE_DISABLED");
        require(tokenAddress != S.loopring.wethAddress(), "WETH_CANNOT_BE_DISABLED");
        require(tokenAddress != S.loopring.lrcAddress(), "LRC_CANNOT_BE_DISABLED");

        uint16 tokenID = getTokenID(S, tokenAddress);
        ExchangeData.Token storage token = S.tokens[tokenID];
        require(!token.depositDisabled, "TOKEN_DEPOSIT_ALREADY_DISABLED");
        token.depositDisabled = true;
    }

    function enableTokenDeposit(
        ExchangeData.State storage S,
        address tokenAddress
        )
        external
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        uint16 tokenID = getTokenID(S, tokenAddress);
        ExchangeData.Token storage token = S.tokens[tokenID];
        require(token.depositDisabled, "TOKEN_DEPOSIT_ALREADY_ENABLED");
        token.depositDisabled = false;
    }
}

library ExchangeDeposits {
    using AddressUtil       for address payable;
    using MathUint          for uint;
    using ERC20SafeTransfer for address;
    using ExchangeAccounts  for ExchangeData.State;
    using ExchangeMode      for ExchangeData.State;
    using ExchangeTokens    for ExchangeData.State;

    event DepositRequested(
        uint    indexed depositIdx,
        uint24  indexed accountID,
        uint16  indexed tokenID,
        uint96          amount,
        uint            pubKeyX,
        uint            pubKeyY
    );

    function getDepositRequest(
        ExchangeData.State storage S,
        uint index
        )
        external
        view
        returns (
          bytes32 accumulatedHash,
          uint    accumulatedFee,
          uint32  timestamp
        )
    {
        require(index < S.depositChain.length, "INVALID_INDEX");
        ExchangeData.Request storage request = S.depositChain[index];
        accumulatedHash = request.accumulatedHash;
        accumulatedFee = request.accumulatedFee;
        timestamp = request.timestamp;
    }

    function depositTo(
        ExchangeData.State storage S,
        address recipient,
        address tokenAddress,
        uint96  amount,  
        uint    additionalFeeETH
        )
        external
    {
        require(recipient != address(0), "ZERO_ADDRESS");
        require(S.areUserRequestsEnabled(), "USER_REQUEST_SUSPENDED");
        require(getNumAvailableDepositSlots(S) > 0, "TOO_MANY_REQUESTS_OPEN");

        uint16 tokenID = S.getTokenID(tokenAddress);
        require(!S.tokens[tokenID].depositDisabled, "TOKEN_DEPOSIT_DISABLED");

        uint24 accountID = S.getAccountID(recipient);
        ExchangeData.Account storage account = S.accounts[accountID];

        
        
        
        
        require(account.pubKeyX > 0, "INVALID_PUBKEY");
        
        require(account.pubKeyX < ExchangeData.SNARK_SCALAR_FIELD(), "INVALID_PUBKEY");
        require(account.pubKeyY < ExchangeData.SNARK_SCALAR_FIELD(), "INVALID_PUBKEY");

        
        uint feeETH = additionalFeeETH.add(S.depositFeeETH);

        
        transferDeposit(
            msg.sender,
            tokenAddress,
            amount,
            feeETH
        );

        
        ExchangeData.Request storage prevRequest = S.depositChain[S.depositChain.length - 1];
        ExchangeData.Request memory request = ExchangeData.Request(
            sha256(
                abi.encodePacked(
                    prevRequest.accumulatedHash,
                    accountID,
                    account.pubKeyX,  
                                      
                                      
                                      
                    account.pubKeyY,
                    uint8(tokenID),
                    amount
                )
            ),
            prevRequest.accumulatedFee.add(feeETH),
            uint32(now)
        );
        S.depositChain.push(request);

        
        ExchangeData.Deposit memory _deposit = ExchangeData.Deposit(
            accountID,
            tokenID,
            amount
        );
        S.deposits.push(_deposit);

        S.tokenBalances[tokenAddress] = S.tokenBalances[tokenAddress].add(amount);

        emit DepositRequested(
            uint32(S.depositChain.length - 1),
            accountID,
            tokenID,
            amount,
            account.pubKeyX,
            account.pubKeyY
        );
    }

    function getNumDepositRequestsProcessed(
        ExchangeData.State storage S
        )
        public
        view
        returns (uint)
    {
        ExchangeData.Block storage currentBlock = S.blocks[S.blocks.length - 1];
        return currentBlock.numDepositRequestsCommitted;
    }

    function getNumAvailableDepositSlots(
        ExchangeData.State storage S
        )
        public
        view
        returns (uint)
    {
        uint numOpenRequests = S.depositChain.length - getNumDepositRequestsProcessed(S);
        return ExchangeData.MAX_OPEN_DEPOSIT_REQUESTS() - numOpenRequests;
    }

    function transferDeposit(
        address source,
        address tokenAddress,
        uint    amount,
        uint    feeETH
        )
        private
    {
        uint totalRequiredETH = feeETH;
        if (tokenAddress == address(0)) {
            totalRequiredETH = totalRequiredETH.add(amount);
        }

        require(msg.value >= totalRequiredETH, "INSUFFICIENT_FEE");
        uint feeSurplus = msg.value.sub(totalRequiredETH);
        if (feeSurplus > 0) {
            msg.sender.sendETHAndVerify(feeSurplus, gasleft());
        }

        
        if (amount > 0 && tokenAddress != address(0)) {
            tokenAddress.safeTransferFromAndVerify(
                source,
                address(this),
                amount
            );
        }
    }
}

library ExchangeGenesis {
    using ExchangeAccounts  for ExchangeData.State;
    using ExchangeTokens    for ExchangeData.State;

    function initializeGenesisBlock(
        ExchangeData.State storage S,
        uint    _id,
        address _loopringAddress,
        address payable _operator,
        bool    _onchainDataAvailability,
        bytes32 _genesisBlockHash
        )
        external
    {
        require(0 != _id, "INVALID_ID");
        require(address(0) != _loopringAddress, "ZERO_ADDRESS");
        require(address(0) != _operator, "ZERO_ADDRESS");
        require(_genesisBlockHash != 0, "ZERO_GENESIS_BLOCK_HASH");
        require(S.id == 0, "INITIALIZED_ALREADY");

        S.id = _id;
        S.exchangeCreationTimestamp = now;
        S.loopring = ILoopringV3(_loopringAddress);
        S.operator = _operator;
        S.onchainDataAvailability = _onchainDataAvailability;

        ILoopringV3 loopring = ILoopringV3(_loopringAddress);
        S.blockVerifier = IBlockVerifier(loopring.blockVerifierAddress());
        S.lrcAddress = loopring.lrcAddress();

        ExchangeData.Block memory genesisBlock = ExchangeData.Block(
            _genesisBlockHash,
            0x0,
            ExchangeData.BlockState.VERIFIED,
            ExchangeData.BlockType(0),
            0,
            0,
            uint32(now),
            1,
            1,
            true,
            0,
            new bytes(0)
        );
        S.blocks.push(genesisBlock);
        S.numBlocksFinalized = 1;

        ExchangeData.Request memory genesisRequest = ExchangeData.Request(
            0,
            0,
            0xFFFFFFFF
        );
        S.depositChain.push(genesisRequest);
        S.withdrawalChain.push(genesisRequest);

        
        
        ExchangeData.Account memory protocolFeePoolAccount = ExchangeData.Account(
            address(0),
            uint(0),
            uint(0)
        );

        S.accounts.push(protocolFeePoolAccount);
        S.ownerToAccountId[protocolFeePoolAccount.owner] = uint24(S.accounts.length);

        
        S.protocolFeeData.timestamp = uint32(0);
        S.protocolFeeData.takerFeeBips = S.loopring.maxProtocolTakerFeeBips();
        S.protocolFeeData.makerFeeBips = S.loopring.maxProtocolMakerFeeBips();
        S.protocolFeeData.previousTakerFeeBips = S.protocolFeeData.takerFeeBips;
        S.protocolFeeData.previousMakerFeeBips = S.protocolFeeData.makerFeeBips;

        
        S.registerToken(address(0), 0);
        S.registerToken(loopring.wethAddress(), 0);
        S.registerToken(S.lrcAddress, 0);
    }
}

library ExchangeWithdrawals {
    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using MathUint          for uint;
    using ERC20SafeTransfer for address;
    using ExchangeAccounts  for ExchangeData.State;
    using ExchangeBalances  for ExchangeData.State;
    using ExchangeMode      for ExchangeData.State;
    using ExchangeTokens    for ExchangeData.State;

    event BlockFeeWithdrawn(
        uint    indexed blockIdx,
        uint            amount
    );

    event WithdrawalRequested(
        uint    indexed withdrawalIdx,
        uint24  indexed accountID,
        uint16  indexed tokenID,
        uint96          amount
    );

    event WithdrawalCompleted(
        uint24  indexed accountID,
        uint16  indexed tokenID,
        address         to,
        uint96          amount
    );

    event WithdrawalFailed(
        uint24  indexed accountID,
        uint16  indexed tokenID,
        address         to,
        uint96          amount
    );

    function getWithdrawRequest(
        ExchangeData.State storage S,
        uint index
        )
        external
        view
        returns (
            bytes32 accumulatedHash,
            uint    accumulatedFee,
            uint32  timestamp
        )
    {
        require(index < S.withdrawalChain.length, "INVALID_INDEX");
        ExchangeData.Request storage request = S.withdrawalChain[index];
        accumulatedHash = request.accumulatedHash;
        accumulatedFee = request.accumulatedFee;
        timestamp = request.timestamp;
    }

    function withdraw(
        ExchangeData.State storage S,
        uint24  accountID,
        address token,
        uint96  amount
        )
        external
    {
        require(amount > 0, "ZERO_VALUE");
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(S.areUserRequestsEnabled(), "USER_REQUEST_SUSPENDED");
        require(getNumAvailableWithdrawalSlots(S) > 0, "TOO_MANY_REQUESTS_OPEN");

        uint16 tokenID = S.getTokenID(token);

        
        require(msg.value >= S.withdrawalFeeETH, "INSUFFICIENT_FEE");

        
        uint feeSurplus = msg.value.sub(S.withdrawalFeeETH);
        if (feeSurplus > 0) {
            msg.sender.sendETHAndVerify(feeSurplus, gasleft());
        }

        
        ExchangeData.Request storage prevRequest = S.withdrawalChain[S.withdrawalChain.length - 1];
        ExchangeData.Request memory request = ExchangeData.Request(
            sha256(
                abi.encodePacked(
                    prevRequest.accumulatedHash,
                    accountID,
                    uint8(tokenID),
                    amount
                )
            ),
            prevRequest.accumulatedFee.add(S.withdrawalFeeETH),
            uint32(now)
        );
        S.withdrawalChain.push(request);

        emit WithdrawalRequested(
            uint32(S.withdrawalChain.length - 1),
            accountID,
            tokenID,
            amount
        );
    }

    
    function withdrawFromMerkleTreeFor(
        ExchangeData.State storage S,
        address  owner,
        address  token,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] calldata accountMerkleProof,
        uint[12] calldata balanceMerkleProof
        )
        external
    {
        require(S.isInWithdrawalMode(), "NOT_IN_WITHDRAW_MODE");

        ExchangeData.Block storage lastFinalizedBlock = S.blocks[S.numBlocksFinalized - 1];

        uint24 accountID = S.getAccountID(owner);
        uint16 tokenID = S.getTokenID(token);
        require(S.withdrawnInWithdrawMode[owner][token] == false, "WITHDRAWN_ALREADY");

        ExchangeBalances.verifyAccountBalance(
            uint(lastFinalizedBlock.merkleRoot),
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

        
        S.withdrawnInWithdrawMode[owner][token] = true;

        
        transferTokens(
            S,
            accountID,
            tokenID,
            balance,
            false
        );
    }

    function getNumWithdrawalRequestsProcessed(
        ExchangeData.State storage S
        )
        public
        view
        returns (uint)
    {
        ExchangeData.Block storage currentBlock = S.blocks[S.blocks.length - 1];
        return currentBlock.numWithdrawalRequestsCommitted;
    }

    function getNumAvailableWithdrawalSlots(
        ExchangeData.State storage S
        )
        public
        view
        returns (uint)
    {
        uint numOpenRequests = S.withdrawalChain.length - getNumWithdrawalRequestsProcessed(S);
        return ExchangeData.MAX_OPEN_WITHDRAWAL_REQUESTS() - numOpenRequests;
    }

    function withdrawFromDepositRequest(
        ExchangeData.State storage S,
        uint depositIdx
        )
        external
    {
        require(S.isInWithdrawalMode(), "NOT_IN_WITHDRAW_MODE");

        ExchangeData.Block storage lastFinalizedBlock = S.blocks[S.numBlocksFinalized - 1];
        require(depositIdx >= lastFinalizedBlock.numDepositRequestsCommitted, "REQUEST_INCLUDED_IN_FINALIZED_BLOCK");

        
        ExchangeData.Deposit storage _deposit = S.deposits[depositIdx.sub(1)];

        uint amount = _deposit.amount;
        require(amount > 0, "WITHDRAWN_ALREADY");

        
        _deposit.amount = 0;

        
        transferTokens(
            S,
            _deposit.accountID,
            _deposit.tokenID,
            amount,
            false
        );
    }

    function withdrawFromApprovedWithdrawal(
        ExchangeData.State storage S,
        uint blockIdx,
        ExchangeData.Block storage withdrawBlock,
        uint slotIdx,
        bool allowFailure
        )
        public
        returns (bool success)
    {
        require(slotIdx < withdrawBlock.blockSize, "INVALID_SLOT_IDX");
        
        require(blockIdx < S.numBlocksFinalized, "BLOCK_NOT_FINALIZED");

        
        uint[] memory slice = new uint[](2);
        uint slot = (7 * slotIdx) / 32;
        uint offset = (7 * (slotIdx + 1)) - (slot * 32);
        uint sc = 0;
        uint data = 0;
        
        if (withdrawBlock.withdrawals.length >= 32) {
            bytes storage withdrawals = withdrawBlock.withdrawals;
            uint dataSlot1 = 0;
            uint dataSlot2 = 0;
            assembly {
                
                mstore(0x0, withdrawals_slot)
                sc := keccak256(0x0, 0x20)
                dataSlot1 := sload(add(sc, slot))
                dataSlot2 := sload(add(sc, add(slot, 1)))
            }
            
            
            slice[0] = dataSlot1;
            slice[1] = dataSlot2;
            assembly {
                data := mload(add(slice, offset))
            }
        } else {
            bytes memory mWithdrawals = withdrawBlock.withdrawals;
            assembly {
                data := mload(add(mWithdrawals, offset))
            }
        }

        
        uint16 tokenID = uint16((data >> 48) & 0xFF);
        uint24 accountID = uint24((data >> 28) & 0xFFFFF);
        uint amount = (data & 0xFFFFFFF).decodeFloat();

        
        success = transferTokens(
            S,
            accountID,
            tokenID,
            amount,
            allowFailure
        );

        if (success && amount > 0) {
            
            data = data & uint(~((1 << (7 * 8)) - 1));

            
            if (withdrawBlock.withdrawals.length >= 32) {
                assembly {
                    mstore(add(slice, offset), data)
                }
                uint dataSlot1 = slice[0];
                uint dataSlot2 = slice[1];
                assembly {
                    sstore(add(sc, slot), dataSlot1)
                    sstore(add(sc, add(slot, 1)), dataSlot2)
                }
            } else {
                bytes memory mWithdrawals = withdrawBlock.withdrawals;
                assembly {
                    mstore(add(mWithdrawals, offset), data)
                }
                withdrawBlock.withdrawals = mWithdrawals;
            }
        }
    }

    function withdrawBlockFee(
        ExchangeData.State storage S,
        uint blockIdx,
        address payable feeRecipient
        )
        external
        returns (uint feeAmountToOperator)
    {
        require(blockIdx > 0 && blockIdx < S.blocks.length, "INVALID_BLOCK_IDX");
        ExchangeData.Block storage requestedBlock = S.blocks[blockIdx];
        ExchangeData.Block storage previousBlock = S.blocks[blockIdx - 1];

        require(blockIdx < S.numBlocksFinalized, "BLOCK_NOT_FINALIZED");
        require(requestedBlock.blockFeeWithdrawn == false, "FEE_WITHDRAWN_ALREADY");

        uint feeAmount = 0;
        uint32 lastRequestTimestamp = 0;
        {
        uint startIndex = previousBlock.numDepositRequestsCommitted;
        uint endIndex = requestedBlock.numDepositRequestsCommitted;
        if(endIndex > startIndex) {
            feeAmount = S.depositChain[endIndex - 1].accumulatedFee.sub(
                S.depositChain[startIndex - 1].accumulatedFee
            );
            lastRequestTimestamp = S.depositChain[endIndex - 1].timestamp;
        } else {
            startIndex = previousBlock.numWithdrawalRequestsCommitted;
            endIndex = requestedBlock.numWithdrawalRequestsCommitted;

            if(endIndex > startIndex) {
                feeAmount = S.withdrawalChain[endIndex - 1].accumulatedFee.sub(
                    S.withdrawalChain[startIndex - 1].accumulatedFee
                );
                lastRequestTimestamp = S.withdrawalChain[endIndex - 1].timestamp;
            } else {
                revert("BLOCK_HAS_NO_OPERATOR_FEE");
            }
        }
        }

        
        
        
        
        
        
        uint32 blockTimestamp = requestedBlock.timestamp;
        uint32 startTime = lastRequestTimestamp + ExchangeData.FEE_BLOCK_FINE_START_TIME();
        uint fine = 0;
        if (blockTimestamp > startTime) {
            fine = feeAmount.mul(blockTimestamp - startTime) / ExchangeData.FEE_BLOCK_FINE_MAX_DURATION();
        }
        uint feeAmountToBurn = (fine > feeAmount) ? feeAmount : fine;
        feeAmountToOperator = feeAmount - feeAmountToBurn;

        
        requestedBlock.blockFeeWithdrawn = true;

        
        S.loopring.protocolFeeVault().sendETHAndVerify(feeAmountToBurn, gasleft());
        
        feeRecipient.sendETHAndVerify(feeAmountToOperator, gasleft());

        emit BlockFeeWithdrawn(blockIdx, feeAmount);
    }

    function distributeWithdrawals(
        ExchangeData.State storage S,
        uint blockIdx,
        uint maxNumWithdrawals
        )
        external
    {
        require(blockIdx < S.blocks.length, "INVALID_BLOCK_IDX");
        require(maxNumWithdrawals > 0, "INVALID_MAX_NUM_WITHDRAWALS");
        ExchangeData.Block storage withdrawBlock = S.blocks[blockIdx];

        
        require(
            withdrawBlock.blockType == ExchangeData.BlockType.ONCHAIN_WITHDRAWAL ||
            withdrawBlock.blockType == ExchangeData.BlockType.OFFCHAIN_WITHDRAWAL,
            "INVALID_BLOCK_TYPE"
        );

        
        require(blockIdx < S.numBlocksFinalized, "BLOCK_NOT_FINALIZED");
        
        require(withdrawBlock.numWithdrawalsDistributed < withdrawBlock.blockSize, "WITHDRAWALS_ALREADY_DISTRIBUTED");

        
        
        bool bOnlyOperator = now < withdrawBlock.timestamp + ExchangeData.MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS();
        if (bOnlyOperator) {
            require(msg.sender == S.operator, "UNAUTHORIZED");
        }

        
        uint start = withdrawBlock.numWithdrawalsDistributed;
        uint end = start.add(maxNumWithdrawals);
        if (end > withdrawBlock.blockSize) {
            end = withdrawBlock.blockSize;
        }

        
        uint gasLimit = ExchangeData.MIN_GAS_TO_DISTRIBUTE_WITHDRAWALS();
        uint totalNumWithdrawn = start;
        while (totalNumWithdrawn < end && gasleft() >= gasLimit) {
            
            
            
            withdrawFromApprovedWithdrawal(
                S,
                blockIdx,
                withdrawBlock,
                totalNumWithdrawn,
                true
            );
            totalNumWithdrawn++;
        }
        withdrawBlock.numWithdrawalsDistributed = uint16(totalNumWithdrawn);

        
        if (!bOnlyOperator) {
            
            uint numWithdrawn = totalNumWithdrawn.sub(start);
            uint totalFine = S.loopring.withdrawalFineLRC().mul(numWithdrawn);
            
            uint amountToBurn = totalFine / 2;
            uint amountToDistributer = totalFine - amountToBurn;
            S.loopring.burnExchangeStake(S.id, amountToBurn);
            S.loopring.withdrawExchangeStake(S.id, msg.sender, amountToDistributer);
        }
    }


    

    
    
    
    
    
    function transferTokens(
        ExchangeData.State storage S,
        uint24  accountID,
        uint16  tokenID,
        uint    amount,
        bool    allowFailure
        )
        private
        returns (bool success)
    {
        
        
        
        
        address to;
        if (accountID == 0 || accountID >= S.accounts.length) {
            to = S.loopring.protocolFeeVault();
        } else {
            to = S.accounts[accountID].owner;
        }

        address token = S.getTokenAddress(tokenID);
        
        uint gasLimit = allowFailure ? ExchangeData.GAS_LIMIT_SEND_TOKENS() : gasleft();

        
        if (amount > 0) {
            if (token == address(0)) {
                
                success = to.sendETH(amount, gasLimit);
            } else {
                
                success = token.safeTransferWithGasLimit(to, amount, gasLimit);
            }
        } else {
            success = true;
        }

        if (!allowFailure) {
            require(success, "TRANSFER_FAILURE");
        }

        if (success) {
            if (amount > 0) {
                S.tokenBalances[token] = S.tokenBalances[token].sub(amount);
            }

            if (accountID > 0 || tokenID > 0 || amount > 0) {
                
                
                emit WithdrawalCompleted(
                    accountID,
                    tokenID,
                    to,
                    uint96(amount)
                );
            }
        } else {
            emit WithdrawalFailed(
                accountID,
                tokenID,
                to,
                uint96(amount)
            );
        }
    }
}

library Cloneable {
    function clone(address a)
        external
        returns (address)
    {

    
        address retval;
        assembly{
            mstore(0x0, or (0x5880730000000000000000000000000000000000000000803b80938091923cF3 ,mul(a,0x1000000000000000000)))
            retval := create(0,0, 32)
        }
        return retval;
    }
}

contract IExchange is Claimable, ReentrancyGuard
{
    string constant public version = ""; 

    event Cloned (address indexed clone);

    
    
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

contract IExchangeV3 is IExchange
{
    
    
    
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

    event TokenRegistered(
        address indexed token,
        uint16  indexed tokenId
    );

    event OperatorChanged(
        uint    indexed exchangeId,
        address         oldOperator,
        address         newOperator
    );

    event AddressWhitelistChanged(
        uint    indexed exchangeId,
        address         oldAddressWhitelist,
        address         newAddressWhitelist
    );

    event FeesUpdated(
        uint    indexed exchangeId,
        uint            accountCreationFeeETH,
        uint            accountUpdateFeeETH,
        uint            depositFeeETH,
        uint            withdrawalFeeETH
    );

    event Shutdown(
        uint            timestamp
    );

    event BlockCommitted(
        uint    indexed blockIdx,
        bytes32 indexed publicDataHash
    );

    event BlockVerified(
        uint    indexed blockIdx
    );

    event BlockFinalized(
        uint    indexed blockIdx
    );

    event Revert(
        uint    indexed blockIdx
    );

    event DepositRequested(
        uint    indexed depositIdx,
        uint24  indexed accountID,
        uint16  indexed tokenID,
        uint96          amount,
        uint            pubKeyX,
        uint            pubKeyY
    );

    event BlockFeeWithdrawn(
        uint    indexed blockIdx,
        uint            amount
    );

    event WithdrawalRequested(
        uint    indexed withdrawalIdx,
        uint24  indexed accountID,
        uint16  indexed tokenID,
        uint96          amount
    );

    event WithdrawalCompleted(
        uint24  indexed accountID,
        uint16  indexed tokenID,
        address         to,
        uint96          amount
    );

    event WithdrawalFailed(
        uint24  indexed accountID,
        uint16  indexed tokenID,
        address         to,
        uint96          amount
    );

    event ProtocolFeesUpdated(
        uint8 takerFeeBips,
        uint8 makerFeeBips,
        uint8 previousTakerFeeBips,
        uint8 previousMakerFeeBips
    );

    event TokenNotOwnedByUsersWithdrawn(
        address sender,
        address token,
        address feeVault,
        uint    amount
    );
    
    
    
    
    
    
    
    
    
    function initialize(
        address loopringAddress,
        address owner,
        uint    exchangeId,
        address payable operator,
        bool    onchainDataAvailability
        )
        external;

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function getConstants()
        external
        pure
        returns(uint[20] memory);

    
    
    
    function isInWithdrawalMode()
        external
        view
        returns (bool);

    
    
    function isShutdown()
        external
        view
        returns (bool);

    
    
    function isInMaintenance()
        external
        view
        returns (bool);

    

    
    
    function getNumAccounts()
        external
        view
        returns (uint);

    
    
    
    
    
    function getAccount(
        address owner
        )
        external
        view
        returns (
            uint24 accountID,
            uint   pubKeyX,
            uint   pubKeyY
        );

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function createOrUpdateAccount(
        uint  pubKeyX,
        uint  pubKeyY,
        bytes calldata permission
        )
        external
        payable
        returns (
            uint24 accountID,
            bool   isAccountNew,
            bool   isAccountUpdated
        );

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function isAccountBalanceCorrect(
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
        returns (bool);

    

    
    
    function getLRCFeeForRegisteringOneMoreToken()
        external
        view
        returns (uint feeLRC);

    
    
    
    
    
    
    
    
    
    
    
    function registerToken(
        address tokenAddress
        )
        external
        returns (uint16 tokenID);

    
    
    
    function getTokenID(
        address tokenAddress
        )
        external
        view
        returns (uint16 tokenID);

    
    
    
    function getTokenAddress(
        uint16 tokenID
        )
        external
        view
        returns (address tokenAddress);

    
    
    
    function disableTokenDeposit(
        address tokenAddress
        )
        external;

    
    
    
    function enableTokenDeposit(
        address tokenAddress
        )
        external;

    
    
    
    
    
    
    
    function getExchangeStake()
        external
        view
        returns (uint);

    
    
    
    
    
    
    
    
    
    function withdrawExchangeStake(
        address recipient
        )
        external
        returns (uint);

    
    
    
    
    function withdrawTokenNotOwnedByUsers(
        address tokenAddress
        )
        external
        returns (uint);

    
    
    
    
    
    function withdrawProtocolFeeStake(
        address recipient,
        uint    amount
        )
        external;

    
    
    
    
    
    function burnExchangeStake()
        external;

    
    
    
    
    function getBlockHeight()
        external
        view
        returns (uint);

    
    
    function getNumBlocksFinalized()
        external
        view
        returns (uint);

    
    
    
    
    
    
    
    
    
    
    
    
    
    function getBlock(
        uint blockIdx
        )
        external
        view
        returns (
            bytes32 merkleRoot,
            bytes32 publicDataHash,
            uint8   blockState,
            uint8   blockType,
            uint16  blockSize,
            uint32  timestamp,
            uint32  numDepositRequestsCommitted,
            uint32  numWithdrawalRequestsCommitted,
            bool    blockFeeWithdrawn,
            uint16  numWithdrawalsDistributed
        );

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function commitBlock(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        bytes  calldata data,
        bytes  calldata offchainData
        )
        external;

    
    
    
    
    
    
    
    
    
    
    
    function verifyBlocks(
        uint[] calldata blockIndices,
        uint[] calldata proofs
        )
        external;

    
    
    
    
    
    
    
    
    
    
    function revertBlock(
        uint blockIdx
        )
        external;

    
    
    
    
    
    function getNumDepositRequestsProcessed()
        external
        view
        returns (uint);

    
    
    function getNumAvailableDepositSlots()
        external
        view
        returns (uint);

    
    
    
    
    
    function getDepositRequest(
        uint index
        )
        external
        view
        returns (
          bytes32 accumulatedHash,
          uint    accumulatedFee,
          uint32  timestamp
        );

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function updateAccountAndDeposit(
        uint    pubKeyX,
        uint    pubKeyY,
        address tokenAddress,
        uint96  amount,
        bytes   calldata permission
        )
        external
        payable
        returns (
            uint24 accountID,
            bool   isAccountNew,
            bool   isAccountUpdated
        );

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function deposit(
        address tokenAddress,
        uint96  amount
        )
        external
        payable;

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function depositTo(
        address recipient,
        address tokenAddress,
        uint96  amount
        )
        external
        payable;

    

    
    
    
    
    function getNumWithdrawalRequestsProcessed()
        external
        view
        returns (uint);

    
    
    function getNumAvailableWithdrawalSlots(
        )
        external
        view
        returns (uint);

    
    
    
    
    
    function getWithdrawRequest(
        uint index
        )
        external
        view
        returns (
            bytes32 accumulatedHash,
            uint    accumulatedFee,
            uint32  timestamp
        );

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function withdraw(
        address tokenAddress,
        uint96  amount
        )
        external
        payable;

    
    
    
    
    
    
    
    
    
    
    function withdrawProtocolFees(
        address tokenAddress
        )
        external
        payable;

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function withdrawFromMerkleTree(
        address  token,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] calldata accountMerkleProof,
        uint[12] calldata balanceMerkleProof
        )
        external;

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function withdrawFromMerkleTreeFor(
        address  owner,
        address  token,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] calldata accountMerkleProof,
        uint[12] calldata balanceMerkleProof
        )
        external;

    
    
    
    
    
    
    
    
    
    
    
    
    function withdrawFromDepositRequest(
        uint depositIdx
        )
        external;

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function withdrawFromApprovedWithdrawal(
        uint blockIdx,
        uint slotIdx
        )
        external;

    
    
    
    
    
    
    
    
    
    
    
    function withdrawBlockFee(
        uint    blockIdx,
        address payable feeRecipient
        )
        external
        returns (uint feeAmount);

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function distributeWithdrawals(
        uint blockIdx,
        uint maxNumWithdrawals
        )
        external;

    

    
    
    
    function setOperator(
        address payable _operator
        )
        external
        returns (address payable oldOperator);

    
    
    
    
    function setAddressWhitelist(
        address _addressWhitelist
        )
        external
        returns (address oldAddressWhitelist);

    
    
    
    
    
    
    function setFees(
        uint _accountCreationFeeETH,
        uint _accountUpdateFeeETH,
        uint _depositFeeETH,
        uint _withdrawalFeeETH
        )
        external;

    
    
    
    
    
    function getFees()
        external
        view
        returns (
            uint _accountCreationFeeETH,
            uint _accountUpdateFeeETH,
            uint _depositFeeETH,
            uint _withdrawalFeeETH
        );

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function startOrContinueMaintenanceMode(
        uint durationMinutes
        )
        external;

    
    
    
    function stopMaintenanceMode()
        external;

    
    
    function getRemainingDowntime()
        external
        view
        returns (uint durationMinutes);

    
    
    function getDowntimeCostLRC(
        uint durationMinutes
        )
        external
        view
        returns (uint costLRC);

    
    
    function getTotalTimeInMaintenanceSeconds()
        external
        view
        returns (uint timeInSeconds);

    
    
    function getExchangeCreationTimestamp()
        external
        view
        returns (uint timestamp);

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    function shutdown()
        external
        returns (bool success);

    
    
    
    
    
    function getRequestStats()
        external
        view
        returns(
            uint numDepositRequestsProcessed,
            uint numAvailableDepositSlots,
            uint numWithdrawalRequestsProcessed,
            uint numAvailableWithdrawalSlots
        );

    
    
    
    
    
    
    function getProtocolFeeValues()
        external
        view
        returns (
            uint32 timestamp,
            uint8 takerFeeBips,
            uint8 makerFeeBips,
            uint8 previousTakerFeeBips,
            uint8 previousMakerFeeBips
        );
}

contract ExchangeV3 is IExchangeV3
{
    string  constant public version = "3.1.1";
    bytes32 constant public genesisBlockHash = 0x2b4827daf74c0ab30deb68b1c337dec40579bb3ff45ce9478288e1a2b83a3a01;

    using ExchangeAdmins        for ExchangeData.State;
    using ExchangeAccounts      for ExchangeData.State;
    using ExchangeBalances      for ExchangeData.State;
    using ExchangeBlocks        for ExchangeData.State;
    using ExchangeDeposits      for ExchangeData.State;
    using ExchangeGenesis       for ExchangeData.State;
    using ExchangeMode          for ExchangeData.State;
    using ExchangeTokens        for ExchangeData.State;
    using ExchangeWithdrawals   for ExchangeData.State;

    ExchangeData.State private state;

    modifier onlyOperator()
    {
        require(msg.sender == state.operator, "UNAUTHORIZED");
        _;
    }

    modifier onlyWhenUninitialized()
    {
        require(owner == address(0) && state.id == 0, "INITIALIZED");
        _;
    }

    
    constructor() public {}

    
    function initialize(
        address _loopringAddress,
        address _owner,
        uint    _id,
        address payable _operator,
        bool    _onchainDataAvailability
        )
        external
        nonReentrant
        onlyWhenUninitialized
    {
        require(address(0) != _owner, "ZERO_ADDRESS");
        owner = _owner;

        state.initializeGenesisBlock(
            _id,
            _loopringAddress,
            _operator,
            _onchainDataAvailability,
            genesisBlockHash
        );
    }

    
    function getConstants()
        external
        pure
        returns(uint[20] memory)
    {
        return [
            uint(ExchangeData.SNARK_SCALAR_FIELD()),
            uint(ExchangeData.MAX_PROOF_GENERATION_TIME_IN_SECONDS()),
            uint(ExchangeData.MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS()),
            uint(ExchangeData.MAX_OPEN_DEPOSIT_REQUESTS()),
            uint(ExchangeData.MAX_OPEN_WITHDRAWAL_REQUESTS()),
            uint(ExchangeData.MAX_AGE_UNFINALIZED_BLOCK_UNTIL_WITHDRAW_MODE()),
            uint(ExchangeData.MAX_AGE_REQUEST_UNTIL_FORCED()),
            uint(ExchangeData.MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE()),
            uint(ExchangeData.MAX_TIME_IN_SHUTDOWN_BASE()),
            uint(ExchangeData.MAX_TIME_IN_SHUTDOWN_DELTA()),
            uint(ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS()),
            uint(ExchangeData.MAX_NUM_TOKENS()),
            uint(ExchangeData.MAX_NUM_ACCOUNTS()),
            uint(ExchangeData.MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS()),
            uint(ExchangeData.MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS_SHUTDOWN_MODE()),
            uint(ExchangeData.FEE_BLOCK_FINE_START_TIME()),
            uint(ExchangeData.FEE_BLOCK_FINE_MAX_DURATION()),
            uint(ExchangeData.MIN_GAS_TO_DISTRIBUTE_WITHDRAWALS()),
            uint(ExchangeData.MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED()),
            uint(ExchangeData.GAS_LIMIT_SEND_TOKENS())
        ];
    }

    
    function isInWithdrawalMode()
        external
        view
        returns (bool)
    {
        return state.isInWithdrawalMode();
    }

    function isShutdown()
        external
        view
        returns (bool)
    {
        return state.isShutdown();
    }

    function isInMaintenance()
        external
        view
        returns (bool)
    {
        return state.isInMaintenance();
    }

    
    function getNumAccounts()
        external
        view
        returns (uint)
    {
        return state.accounts.length;
    }

    function getAccount(
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
        return state.getAccount(owner);
    }

    function createOrUpdateAccount(
        uint  pubKeyX,
        uint  pubKeyY,
        bytes calldata permission
        )
        external
        payable
        nonReentrant
        returns (
            uint24 accountID,
            bool   isAccountNew,
            bool   isAccountUpdated
        )
    {
        return updateAccountAndDepositInternal(
            pubKeyX,
            pubKeyY,
            address(0),
            0,
            permission
        );
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
        uint[30] calldata accountPath,
        uint[12] calldata balancePath
        )
        external
        pure
        returns (bool)
    {
        return ExchangeBalances.isAccountBalanceCorrect(
            merkleRoot,
            accountID,
            tokenID,
            pubKeyX,
            pubKeyY,
            nonce,
            balance,
            tradeHistoryRoot,
            accountPath,
            balancePath
        );
    }

    
    function getLRCFeeForRegisteringOneMoreToken()
        external
        view
        returns (uint)
    {
        return state.getLRCFeeForRegisteringOneMoreToken();
    }

    function registerToken(
        address tokenAddress
        )
        external
        nonReentrant
        onlyOwner
        returns (uint16)
    {
        return state.registerToken(tokenAddress);
    }

    function getTokenID(
        address tokenAddress
        )
        external
        view
        returns (uint16)
    {
        return state.getTokenID(tokenAddress);
    }

    function getTokenAddress(
        uint16 tokenID
        )
        external
        view
        returns (address)
    {
        return state.getTokenAddress(tokenID);
    }

    function disableTokenDeposit(
        address tokenAddress
        )
        external
        nonReentrant
        onlyOwner
    {
        state.disableTokenDeposit(tokenAddress);
    }

    function enableTokenDeposit(
        address tokenAddress
        )
        external
        nonReentrant
        onlyOwner
    {
        state.enableTokenDeposit(tokenAddress);
    }

    
    function getExchangeStake()
        external
        view
        returns (uint)
    {
        return state.loopring.getExchangeStake(state.id);
    }

    function withdrawExchangeStake(
        address recipient
        )
        external
        nonReentrant
        onlyOwner
        returns (uint)
    {
        return state.withdrawExchangeStake(recipient);
    }

    function withdrawTokenNotOwnedByUsers(
        address tokenAddress
        )
        external
        nonReentrant
        returns(uint amount)
    {
        address payable feeVault = state.loopring.protocolFeeVault();
        require(feeVault != address(0), "ZERO_ADDRESS");
        amount = state.withdrawTokenNotOwnedByUsers(tokenAddress, feeVault);
        emit TokenNotOwnedByUsersWithdrawn(msg.sender, tokenAddress, feeVault, amount);
    }

    function withdrawProtocolFeeStake(
        address recipient,
        uint amount
        )
        external
        nonReentrant
        onlyOwner
    {
        state.loopring.withdrawProtocolFeeStake(state.id, recipient, amount);
    }

    function burnExchangeStake()
        external
        nonReentrant
    {
        
        if(state.isInWithdrawalMode()) {
            
            uint stake = state.loopring.getExchangeStake(state.id);
            state.loopring.burnExchangeStake(state.id, stake);
        }
    }

    
    function getBlockHeight()
        external
        view
        returns (uint)
    {
        return state.blocks.length - 1;
    }

    function getNumBlocksFinalized()
        external
        view
        returns (uint)
    {
        return state.numBlocksFinalized - 1;
    }

    function getBlock(
        uint blockIdx
        )
        external
        view
        returns (
            bytes32 merkleRoot,
            bytes32 publicDataHash,
            uint8   blockState,
            uint8   blockType,
            uint16  blockSize,
            uint32  timestamp,
            uint32  numDepositRequestsCommitted,
            uint32  numWithdrawalRequestsCommitted,
            bool    blockFeeWithdrawn,
            uint16  numWithdrawalsDistributed
        )
    {
        require(blockIdx < state.blocks.length, "INVALID_BLOCK_IDX");
        ExchangeData.Block storage specifiedBlock = state.blocks[blockIdx];

        merkleRoot = specifiedBlock.merkleRoot;
        publicDataHash = specifiedBlock.publicDataHash;
        blockState = uint8(specifiedBlock.state);
        blockType = uint8(specifiedBlock.blockType);
        blockSize = specifiedBlock.blockSize;
        timestamp = specifiedBlock.timestamp;
        numDepositRequestsCommitted = specifiedBlock.numDepositRequestsCommitted;
        numWithdrawalRequestsCommitted = specifiedBlock.numWithdrawalRequestsCommitted;
        blockFeeWithdrawn = specifiedBlock.blockFeeWithdrawn;
        numWithdrawalsDistributed = specifiedBlock.numWithdrawalsDistributed;
    }

    function commitBlock(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        bytes  calldata ,
        bytes  calldata offchainData
        )
        external
        nonReentrant
        onlyOperator
    {
        
        bytes4 selector = IDecompressor(0x0).decompress.selector;
        bytes memory decompressed;
        assembly {
          
          
          
          
          
          
          
          let dataOffset := add(calldataload(100), 4)
          let mode := and(calldataload(add(dataOffset, 1)), 0xFF)
          switch mode
          case 0 {
              
              let length := sub(calldataload(dataOffset), 1)

              let data := mload(0x40)
              calldatacopy(add(data, 32), add(dataOffset, 33), length)
              mstore(data, length)
              decompressed := data
              mstore(0x40, add(add(decompressed, length), 32))
          }
          case 1 {
              
              let contractAddress := and(
                calldataload(add(dataOffset, 21)),
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
              let length := sub(calldataload(dataOffset), 21)

              let data := mload(0x40)
              mstore(data, selector)
              mstore(add(data,  4), 32)
              mstore(add(data, 36), length)
              calldatacopy(add(data, 68), add(dataOffset, 53), length)

              let success := call(gas, contractAddress, 0, data, add(68, length), 0x0, 0)
              if eq(success, 0) {
                revert(0, 0)
              }

              returndatacopy(data, 32, sub(returndatasize(), 32))
              decompressed := data
              mstore(0x40, add(add(decompressed, mload(decompressed)), 32))
          }
          default {
              revert(0, 0)
          }
        }
        state.commitBlock(blockType, blockSize, blockVersion, decompressed, offchainData);
    }

    function verifyBlocks(
        uint[] calldata blockIndices,
        uint[] calldata proofs
        )
        external
        nonReentrant
        onlyOperator
    {
        state.verifyBlocks(blockIndices, proofs);
    }

    function revertBlock(
        uint blockIdx
        )
        external
        nonReentrant
        onlyOperator
    {
        state.revertBlock(blockIdx);
    }

    
    function getNumDepositRequestsProcessed()
        external
        view
        returns (uint)
    {
        return state.getNumDepositRequestsProcessed();
    }

    function getNumAvailableDepositSlots()
        external
        view
        returns (uint)
    {
        return state.getNumAvailableDepositSlots();
    }

    function getDepositRequest(
        uint index
        )
        external
        view
        returns (
          bytes32 accumulatedHash,
          uint    accumulatedFee,
          uint32  timestamp
        )
    {
        return state.getDepositRequest(index);
    }

    function updateAccountAndDeposit(
        uint    pubKeyX,
        uint    pubKeyY,
        address token,
        uint96  amount,
        bytes   calldata permission
        )
        external
        payable
        nonReentrant
        returns (
            uint24 accountID,
            bool   isAccountNew,
            bool   isAccountUpdated
        )
    {
        return updateAccountAndDepositInternal(
            pubKeyX,
            pubKeyY,
            token,
            amount,
            permission
        );
    }

    function deposit(
        address token,
        uint96  amount
        )
        external
        payable
        nonReentrant
    {
        state.depositTo(msg.sender, token, amount, 0);
    }

    function depositTo(
        address recipient,
        address tokenAddress,
        uint96  amount
        )
        external
        payable
        nonReentrant
    {
        state.depositTo(recipient, tokenAddress, amount, 0);
    }

    
    function getNumWithdrawalRequestsProcessed()
        external
        view
        returns (uint)
    {
        return state.getNumWithdrawalRequestsProcessed();
    }

    function getNumAvailableWithdrawalSlots()
        external
        view
        returns (uint)
    {
        return state.getNumAvailableWithdrawalSlots();
    }

    function getWithdrawRequest(
        uint index
        )
        external
        view
        returns (
            bytes32 accumulatedHash,
            uint    accumulatedFee,
            uint32  timestamp
        )
    {
        return state.getWithdrawRequest(index);
    }

    function withdraw(
        address token,
        uint96 amount
        )
        external
        payable
        nonReentrant
    {
        uint24 accountID = state.getAccountID(msg.sender);
        state.withdraw(accountID, token, amount);
    }

    function withdrawProtocolFees(
        address token
        )
        external
        payable
        nonReentrant
    {
        
        state.withdraw(0, token, ~uint96(0));
    }

    function withdrawFromMerkleTree(
        address  token,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] calldata accountPath,
        uint[12] calldata balancePath
        )
        external
        nonReentrant
    {
        state.withdrawFromMerkleTreeFor(
            msg.sender,
            token,
            pubKeyX,
            pubKeyY,
            nonce,
            balance,
            tradeHistoryRoot,
            accountPath,
            balancePath
        );
    }

    
    function withdrawFromMerkleTreeFor(
        address  owner,
        address  token,
        uint     pubKeyX,
        uint     pubKeyY,
        uint32   nonce,
        uint96   balance,
        uint     tradeHistoryRoot,
        uint[30] calldata accountPath,
        uint[12] calldata balancePath
        )
        external
        nonReentrant
    {
        state.withdrawFromMerkleTreeFor(
            owner,
            token,
            pubKeyX,
            pubKeyY,
            nonce,
            balance,
            tradeHistoryRoot,
            accountPath,
            balancePath
        );
    }

    function withdrawFromDepositRequest(
        uint depositIdx
        )
        external
        nonReentrant
    {
        state.withdrawFromDepositRequest(depositIdx);
    }

    function withdrawFromApprovedWithdrawal(
        uint blockIdx,
        uint slotIdx
        )
        external
        nonReentrant
    {
        require(blockIdx < state.blocks.length, "INVALID_BLOCK_IDX");
        ExchangeData.Block storage withdrawBlock = state.blocks[blockIdx];
        state.withdrawFromApprovedWithdrawal(
            blockIdx,
            withdrawBlock,
            slotIdx,
            false
        );
    }

    function withdrawBlockFee(
        uint blockIdx,
        address payable feeRecipient
        )
        external
        nonReentrant
        onlyOperator
        returns (uint)
    {
        return state.withdrawBlockFee(blockIdx, feeRecipient);
    }

    function distributeWithdrawals(
        uint blockIdx,
        uint maxNumWithdrawals
        )
        external
        nonReentrant
    {
        state.distributeWithdrawals(blockIdx, maxNumWithdrawals);
    }

    
    function setOperator(
        address payable _operator
        )
        external
        nonReentrant
        onlyOwner
        returns (address payable)
    {
        return state.setOperator(_operator);
    }

    function setAddressWhitelist(
        address _addressWhitelist
        )
        external
        nonReentrant
        onlyOwner
        returns (address)
    {
        return state.setAddressWhitelist(_addressWhitelist);
    }

    function setFees(
        uint _accountCreationFeeETH,
        uint _accountUpdateFeeETH,
        uint _depositFeeETH,
        uint _withdrawalFeeETH
        )
        external
        nonReentrant
        onlyOwner
    {
        state.setFees(
            _accountCreationFeeETH,
            _accountUpdateFeeETH,
            _depositFeeETH,
            _withdrawalFeeETH
        );
    }

    function getFees()
        external
        view
        returns (
            uint _accountCreationFeeETH,
            uint _accountUpdateFeeETH,
            uint _depositFeeETH,
            uint _withdrawalFeeETH
        )
    {
        _accountCreationFeeETH = state.accountCreationFeeETH;
        _accountUpdateFeeETH = state.accountUpdateFeeETH;
        _depositFeeETH = state.depositFeeETH;
        _withdrawalFeeETH = state.withdrawalFeeETH;
    }

    function startOrContinueMaintenanceMode(
        uint durationMinutes
        )
        external
        nonReentrant
        onlyOwner
    {
        state.startOrContinueMaintenanceMode(durationMinutes);
    }

    function stopMaintenanceMode()
        external
        nonReentrant
        onlyOwner
    {
        state.stopMaintenanceMode();
    }

    function getRemainingDowntime()
        external
        view
        returns (uint)
    {
        return state.getRemainingDowntime();
    }

    function getDowntimeCostLRC(
        uint durationMinutes
        )
        external
        view
        returns (uint costLRC)
    {
        return state.getDowntimeCostLRC(durationMinutes);
    }

    function getTotalTimeInMaintenanceSeconds()
        external
        view
        returns (uint)
    {
        return state.getTotalTimeInMaintenanceSeconds();
    }

    function getExchangeCreationTimestamp()
        external
        view
        returns (uint)
    {
        return state.exchangeCreationTimestamp;
    }

    function shutdown()
        external
        nonReentrant
        onlyOwner
        returns (bool success)
    {
        require(!state.isInWithdrawalMode(), "INVALID_MODE");
        require(!state.isShutdown(), "ALREADY_SHUTDOWN");
        state.shutdownStartTime = now;
        emit Shutdown(state.shutdownStartTime);
        return true;
    }

    function getRequestStats()
        external
        view
        returns(
            uint numDepositRequestsProcessed,
            uint numAvailableDepositSlots,
            uint numWithdrawalRequestsProcessed,
            uint numAvailableWithdrawalSlots
        )
    {
        numDepositRequestsProcessed = state.getNumDepositRequestsProcessed();
        numAvailableDepositSlots = state.getNumAvailableDepositSlots();
        numWithdrawalRequestsProcessed = state.getNumWithdrawalRequestsProcessed();
        numAvailableWithdrawalSlots = state.getNumAvailableWithdrawalSlots();
    }

    function getProtocolFeeValues()
        external
        view
        returns (
            uint32 timestamp,
            uint8  takerFeeBips,
            uint8  makerFeeBips,
            uint8  previousTakerFeeBips,
            uint8  previousMakerFeeBips
        )
    {
        timestamp = state.protocolFeeData.timestamp;
        takerFeeBips = state.protocolFeeData.takerFeeBips;
        makerFeeBips = state.protocolFeeData.makerFeeBips;
        previousTakerFeeBips = state.protocolFeeData.previousTakerFeeBips;
        previousMakerFeeBips = state.protocolFeeData.previousMakerFeeBips;
    }

    
    function updateAccountAndDepositInternal(
        uint    pubKeyX,
        uint    pubKeyY,
        address token,
        uint96  amount,
        bytes   memory permission
        )
        internal
        returns (
            uint24 accountID,
            bool   isAccountNew,
            bool   isAccountUpdated
        )
    {
        (accountID, isAccountNew, isAccountUpdated) = state.createOrUpdateAccount(
            pubKeyX,
            pubKeyY,
            permission
        );
        uint additionalFeeETH = 0;
        if (isAccountNew) {
            additionalFeeETH = state.accountCreationFeeETH;
        } else if (isAccountUpdated) {
            additionalFeeETH = state.accountUpdateFeeETH;
        }
        state.depositTo(msg.sender, token, amount, additionalFeeETH);
    }
}
