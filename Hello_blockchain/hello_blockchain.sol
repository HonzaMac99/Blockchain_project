// Hello.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hello {
    string public message;

    function setMessage(string calldata newMessage) public {
        message = newMessage;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}