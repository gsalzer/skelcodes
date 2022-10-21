pragma solidity ^0.5.4;


contract Test3{
    function getDifficulty() view public returns(uint){
        return block.difficulty;
    }
}
