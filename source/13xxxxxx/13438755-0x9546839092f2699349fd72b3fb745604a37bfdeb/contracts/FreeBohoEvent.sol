// SPDX-License-Identifier: ISC

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/**
 * @title ERC721
 * @dev Abstract base implementation for ERC721 functions utilized within dispensary contract.
 */
abstract contract ERC721 {
    using SafeMath for uint256;
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view virtual returns (uint256 tokenId);
    function balanceOf(address owner) external view virtual returns (uint256 balance);
}

contract FreeBohoEvent is ERC721Holder, Ownable {
    using SafeMath for uint256;

    /**************************************************************/
    /*********************** Events & Vars ************************/
    /**************************************************************/
    // Boho Bones ERC721 Contract
    ERC721 public bohoBonesContract = ERC721(0x6B521ADC1Ca2fC6819dddB66b24e458FeD0780c6);

    // Dispensary wallet
    address public dispensaryWallet = 0x1d3F0BaE0dD29aaEaCECC7F73b3A236a61369dD7;

    mapping(address => uint256) public freeBohoBonesClaims;

    // Bool to pause/unpause gift event
    bool public isActive = false;

    /**
     * @param claimee Address of the claimee.
     */
    event Claim(address claimee);

    /**************************************************************/
    /************************ Constructor *************************/
    /**************************************************************/
    constructor() {freeBohoBonesClaims[0x8DD23f498DD5543D2EB4fc25E7126B38e764c1AC] = 29;
        freeBohoBonesClaims[0xad0178f0bD6366c8ea06148D3250FDc1103Cb555] = 25;
        freeBohoBonesClaims[0xC7Ff03e2bf706BD0b45d59dd964bd9c39De1eC2D] = 18;
        freeBohoBonesClaims[0x0BbF707661Ec707cf3d0f78A053558da88Cb086c] = 14;
        freeBohoBonesClaims[0xc1b52456b341f567dFC0Ee51Cae40d35F507129E] = 8;
        freeBohoBonesClaims[0x1d3F0BaE0dD29aaEaCECC7F73b3A236a61369dD7] = 5;
        freeBohoBonesClaims[0x98F32222F1A9ED6A2E71FfC7c322bEE1A8AE5f2A] = 5;
        freeBohoBonesClaims[0xB14Ff6a76573DB4FebeC7E002ea5CB01bfCeF784] = 4;
        freeBohoBonesClaims[0xEFAa2607F171b6df935aC679253734223A3275a4] = 4;
        freeBohoBonesClaims[0x8cE584fe9609fe2F0EFD1a8b9b7fc4846C32e679] = 3;
        freeBohoBonesClaims[0xd45858221bc7170BA813495f8C777c006189F910] = 3;
        freeBohoBonesClaims[0xEc7641e298aF02c19171451381C570327389b0c2] = 3;
        freeBohoBonesClaims[0xDd4C53C7747660fb9954E5fc7B36f94b4A297922] = 3;
        freeBohoBonesClaims[0xb3a3eed660EA4C43Caf8774cfA3e09049C798468] = 3;
        freeBohoBonesClaims[0xbd87223189f01ad1A5aa35324744A70edeEF24Bc] = 3;
        freeBohoBonesClaims[0x36A8A94153514202E1a0b957659fE2599B1eB0F1] = 3;
        freeBohoBonesClaims[0xE9cF68cdDB318e142fA40D60C4458425F78Ab18E] = 2;
        freeBohoBonesClaims[0x1Bb01159AB168ACD0Cc055eAD980729A2ADAe919] = 2;
        freeBohoBonesClaims[0x2d021B60d85A36a3Cc25fbc9959A1749a8Dbd697] = 2;
        freeBohoBonesClaims[0x39dB72Dc9494Ed36Fffd3A3458f1eb969213E9A1] = 2;
        freeBohoBonesClaims[0x5EB57983CA289A3F06c25Bb968D467283AB9925C] = 2;
        freeBohoBonesClaims[0xe397dD922a12149Dc346c405c89c4cdbf5ae99FC] = 2;
        freeBohoBonesClaims[0xD8f76F9B09984150ae868DEB81ECBf33352f9fD8] = 1;
        freeBohoBonesClaims[0xA5C8C195E6136F29Ef27d9ab9Cccb4440B981B96] = 1;
        freeBohoBonesClaims[0xC830A16B73EEF1b47FeB25210b0E40BE06C5f8eF] = 1;
        freeBohoBonesClaims[0xEa704D7c14D0073C5548ed19b73bfD060a618079] = 1;
        freeBohoBonesClaims[0x6f3000B303947B36323C7c3755a1801b450c7f9f] = 1;
        freeBohoBonesClaims[0xA30DA7f10BbAF3Bc2f2F988ed3f12D486397F454] = 1;
        freeBohoBonesClaims[0x1D144AE3991C86504a38aA9A3EB4CCD27fa4af72] = 1;
        freeBohoBonesClaims[0x0B3B6585e71c2175667360cce8dDe426D4B63f88] = 1;
        freeBohoBonesClaims[0x491E7B27d69597EF6b2cAB4002Da3B9C0229943c] = 1;
        freeBohoBonesClaims[0x30104D7F97d93b06A907589d122491A4527a0a9b] = 1;
        freeBohoBonesClaims[0x73Ac429c11f80480D50eD48cDA7D84d36A3375aa] = 1;
        freeBohoBonesClaims[0xa5C065337C5bADb5f5De5376d3AfB97f510Aa193] = 1;
        freeBohoBonesClaims[0x1aD0D21036d845acF68a26907338F9180b58E992] = 1;
        freeBohoBonesClaims[0x3Df9e23C1e069702D86736BE5C2f425b9e528835] = 1;
        freeBohoBonesClaims[0xE463d56e80da7292A90faF77bA3F7524F0a0dCCd] = 1;
        freeBohoBonesClaims[0xd9888eEFfab4b0a215C8af47923d80190beAcd5b] = 1;
        freeBohoBonesClaims[0xf269a8883a87AdB37CCe8a5de21Df504796654f5] = 1;
        freeBohoBonesClaims[0xB74FA1c2BDA1D5b5FFC9C5818088F4CFD1De3376] = 1;
        freeBohoBonesClaims[0x617970384Ef3f78c67bcd47D0554E26a0bA315Fa] = 1;
        freeBohoBonesClaims[0x7fb6F52996ba02884Fd4Cd136bB2af3D8909c56C] = 1;
        freeBohoBonesClaims[0x7bE2f3eB66634762ba9b00287104e3f904a7A982] = 1;
        freeBohoBonesClaims[0x849fc8D14979b3525F00D022DD1a600Ed45fEd23] = 1;
        freeBohoBonesClaims[0x1a968C13bE8eafFaDa60d3d0A1128aB4B914960A] = 1;
        freeBohoBonesClaims[0xE2aB3D4d0684eBF9D994dAbA3AcD91caCD99D862] = 1;
        freeBohoBonesClaims[0xBF72F634b1938f3dFA6e11c92C2AA115e55497dC] = 1;
        freeBohoBonesClaims[0x73EfD6D8CB6AC17e147944b27a7a9890a8bc48b1] = 1;
        freeBohoBonesClaims[0x6f0290eEe760B6e025ff1546ec1154546c71C203] = 1;
        freeBohoBonesClaims[0xEB878d6728CB326360049FE1F14E3F48B4fFAFdd] = 1;
        freeBohoBonesClaims[0xC2F33614aE5EC27B4b27785A74aeF12EC45087C0] = 1;
        freeBohoBonesClaims[0x1D751999d27F4EB8E48A280075dCdcE546078fbd] = 1;
        freeBohoBonesClaims[0x50869083Fd81B1858864bF72b843a060De7Fa695] = 1;
        freeBohoBonesClaims[0xD74597B0D23753d186d79f96Da01a0b73cAe98aA] = 1;
        freeBohoBonesClaims[0x4E10b980073D5Db98A10352a70c7BdDc78CCa0A6] = 1;
        freeBohoBonesClaims[0xb1F63d177fD6A8Df51e85Ed0DBbf498f1D778C84] = 1;
        freeBohoBonesClaims[0xEb6C72D50a6F9fA53e25946085373d40c4437e99] = 1;
        freeBohoBonesClaims[0xE55E2d78b143BA8f52e5e5EFb35c97455022e27c] = 1;
        freeBohoBonesClaims[0xe542fFa2D9FB68F7F72f7E6b1A1d629650cBdE2E] = 1;
        freeBohoBonesClaims[0x3ad13bC4030129269537F7fF97Cb14B9b94465Fd] = 1;
        freeBohoBonesClaims[0x94C0aF134A748f4E973455Fc3D6c4130e47DDb5d] = 1;
        freeBohoBonesClaims[0xAcf63dc3a045E5B530A3c1aE8F92565368e7BbeF] = 1;
        freeBohoBonesClaims[0x7cF85fdC696EE5A9f872c3408dDb57c587aDC079] = 1;
        freeBohoBonesClaims[0x017715B9A71DaBed2DdAE0BBBb6b0896509C8212] = 1;
        freeBohoBonesClaims[0x2Ac8507AC54FbBf114FDf5520E3D9BD0f738C281] = 1;
        freeBohoBonesClaims[0x7768FBc67afecF2b4Caee9D1841ad14637D13652] = 1;
        freeBohoBonesClaims[0x49f407e2Af4b1305f61b5F65e660eC2a65DD588b] = 1;
        freeBohoBonesClaims[0xEB421fE44B25dA86982CDc36c525D5f1BAAFcfcA] = 1;
        freeBohoBonesClaims[0x902222853F4885A685962bd191D885c0A5b92Fc7] = 1;
        freeBohoBonesClaims[0x263994646816dBfD5849F44dec7909fc2c1f8037] = 1;
        freeBohoBonesClaims[0x2DfC6f2EB7f89EA1ad1C785c94e407e658EBc645] = 1;
        freeBohoBonesClaims[0x3f4772105eE6bFF1241A8564D32525Bb46725401] = 1;
        freeBohoBonesClaims[0xe2817B82845A19D93E817EDfB0F68E78f34D35A5] = 1;
        freeBohoBonesClaims[0x8d4B4c1eC39148E22c296c0090f7D4f3478cFE75] = 1;
        freeBohoBonesClaims[0x5aA91fc20C63C03f0C6e108FaDcFe521F117Bbd4] = 1;
        freeBohoBonesClaims[0x0b9c75E3786Fbe0c7c795C4fEe19111693b529C8] = 1;
        freeBohoBonesClaims[0x7642afA2F917Be8DEe1e4e16033A8CA3B8389aB3] = 1;
        freeBohoBonesClaims[0x50D356d2440c0e2Bcdbb2f26f7fFBfAd135358FE] = 1;
        freeBohoBonesClaims[0x6B796152085318d1c415762e9d876E50593E1B9F] = 1;
        freeBohoBonesClaims[0x9F9E9430D66b6B05EA0E007E8E957a9Ba41ad1D1] = 1;
        freeBohoBonesClaims[0x49E7C2De8b8e4886CE2511Bec96325f96F2D71C3] = 1;
        freeBohoBonesClaims[0xeb67a9E45d3D74f3794Dd716651d40Ef97Fc1b51] = 1;
        freeBohoBonesClaims[0x207d48a7C63960451bD3E02A0A43AA66f550196E] = 1;
        freeBohoBonesClaims[0xAfc4CbA5Af99f89b5a7aCD2cc04876dF6889d34B] = 1;
        freeBohoBonesClaims[0xd1Af703A834d074617785c989291eC0067Faa56F] = 1;
        freeBohoBonesClaims[0x3361Ed013fEf5fBa7b7a19C6de6EdcF686813820] = 1;
        freeBohoBonesClaims[0xDB720e23034d380F414bb31c142B501622458a1B] = 1;
        freeBohoBonesClaims[0x92DbC41f895d65fE7081cc2bEE91E9EAae7EA1c7] = 1;
        freeBohoBonesClaims[0x80136fE63bdB22b981D5C6E2738bd2216fB05C67] = 1;
        freeBohoBonesClaims[0x0C190A40D2925fB44D1e114963A8C642b8117A49] = 1;
        freeBohoBonesClaims[0xB0189F86c7D8079965CBF624dBd3AD5A01b00585] = 1;
        freeBohoBonesClaims[0x0c4037B72A0C63340FB530690EA123C612665A34] = 1;
        freeBohoBonesClaims[0xa54d7BD6E82152E061097869b9f478c800e103E4] = 1;
        freeBohoBonesClaims[0x215792FC17032988abEb64BdAeC23487AC384694] = 1;
        freeBohoBonesClaims[0x5966A41fd8588Ae21FD0A01DB36d1ba8C07D1eA5] = 1;
        freeBohoBonesClaims[0x112B22a9664a22D02426713EC9ffeB072f64E291] = 1;
        freeBohoBonesClaims[0x3043ec75e223C7c1aE74bcFA7EAab906f9ADC883] = 1;
        freeBohoBonesClaims[0x7d340fAA2A5cB6dEAaD18393477249334312a249] = 1;
        freeBohoBonesClaims[0x70781b7a217FB5798431225e829ab90A314a6845] = 1;
        freeBohoBonesClaims[0xBa44c50261348505F988Dc44F564568358B68EE6] = 1;
        freeBohoBonesClaims[0x2fb197c272879CACA350Fe0DbFE0e4de4984403E] = 1;
        freeBohoBonesClaims[0x72eA3953c6444cE68Ccaf23B93C306e56A591Db2] = 1;
        freeBohoBonesClaims[0xc63412bfeA02513132d829d9C396510a8065E564] = 1;
        freeBohoBonesClaims[0xD6e0Ce6a9A5AB32e0ac25F3c0241831268c70BF3] = 1;
        freeBohoBonesClaims[0xb8F5EE84E27497345dea6a1815027A41C8eaA7Eb] = 1;
        freeBohoBonesClaims[0xa627734D74AAb4D17c9EF358e5b44B0f951499E9] = 1;
        freeBohoBonesClaims[0x33094A50A0e29A22a2DAd090006fE27E3A2f0deb] = 1;
        freeBohoBonesClaims[0xc0114E2fCBc7fa985452AA73C986F947716c4b84] = 1;
        freeBohoBonesClaims[0x91107D20346BbBa8AeF12f34b541F3ec39a70575] = 1;
        freeBohoBonesClaims[0xA06941D533f7714f12387381284d7af21f58764e] = 1;
        freeBohoBonesClaims[0x6dd0E9b9bF3a19B89297FE22914C87F0e3402A96] = 1;
        freeBohoBonesClaims[0xf27BdcD155cC9f5e90baFE616D2E8cEe47609A7A] = 1;
        freeBohoBonesClaims[0x94F23611cBd115cdB78Acdc1401028a5526904Df] = 1;
        freeBohoBonesClaims[0x9678C36Dc13FF1c48bdEFfa0CC0Da14C4fFd4D92] = 1;
        freeBohoBonesClaims[0x074a19AefAC9E774d1b29F584B9ce74bc4D2b2de] = 1;
        freeBohoBonesClaims[0xff2450085510b5Eb86c7f9451d5FBc0cA5a793AA] = 1;
        freeBohoBonesClaims[0xa752C19A93B612caCF3dbc13D8E5E251eF6f75c1] = 1;
        freeBohoBonesClaims[0xC1E69Aef752f3b9B8BE4E6b2e6c7A9c04D7f1166] = 1;
    }

    /**************************************************************/
    /******************** Function Modifiers **********************/
    /**************************************************************/
    /**
     * @dev Prevents a function from running if contract is paused
     */
    modifier eventIsActive() {
        require(isActive == true, "FreeBohoEvent: Gift event has paused or ended.");
        _;
    }

    /**
     * @param claimee address of the claimee checking claimed status for.
     * @dev Prevents repeat claims for a given claimee.
     */
    modifier isNotClaimed(address claimee) {
        uint256 numClaims = freeBohoBonesClaims[claimee];
        require(numClaims != 0, "FreeBohoEvent: You have no more free Bohos to claim.");
        _;
    }


    /**************************************************************/
    /************** Access Controlled Functions *******************/
    /**************************************************************/
    /**
     * @dev Sets the gift event to unpaused if paused, and paused if unpaused.
     * @dev Can only be called by contract owner.
     */
    function flipEventState() public onlyOwner {
        isActive = !isActive;
    }

    /**
     * @param newBohoBonesContractAddress Address of the new Boho Bones ERC721 contract.
     * @dev Sets the address for the referenced Boho Bones ERC721 contract.
     * @dev Can only be called by contract owner.
     */
    function setBohoBonesContractAddress(address newBohoBonesContractAddress) public onlyOwner {
        bohoBonesContract = ERC721(newBohoBonesContractAddress);
    }


    /**
     * @param newDispensaryWallet Address of the new wallet free bohos will be dispensed from.
     * @dev Sets the address for the referenced dispensary wallet.
     * @dev Can only be called by contract owner.
     */
    function setDispensaryWallet(address newDispensaryWallet) public onlyOwner {
        dispensaryWallet = newDispensaryWallet;
    }
    
    /**
     * @param gifteeAddress Address to be added to the list of giftees.
     * @param numFreeBohoBones Amount of free boho bones to give to giftee.
     * @dev Can only be called by owner.
     */
    function addGifteeAddress(address gifteeAddress, uint256 numFreeBohoBones) public onlyOwner {
        require(gifteeAddress != address(0), "BohoBones: Cannot add burn address to the gift event.");
         
        freeBohoBonesClaims[gifteeAddress] = numFreeBohoBones;
    }

    /**
     * @param newGifteeAddresses Addresses to be added to the list of giftee addresses.
     * @param giftAmount Amount of free boho bones to give per address.
     * @dev Can only be called by owner.
     */
    function addGifteeAddresses(address[] memory newGifteeAddresses, uint256 giftAmount) public onlyOwner {
        for (uint256 i = 0; i < newGifteeAddresses.length; i++) {
            addGifteeAddress(newGifteeAddresses[i], giftAmount);
        }
    }

    /**
     * @param addressToDelete The address to remove from the giftee list.
     * @dev Can only be called by owner.
     */
    function removeGifteeAddress(address addressToDelete) public onlyOwner {
        delete freeBohoBonesClaims[addressToDelete];
    }

    /**
     * @param gifteeAddressesToDelete Addresses to be removed from the list of giftee addresses.
     * @dev Can only be called by owner.
     */
    function removeGifteeAddresses(address[] memory gifteeAddressesToDelete) public onlyOwner {
        for (uint256 i = 0; i < gifteeAddressesToDelete.length; i++) {
            removeGifteeAddress(gifteeAddressesToDelete[i]);
        }
    }

    /**************************************************************/
    /******************** Getter Functions ************************/
    /**************************************************************/
    /**
     * @dev Returns the balance of the dispensary wallet.
     */
    function getDispensaryBalance() public view returns (uint256) {
        return ERC721(bohoBonesContract).balanceOf(dispensaryWallet);
    }

    /**************************************************************/
    /******************** Claim Functions *************************/
    /**************************************************************/
    /**
     * @dev Claims one free boho for the given address.
     * @dev Can only be called when gift event is active.
     * @dev Can only be called by the owner of the free bohos.
     */
    function claimOneFreeBoho() internal eventIsActive isNotClaimed(msg.sender) {
        uint256 numFreeBohos = freeBohoBonesClaims[msg.sender];

        bohoBonesContract.safeTransferFrom(
            dispensaryWallet,
            msg.sender,
            bohoBonesContract.tokenOfOwnerByIndex(dispensaryWallet, 0)
        );

        // Reduce num free bohos by one
        freeBohoBonesClaims[msg.sender] = numFreeBohos.sub(1);

        // Emit claim event
        emit Claim(msg.sender);
    }

    /**
     * @dev Claims N free bohos for the given address.
     * @dev Can only be called when gift event is active.
     * @dev Can only be called by the owner of the free bohos.
     */
    function claimNFreeBohos(uint256 n) public eventIsActive isNotClaimed(msg.sender) {
        uint256 numFreeBohos = freeBohoBonesClaims[msg.sender];
        require(numFreeBohos >= n, "FreeBohoEvent: Not enough gifts left for address.");
        require(n > 0, "FreeBohoEvent: Please input a positive integer.");

        for (uint256 i = 0; i < n; i++) {
            claimOneFreeBoho();
        }
    }
}

