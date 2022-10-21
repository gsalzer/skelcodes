/**
 *Submitted for verification at Etherscan.io on 2019-09-23
*/
pragma solidity >=0.4.22 <0.6.0;
import './safemath.sol';
/**
 * @title -EV5.Win- v0.5.11
 * ╔═╗┌─┐┬ ┬┬─┐┌─┐┌─┐┌─┐  ┌─┐┌┐┌┌┬┐  ┬ ┬┬┌─┐┌┬┐┌─┐┌┬┐  ┌─┐┬─┐┌─┐  ┌┬┐┬ ┬┌─┐  ┌┐ ┌─┐┌─┐┌┬┐  ┬ ┬┌─┐┌─┐┬  ┌┬┐┬ ┬
 * ║  │ ││ │├┬┘├─┤│ ┬├┤   ├─┤│││ ││  ││││└─┐ │││ ││││  ├─┤├┬┘├┤    │ ├─┤├┤   ├┴┐├┤ └─┐ │   │││├┤ ├─┤│   │ ├─┤
 * ╚═╝└─┘└─┘┴└─┴ ┴└─┘└─┘  ┴ ┴┘└┘─┴┘  └┴┘┴└─┘─┴┘└─┘┴ ┴  ┴ ┴┴└─└─┘   ┴ ┴ ┴└─┘  └─┘└─┘└─┘ ┴   └┴┘└─┘┴ ┴┴─┘ ┴ ┴ ┴
 *
 * ==('-.==========(`-. ====================(`\ .-') /`===============.-') _====================================
 * _(  OO)      _(OO  )_                  `.( OO ),'              ( OO ) )
 * (,------. ,--(_/   ,. \.------.      ,--./  .--.    ,-.-')  ,--./ ,--,'
 *  |  .---' \   \   /(__/|   ___|      |      |  |    |  |OO) |   \ |  |\
 *  |  |      \   \ /   / |  '--.       |  |   |  |,   |  |  \ |    \|  | )
 * (|  '--.    \   '   /, `---.  '.     |  |.'.|  |_)  |  |(_/ |  .     |/
 *  |  .--'     \     /__).-   |  |     |         |   ,|  |_.' |  |\    |
 *  |  `---.     \   /    | `-'   / .-. |   ,'.   |  (_|  |    |  | \   |          © Cargo Keep Team Inc. 2019
 *  `------'      `-'      `----''  `-' '--'   '--'    `--'    `--'  `--'
 * =============================================================================================================
*/
contract Vendor {
    uint ethWei = 1 ether;
    uint public trustRo = 5;
    uint public feeRo = 35;
    uint public maxCoin = 30;
    using SafeMath for *;
    //getlv
    function getLv(uint _value) external view returns(uint){
        if(_value >= 1*ethWei && _value <= 5*ethWei){
            return 1;
        }if(_value >= 6*ethWei && _value <= 10*ethWei){
            return 2;
        }if(_value>= 11*ethWei && _value <= 15*ethWei){
            return 3;
        }if(_value >= 16*ethWei && _value <= 30*ethWei){
            return 4;
        }
        return 0;
    }
    //getQueueLv
    function getQueueLv(uint _value) external view returns(uint){
        if(_value >= 1*ethWei && _value <= 5*ethWei){
            return 1;
        }if(_value >= 6*ethWei && _value <= 10*ethWei){
            return 2;
        }if(_value >= 11*ethWei && _value <= 15*ethWei){
            return 3;
        }if(_value >= 16*ethWei && _value <= 29*ethWei){
            return 4;
        }if(_value == 30*ethWei){
            return 5;
        }
        return 0;
    }

    //level-bonus ratio/1000
    function getBonusRo(uint _level) external pure returns(uint){
        if(_level == 1){
            return 5;
        }if(_level == 2){
            return 6;
        }if(_level == 3){
            return 10;
        }if(_level ==4){
            return 10;
        }
        return 0;
    }

    //level-fired ratio/10
    function getFireRo(uint _linelevel) external pure returns(uint){
        if(_linelevel == 1){
            return 2;
        }if(_linelevel == 2){
            return 4;
        }if(_linelevel == 3) {
            return 6;
        }if(_linelevel == 4){
            return 5;
        }
        return 0;
    }

    //params:_level & _era => Invite Ratio/1000
    function getReferRo(uint _linelevel,uint _era) external pure returns(uint){
        if(_linelevel == 1 && _era == 1){
            return 500;
        }if(_linelevel == 2 && _era == 1){
            return 500;
        }if(_linelevel == 2 && _era == 2){
            return 300;
        }if(_linelevel == 3) {
            if(_era == 1){
                return 1000;
            }if(_era == 2){
                return 700;
            }if(_era == 3){
                return 500;
            }if(_era >= 4 && _era <= 10){
                return 80;
            }if(_era >= 11 && _era <= 20){
                return 30;
            }if(_era >= 21){
                return 5;
            }
        }if(_linelevel == 4 || _linelevel == 5) {
            if(_era == 1){
                return 1200;
            }if(_era == 2){
                return 800;
            }if(_era == 3){
                return 600;
            }if(_era >= 4 && _era <= 10){
                return 100;
            }if(_era >= 11 && _era <= 20){
                return 50;
            }if(_era >= 21){
                return 10;
            }
        }
        return 0;
    }

    //params:_level & _era => Invite Ratio/10
    function getReferProRo(uint _linelevel, uint _era) external pure returns(uint){
        if(_linelevel == 5){
            if(_era == 1){
                return 1;
            }if(_era == 2){
                return 2;
            }if(_era == 3){
                return 4;
            }if(_era >= 4){
                return 8;
            }
        }
        return 0;
    }

    function caleReadyTime(uint _frozenCoin, uint8 _level) external pure returns(uint32){
        uint addHour = 24;
        if(_level == 1){
            addHour = addHour.add(40);
        } if(_level == 2){
            addHour = addHour.add(30);
        } if(_level == 3){
            addHour = addHour.add(20);
        } if(_level == 0){
            addHour = addHour.add(24);
        }

        uint coin = _frozenCoin;
        if(coin == 15 * 1 ether){
            addHour = addHour.add(10);
        } if(coin >= 11 * 1 ether && coin < 15 * 1 ether){
            addHour = addHour.add(20);
        } if(coin >= 6 * 1 ether && coin < 11 * 1 ether){
            addHour = addHour.add(30);
        } if(coin >= 1 * 1 ether && coin < 6 * 1 ether){
            addHour = addHour.add(40);
        }
        return uint32(addHour * 1 hours);
    }
}

