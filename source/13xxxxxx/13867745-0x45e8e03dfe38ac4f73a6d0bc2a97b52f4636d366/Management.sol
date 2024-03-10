pragma solidity ^0.5.10;

contract Management {

    //VOTES
    struct DirectorsApprove{
        address director;
        bool voted;
    }

    //DIRECTORS PROPERTIES
    uint256 totalDirectors;

    mapping(address => bool) directors;
    mapping(address => uint8) countApproveDirectors;
    mapping(address => DirectorsApprove[]) directorsApprove;
    mapping(address => mapping(address => bool)) countDirectorApprove;

    modifier onlyDirector {
        require(directors[msg.sender], "Invalid sender");
        _;
    }

    //GENEALOGY PROPERTIES
    address[] addressesInitiated;

    struct Genealogy{
        address law;
        address father;
        mapping(address => uint256) children;
    }

    mapping(address => Genealogy) genealogy;
    mapping(address => mapping(address => uint8)) countApproveGenealogy;
    mapping(address => mapping(address => DirectorsApprove[])) genalogyApprove;
    mapping(address => mapping(address => mapping(address => bool))) directorsVoted;

    //LAW PROPERTIES
    bool public legislationValid;

    mapping(address => uint8) countVotes;
    mapping(address => mapping(address => bool)) abortLaw;

    modifier currentLaw {
        require(legislationValid, "The law is invalid");
        _;
    }

    //CONSTRUCTOR
    constructor() public {
        directors[msg.sender] = true;
        totalDirectors = 1;
        legislationValid = true;
    }

     //INTERFACES FUNCTIONS
    function initContract(address _address) public currentLaw returns (bool success){
        require(genealogy[_address].law == address(0x0), "Invalid address");

        Genealogy memory newGenealogy = Genealogy({
            law: address(this),
            father: msg.sender
        });

        addressesInitiated.push(_address);
        genealogy[_address] = newGenealogy;

        return true;
    }

    function setPermission(address _address, uint256 _permission) public currentLaw returns (bool success){
        require(genealogy[_address].father == msg.sender, "Sender must be father");
        genealogy[msg.sender].children[_address] = _permission;
        return true;
    }

    function setPermissionOperator(address _address, address _operatorAddress, uint256 _permission) public currentLaw returns (bool success){
        require(genealogy[_address].father == msg.sender, "Sender must be father");
        genealogy[_operatorAddress].children[_address] = _permission;
        return true;
    }

    function getPermission(address _address) public view currentLaw returns (uint256){
        return genealogy[msg.sender].children[_address];
    }

    function getGenealogy(address _child, address _father) public view currentLaw returns(uint256 permission){
        return genealogy[_father].children[_child];
    }

    function getGenealogyComplete(address _me) public view currentLaw returns(address law, address father){
        return (
            genealogy[_me].law,
            genealogy[_me].father
        );

    }

    //DIRECTORS FUNCTIONS
    function addDirector(address _newDirector) private returns(bool success){
        directors[_newDirector] = true;
        totalDirectors++;

        return true;
    }

    function removeDirector(address _director) private returns(bool success){
        directors[_director] = false;
        totalDirectors--;

        return true;
    }

    function seeDirector(address _address) public view currentLaw returns(bool director){
        return directors[_address];
    }

    function directorAddRequest(address _address) public onlyDirector currentLaw returns(bool success){
        require(!countDirectorApprove[_address][msg.sender] && !directors[_address], "Ivalid values");

        DirectorsApprove memory newRequest = DirectorsApprove({
            director: msg.sender,
            voted: true
        });

        directorsApprove[_address].push(newRequest);
        countDirectorApprove[_address][msg.sender] = true;
        countApproveDirectors[_address]++;

        if(countApproveDirectors[_address] > totalDirectors/2) {
            addDirector(_address);
            countApproveDirectors[_address] = 0;
            for(uint8 i = 0; i < directorsApprove[_address].length; i++){
                directorsApprove[_address][i].voted = false;
                countDirectorApprove[_address][directorsApprove[_address][i].director] = false;
            }
        }
        return true;
    }

    function directorRemoveRequest(address _address) public onlyDirector currentLaw returns(bool success){
        require(!countDirectorApprove[_address][msg.sender] && totalDirectors > 1 && directors[_address], "Invalid values");
        DirectorsApprove memory newRequest = DirectorsApprove({
            director: msg.sender,
            voted: true
        });

        directorsApprove[_address].push(newRequest);
        countDirectorApprove[_address][msg.sender] = true;
        countApproveDirectors[_address]++;

        if(countApproveDirectors[_address] > totalDirectors/2) {
            removeDirector(_address);
            countApproveDirectors[_address] = 0;
            for(uint8 i = 0; i < directorsApprove[_address].length; i++){
                directorsApprove[_address][i].voted = false;
                countDirectorApprove[_address][directorsApprove[_address][i].director] = false;
            }
        }
        return true;
    }

    function getTotalDirectors() public view currentLaw returns (uint256 total){
        return totalDirectors;
    }

    //GENEALOGY FUNCTIONS
    function setNewGenealogy(address _child, address _father) private returns (bool succcess){
        genealogy[_child].father = _father;
        genealogy[_father].children[_child] = 1;

        return true;
    }

    function removeGenealogy(address _child, address _father) private returns (bool success){
        genealogy[_child].father = address(0x0);
        genealogy[_father].children[_child] = 0;

        return true;
    }

    function genealogyAddRequest(address _child, address _father) public onlyDirector currentLaw returns(bool success){
        require(!directorsVoted[_child][_father][msg.sender] && genealogy[_child].law != address(0x0) &&
            genealogy[_father].law != address(0x0), "Invalid values");

        DirectorsApprove memory newRequest = DirectorsApprove({
            director: msg.sender,
            voted: true
        });

        genalogyApprove[_child][_father].push(newRequest);
        directorsVoted[_child][_father][msg.sender] = true;
        countApproveGenealogy[_child][_father]++;

        if(countApproveGenealogy[_child][_father] > totalDirectors/2){
            setNewGenealogy(_child, _father);
            countApproveGenealogy[_child][_father] = 0;
            for(uint8 i = 0; i < genalogyApprove[_child][_father].length; i++){
                genalogyApprove[_child][_father][i].voted = false;
                directorsVoted[_child][_father][genalogyApprove[_child][_father][i].director] = false;
            }
        }
        return true;
    }

    function genealogyRemoveRequest(address _child, address _father) public onlyDirector currentLaw returns(bool success){
        require(!directorsVoted[_child][_father][msg.sender] && genealogy[_father].children[_child] >= 1, "Invalid values");

        DirectorsApprove memory newRequest = DirectorsApprove({
            director: msg.sender,
            voted: true
        });

        genalogyApprove[_child][_father].push(newRequest);
        directorsVoted[_child][_father][msg.sender] = true;
        countApproveGenealogy[_child][_father]++;

        if(countApproveGenealogy[_child][_father] > totalDirectors/2){
            removeGenealogy(_child, _father);
            countApproveGenealogy[_child][_father] = 0;
            for(uint8 i = 0; i < genalogyApprove[_child][_father].length; i++){
                genalogyApprove[_child][_father][i].voted = false;
                directorsVoted[_child][_father][genalogyApprove[_child][_father][i].director] = false;
            }
        }

        return true;
    }

    //LAW FUNCTION
    function abortLawRequest(address _address) public onlyDirector currentLaw returns(bool success){
        require(!abortLaw[_address][msg.sender], "Sender already voted");

        abortLaw[_address][msg.sender] = true;
        countVotes[_address]++;

        if(countVotes[_address] == totalDirectors){
            legislationValid = false;
        }
        return true;
    }
}
