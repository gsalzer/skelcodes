pragma solidity >=0.4.21 <0.6.0;

//import "./DataContract.sol";
// 彩票合约
contract LotteryShop{
    //数据合约
    //DataContract dataContract;
    //购买彩票事件，在购买彩票方法中调用
    event BuyLottery(address indexed buyer,uint money,uint16 luckNum);
    //开奖事件，在开奖方法中调用
    event DrawLottery(address winner,uint money,uint16 luckNum);

    //购买记录（购买者的address, 彩票号码）
    mapping(address=>uint) buyMapping;
    //购买用户的地址
    address payable[]  usrAdrList;

    //管理员地址
    address  manageAdr;
    //合约地址
    address payable contractAdr;
    //数据合约地址
    address payable dataContractAdr;
    constructor() public {//address _dataContractAddr
        //将合约部署人的地址保存起来作为管理员地址
        manageAdr=msg.sender;
        //将当前合约对象的地址保存
        // contractAdr = address(this);
        contractAdr = address(uint160(address(this)));// address(this);
        //contractAdr = msg.sender;
        //初始化构造数据合约
        //dataContract = DataContract(_dataContractAddr);
        //dataContractAdr = address(uint160(_dataContractAddr));

    }

    //0.1 显示管理员地址
    /*function ShowManageAdr() constant returns(address){
        return manageAdr;
    }*/

    //0.2 显示调用者的彩票数据
    /*function ShowInvokerCaiPiao() constant returns(uint){
        return buyMapping[msg.sender];
    }*/
    function ShowInvokerCaiPiao()  public view returns(uint){
        return buyMapping[msg.sender];
    }
    function ShowInvokerBalance()  public view returns(uint){
        return msg.sender.balance;
    }

    //0.3 显示管理员余额
    /*function ShowManageBalance() constant returns(uint){
        return manageAdr.balance;
    }*/
    function ShowManageBalance()  public view  returns(uint){
        return manageAdr.balance;
    }

    //0.4 显示合约余额
    /*function ShowContractMoney() constant returns(uint){
        return contractAdr.balance;
    }*/
    function ShowContractMoney() public view returns(uint){
        return contractAdr.balance;
    }
    function ShowContractAdr() public view returns(address payable){
         return contractAdr;
    }
    function ShowManageAdr() public view returns(address){
        return manageAdr;
    }
    //0.5 获取买家地址列表
    function getAllUsrAddress() public view returns(address payable[] memory){
        return usrAdrList;
    }
    //0.5 买彩票方法
    function BuyCaiPiao(uint16 haoMa) payable public {
        //0. 判断用户账户是否有1 eth
        //require(msg.value == 1 ether);
        //1. 判断彩票购买列表里是否已经存在当前用户
        require(buyMapping[msg.sender]==0);

        //2. 将用户的钱转到合约账户
        //contractAdr.send(msg.value);
        //dataContractAdr.transfer(msg.value);
        //dataContract.setBlance2(msg.sender,msg.value);

        //3.1 调用事件日志
        emit BuyLottery(msg.sender,msg.value,haoMa);

        //3.2 添加到mapping
        buyMapping[msg.sender] = haoMa;
        //3.3 将地址存入买家数组
        usrAdrList.push(msg.sender);
    }
    //0.5 买彩票方法
    /*function BuyCaiPiao(uint16 haoMa,uint etherValue) public {
        //0. 判断用户账户是否有1 eth
        require(etherValue == 1 ether);
        //1. 判断彩票购买列表里是否已经存在当前用户
        require(buyMapping[msg.sender]==0);
        //2. 将用户的钱转到合约账户
        //dataContract.setBlance(etherValue);
        dataContract.setBlance2(msg.sender,etherValue);
        //3.1 调用事件日志
        emit BuyLottery(msg.sender,etherValue,haoMa);

        //3.2 添加到mapping
        buyMapping[msg.sender] = haoMa;
        //3.3 将地址存入买家数组
        usrAdrList.push(msg.sender);
    }*/
    //0.5 买彩票方法
   /* function BuyCaiPiao(uint16 haoMa) payable public {
        //0. 判断用户账户是否有1 eth
        require(msg.value == 1 ether);
        //1. 判断彩票购买列表里是否已经存在当前用户
        require(buyMapping[msg.sender]==0);

        //2. 将用户的钱转到合约账户
        //contractAdr.send(msg.value);
        // contractAdr.transfer(msg.value);

        //3.1 调用事件日志
        emit BuyLottery(msg.sender,msg.value,haoMa);

        //3.2 添加到mapping
        buyMapping[msg.sender] = haoMa;
        //3.3 将地址存入买家数组
        usrAdrList.push(msg.sender);
    }*/

    function KaiJiangTest()  public view returns(uint){
        //1.生成一个随机的开奖号码
        uint256 luckNum = uint256(keccak256(abi.encodePacked(block.difficulty,now)));
        //1.1 取模10，保证奖号在10以内
        luckNum = luckNum % 3;
        return luckNum;
    }


    //1. 开奖 - 必须是管理员才能操作
    function KaiJiang() adminOnly public returns(uint){

        //1.生成一个随机的开奖号码
        uint256 luckNum = uint256(keccak256(abi.encodePacked(block.difficulty,now)));
        //1.1 取模10，保证奖号在10以内
        luckNum = luckNum % 3;

        //开场费
        //emit DrawLottery( msg.sender,contractAdr.balance*0.001,uint16(luckNum));
        //msg.sender.transfer(contractAdr.balance*0.001);

        address payable tempAdr;
        //2.循环用户地址数组
        for(uint32 i=0; i< usrAdrList.length;i++){
            tempAdr = usrAdrList[i];
            //2.1 判断用户地址 在 mapping中 对应的 CaiPiao.hao 的数字是否一样
            if(buyMapping[tempAdr] == luckNum){
                //2.2 记录日志
                emit DrawLottery(tempAdr,(contractAdr.balance),uint16(luckNum));
                //2.3 将合约里所有的钱转给 中奖账户地址
               // tempAdr.send(contractAdr.balance);
                tempAdr.transfer((contractAdr.balance));
                //2.4 提手续费
                //emit DrawLottery(msg.sender,1 ether,uint16(luckNum));
                //msg.sender.transfer(1 ether);

                //emit DrawLottery(tempAdr,msg.value,uint16(luckNum));
                //tempAdr.transfer(msg.value);
                break;
            }
        }
        //3.返回 中奖号码
        return luckNum;
    }

    //2. 重置数据
    function resetData() adminOnly public{
        //2.1 循环 买家数组，删除 购买记录mapping中对应的记录
        for(uint16 i = 0;i<usrAdrList.length;i++){
            delete buyMapping[usrAdrList[i]];
        }
        //2.2 删除 买家数组
        delete usrAdrList;
    }

    //3. 销毁合约
    function kill() adminOnly public{
        //3.1 调用合约自毁函数，把合约账户余额转给当前调用者（管理员）
        selfdestruct(msg.sender);
    }

    //4. 管理员修饰符，只允许管理员操作
    modifier adminOnly() {
        require(msg.sender == manageAdr);
        //代码修饰器所修饰函数的代码
        _;
    }
}
