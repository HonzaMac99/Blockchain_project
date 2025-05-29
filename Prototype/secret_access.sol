// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiDataAccess {
    address public owner;

    enum DataType { Sensor, Image, Video }

    struct DataInfo {
        uint256 price;
        string accessMessage;
    }

    mapping(DataType => DataInfo) public dataInfo;
    mapping(address => mapping(DataType => bool)) public hasPaid;

    constructor() {
        owner = msg.sender;

        // Initialize data types with prices and messages
        dataInfo[DataType.Sensor] = DataInfo({
            price: 0.005 ether,
            accessMessage:
                "==============================\n"
                "|        ACCESS TOKEN        |\n"
                "|----------------------------|\n"
                "|    Access key to Sensor    |\n"
                "|    Keep it confidential!   |\n"
                "=============================="
        });

        dataInfo[DataType.Image] = DataInfo({
            price: 0.01 ether,
            accessMessage:
                "==============================\n"
                "|        ACCESS TOKEN        |\n"
                "|----------------------------|\n"
                "|    Access key to Image     |\n"
                "|    Keep it confidential!   |\n"
                "=============================="
        });

        dataInfo[DataType.Video] = DataInfo({
            price: 0.02 ether,
            accessMessage:
                "==============================\n"
                "|        ACCESS TOKEN        |\n"
                "|----------------------------|\n"
                "|    Access key to Video     |\n"
                "|    Keep it confidential!   |\n"
                "=============================="
        });
    }

    // Get the price of a data type
    function getPrice(DataType _type) external view returns (uint256) {
        return dataInfo[_type].price;
    }

    // Pay for access to a specific data type
    function buyAccess(DataType _type) external payable {
        require(!hasPaid[msg.sender][_type], "Already purchased");
        require(msg.value >= dataInfo[_type].price, "Not enough ETH sent");

        hasPaid[msg.sender][_type] = true;

        (bool sent, ) = owner.call{value: msg.value}("");
        require(sent, "Payment failed");
    }

    // Get the access message after paying
    function getAccessMessage(DataType _type) external view returns (string memory) {
        require(hasPaid[msg.sender][_type], "Access not purchased");
        return dataInfo[_type].accessMessage;
    }

    // Owner can update prices or messages
    function updateDataInfo(DataType _type, uint256 _price, string memory _message) external {
        require(msg.sender == owner, "Only owner can update");
        dataInfo[_type] = DataInfo({price: _price, accessMessage: _message});
    }

    // Withdraw any funds stuck in the contract (precaution)
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
}

