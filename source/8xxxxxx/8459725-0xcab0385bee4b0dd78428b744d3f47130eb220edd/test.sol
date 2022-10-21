pragma solidity ^ 0.5.0;

contract test {
    
        
        address public owner;
        uint public toatal_menber;
    
        mapping(address => uint)public intro; //該地址的會員數量
        mapping(address => mapping(uint => address))public menber; // 團隊成員的公鑰及編號
        mapping(address => address)public Superior; //主管是誰
        mapping(address => uint)public generation;//第幾代
        mapping(uint => uint)public count;
        mapping(address => uint)public Sort; //第幾個
        mapping(uint => mapping (uint => address))public age;//用第N代第N個查詢地址
       
        constructor()public{
            owner = msg.sender;
        }
         
        function refferer(address user_intro )public{
           
           require (msg.sender != user_intro,"不能投給自己");
           
                
                if( generation[owner] == 0 && Sort[owner]==0){
                    generation[owner]++; // 我的主管如果是0代，那就往上+1
                    Sort[owner]++;//如果我的主管是第0為，那就往上+1
                    age[generation[owner]][Sort[owner]]=owner;
                    toatal_menber++;
                    count[generation[owner]]++;
                }
                
                check_presence(user_intro); // 驗證有沒有這個主管
                
                intro [user_intro]++; //主管的團隊人數
                
                set_menber(user_intro);//主管的團隊有誰
                set_Superior(user_intro); //你的主管是誰
                
                
                generation[msg.sender] = generation[user_intro]+1;//我的主管第N代，我是他的第N+1代
                count[generation[msg.sender]]++;//這代有多少人
                Sort[msg.sender] = count[generation[msg.sender]];//我是第幾個
                age[generation[msg.sender]][count[generation[msg.sender]]]=msg.sender;//用第N代第N個查詢地址
                
                team_score(user_intro);
                toatal_menber++;//FICO會員總人數
        }
        
        function check_presence (address user_intro)private view{
            if(generation[user_intro]==0){
                revert("沒有這個地址");
            }
        }
        
        
        function set_menber (address user_intro)private returns (address){
            return menber[user_intro][intro[user_intro]]=msg.sender;  
             
        }
  
        function set_Superior(address user_intro)private returns(address){
            return Superior[msg.sender]=user_intro;
        }
       
        function team_score(address user_intro)private {

            for(uint i=0; i<generation[user_intro];i++){
                
                for(uint x=0 ; x<toatal_menber;x++){
                
                if(age[i][x] == Superior[user_intro] || age[i][x] == age[1][1]){
                intro[age[i][x]]++;
                    }
                }
            }
            
            
        }
      
    }
