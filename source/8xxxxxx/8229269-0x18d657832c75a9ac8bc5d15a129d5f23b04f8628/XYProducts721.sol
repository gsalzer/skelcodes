pragma solidity >=0.5.0 <0.6.0;
import "./ERC721Enumerable.sol";
import "./MinterRole.sol";


/**
 * @title A 721 Token Contract - A non-fungible token contract
 * @dev Basic version of ERC721Token.
 */
contract XYProducts721 is ERC721Enumerable, MinterRole {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from product ID to list of owned token IDs

    event TokenMinted(address beneficiary, uint tokenType, uint index, uint tokenId);

    mapping(uint => uint) public tokenTypeSupply;
    mapping(uint => uint[]) public tokensByType;
    mapping(uint => uint) public tokenType;
    mapping(uint => uint) public tokenIndexInTypeArray;
    uint[] public tokenTypes;

    /**
     * @dev Constructor function
     */
    constructor (
      string memory name,
      string memory symbol,
      uint[] memory types,
      uint[] memory supplies
    )
        public
        ERC721Enumerable()
        MinterRole()
      {
        _name = name;
        _symbol = symbol;
        tokenTypes = types;
        for (uint i = 0; i < types.length; i++) {
          tokenTypeSupply[types[i]] = supplies[i];
        }
    }

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function numTokensByOwner(address owner) public view returns (uint) {
      return _tokensOfOwner(owner).length;
    }
    function numTokensByType(uint tType) public view returns (uint) {
      return tokensByType[tType].length;
    }

    function getTokenId(uint tType, uint index) public pure returns (uint) {
      return uint(keccak256(abi.encode(tType, index)));
    }

    function batchMint(
      address[] memory beneficiaries,
      uint[] memory types
    ) public returns (uint[] memory) {
      uint[] memory tokens = new uint[](beneficiaries.length);
      for (uint i = 0; i < beneficiaries.length; i++) {
        uint tokenId = mint(beneficiaries[i], types[i]);
        tokens[i] = tokenId;
      }
      return tokens;
    }

    function batchMintAllTypes(
      address[] memory beneficiaries
    ) public returns (uint[] memory) {
      uint[] memory tokens = new uint[](beneficiaries.length*tokenTypes.length);
      uint index = 0;
      for (uint i = 0; i < beneficiaries.length; i++) {
        for (uint j = 0; j < tokenTypes.length; j++) {
          uint tokenId = mint(beneficiaries[i], tokenTypes[j]);
          tokens[index] = tokenId;
          index++;
        }
      }
      return tokens;
    }

    /*
      Let's at least allow some minting of tokens!
      @param beneficiary - who should receive it
      @param tokenId - the id of the 721 token
    */
    function mint
    (
        address beneficiary,
        uint tType
    )
      public
      onlyMinter()
      returns (uint tokenId)
    {
      uint index = tokensByType[tType].length;
      require (index < tokenTypeSupply[tType], "Token supply limit reached");
      tokenId = getTokenId(tType, index);
      tokensByType[tType].push(tokenId);
      tokenType[tokenId] = tType;
      tokenIndexInTypeArray[tokenId] = index;
      
      _mint(beneficiary, tokenId);
      emit TokenMinted(beneficiary, tType, index, tokenId);
    }
    
}
