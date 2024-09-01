// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import './models.sol';
import './building.sol';
import './resource.sol';
import './utils.sol';
import './resourceManager.sol';
import './buildingManager.sol';
import './map.sol';
import './shopManager.sol';

contract Game is Ownable {
    using Utils for *;

    struct Contracts{
        address goldContract;
        address castleContract;
        address[] buildingContracts;
        address[] resourceContracts;
    }

    address private _mapAddress;
    address private _buildingManagerAddress;
    address private _resourceManagerAddress;
    address private _shopManagerAddress;

    mapping(address => uint256[]) private _ownedBuildings;
    mapping(uint256 => address) private _placedBuildings;

    constructor() Ownable(msg.sender) {
    }

    function __initialize__(address mapAddress, address buildingManagerAddress, address resourceManagerAddress, address shopManagerAddress) public onlyOwner{
        _mapAddress = mapAddress;
        _buildingManagerAddress = buildingManagerAddress;
        _resourceManagerAddress = resourceManagerAddress;
        _shopManagerAddress = shopManagerAddress;
    }

    function getMap() public view returns (uint256 width,uint256 height, Models.Tile[] memory) {
        return Map(_mapAddress).getMap();
    }

    function getContracts() public view returns (Contracts memory){
        BuildingManager buildingManager = BuildingManager(_buildingManagerAddress);
        ResourceManager resourceManager = ResourceManager(_resourceManagerAddress);

        return Contracts({
            goldContract: resourceManager.getGoldContract(),
            castleContract: buildingManager.getCastleContract(),
            buildingContracts: buildingManager.getAllContracts(),
            resourceContracts: resourceManager.getAllContracts()
        });
    }

    function getShopItems(uint256 x, uint256 y) public view returns(Models.ShopItem[] memory){
        return ShopManager(_shopManagerAddress).getShopItems(x, y);
    }

    function buyGold() public payable {
        Resource(ResourceManager(_resourceManagerAddress).getGoldContract()).mint(msg.sender, (msg.value * 100000) / 1e18);
    }

    function executeShopOrder(uint256 shopItemId) public {
        Models.ShopItem memory shopItem = ShopManager(_shopManagerAddress).getShopItem(shopItemId);
        require(shopItem.id != 0, "Shop item does not exist");

        IERC20 productToken = IERC20(shopItem.product);
        Resource goldToken = Resource(ResourceManager(_resourceManagerAddress).getGoldContract());

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
        Building building = BuildingManager(_buildingManagerAddress).get(buildingAddress);
        require(Utils.isBuildingDefined(building), "Invalid building");

        // Validate if terrain type matches with building's allowed terrain types
        require(building.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");
        
        // Verify if tile occupied or not
        require(_placedBuildings[encodedCordinates] == address(0), "Tile is already occupied");

        // Eligible to place building. If owned buildings count is 0, then castle should be built first
        uint256[] memory ownedBuildings = _ownedBuildings[msg.sender];

        if(ownedBuildings.length == 0){

            // Ensure building address is castle
            require(buildingAddress == BuildingManager(_buildingManagerAddress).getCastleContract(), "Invalid building");
            
            // Burn gold for castle
            Resource(ResourceManager(_resourceManagerAddress).getGoldContract()).burn(10000);
        
        }else{

            // Validate if tile is free to place building on it and at least 1 building is owned by the caller in the tile's radius
            require(_hasAdjacentOwnedBuilding(x, y), "Tile is already occupied");
            
            // Burn building
            building.burn(1);
        }
        
        // Register building ownership
        _ownedBuildings[msg.sender].push(encodedCordinates);
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