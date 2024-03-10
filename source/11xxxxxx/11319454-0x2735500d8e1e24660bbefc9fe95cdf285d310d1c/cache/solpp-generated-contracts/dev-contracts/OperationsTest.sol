pragma solidity ^0.7.0;

// SPDX-License-Identifier: UNLICENSED



import "../Operations.sol";

contract OperationsTest {
    function testDeposit() external pure returns (uint256, uint256) {
        Operations.Deposit memory x =
            Operations.Deposit({
                accountId: 0,
                tokenId: 0x0102,
                amount: 0x101112131415161718191a1b1c1d1e1f,
                owner: 0x823B747710C5bC9b8A47243f2c3d1805F1aA00c5
            });

        bytes memory pubdata = Operations.writeDepositPubdata(x);
        //require(pubdata.length == Operations.PackedFullExitPubdataBytes());
        Operations.Deposit memory r = Operations.readDepositPubdata(pubdata);

        require(x.tokenId == r.tokenId, "tokenId mismatch");
        require(x.amount == r.amount, "amount mismatch");
        require(x.owner == r.owner, "owner mismatch");
    }

    function testDepositMatch(bytes calldata offchain) external pure returns (bool) {
        Operations.Deposit memory x =
            Operations.Deposit({
                accountId: 0,
                tokenId: 0x0102,
                amount: 0x101112131415161718191a1b1c1d1e1f,
                owner: 0x823B747710C5bC9b8A47243f2c3d1805F1aA00c5
            });
        bytes memory onchain = Operations.writeDepositPubdata(x);

        return Operations.depositPubdataMatch(onchain, offchain);
    }

    function testFullExit() external pure {
        Operations.FullExit memory x =
            Operations.FullExit({
                accountId: 0x01020304,
                owner: 0x823B747710C5bC9b8A47243f2c3d1805F1aA00c5,
                tokenId: 0x3132,
                amount: 0x101112131415161718191a1b1c1d1e1f
            });

        bytes memory pubdata = Operations.writeFullExitPubdata(x);
        //require(pubdata.length == Operations.PackedDepositPubdataBytes());
        Operations.FullExit memory r = Operations.readFullExitPubdata(pubdata);

        require(x.accountId == r.accountId, "accountId mismatch");
        require(x.owner == r.owner, "owner mismatch");
        require(x.tokenId == r.tokenId, "tokenId mismatch");
        require(x.amount == r.amount, "amount mismatch");
    }

    function testFullExitMatch(bytes calldata offchain) external pure returns (bool) {
        Operations.FullExit memory x =
            Operations.FullExit({
                accountId: 0x01020304,
                owner: 0x823B747710C5bC9b8A47243f2c3d1805F1aA00c5,
                tokenId: 0x3132,
                amount: 0
            });
        bytes memory onchain = Operations.writeFullExitPubdata(x);

        return Operations.fullExitPubdataMatch(onchain, offchain);
    }

    function writePartialExitPubdata(Operations.PartialExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(Operations.OpType.PartialExit),
            bytes4(0), // accountId - ignored
            op.tokenId, // tokenId
            op.amount, // amount
            bytes2(0), // fee - ignored
            op.owner // owner
        );
    }

    function testPartialExit() external pure {
        Operations.PartialExit memory x =
            Operations.PartialExit({
                tokenId: 0x3132,
                amount: 0x101112131415161718191a1b1c1d1e1f,
                owner: 0x823B747710C5bC9b8A47243f2c3d1805F1aA00c5
            });

        bytes memory pubdata = writePartialExitPubdata(x);
        Operations.PartialExit memory r = Operations.readPartialExitPubdata(pubdata);

        require(x.owner == r.owner, "owner mismatch");
        require(x.tokenId == r.tokenId, "tokenId mismatch");
        require(x.amount == r.amount, "amount mismatch");
    }

    function writeForcedExitPubdata(Operations.ForcedExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(Operations.OpType.ForcedExit),
            bytes4(0), // initator accountId - ignored
            bytes4(0), // target accountId - ignored
            op.tokenId, // tokenId
            op.amount, // amount
            bytes2(0), // fee - ignored
            op.target // owner
        );
    }

    function testForcedExit() external pure {
        Operations.ForcedExit memory x =
            Operations.ForcedExit({
                target: 0x823B747710C5bC9b8A47243f2c3d1805F1aA00c5,
                tokenId: 0x3132,
                amount: 0x101112131415161718191a1b1c1d1e1f
            });

        bytes memory pubdata = writeForcedExitPubdata(x);
        Operations.ForcedExit memory r = Operations.readForcedExitPubdata(pubdata);

        require(x.target == r.target, "target mismatch");
        require(x.tokenId == r.tokenId, "tokenId mismatch");
        require(x.amount == r.amount, "packed amount mismatch");
    }

    function parseDepositFromPubdata(bytes calldata _pubdata)
        external
        pure
        returns (
            uint16 tokenId,
            uint128 amount,
            address owner
        )
    {
        Operations.Deposit memory r = Operations.readDepositPubdata(_pubdata);
        return (r.tokenId, r.amount, r.owner);
    }

    function parseFullExitFromPubdata(bytes calldata _pubdata)
        external
        pure
        returns (
            uint32 accountId,
            address owner,
            uint16 tokenId,
            uint128 amount
        )
    {
        Operations.FullExit memory r = Operations.readFullExitPubdata(_pubdata);
        accountId = r.accountId;
        owner = r.owner;
        tokenId = r.tokenId;
        amount = r.amount;
    }
}

