//SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/math/Math.sol";
import "../interfaces/Keep3r/IKeep3rV1Mini.sol";

// Based on https://github.com/banteg/lido-keep3r/blob/master/contracts/LidoJob.vy, rewritten in solidity

interface ILido {
    function getBufferedEther() external view returns (uint256);
    function depositBufferedEther(uint256 max_deposits) external returns (uint256);
}

contract LidoRelayer is Ownable {
    IKeep3rV1Mini RLR = IKeep3rV1Mini(0x5b3F693EfD5710106eb2Eac839368364aCB5a70f);
    ILido Lido = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);

    uint256 public constant DEPOSIT_SIZE = 32 * 1e18;
    uint256 public constant MIN_DEPOSITS = 16;
    uint256 public constant MAX_DEPOSITS = 60;

    modifier upkeep() {
        require(RLR.isKeeper(msg.sender), "!relayer");
        _;
        RLR.worked(msg.sender);
    }

    function workable() external view returns (bool) {
        return Lido.getBufferedEther() / DEPOSIT_SIZE >= MIN_DEPOSITS;
    }

    function work() public upkeep {
        uint256 deposits = Math.min(Lido.getBufferedEther() / DEPOSIT_SIZE, MAX_DEPOSITS);
        require (deposits >= MIN_DEPOSITS,"!workable");
        Lido.depositBufferedEther(deposits);
    }

    //Use this to depricate this job to move rlr to another job later
    function destructJob() public onlyOwner {
        //Get the credits for this job first
        uint256 currRLRCreds = RLR.credits(address(this),address(RLR));
        //Send out RLR Credits if any
        if(currRLRCreds > 0) {
            //Invoke receipt to send all the credits of job to owner
            RLR.receipt(address(RLR),owner(),currRLRCreds);
        }
        //Finally self destruct the contract after sending the credits
        selfdestruct(payable(owner()));
    }
}

