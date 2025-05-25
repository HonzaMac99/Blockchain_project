// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecretSale {
    address public owner;
    address public buyer;
    uint256 public price;
    string private secretKey;
    bool public keyRevealed;

    constructor(uint256 _price, string memory _secretKey) {
        owner = msg.sender; // Seller becomes the owner
        price = _price;
        secretKey = _secretKey;
        keyRevealed = false;
    }

    // Buyer sends money to purchase the secret key
    function buy() public payable {
        require(!keyRevealed, "Secret already purchased.");
        require(msg.value >= price, "Insufficient payment.");
        
        buyer = msg.sender;
        keyRevealed = true;

        // Transfer funds to the seller
        payable(owner).transfer(price);

        // Refund excess if any
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // Buyer retrieves the secret key
    function getSecretKey() public view returns (string memory) {
        require(msg.sender == buyer, "Not authorized.");
        require(keyRevealed, "Payment not completed.");
        return secretKey;
    }
}