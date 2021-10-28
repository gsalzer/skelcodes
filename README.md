# SkelCodes

This repository contains the runtime code of contracts (self-destructed or not)
from the Ethereum main chain (deployed up to but not including block
13,350,000), one for each type of skeleton. By the way of selection, this
collection of 229,951 bytecodes is representative of 42,818,283 contracts
with 481,790 distinct runtime codes.

## Contents of the repository

The codes are labeled `blockid-address.hex`. `address` is one of the addresses,
where the code has been deployed on Ethereum's main chain, `blockid` is the
corresponding block.  Note that the address by itself is not enough to identify
the codes uniquely.  Because of `CREATE2`, there are cases where different
codes have been deployed at the same address.

The codes are divided up into directories, where each directory covers the
range of 1,000,000 blocks.

| directory | #contracts |
| --------- | ---------- |
|  0xxxxxx  |     2,542  |
|  1xxxxxx  |     3,305  |
|  2xxxxxx  |     2,572  |
|  3xxxxxx  |     4,018  |
|  4xxxxxx  |    17,752  |
|  5xxxxxx  |    26,510  |
|  6xxxxxx  |    23,590  |
|  7xxxxxx  |    15,864  |
|  8xxxxxx  |    14,514  |
|  9xxxxxx  |    16,289  |
| 10xxxxxx  |    21,954  |
| 11xxxxxx  |    34,045  |
| 12xxxxxx  |    29,426  |
| 13xxxxxx  |    17,570  |
| --------- | ---------- |
|           |   229,951  |

The file `info.csv` contains supplementary data for each bytecode (see the next section for details).
The scripts `database2csv.sql` and `csv2files.bash` document the extraction process.

## How the bytecodes were selected and stored

1. We collected all bytecodes that resulted from a successful `CREATE`/`CREATE2`
   instruction, except for the empty bytecode.

2. For each bytecode, we compute its skeleton, see
   [https://github.com/gsalzer/ethutils](https://github.com/gsalzer/ethutils/tree/main/doc/skeleton)
   for information on skeletons.

3. We group the bytecodes by skeleton. Note that there may be several bytecodes
   with the same skeleton, and each bytecode may have been deployed at several
   addresses. In each group, we select one bytecode and one deployment address
   according to the following criteria, with priority decreasing from top to bottom.
    - We prefer addresses, where the contract has not yet self-destructed.
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

