# SkelCodes

This repository contains the deployment code (contract creation code) as well
as the deployed code (runtime code) of contracts, self-destructed or not, from
Ethereum's main chain, *one for each type of skeleton*. Moreover, the folder
*source* contains the ABIs of those contracts, where the source code if
available from [Etherscan](etherscan.io). By the way the contracts were
selected, the collection of **248,328** bytecodes faithfully represents, in
most respects, the **45 million** contracts successfully deployed up to block
**14,000,000** (see below for details of the selection process).

## Contents of the repository

The repository contains three directories, *source*, *deployment* and
*runtime*, of identical structure, containing the ABIs, deployment and runtime
codes of the contracts, respectively. The folder name *source* indicates that
for the addresses in this folder, the source code can be obtained from
[Etherscan](etherscan.io).

The codes are labeled `blockid-address.hex`. `address` is one of the addresses,
where the code has been deployed on Ethereum's main chain, and `blockid` is the
block of creation.  Note that the address by itself is not enough to identify
the codes uniquely.  Because of `CREATE2`, there are cases where different
codes have been successively deployed at the same address.

The codes are divided up into directories, with each directory covering the
range of 1,000,000 blocks.

| directory |    #codes  | with source      |
| --------- | ---------- |------------------|
|  0xxxxxx  |     2,542  |               26 |
|  1xxxxxx  |     3,305  |              336 |
|  2xxxxxx  |     2,572  |              353 |
|  3xxxxxx  |     4,018  |              940 |
|  4xxxxxx  |    17,752  |            6,749 |
|  5xxxxxx  |    26,510  |           11,676 |
|  6xxxxxx  |    23,590  |            9,270 |
|  7xxxxxx  |    15,864  |            5,807 |
|  8xxxxxx  |    14,514  |            5,525 |
|  9xxxxxx  |    16,289  |            5,483 |
| 10xxxxxx  |    21,954  |           10,184 |
| 11xxxxxx  |    34,045  |           18,126 |
| 12xxxxxx  |    29,426  |           16,762 |
| 13xxxxxx  |    35,947  |           24,357 |
| total     |   248,328  |          115,594 |

The file `info.csv` contains supplementary data for each bytecode, whereas
`contract2skelcode.csv.zip` maps the deployed contracts to the skelcodes in
this repository. See below for details.

The scripts `runtime/database2csv.sql` and `runtime/csv2files.bash` folder
document the extraction process. They are not overly useful if you don't have
access to the database they refer to.  Etherscan provides source code with
additional information, packed in a `json` file. The script
`source/json2sol.py` can be used to extract the source code from such a file.

## Selection of bytecodes

1. We collect all runtime bytecodes (with the corresponding deployment codes)
   that resulted from a successful `CREATE`/`CREATE2` instruction or
   transaction before block 14,000,000 on Ethereum's main chain.

2. For each runtime code, we compute its skeleton, see
   [https://github.com/gsalzer/ethutils](https://github.com/gsalzer/ethutils/tree/main/doc/skeleton)
   for more information and scripts.

3. We discard contracts with an empty skeleton, corresponding essentially to
   empty runtime codes, which are the result of self-destructing deployment
   code.  A few bytecodes consist entirely of zeros and also possess an empty
   skeleton.

3. We group the runtime codes by skeleton. There may be several runtime codes
   with the same skeleton, and each runtime code may have been deployed at
   several addresses (using various deployment codes). In each group, we select
   one bytecode and one deployment address according to the following criteria,
   with priority decreasing from top to bottom.

    - We prefer addresses, where the contract has not self-destructed
      until block 14,000,000.
    - We prefer addresses, where [Etherscan](https://etherscan.io) provides
      verified source code.
    - We prefer addresses of earlier deployments.

   The first two criteria prefer deployment addresses where
   [Etherscan](https://etherscan.io) provides more information. Note, however,
   that the criteria refer to moving targets: Contracts keep self-destructing,
   Etherscan removes the source code for self-destructed contracts, and new source
   codes are uploaded every day. Moreover, the repository initially contained codes
   up to block 13,500,000 only, and was later on conservatively extended by the
   codes newly deployed up to block 14,000,000.

Currently 115,594 of the 248,328 codes (47%) possess a verified source.
To obtain additional information for an ADDRESS from [Etherscan](https://etherscan.io), use the link
    https://etherscan.io/address/0xADDRESS#code

## Supplementary data

### info.csv

The file `info.csv` contains the following supplementary data for each bytecode
in the repository:

   - the *filename*
   - the *block number*, *transaction id*, and *message id* where the deployment took place
     (uniquely identifying the deployment)
   - the deployment *address* on Ethereum's main chain
   - the *first block*, where a contract with the same skeleton was deployed
   - the *last block*, where a contract with the same skeleton was deployed
   - the *number of different bytecodes* with the same skeleton
   - the *number of deployments* of contracts with the same skeleton
   - the *length of the bytecode*
   - the *length of the first code segment* of the bytecode
   - the *number of entry points* (contract methods)
   - the version of *solc* used to compile the contract (obtained from the meta data in the bytecode or from [Etherscan](https://etherscan.io), if it has the Solidity source of the contract)

The fields *last block*, *number of different bytecodes* and *number of deployments* take only
deployments before block 14,000,000 into account.

 As an example, the line
```
10018484-0xa1e55c7c255d23dd1fdd6248e64b6355685ae8c8.hex,10018484,181,0,0xa1e55c7c255d23dd1fdd6248e64b6355685ae8c8,10018484,10785507,3,5,235,182,3,0.6.7
```
tells that the bytecode in file
`10018484-0xa1e55c7c255d23dd1fdd6248e64b6355685ae8c8.hex` (directory
`10xxxxxx`) was deployed by message `0` of transaction `181` in block `10018484`
at the address `0xa1e55c7c255d23dd1fdd6248e64b6355685ae8c8`. The contracts with
the same skeleton as this bytecode were deployed between the
blocks `10018484` and `10785507`. In total, there are `3` different bytecodes
and `5` deployments. Further information on this bytecode can be found at
`https://etherscan.io/address/0xa1e55c7c255d23dd1fdd6248e64b6355685ae8c8`.
Columns 10, 11 and 12 roughly indicate the complexity of the bytecode:
Its total length is `235` bytes, whereas the length of the first code segment (the part that is actually executed) consists of just `182` bytes.
The code implements `3` methods (functions in Solidity).

### contract2skelcode.csv

The file `contract2skelcode.csv` contains one line for each contract of the
main chain (up to block 14,000,000). For size reasons, it has been split into
16 files based on the first byte of the deployment address. It maps each
deployed contract to the corresponding skelcode in this repository.  The file
has the following fields.

   - The number of the *block*, where the contract has been deployed.
   - The number of the transaction, *tx*, within the block, where the contract has been deployed.
   - The number of the message, *msg*, within the transaction, where the contract has been deployed.
   - The *address*, at which the contract has been deployed.
   - The fields *skel_block*, *skel_tx*, *skel_msg*, *skel_address* are the same information for the corresponding skelcode, which carries the name *skel_block*`-`*skel_address* in this repository.
   - If Etherscan has source code for the contract, the field `contractname` gives the name of the contract within the source files.

As an example, the line
```
7323071,81,14,0xd7c2546027141d7d101985f1867a51c993effadb,6791341,170,14,0x3783028ce720304fc8877789e8eecdd2e349117c,CappedSTO
```
expresses that the contract deployed in block `7323071`, transaction `81`, message `14` at the main chain address `0xd7c2546027141d7d101985f1867a51c993effadb` has the same skeleton as the contract deployed in block `6791341`, transaction `170`, message `14` at address `0x3783028ce720304fc8877789e8eecdd2e349117c`. The latter contract is included in this repository. The name of the contract in source at Etherscan is `CappedSTO`. The skelcode corresponding to the contract is named `6791341-0x3783028ce720304fc8877789e8eecdd2e349117c` in this repository.
