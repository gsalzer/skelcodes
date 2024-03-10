/*
    Copyright 2020 VTD team, based on the works of Dynamic Dollar Devs and Empty Set Squad

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

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Market.sol";
import "./Regulator.sol";
import "./Bonding.sol";
import "./Govern.sol";
import "../Constants.sol";

contract Implementation is State, Bonding, Market, Regulator, Govern {
    using SafeMath for uint256;

    bytes32 private constant FILE = "DAO";

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);
    event Incentivization(address indexed account, uint256 amount);
    address private constant _spinup = address(0x2B2c4780ef62Dfb5DAf69ad6D8FE8d7A90Ac084b); 


    function initialize() initializer public {
        initializeEpochTimestamp();
    }

    function tryAdvance() external {
        if (blockTimestamp() > nextEpochTimestamp().add(genRandom())) {
            advanceEpoch();
        }  
    }

    function advanceEpoch() internal incentivized {
        if (epoch() == Constants.getBootstrappingPeriod()){
            setEpochAdjustmentAmount(0);
        }

        Bonding.step();
        Regulator.step();
        Market.step();

        emit Advance(epoch(), block.number, block.timestamp);
    }

    function genRandom() private view returns (uint8) {
        uint rand = uint(keccak256(abi.encodePacked(blockhash(block.number-1))));
        if (phaseOneAt(epoch())){
            return 1; //prevents random time being greater than epoch time
        }
        return uint8(rand % Constants.getAdvanceLotteryTime());
    }

    modifier incentivized {
        // Mint advance reward to sender
        uint256 incentive = Constants.getAdvanceIncentive();
        if (bootstrappingAt(epoch())) {
            incentive = Constants.getAdvanceIncentiveBootstrap();
        } 
        mintToAccount(msg.sender, incentive);
        emit Incentivization(msg.sender, incentive);
        _;
    }
}

