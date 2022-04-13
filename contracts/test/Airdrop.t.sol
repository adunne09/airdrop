// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/Vm.sol";
import "../Airdrop.sol";

contract NFTMarketTest is DSTest, Airdrop {
    Vm vm = Vm(HEVM_ADDRESS);
    Airdrop airdrop;

    function setUp() public {
        vm.prank(address(1));
        airdrop = new Airdrop();
    }

    // TODO-- test owner

    // how to test that functions emit events
    function testCreateToken() public {
        uint tokenId = airdrop.createToken("example uri", address(1));
        assertEq(tokenId, 1, "Incorrect token id");

        string memory tokenURI = airdrop.tokenURI(tokenId);
        assertEq(tokenURI, "example uri", "Incorrect token URI");
    }

    function testCreateTokenWithMatchingRecipientAddress() public {
        vm.prank(address(1));

        vm.expectRevert("Sender and recipient cannot match");
        airdrop.createToken("example uri", address(1));
    }

    function testFetchSentItems() public {
        vm.startPrank(address(2));
        
        airdrop.createToken("example uri", address(3));

        AirdropItem[] memory items = airdrop.fetchSentItems();
        assertEq(items.length, 1, "Items not found");
        
        address airdropItemSender = items[0].sender;
        assertEq(airdropItemSender, address(2), "Wrong sender");

        address airdropItemRecipient = items[0].recipient;
        assertEq(airdropItemRecipient, address(3), "Wrong recipient");

        bool claimed = items[0].claimed;
        assert(!claimed);
    }

    function testFetchSentItemsWithNoItems() public {
        AirdropItem[] memory items = airdrop.fetchSentItems();
        assertEq(items.length, 0, "Found items");
    }

    function testFetchReceivedItems() public {
        vm.prank(address(4));
        airdrop.createToken("example uri", address(5));

        vm.prank(address(5));
        AirdropItem[] memory items = airdrop.fetchReceivedItems();
        assertEq(items.length, 1, "Items not found");

        address airdropItemSender = items[0].sender;
        assertEq(airdropItemSender, address(4), "Wrong sender");

        address airdropItemRecipient = items[0].recipient;
        assertEq(airdropItemRecipient, address(5), "Wrong recipient");

        bool claimed = items[0].claimed;
        assert(!claimed);
    }

    function testFetchReceivedItemsWithNoItems() public {
        AirdropItem[] memory items = airdrop.fetchReceivedItems();
        assertEq(items.length, 0, "Found items");
    }

    function testClaimItem() public {
        vm.prank(address(5));
        uint tokenId = airdrop.createToken("example uri", address(6));

        vm.prank(address(6));
        airdrop.claimItem(tokenId);

        AirdropItem memory item = airdrop.getAirdropItem(tokenId);

        address airdropItemSender = item.sender;
        assertEq(airdropItemSender, address(5), "Wrong sender");

        address airdropItemRecipient = item.recipient;
        assertEq(airdropItemRecipient, address(6), "Wrong recipient");

        bool claimed = item.claimed;
        assert(claimed);
    }

    // could combine these into one testIdExistsModifier test
    function testIdExistsModifier() public {
        vm.expectRevert("Token id does not exist");
        airdrop.claimItem(0);
    }

    function testGetAirdropItemWithNonexistentId() public {
        vm.expectRevert("Token id does not exist");
        airdrop.getAirdropItem(0);
    }
}
