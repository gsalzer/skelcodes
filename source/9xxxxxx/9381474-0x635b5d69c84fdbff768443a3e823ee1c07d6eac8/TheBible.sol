/* solium-disable no-trailing-whitespace */

pragma solidity >= 0.5.0 < 0.6.0;
import './provableAPI_0.5.sol';
import './strings.sol';

contract TheBible is usingProvable {
  using strings for *;

  mapping(string => mapping(string => mapping(string => string))) verses;
  uint public versePrice;
  mapping(bytes32=>bool) validProvableQueryIds;
  address public owner;
  uint public provableGasLimit;
  /**
   * At the point when all verses have been added, a user may read through all
   * verses by querying [book][chapter][verse], wherein the chapter and verse
   * are always incrementing numbers (as strings).
   * 
   * Therefore, all books names are added upon instantiation. To get all verses for
   * John, for example, a user need only query incrementing chapter and verse numbers
   * until he receives an undefined value (once all verses have been added).
   * */
  string[66] books = [
    '1 Chronicles',
    '1 Corinthians',
    '1 John',
    '1 Kings',
    '1 Peter',
    '1 Samuel',
    '1 Thessalonians',
    '1 Timothy',
    '2 Chronicles',
    '2 Corinthians',
    '2 John',
    '2 Kings',
    '2 Peter',
    '2 Samuel',
    '2 Thessalonians',
    '2 Timothy',
    '3 John',
    'Acts',
    'Amos',
    'Colossians',
    'Daniel',
    'Deuteronomy',
    'Ecclesiastes',
    'Ephesians',
    'Esther',
    'Exodus',
    'Ezekiel',
    'Ezra',
    'Galatians',
    'Genesis',
    'Habakkuk',
    'Haggai',
    'Hebrews',
    'Hosea',
    'Isaiah',
    'James',
    'Jeremiah',
    'Job',
    'Joel',
    'John',
    'Jonah',
    'Joshua',
    'Jude',
    'Judges',
    'Lamentations',
    'Leviticus',
    'Luke',
    'Malachi',
    'Mark',
    'Matthew',
    'Micah',
    'Nahum',
    'Nehemiah',
    'Numbers',
    'Obadiah',
    'Philemon',
    'Philippians',
    'Proverbs',
    'Psalms',
    'Revelation',
    'Romans',
    'Ruth',
    'Song of Solomon',
    'Titus',
    'Zechariah',
    'Zephaniah'
  ];

  modifier onlyProvable() {
    require(msg.sender == provable_cbAddress(), 'Callback did not originate from Provable');

    _;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner, 'Only the contract creator may interact with this function');
    
    _;
  }

  event LogNewProvableQuery(string description);
  event LogError(uint code);
  event LogVerseAdded(string book, string chapter, string verse);

  constructor() public {
    versePrice = 15000000000000000;
    
    owner = msg.sender;
    
    provableGasLimit = 500000;
  }

  function setVerse(string memory concatenatedReference) public payable {
    require(
      msg.value >= versePrice,
      'Please send at least as much ETH as the versePrice with your transaction'
    );

    if (provable_getPrice("URL") > address(this).balance) {
      emit LogNewProvableQuery(
        "Provable query was NOT sent, please add some ETH to cover the Provable query fee"
      );
      
      emit LogError(1);

      revert('Address balance is not enough to cover Provable fee');
    }
    
    require(
      textIsEmpty(concatenatedReference) == false,
      'A concatenatedReference must be provided in the format book/chapter/verse'
    );

    bytes32 queryId = provable_query(
      "URL",
      "json(https://api.ourbible.io/verses/"
        .toSlice()
        .concat(concatenatedReference.toSlice())
        .toSlice()
        .concat(").provableText".toSlice()),
      provableGasLimit
    );
    
    emit LogNewProvableQuery("Provable query was sent, standing by for the answer");

    validProvableQueryIds[queryId] = true;
  }

  function __callback(bytes32 myid, string memory result) public onlyProvable() {
    require(
      validProvableQueryIds[myid] == true,
      'ID not included in Provable valid IDs'
    );
    
    delete validProvableQueryIds[myid];

    string memory book;
    string memory chapter;
    string memory verse;
    string memory text;

    (book, chapter, verse, text) = processProvableText(result);

    verses[book][chapter][verse] = text;
    
    emit LogVerseAdded(book, chapter, verse);
  }

  function processProvableText(string memory result) public returns (
    string memory,
    string memory,
    string memory,
    string memory
  ) {
    require(
      textIsEmpty(result) == false,
      'The Provable result was empty.'
    );

    // The result should be in the format: book---chapter---verse---text
    
    strings.slice[4] memory parts;

    strings.slice memory full = result.toSlice();

    for (uint i = 0; i < 4; i++) {
      strings.slice memory part = full.split("---".toSlice());
        
      if (textIsEmpty(part.toString()) == true) {
        emit LogError(2);

        revert('Provable text was invalid.');
      }
      
      parts[i] = part;
    }

    return (
      parts[0].toString(),
      parts[1].toString(),
      parts[2].toString(),
      parts[3].toString()
    );
  }

  function textIsEmpty(string memory _string) internal pure returns(bool) {
    return bytes(_string).length == 0;
  }

  function getVerse(
    string memory book,
    string memory chapter,
    string memory verse
  ) public view returns(string memory) {
    return verses[book][chapter][verse];
  }
  
  function setVersePrice(uint _versePrice) public onlyOwner() {
    versePrice = _versePrice;
  }
  
  function setProvableGasLimit(uint _provableGasLimit) public onlyOwner() {
    provableGasLimit = _provableGasLimit;
  }
  
  function withdraw() public onlyOwner() {
    msg.sender.transfer(address(this).balance);
  }
  
  function() external payable {
    if (msg.value < versePrice) {
      emit LogError(3);
      
      return;
    }
   
    bytes32 queryId = provable_query(
      "URL",
      "json(https://api.ourbible.io/verses/random).provableText",
      provableGasLimit
    );
    
    emit LogNewProvableQuery("Provable query was sent, standing by for the answer.");
    
    validProvableQueryIds[queryId] = true;
  }
}

