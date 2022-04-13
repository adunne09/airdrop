// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Airdrop is ERC721URIStorage {
    address public owner;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => AirdropItem) private tokenIdToAirdropItem;

    struct AirdropItem {
        uint256 tokenId;
        address sender;
        address recipient;
        bool claimed;
    }

    event AirdropItemEvent (
        uint256 indexed tokenId,
        address sender,
        address recipient,
        bool claimed
    );

    // there's probably a modifier or function in openzeppelin that handles this
    modifier idExists(uint tokenId) {
      require(tokenIdToAirdropItem[tokenId].recipient != address(0), "Token id does not exist");
      _;
    }

    constructor() ERC721("Airdrop Tokens", "ADT") {
        owner = payable(msg.sender);
    }

    function createToken(string memory tokenURI, address recipient) external returns (uint) {
        require(msg.sender != recipient, "Sender and recipient cannot match");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        tokenIdToAirdropItem[newTokenId] = AirdropItem(
            newTokenId,
            msg.sender,
            recipient,
            false
        );

        _transfer(msg.sender, address(this), newTokenId);

        emit AirdropItemEvent(
            newTokenId,
            msg.sender,
            recipient,
            false
        );

        return newTokenId;
    }

    function fetchSentItems() external view returns (AirdropItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint senderItemCount = 0;

        for (uint i = 0; i < itemCount; i++) {
            if (tokenIdToAirdropItem[i + 1].sender == msg.sender) {
                senderItemCount++;
            }
        }

        if (senderItemCount == 0) {
            return new AirdropItem[](0);
        }
        
        AirdropItem[] memory senderItems = new AirdropItem[](senderItemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < itemCount; i++) {
            if (tokenIdToAirdropItem[i + 1].sender == msg.sender) {
                senderItems[currentIndex++] = tokenIdToAirdropItem[i + 1];
            }
        }

        return senderItems;
    }

    function fetchReceivedItems() external view returns (AirdropItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint recipientItemCount = 0;

        for (uint i = 0; i < itemCount; i++) {
            if (tokenIdToAirdropItem[i + 1].recipient == msg.sender) {
                recipientItemCount++;
            }
        }

        if (recipientItemCount == 0) {
            return new AirdropItem[](0);
        }
        
        AirdropItem[] memory recipientItems = new AirdropItem[](recipientItemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < itemCount; i++) {
            if (tokenIdToAirdropItem[i + 1].recipient == msg.sender) {
                recipientItems[currentIndex++] = tokenIdToAirdropItem[i + 1];
            }
        }

        return recipientItems;
    }

    // should this exist or should the claimItem function simply return the newly claimed item
    function getAirdropItem(uint256 tokenId) external view idExists(tokenId) returns (AirdropItem memory) {
        return tokenIdToAirdropItem[tokenId];
    }

    function claimItem(uint256 tokenId) external idExists(tokenId) {
        require(tokenIdToAirdropItem[tokenId].recipient == msg.sender, "Not recipient");

        _transfer(address(this), msg.sender, tokenId);
        
        tokenIdToAirdropItem[tokenId].claimed = true;

        emit AirdropItemEvent (
            tokenId,
            tokenIdToAirdropItem[tokenId].sender,
            msg.sender,
            true
        );

        // return item?
    }
}
