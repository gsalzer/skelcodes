*If you are looking for the 248,328 skelcodes used in our [EMSE 2024 paper](https://arxiv.org/abs/2303.10517), do `git checkout emse2024`.*

# SkelCodes

This repository contains the deployment code (contract creation code) as well
as the deployed code (runtime code) of contracts, self-destructed or not, from
Ethereum's main chain, *one for each type of skeleton*. Moreover, the folder
*source* contains the ABIs of those contracts, where the source code if
available from [Etherscan](etherscan.io). By the way the contracts were
selected, the collection of **241,292** bytecodes faithfully represents, in
most respects, the **45 million** contracts successfully deployed up to block
**14,000,000** (see below for the details of the selection process).

## Contents of the repository

The repository contains three directories, *source*, *deployment* and
*runtime*, of identical structure, containing the ABIs, deployment and runtime
codes of the contracts, respectively. The folder name *source* indicates that
for the addresses in this folder, the source code can be obtained from
[Etherscan](etherscan.io).

The codes are labeled `blockid-address.hex`. `address` is one of the addresses,
where the code has been deployed on Ethereum's main chain, and `blockid` is the
block of creation.  Note that the address by itself is not enough to identify
the codes uniquely:  Because of `CREATE2`, there are cases where different
codes have been successively deployed at the same address.

The codes are divided up into directories, with each directory covering the
range of 1,000,000 blocks.

| directory |    #codes  | with source      |
| --------- | ---------- |------------------|
|  0xxxxxx  |     2,515  |               34 |
|  1xxxxxx  |     3,269  |              328 |
|  2xxxxxx  |     2,562  |              352 |
|  3xxxxxx  |     3,972  |              934 |
|  4xxxxxx  |    17,226  |            6,614 |
|  5xxxxxx  |    25,789  |           11,390 |
|  6xxxxxx  |    22,780  |            8,952 |
|  7xxxxxx  |    15,374  |            5,601 |
|  8xxxxxx  |    14,061  |            5,347 |
|  9xxxxxx  |    15,967  |            5,340 |
| 10xxxxxx  |    21,329  |            9,858 |
| 11xxxxxx  |    33,238  |           17,648 |
| 12xxxxxx  |    28,630  |           16,264 |
| 13xxxxxx  |    34,580  |           23,281 |
| total     |   241,292  |          111,943 |

The file `info.csv` contains supplementary data for each bytecode, whereas
`contract2skelcode.csv.zip` maps the deployed contracts to the skelcodes in
this repository. See below for details.

The scripts `runtime/database2csv.sql` and `runtime/csv2files.bash`
document the extraction process. They are not overly useful if you don't have
access to the database they refer to.  Etherscan provides the source code with
additional information, packed in a `json` file. The script
`source/json2sol.py` can be used to extract the source code from such a file.

## Selection of bytecodes

1. We collect all runtime bytecodes (with the corresponding deployment codes)
   that resulted from a successful `CREATE`/`CREATE2` instruction or
   transaction before block 14,000,000 on Ethereum's main chain.

2. For each runtime code, we compute its skeleton, see
   [https://github.com/gsalzer/ethutils](https://github.com/gsalzer/ethutils/tree/main/doc/skeleton)
   for more information and scripts.
   In short, the skeleton is obtained from a bytecode by removing metadata and replacing all PUSH operations with their arguments by PUSH0.

3. We discard contracts with an empty skeleton, corresponding essentially to
   empty runtime codes, which are the result of self-destructing deployment
   code.

4. We group the runtime codes by skeleton. There may be several runtime codes
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
   codes are uploaded every day.

Currently 111,943 of the 241,292 codes (46%) possess a verified source.
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
10013630-0x3fd4804e3201df594e521b6a803898e0b0f4cd54.hex,10013630,48,0,0x3fd4804e3201df594e521b6a803898e0b0f4cd54,10013630,10813647,12,14,245,192,3,0.6.7
```
tells that the bytecode in file
`10013630-0x3fd4804e3201df594e521b6a803898e0b0f4cd54.hex` (directory
`10xxxxxx`) was deployed by message `0` of transaction `48` in block `10013630`
at the address `0x3fd4804e3201df594e521b6a803898e0b0f4cd54`. The contracts with
the same skeleton as this bytecode were deployed between the
blocks `10013630` and `10813647`. In total, there are `12` different bytecodes
and `14` deployments. Further information on this bytecode can be found at
`https://etherscan.io/address/0x3fd4804e3201df594e521b6a803898e0b0f4cd54`.
Columns 10, 11 and 12 roughly indicate the complexity of the bytecode:
Its total length is `245` bytes, whereas the length of the first code segment (the part that is actually executed) consists of just `192` bytes.
The code implements `3` methods (functions in Solidity).
The contract was generated by solc `0.6.7`.

### contract2skelcode.csv

The file `contract2skelcode.csv` contains one line for each contract of the
main chain (up to block 14,000,000). For size reasons, it is split into
16 files based on the first byte of the deployment address. It maps each
deployed contract to the corresponding skelcode in this repository.  The file
has the following fields.

   - The number of the *block*, where the contract has been deployed.
   - The number of the transaction, *tx*, within the block, where the contract has been deployed.
   - The number of the message, *msg*, within the transaction, where the contract has been deployed.
   - The *address*, at which the contract has been deployed.
   - If Etherscan has source code for the contract, the field `contractname` gives the name of the contract within the source files.
   - The fields *skel_block*, *skel_tx*, *skel_msg*, *skel_address* are the same information for the corresponding skelcode, which carries the name *skel_block*`-`*skel_address* in this repository.

As an example, the line
```
7323071,81,14,0xd7c2546027141d7d101985f1867a51c993effadb,CappedSTO,6791341,170,14,0x3783028ce720304fc8877789e8eecdd2e349117c
```
expresses that the contract deployed in block `7323071`, transaction `81`, message `14` at the main chain address `0xd7c2546027141d7d101985f1867a51c993effadb` has the same skeleton as the contract deployed in block `6791341`, transaction `170`, message `14` at address `0x3783028ce720304fc8877789e8eecdd2e349117c`. The latter contract is included in this repository. The contract at `0xd7c2546027141d7d101985f1867a51c993effadb` is called `CappedSTO` in the source code on Etherscan. The skelcode corresponding to the contract is named `6791341-0x3783028ce720304fc8877789e8eecdd2e349117c` in this repository.
