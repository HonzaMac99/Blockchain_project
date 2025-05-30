// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataExchange {
    address public owner;
    uint256 private tokenCounter;
    
    // Structure to represent a data product
    struct DataProduct {
        uint256 id;
        string name;
        string description;
        uint256 price; // Price in wei
        address seller;
        string ipfsHash; // IPFS hash where actual data is stored
        bool isActive;
        uint256 totalSales;
    }
    
    // Structure to represent a purchase
    struct Purchase {
        uint256 productId;
        address buyer;
        uint256 timestamp;
        string accessToken;
        bool isActive;
    }
    
    // Mappings
    mapping(uint256 => DataProduct) public dataProducts;
    mapping(address => mapping(uint256 => bool)) public hasPurchased; // buyer => productId => bool
    mapping(string => bool) public tokenExists; // to ensure unique tokens
    mapping(address => uint256[]) public buyerPurchases; // buyer's purchase history
    mapping(uint256 => Purchase) public purchases;
    
    // Events
    event DataProductListed(uint256 indexed productId, string name, uint256 price, address seller);
    event DataPurchased(uint256 indexed productId, address indexed buyer, string accessToken, uint256 timestamp);
    event AccessTokenGenerated(address indexed buyer, uint256 indexed productId, string token);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier productExists(uint256 _productId) {
        require(dataProducts[_productId].isActive, "Product does not exist or is inactive");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        tokenCounter = 0;
        
        // Pre-populate with some sample data products
        _addSampleProducts();
    }
    
    // Function to add sample products (for demo purposes)
    function _addSampleProducts() private {
        _listDataProduct(
            "IoT Sensor Data Package",
            "Real-time temperature, humidity, and air quality data from smart city sensors",
            0.01 ether,
            "QmSensorDataHash123"
        );
        
        _listDataProduct(
            "Weather Analytics Dataset",
            "Historical weather patterns and forecasting data for major cities",
            0.005 ether,
            "QmWeatherDataHash456"
        );
        
        _listDataProduct(
            "Traffic Flow Analysis",
            "Real-time traffic data and congestion patterns for urban planning",
            0.02 ether,
            "QmTrafficDataHash789"
        );
        
        _listDataProduct(
            "Financial Market Data",
            "High-frequency trading data and market sentiment analysis",
            0.05 ether,
            "QmFinancialDataHash101"
        );
    }
    
    // Internal function to list data products
    function _listDataProduct(
        string memory _name,
        string memory _description,
        uint256 _price,
        string memory _ipfsHash
    ) private {
        tokenCounter++;
        
        dataProducts[tokenCounter] = DataProduct({
            id: tokenCounter,
            name: _name,
            description: _description,
            price: _price,
            seller: owner, // For demo, owner is the seller
            ipfsHash: _ipfsHash,
            isActive: true,
            totalSales: 0
        });
        
        emit DataProductListed(tokenCounter, _name, _price, owner);
    }
    
    // Function for sellers to list new data products
    function listDataProduct(
        string memory _name,
        string memory _description,
        uint256 _price,
        string memory _ipfsHash
    ) public {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(_price > 0, "Price must be greater than 0");
        
        tokenCounter++;
        
        dataProducts[tokenCounter] = DataProduct({
            id: tokenCounter,
            name: _name,
            description: _description,
            price: _price,
            seller: msg.sender,
            ipfsHash: _ipfsHash,
            isActive: true,
            totalSales: 0
        });
        
        emit DataProductListed(tokenCounter, _name, _price, msg.sender);
    }
    
    // Function to purchase data
    function purchaseData(uint256 _productId) public payable productExists(_productId) {
        DataProduct storage product = dataProducts[_productId];
        
        require(msg.value >= product.price, "Insufficient payment");
        require(!hasPurchased[msg.sender][_productId], "Already purchased this data");
        
        // Mark as purchased
        hasPurchased[msg.sender][_productId] = true;
        product.totalSales++;
        
        // Generate unique access token
        string memory accessToken = _generateAccessToken(_productId, msg.sender);
        
        // Record the purchase
        purchases[tokenCounter] = Purchase({
            productId: _productId,
            buyer: msg.sender,
            timestamp: block.timestamp,
            accessToken: accessToken,
            isActive: true
        });
        
        // Add to buyer's purchase history
        buyerPurchases[msg.sender].push(_productId);
        
        // Transfer payment to seller (minus small platform fee)
        uint256 platformFee = (msg.value * 5) / 100; // 5% platform fee
        uint256 sellerAmount = msg.value - platformFee;
        
        // Transfer to seller
        payable(product.seller).transfer(sellerAmount);
        
        // Refund excess payment if any
        if (msg.value > product.price) {
            payable(msg.sender).transfer(msg.value - product.price);
        }
        
        emit DataPurchased(_productId, msg.sender, accessToken, block.timestamp);
        emit AccessTokenGenerated(msg.sender, _productId, accessToken);
    }
    
    // Function to generate unique access token
    function _generateAccessToken(uint256 _productId, address _buyer) private returns (string memory) {
        string memory token = string(abi.encodePacked(
            "dataex_",
            _toString(_productId),
            "_",
            _toString(block.timestamp),
            "_",
            _toAsciiString(_buyer)
        ));
        
        // Ensure token is unique
        require(!tokenExists[token], "Token collision occurred");
        tokenExists[token] = true;
        
        return token;
    }
    
    // Function to verify access token and get IPFS hash
    function getDataAccess(string memory _accessToken) public view returns (string memory ipfsHash, bool isValid) {
        // In a real implementation, you'd parse the token and verify ownership
        // For now, we'll return a simplified version
        
        // This is a simplified check - in production, you'd want more robust verification
        if (tokenExists[_accessToken]) {
            return ("QmExampleHash", true);
        }
        
        return ("", false);
    }
    
    // Function to check if user has purchased specific data
    function checkPurchaseStatus(address _buyer, uint256 _productId) public view returns (bool) {
        return hasPurchased[_buyer][_productId];
    }
    
    // Function to get all products
    function getAllProducts() public view returns (DataProduct[] memory) {
        DataProduct[] memory activeProducts = new DataProduct[](tokenCounter);
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= tokenCounter; i++) {
            if (dataProducts[i].isActive) {
                activeProducts[activeCount] = dataProducts[i];
                activeCount++;
            }
        }
        
        // Resize array to actual size
        DataProduct[] memory result = new DataProduct[](activeCount);
        for (uint256 i = 0; i < activeCount; i++) {
            result[i] = activeProducts[i];
        }
        
        return result;
    }
    
    // Function to get buyer's purchase history
    function getBuyerPurchases(address _buyer) public view returns (uint256[] memory) {
        return buyerPurchases[_buyer];
    }
    
    // Owner functions
    function withdrawPlatformFees() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    function deactivateProduct(uint256 _productId) public onlyOwner {
        dataProducts[_productId].isActive = false;
    }
    
    // Utility functions
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    function _toAsciiString(address x) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = _char(hi);
            s[2*i+1] = _char(lo);            
        }
        return string(s);
    }
    
    function _char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    // Fallback function
    receive() external payable {
        revert("Direct payments not accepted");
    }
}