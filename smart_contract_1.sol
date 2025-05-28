// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DataMarketplace {
    address public owner;
    uint public dataIdCounter;

    struct DataItem {
        uint id;
        address payable seller;
        string ipfsHash;
        uint price;
        bool isPurchased;
        address buyer;
        string decryptionKey;
    }

    mapping(uint => DataItem) public dataItems;

    event DataListed(uint id, address seller, string ipfsHash, uint price);
    event DataPurchased(uint id, address buyer);
    event KeyRevealed(uint id, string key);

    constructor() {
        owner = msg.sender;
    }

    function listData(string memory _ipfsHash, uint _price) external {
        dataIdCounter++;
        dataItems[dataIdCounter] = DataItem(
            dataIdCounter,
            payable(msg.sender),
            _ipfsHash,
            _price,
            false,
            address(0),
            ""
        );
        emit DataListed(dataIdCounter, msg.sender, _ipfsHash, _price);
    }

    function purchaseData(uint _id) external payable {
        DataItem storage item = dataItems[_id];
        require(!item.isPurchased, "Already purchased");
        require(msg.value == item.price, "Incorrect price");

        item.isPurchased = true;
        item.buyer = msg.sender;

        emit DataPurchased(_id, msg.sender);
    }

    function revealKey(uint _id, string memory _key) external {
        DataItem storage item = dataItems[_id];
        require(msg.sender == item.seller, "Only seller can reveal key");
        require(item.isPurchased, "Not purchased yet");

        item.decryptionKey = _key;
        item.seller.transfer(item.price);

        emit KeyRevealed(_id, _key);
    }

    function getKey(uint _id) external view returns (string memory) {
        DataItem memory item = dataItems[_id];
        require(msg.sender == item.buyer, "Not authorized");
        return item.decryptionKey;
    }

    function getData(uint _id) public view returns (
        string memory ipfsHash,
        uint price,
        bool isPurchased,
        address buyer
    ) {
        DataItem memory item = dataItems[_id];
        return (item.ipfsHash, item.price, item.isPurchased, item.buyer);
    }
}
