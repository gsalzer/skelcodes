# SkelCodes

This repository contains the runtime code of contracts (self-destructed or not)
from the Ethereum main chain (deployed up to but not including block
13,340,000), one for each type of skeleton. By the way of selection, this
collection of 226,100 bytecodes is representative of all deployed contracts
(roughly 40 millions).

## Contents of the repository

The directories are named by the block numbers of hard forks. A bytecode is
stored in the directory corresponding to the latest fork preceding the
deployment of the first contract with the same skeleton as the bytecode.
Bytecodes in a particular directory will not contain instructions introduced
only in a later fork.

| block id | fork name | #contracts | new opcodes |
| -------- | --------- | ---------- | ----------- |
|        0 | Frontier | 460 | |
|   200000 | Ice Age | 2614 | |
|  1150000 | Homestead | 2522 | DELEGATECALL |
|  1920000 | DAO Fork | 1546 | |
|  2463000 | Tangerine Whistle | 495 | |
|  2675000 | Spurious Dragon | 11971 | |
|  4370000 | Byzantium | 66529 | RETURNDATASIZE, RETURNDATACOPY, STATICCALL, REVERT |
|  7280000 | Constantinople / St.Petersburg | 26042 | SHL, SAR, SHA3, EXTCODEHASH, CREATE2 |
|  9069000 | Istanbul | 2239 | CHAINID, SELFBALANCE |
|  9200000 | Muir Glacier | 96929 | |
| 12965000 | London | 14753 | BASEFEE |

The file `info.csv` contains supplementary data for each bytecode (see the next section for details).
The scripts `database2csv.sql` and `csv2files.bash` document the extraction process.

## How the bytecodes were selected and stored

1. We collected all bytecodes that resulted from a successful `CREATE`
   operation, except for the empty bytecode.

2. For each bytecode, we compute its skeleton. Several bytecodes may have the
   same skeleton. See
   [https://github.com/gsalzer/ethutils](https://github.com/gsalzer/ethutils/tree/main/doc/skeleton)
   for information on skeletons.

3. We group the bytecodes by skeleton. Note that there may be several bytecodes
   with the same skeleton, and each bytecode may have been deployed at several
   addresses. In each group, we select one bytecode and one deployment address
   according to the following criteria, with priority decreasing from top to bottom.
    - We prefer addresses, where the contract has not yet self-destructed (until block 13,400,000).
    - We prefer addresses, where [Etherscan](https://etherscan.io) provides verified source code.
    - We prefer addresses of earlier deployments.

In the end, we obtain the following data for each skeleton:
   - one *address* from the Ethereum main chain
   - the *bytecode* deployed at this address, which possesses this skeleton
   - the *block, transaction, and message id* where the deployment took place (uniquely identifying the deployment)
   - the *number of the first block*, where a contract with this skeleton was deployed
   - the *number of the last block*, where a contract with this skeleton was deployed
   - the *number of different bytecodes* possessing this skeleton
   - the *number of deployments* of contracts with this skeleton
This data can be found in the file `info.csv`.

4. We store the bytecode in the directory corresponding to the latest fork
   before the first deployment, using its deployment address as file name. This
means: If the number of the first block, where a contract with the same
skeleton as the bytecode was deployed, is `N`, and if `F` is the largest fork
number smaller or equal to `N`, and if `A` is one of the deployment addresses of
the bytecode (selected as described above), then the bytecode is stored in the file
`F/0xA.hex`.

