# SkelCodes

This repository contains the runtime code of contracts, self-destructed or not,
from Ethereum's main chain, *one for each type of skeleton*. By the way of
selection, this collection of **229,951** bytecodes faithfully represents, in
most respects, the 42,818,283 contracts successfully deployed up to
block **13,500,000** (see below for details of the selection process).

## Contents of the repository

The codes are labeled `blockid-address.hex`. `address` is one of the addresses,
where the code has been deployed on Ethereum's main chain, `blockid` is the
block of creation.  Note that the address by itself is not enough to identify
the codes uniquely.  Because of `CREATE2`, there are cases where different
codes have been successively deployed at the same address.

The codes are divided up into directories, with each directory covering the
range of 1,000,000 blocks.

| directory |    #codes  |
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
| total     |   229,951  |

The file `info.csv` contains supplementary data for each bytecode (see the next
section for details).  The scripts `database2csv.sql` and `csv2files.bash`
document the extraction process. They are not overly useful if you don't have
access to the database they are referring to.

## Selection of bytecodes

1. We collect all bytecodes that resulted from a successful `CREATE`/`CREATE2`
   instruction or transaction, except for the empty bytecode. The latter is
mainly the result of self-destructing deployment code.

2. For each bytecode, we compute its skeleton, see
   [https://github.com/gsalzer/ethutils](https://github.com/gsalzer/ethutils/tree/main/doc/skeleton)
   for more information and scripts.

3. We group the bytecodes by skeleton. There may be several bytecodes
   with the same skeleton, and each bytecode may have been deployed at several
   addresses. In each group, we select one bytecode and one deployment address
   according to the following criteria, with priority decreasing from top to bottom.

    - We prefer addresses, where the contract has not yet self-destructed.
    - We prefer addresses, where [Etherscan](https://etherscan.io) provides verified source code.
    - We prefer addresses of earlier deployments.

   The first two criteria ensure that we pick a deployment address where we find more information
   on Etherscan, if available. (Etherscan removes the information once a contract
   self-destructs.)

## Supplementary data

The file `info.csv` contains the following supplementary data for each bytecode
in the repository:

   - the *block number*, *transaction id*, and *message id* where the deployment took place
     (uniquely identifying the deployment)
   - the deployment *address* on Ethereum's main chain
   - the *first block*, where a contract with the same skeleton was deployed
   - the *last block*, where a contract with the same skeleton was deployed
   - the *number of different bytecodes* with the same skeleton
   - the *number of deployments* of contracts with the same skeleton

 As an example, the line
```
10861487,142,3,0x740f1a77a43ea4e26ffc30d1ef92358f5a221406,8533807,13229753,20,12212167
```
tells that the bytecode
`10861487-0x740f1a77a43ea4e26ffc30d1ef92358f5a221406.hex` in directory
`10xxxxxx` was deployed by message `3` of transaction `142` in block `10861487`
at the address `0x740f1a77a43ea4e26ffc30d1ef92358f5a221406`. The contracts with
the same skeleton as this bytecode were deployed between the
blocks `8533807` and `13229753`. In total, there are `20` different bytecodes
and `12212167` deployments. Further information can be found on
[https://etherscan.io/address/0x740f1a77a43ea4e26ffc30d1ef92358f5a221406](https://etherscan.io/address/0x740f1a77a43ea4e26ffc30d1ef92358f5a221406).

