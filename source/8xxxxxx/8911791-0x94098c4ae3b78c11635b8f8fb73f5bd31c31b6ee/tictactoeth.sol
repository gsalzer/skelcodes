pragma solidity ^0.4.24;
import "./Ownable.sol";
import "./gameLib.sol";

contract tictactoeth is Ownable{

  uint public fees;
  function collectFees() external onlyOwner(){
    owner().transfer( fees );
    fees = 0;
  }
  uint constant feeDivisor = 100;
  uint constant minBet = 100;
  uint constant minTurn = 280; // approx. 5 minutes
  uint constant maxTurn = 864020; // approx. 10 days 

  uint public numGames;
  gameLib.game[] public games;
  using gameLib for gameLib.game;
  event gameEvent(
      uint indexed id
  );
  modifier validGame(uint id){
    require( games[id].isValidGame() );
    _;
  }
  modifier playerTurn(uint id){
    require( games[id].isPlayerTurn(msg.sender) );
    _;
  }
  modifier validMove(uint id, uint8 move){
    require( games[id].isValidMove(move) );
    _;
  }
  function getMoves(uint id) external view returns (uint8[9] moves){
    for(uint8 i=0; i < 9; i++){
      moves[i] = uint8( games[id].moves[i] );
    }
  }

  function newGame( uint wager, uint turn, uint8 move ) payable external returns( uint ){
    require( minBet < msg.value ); 
    require( minBet < wager );
    require( minTurn < turn && turn < maxTurn );
    require( move < 9 );

    gameLib.mark[9] memory moves;
    moves[move]=gameLib.mark.pX;

    games.push( gameLib.game( msg.sender, 0, msg.value, wager, turn, 0, 1, moves ) );
    numGames++;
    emit gameEvent( numGames - 1 );
    return( numGames - 1 );
  }

  function cancelGame(uint id) external validGame(id) returns (bool){
    require( 1 == games[id].numMoves && msg.sender == games[id].playerX );
    return endGame( id, 0 );
  }

  function joinGame( uint id, uint8 move ) payable external validGame(id) validMove(id,move) returns (bool){
    require( 1 == games[id].numMoves && games[id].wager <= msg.value );

    require( games[id].join( msg.sender, move ) );
    emit gameEvent( id );

    if( games[id].wager < msg.value ) msg.sender.transfer( msg.value - games[id].wager );
    return true;
  }

  function newMove( uint id, uint8 move ) external validGame(id) validMove(id,move) playerTurn(id) returns(bool){
    if( games[id].isTimeout() ) return endGame(id,3);

    require( games[id].newMove( move ) );

    if( games[id].isWin() ) return endGame(id,1);
    else if( games[id].isOver() ) return endGame(id,2);

    emit gameEvent(id);
    return true;
  }

  function endGame(uint id, uint8 code) private returns (bool){
    uint vig;
    uint payX;
    uint payO;
    gameLib.game memory gm = games[id];

    if(code==0){ // Cancel
      payX = gm.bet; 
    }
    else if(code==1){ // Win
      if( gm.numMoves % 2 == 1 ) payX = gm.bet + gm.wager;
      else payO = gm.bet + gm.wager;
    }
    else if(code==2){ //  Stalemate
      vig = (gm.bet / feeDivisor) + (gm.wager / feeDivisor);
      payX = gm.bet - (gm.bet / feeDivisor);
      payO = gm.wager - (gm.wager / feeDivisor); 
    }
    else if(code==3){ // Timeout
      vig = (gm.bet + gm.wager) / feeDivisor;
      if( gm.numMoves % 2 == 1 ) payX = gm.bet + gm.wager - vig;
      else payO = gm.bet + gm.wager - vig;
    }

    games[id].end(code); 
    fees += vig;
    gm.playerX.transfer(payX);
    gm.playerO.transfer(payO);
    emit gameEvent(id);
    return true;
  }
}
