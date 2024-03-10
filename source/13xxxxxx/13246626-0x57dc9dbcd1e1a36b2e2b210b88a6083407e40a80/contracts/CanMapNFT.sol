// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//                                                                                             o
//               /~~~~~~~~~~~~~~~\_____________________________________________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\______________________^______________________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\_____________________/~\_____________________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\______________^_____/~~~\_____^______________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\______________/~\__/~~~~~\__/~\______________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\______________/~~\/~~~~~~~\/~~\______________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\_________^____/~~~~~~~~~~~~~~~\____^_________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\________/~~\___/~~~~~~~~~~~~~\___/~~\________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\_/~~~~~~~~~~~\_/~~~~~~~~~~~~~\_/~~~~~~~~~~~\_/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\__/~~~~~~~~~~~\/~~~~~~~~~~~~~\/~~~~~~~~~~~\__/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\___/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\_/~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\_/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\____/~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\____/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\________/~~~~~~~~~~~~~~~~~~~~~~~~~~~\________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\___________/~~~~~~~~~~~~~~~~~~~~~\___________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\___________/~~~~~~~~~~~~~~~~~~~~~\___________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\_____________________/~\_____________________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\_____________________/~\_____________________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\_____________________/~\_____________________/~~~~~~~~~~~~~~~|
//               /~~~~~~~~~~~~~~~\_____________________________________________/~~~~~~~~~~~~~~~|
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                             |
//                                                                                            |~|
//   ______                                                                                   |||
//  /      \                                                                                 .'|`.
// |  $$$$$$\  ______   _______                                                              |||||
// | $$   \$$ |      \ |       \                                                            .'|||`.
// | $$        \$$$$$$\| $$$$$$$\                                                         /\|||||||/\
// | $$   __  /      $$| $$  | $$                                                        :%%|=====|%%:
// | $$__/  \|  $$$$$$$| $$  | $$                                                        |  |/ | \|  |
//  \$$    $$ \$$    $$| $$  | $$                                                        |--| -O  |--|
//   \$$$$$$   \$$$$$$$ \$$   \$$                                                        |--|\   /|--|
//  __       __                                     __    __  ________  ________         |==|%%%%%|==|
// |  \     /  \                                    |  \  |  \|        \|        \       |  |ooooo|  |
// | $$\   /  $$  ______    ______    _______       | $$\ | $$| $$$$$$$$ \$$$$$$$$       |  |"""""|  |
// | $$$\ /  $$$ |      \  /      \  /       \      | $$$\| $$| $$__       | $$          |  |||||||  |
// | $$$$\  $$$$  \$$$$$$\|  $$$$$$\|  $$$$$$$      | $$$$\ $$| $$  \      | $$          |  |||||||  |
// | $$\$$ $$ $$ /      $$| $$  | $$ \$$    \       | $$\$$ $$| $$$$$      | $$          |  ||=|=||  |
// | $$ \$$$| $$|  $$$$$$$| $$__/ $$ _\$$$$$$\      | $$ \$$$$| $$         | $$          |  ||=|=||  |
// | $$  \$ | $$ \$$    $$| $$    $$|       $$      | $$  \$$$| $$         | $$          |  ||=|=||  |
//  \$$      \$$  \$$$$$$$| $$$$$$$  \$$$$$$$        \$$   \$$ \$$          \$$          |  ||=|=||  |
//                        | $$                                                           |  ||=|=||  |
//                  |-----| $$                        |-----|                            |  ||=|=||  |                            |-----|                           |-----|
//                  :. | .\ $$       .__.             :. | .:                            |/\||^|^||/\|                            :. | .:             .__.          :. | .:
//                 .'| | |`.         :..:            .'| | |`.              _      _     |""|"""""|""|     _      _              .'| | |`.            :..:         .'| | |`.
//                .'|| | ||`.       .'||`.          .'|| | ||`.            |=|    |=|    |  | ,^. |  |    |=|    |=|            .'|| | ||`.          .'||`.       .'|| | ||`.
//               .' == | == `.     .'||||`.        .' == | == `.           |=|    |=|    |__|/|||\|__|    |=|    |=|           .' == | == `.        .'||||`.     .' == | == `.
//               |__._____.__|---------------------|__._____.__|-------------------------|  |||||||  |-------------------------|__._____.__|---------------------|__._____.__|
//               |%%|||||||%%| | | | | | | | | | | |%%|||||||%%| | | | | | | | | | | | | |  |||||||  | | | | | | | | | | | | | |%%|||||||%%| | | | | | | | | | | |%%|||||||%%|
//               |  |||||||  | | | | | | | | | | | |  |||||||  | | | | | | | | | | | | | |  |||||||  | | | | | | | | | | | | | |  |||||||  | | | | | | | | | | | |  |||||||  |
//               |  |||||||  | | | | | | | | | | | |  |||||||  | | | | | | | | | | | | | |  |||||||  | | | | | | | | | | | | | |  |||||||  | | | | | | | | | | | |  |||||||  |
//               |  |||||||  | |^| |^| |^| |^| |^| |  |||||||  | |^| |^| |^| |^| |^| |^| |  |||||||  | |^| |^| |^| |^| |^| |^| |  |||||||  | |^| |^| |^| |^| |^| |  |||||||  |
//               |  |||||||  |---------------------|  |||||||  |-------------------------|  |||||||  |-------------------------|  |||||||  |---------------------|  |||||||  |
//               |--|||||||--| ||| ||| ||| ||| ||| |--|||||||--| ||| ||| ||| ||| ||| ||| |--|-----|--| ||| ||| ||| ||| ||| ||| |--|||||||--| ||| ||| ||| ||| ||| |--|||||||--|
//               |  |||||||  |                     |  |||||||  |                         |  | ,^. |  |                         |  |||||||  |                     |  |||||||  |
//               |  |||||||  | ||| ||| ||| ||| ||| |  |||||||  | ||| ||| ||| ||| ||| ||| |  |/-"-\|  | ||| ||| ||| ||| ||| ||| |  |||||||  | ||| ||| ||| ||| ||| |  |||||||  |
//               |  |||||||  |                     |  |||||||  |                         |  |=.^.=|  |                         |  |||||||  |                     |  |||||||  |
//               |  |||||||  | ||| ||| ||| ||| ||| |  |||||||  | ||| ||| ||| ||| ||| ||| |  |=| |=|  | ||| ||| ||| ||| ||| ||| |  |||||||  | ||| ||| ||| ||| ||| |  |||||||  |
//               |  |||||||  |        .___.        |  |||||||  |                         |  |=| |=|  |                         |  |||||||  |        .___.        |  |||||||  |
//               |  |||||||  | ||| || |/"\| || ||| |  |||||||  | ||| ||| ||| ||| ||| ||| |  |=| |=|  | ||| ||| ||| ||| ||| ||| |  |||||||  | ||| || |/"\| || ||| |  |||||||  |
//               |__|||||||__|________|___|________|__|||||||__|_________________________|__|=|_|=|__|_________________________|__|||||||__|________|___|________|__|||||||__|
//               @@8#8@%##%@8#88@%#%@##@#8%@#%@#8@8##8@##%%@#8%@@%#88@@#8#@#%@#8@%#@|^|_________________|^|#%@8%#@#@8#%@%#@8#@8#@%#%@8#@##@8#%@##8@#@%%##@8%#@#8#@#%##@##8#@%@
//               @%#8%8@#%@#8%8@#%#%@@8#@#%@#@#8#%@@8#8#%%@#@8@8#8#@%@8#8#%@#88@@#%8|^|_________________|^|#@%@%@88#@%8@#@@8@8#%@%8@8#%@%#8%#%@8%88#@#%@#%%8###@8%8%@%8#%#8#@@
//               @#%@8@#%8@8@#8%%8#@%8##@%8@##8#8%#@#8%#%8#@8#8%8%%8#8@###8@@%@8%#8#|^|_________________|^|@#%@8#%%8%@@8@%#@#@@#8#8%8@%#@8#@%@#8%8@8#%@%8#@#8@88#%#@%8@@#@##%@

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CanMapNFT is Ownable, ERC721Enumerable, ERC721Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    uint256 totalCanMaps = 10000;
    uint256 private randomnessA;
    uint256 private randomnessB;
    uint256 amountPerCanMap = 0.02 ether;

    uint256 public winningAmount = 0;
    uint256 public devAmount = 0;

    uint256 maxPurchase;
    address cryptoChad;

    mapping(uint256 => uint256) private randomizerDecoder;

    using SafeMath for uint256;

    string private _baseTokenURI;

    constructor(string memory baseTokenURI) ERC721("CanMapNFT", "CANMAP") {
        _baseTokenURI = baseTokenURI;
        randomnessA = 2 * 3 * 23;
        randomnessB = 1337;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw_half() external onlyOwner {
        payable(owner()).transfer(devAmount);
    }

    function send_half_to_winner(address addy) external onlyOwner {
        payable(addy).transfer(winningAmount);
    }

    function getMintNumber(uint256 number) public view returns (uint256) {
        return randomizerDecoder[number];
    }

    /**
     * Let's mint some Can Maps!
     */
    function mintNFT(uint256 amount) public payable whenNotPaused {
        require(amount <= 10, "Max mint per tx is 10");
        require(
            totalSupply().add(amount) <= totalCanMaps,
            "Purchase would exceed number of maps left"
        );

        uint256 amountDue = amountPerCanMap.mul(amount);
        require(msg.value == amountDue, "Payment amount incorrect.");

        for (uint256 i = 0; i < amount; i++) {
            _tokenIdTracker.increment();
            uint256 newItemId = _tokenIdTracker.current();
            uint256 nft_id = ((randomnessA.mul(newItemId)).add(randomnessB))
                .mod(totalCanMaps);
            randomizerDecoder[nft_id] = newItemId;
            _safeMint(msg.sender, nft_id);
        }
        uint256 half = amountDue.div(2);
        devAmount += half;
        winningAmount += half;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be owner
     */
    function pause() public virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev These are needed because we double import ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

