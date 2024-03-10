pragma solidity ^0.4.24;

library gameLib{

  enum mark { blank, pX, pO }
  struct game{
    address playerX;
    address playerO;
    uint bet;
    uint wager;
    uint turn;
    uint deadline;
    uint8 numMoves;
    mark[9] moves;    
  }

  function join( game storage gm, address playerO, uint8 move) public returns (bool){
    gm.numMoves++;
    gm.deadline = block.timestamp + gm.turn;
    gm.moves[move] = mark.pO;
    gm.playerO = playerO;
    return true;
  }

  function newMove( game storage gm, uint8 move) public returns (bool){
    gm.numMoves++;
    gm.moves[move] = mark( 2 - ( gm.numMoves % 2 ) );
    gm.deadline = block.timestamp + gm.turn;
    return true;
  }

  function isWin( game storage gm ) public view returns( bool ){
    if( gm.numMoves < 5 ) return false;

    mark player = mark( 2 - ( gm.numMoves % 2 ) );
    if( ((gm.moves[0] == player) && (gm.moves[3] == player) && (gm.moves[6] == player) )
      ||((gm.moves[1] == player) && (gm.moves[4] == player) && (gm.moves[7] == player) ) 
      ||((gm.moves[2] == player) && (gm.moves[5] == player) && (gm.moves[8] == player) ) 
      ||((gm.moves[0] == player) && (gm.moves[1] == player) && (gm.moves[2] == player) )
      ||((gm.moves[3] == player) && (gm.moves[4] == player) && (gm.moves[5] == player) )
      ||((gm.moves[6] == player) && (gm.moves[7] == player) && (gm.moves[8] == player) )
      ||((gm.moves[0] == player) && (gm.moves[4] == player) && (gm.moves[8] == player) )
      ||((gm.moves[2] == player) && (gm.moves[4] == player) && (gm.moves[6] == player) ) 
      ) return true;
    return false;
  }

  function isOver( game storage gm ) public view returns(bool){
    return 8 < gm.numMoves;
  }

  function isPlayerTurn( game storage gm, address player ) public view returns(bool){
    return (gm.numMoves % 2 == 0 && player == gm.playerX )
            || (gm.numMoves % 2 == 1 && player == gm.playerO );
  }

  function isTimeout( game storage gm ) public view returns(bool){
    return (1 < gm.numMoves) && (gm.deadline < block.timestamp);
  }

  function isValidMove( game storage gm, uint8 move ) public view returns(bool){
    return move < 9 && gm.moves[move] == mark.blank;
  }

  function isValidGame( game storage gm ) public view returns(bool){
    return 0 < gm.turn;
  }

  function end( game storage gm, uint8 code) public{
    gm.turn = 0;
    gm.deadline = code;
  }
}
