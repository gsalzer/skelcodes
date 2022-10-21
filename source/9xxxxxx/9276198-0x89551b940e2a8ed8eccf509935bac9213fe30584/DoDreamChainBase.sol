pragma solidity ^0.5.5;

import "./LockableToken.sol";

/**
 * @title DRMBaseToken
 * dev 트랜잭션 실행 시 메모를 남길 수 있다.
 */
contract DoDreamChainBase is LockableToken   {
    event DRMTransfer(address indexed from, address indexed to, uint256 value, string note);
    event DRMTransferFrom(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event DRMApproval(address indexed owner, address indexed spender, uint256 value, string note);

    event DRMMintTo(address indexed controller, address indexed to, uint256 amount, string note);
    event DRMBurnFrom(address indexed controller, address indexed from, uint256 value, string note);

    event DRMTransferToTeam(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);
    event DRMTransferToPartner(address indexed owner, address indexed spender, address indexed to, uint256 value, string note);

    event DRMTransferToEcosystem(address indexed owner, address indexed spender, address indexed to
    , uint256 value, uint256 processIdHash, uint256 userIdHash, string note);

    // ERC20 함수들을 오버라이딩 작업 > drm~ 함수를 타게 한다.
    function transfer(address to, uint256 value) public returns (bool ret) {
        return drmTransfer(to, value, "transfer");
    }

    function drmTransfer(address to, uint256 value, string memory note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transfer(to, value);
        emit DRMTransfer(msg.sender, to, value, note);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        return drmTransferFrom(from, to, value, "");
    }
             
     function drmTransferFrom(address from, address to, uint256 value, string memory note) public returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transferFrom(from, to, value);
        emit DRMTransferFrom(from, msg.sender, to, value, note);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        return drmApprove(spender, value, "");
    }

    function drmApprove(address spender, uint256 value, string memory note) public returns (bool ret) {
        ret = super.approve(spender, value);
        emit DRMApproval(msg.sender, spender, value, note);
    }

    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        return drmIncreaseApproval(spender, addedValue, "");
    }

    function drmIncreaseApproval(address spender, uint256 addedValue, string memory note) public returns (bool ret) {
        ret = super.increaseApproval(spender, addedValue);
        emit DRMApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
        return drmDecreaseApproval(spender, subtractedValue, "");
    }

    function drmDecreaseApproval(address spender, uint256 subtractedValue, string memory note) public returns (bool ret) {
        ret = super.decreaseApproval(spender, subtractedValue);
        emit DRMApproval(msg.sender, spender, allowed[msg.sender][spender], note);
    }

    /**
     * dev 신규 발행시 반드시 주석을 남길수 있도록한다.
     */
    function mintTo(address to, uint256 amount) internal returns (bool) {
        require(to != address(0x0), "This address to be set is zero address(0). Check the input address.");
    
        totalSupply_ = totalSupply_.add(amount);
        balances[to] = balances[to].add(amount);

        emit Transfer(address(0), to, amount);
        return true;
    }

    function drmMintTo(address to, uint256 amount, string memory note) public onlyOwner returns (bool ret) {
        ret = mintTo(to, amount);
        emit DRMMintTo(msg.sender, to, amount, note);
    }

    /**
     * dev 화폐 소각시 반드시 주석을 남길수 있도록한다.
     */
    function burnFrom(address from, uint256 value) internal returns (bool) {
        require(value <= balances[from], "Your balance is insufficient.");

        balances[from] = balances[from].sub(value);
        totalSupply_ = totalSupply_.sub(value);

        emit Transfer(from, address(0), value);
        return true;
    }

    function drmBurnFrom(address from, uint256 value, string memory note) public onlyOwner returns (bool ret) {
        ret = burnFrom(from, value);
        emit DRMBurnFrom(msg.sender, from, value, note);
    }
    
    /**
     * dev DRM 팀에게 전송하는 경우
     */
    function drmTransferToTeam(
        address from,
        address to,
        uint256 value,
        string memory note
    ) public onlyOwner returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transferFrom(from, to, value);
        emit DRMTransferToTeam(from, msg.sender, to, value, note);
        return ret;
    }
    
    /**
     * dev 파트너(어드바이저)에게 전송하는 경우
     */
    function drmTransferToPartner(
        address from,
        address to,
        uint256 value,
        string memory note
    ) public onlyOwner returns (bool ret) {
        require(to != address(this), "The receive address is the Contact Address of DoDreamChain.");

        ret = super.transferFrom(from, to, value);
        emit DRMTransferToPartner(from, msg.sender, to, value, note);
    }

    /**
     * dev 보상을 DRM 지급
     * dev EOA가 트랜잭션을 일으켜서 처리 * 여러개 계좌를 기준으로 한다. (가스비 아끼기 위함)
     */
    function drmBatchTransferToEcosystem(
        address from, address[] memory to,
        uint256[] memory values,
        uint256 processIdHash,
        uint256[] memory userIdHash,
        string memory note
    ) public onlyOwner returns (bool ret) {
        uint256 length = to.length;
        require(length == values.length, "The sizes of \'to\' and \'values\' arrays are different.");
        require(length == userIdHash.length, "The sizes of \'to\' and \'userIdHash\' arrays are different.");

        ret = true;
        for (uint256 i = 0; i < length; i++) {
            require(to[i] != address(this), "The receive address is the Contact Address of DoDreamChain.");

            ret = ret && super.transferFrom(from, to[i], values[i]);
            emit DRMTransferToEcosystem(from, msg.sender, to[i], values[i], processIdHash, userIdHash[i], note);
        }
    }
    
    function destroy() public onlyRoot {
        selfdestruct(msg.sender);
    }
   
}
