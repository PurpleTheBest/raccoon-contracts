// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import './resourceFactory.sol';
import './buildingFactory.sol';
import './shopFactory.sol';
import './map.sol';

contract Game is Ownable {
    using Utils for *;

    struct Contracts{
        address goldContract;
        address castleContract;
        address[] buildingContracts;
        address[] resourceContracts;
    }

    address private _mapAddress;
    address private _buildingFactoryAddress;
    address private _resourceFactoryAddress;
    address private _shopFactoryAddress;

    // Owner => owned coordinates
    mapping(address => uint256[]) private _ownedBuildings;

    // coordinate => building address
    mapping(uint256 => address) private _placedBuildings;

    // coordinate => owner
    mapping(uint256 => address) private _coordinateOwners;

    uint256[] private _occupiedCoordinates;
    
    constructor() Ownable(msg.sender) {
    }

    function __initialize__(address mapAddress, address buildingFactoryAddress, address resourceFactoryAddress, address shopFactoryAddress) public onlyOwner{
        _mapAddress = mapAddress;
        _buildingFactoryAddress = buildingFactoryAddress;
        _resourceFactoryAddress = resourceFactoryAddress;
        _shopFactoryAddress = shopFactoryAddress;
    }

    function getMap() public view returns (uint256 width,uint256 height, Models.Tile[] memory) {
        return Map(_mapAddress).getMap();
    }

    function getContracts() public view returns (Contracts memory){
        BuildingFactory buildingFactory = BuildingFactory(_buildingFactoryAddress);
        ResourceFactory resourceFactory = ResourceFactory(_resourceFactoryAddress);
        address gameAddress = address(this);
        return Contracts({
            goldContract: resourceFactory.getGold(gameAddress),
            castleContract: buildingFactory.getCastle(gameAddress),
            buildingContracts: buildingFactory.getBuildings(gameAddress),
            resourceContracts: resourceFactory.getResources(gameAddress)
        });
    }

    function getMapBuildings() public view returns (uint256[] memory, uint256[] memory, address[] memory, address[] memory) {
        uint256 occupiedCount = _occupiedCoordinates.length;
        uint256[] memory xCoords = new uint256[](occupiedCount);
        uint256[] memory yCoords = new uint256[](occupiedCount);
        address[] memory buildings = new address[](occupiedCount);
        address[] memory owners = new address[](occupiedCount);

        for (uint256 i = 0; i < occupiedCount; i++) {
            buildings[i] = _placedBuildings[_occupiedCoordinates[i]];
            owners[i] = _coordinateOwners[_occupiedCoordinates[i]];
            (uint256 x, uint256 y) = Utils.decodeCoordinates(_occupiedCoordinates[i]);
            xCoords[i] = x;
            yCoords[i] = y;
        }

        return (xCoords, yCoords, buildings, owners);
    }

    function getShopItems(uint256 x, uint256 y) public view returns(Models.ShopItem[] memory){
        return ShopFactory(_shopFactoryAddress).getShopItems(x, y);
    }

    function buyGold() public payable {
        Resource(ResourceFactory(_resourceFactoryAddress).getGold(address(this))).mint(msg.sender, (msg.value * 100000) / 1e18);
    }

    function executeShopOrder(uint256 shopItemId) public {
        Models.ShopItem memory shopItem = ShopFactory(_shopFactoryAddress).getShopItem(shopItemId);
        require(shopItem.id != 0, "Shop item does not exist");

        IERC20 productToken = IERC20(shopItem.product);
        Resource goldToken = Resource(ResourceFactory(_resourceFactoryAddress).getGold(address(this)));

        if (shopItem.buySell == Models.BuySell.Buy) {
            require(goldToken.transferFrom(msg.sender, shopItem.owner, shopItem.price), "Gold transfer failed");
            require(productToken.transfer(msg.sender, shopItem.quantity), "Product transfer failed");
        } else if (shopItem.buySell == Models.BuySell.Sell) {
            require(productToken.transferFrom(msg.sender, address(this), shopItem.quantity), "Product transfer failed");
            require(goldToken.transfer(msg.sender, shopItem.price), "Gold transfer failed");
        }

        emit Models.OrderExecuted(msg.sender, shopItemId, shopItem.quantity, shopItem.price, shopItem.buySell);
    }

    function placeBuilding(uint256 x, uint256 y, address buildingAddress) public{
        uint256 encodedCordinates = Utils.encodeCoordinates(x, y);

        // Validate if tile exists
        Models.Tile memory tile = Map(_mapAddress).getTile(x, y);
        require(Utils.isTileDefined(tile), "Tile not found");        
       
        // Validate if building exists
        require(BuildingFactory(_buildingFactoryAddress).isDefined(buildingAddress), "Invalid building");

        // Get building contract
        Building building = Building(buildingAddress);

        // Validate if terrain type matches with building's allowed terrain types
        require(building.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");
        
        // Verify if tile occupied or not
        require(_placedBuildings[encodedCordinates] == address(0), "Tile is already occupied");

        // Eligible to place building. If owned buildings count is 0, then castle should be built first
        uint256[] memory ownedBuildings = _ownedBuildings[msg.sender];

        if(ownedBuildings.length == 0){

            // Ensure building address is castle
            require(buildingAddress == BuildingFactory(_buildingFactoryAddress).getCastle(address(this)), "Invalid building");
            
            // Burn gold for castle
            Resource(ResourceFactory(_resourceFactoryAddress).getGold(address(this))).burn(msg.sender, 10000);
        
        }else{

            // Validate if tile is free to place building on it and at least 1 building is owned by the caller in the tile's radius
            require(_hasAdjacentOwnedBuilding(x, y), "Tile is already occupied");
            
            // Burn building
            building.burn(msg.sender, 1);
        }
        
        // Register building ownership
        _ownedBuildings[msg.sender].push(encodedCordinates);
        _occupiedCoordinates.push(encodedCordinates);
        _placedBuildings[encodedCordinates] = buildingAddress;
        _coordinateOwners[encodedCordinates] = msg.sender;
    }
   
    function _hasAdjacentOwnedBuilding(uint256 x, uint256 y) private view returns (bool) {
        uint256[6] memory adjacentTileCordinates = Utils.getAdjacentTileCordinates(x, y);
        bool hasAdjacentOwnedBuilding = false;

        for (uint256 i = 0; i < adjacentTileCordinates.length; i++) {
            if (_placedBuildings[adjacentTileCordinates[i]] != address(0) &&
                _isBuildingOwnedByCaller(adjacentTileCordinates[i])) {
                hasAdjacentOwnedBuilding = true;
                break;
            }
        }

        return hasAdjacentOwnedBuilding;
    }

    function _isBuildingOwnedByCaller(uint256 encodedCoords) private view returns (bool) {
        address buildingContractAddress = _placedBuildings[encodedCoords];
        return buildingContractAddress == msg.sender;
    }
} 