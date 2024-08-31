// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import './models.sol';
import './building.sol';
import './resource.sol';
import './utils.sol';
import './resourceManager.sol';
import './buildingManager.sol';
import './tileManager.sol';
import './shopManager.sol';

contract Game is Ownable {
    using Utils for *;

    struct Contracts{
        address goldContract;
        address castleContract;
        address[] buildingContracts;
        address[] resourceContracts;
    }

    string private _mapName;

    address private _owner;
    address private _tileManagerAddress;
    address private _buildingManagerAddress;
    address private _resourceManagerAddress;
    address private _shopManagerAddress;

    mapping(address => uint256[]) private _ownedBuildings;
    mapping(uint256 => address) private _placedBuildings;

    constructor(
        uint256 height,
        uint256 width,
        string memory mapName) Ownable(msg.sender) {
        _owner = msg.sender;
        _mapName = mapName;
       
        _tileManagerAddress = address(new TileManager(height, width, _owner));
        emit Models.ContractDeployed("Tile manager deployed", _tileManagerAddress);
        
        _buildingManagerAddress = address(new BuildingManager(_owner));
        emit Models.ContractDeployed("Building manager deployed", _buildingManagerAddress);

        ResourceManager resourceManager = new ResourceManager(_owner);
        _resourceManagerAddress = address(resourceManager);
        emit Models.ContractDeployed("Resource manager deployed", _resourceManagerAddress);
    
        _shopManagerAddress = address(new ShopManager(_owner, resourceManager.getGoldContract()));
        emit Models.ContractDeployed("Shop manager deployed", _shopManagerAddress);
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

    function getMap() public view returns (uint256 width,uint256 height, Models.Tile[] memory) {
        return TileManager(_tileManagerAddress).getMap();
    }

    function getShopItems(uint256 x, uint256 y) public view returns(Models.ShopItem[] memory){
        return ShopManager(_shopManagerAddress).getShopItems(x, y);
    }

    function buyGold() public payable {
        Resource(ResourceManager(_resourceManagerAddress).getGoldContract()).mint(msg.sender, (msg.value * 100000) / 1e18);
    }

    function placeCastle(uint256 x, uint256 y) public{
        // Check if user eligible to place a castle
        uint256[] memory ownedBuildings = _ownedBuildings[msg.sender];
        require(ownedBuildings.length == 0, "Unable to build castle");

        // Validate if tile exists
        Models.Tile memory tile = TileManager(_tileManagerAddress).get(x, y);
        require(Utils.isTileDefined(tile), "Tile not found");

        // Check if tile is free
        require(!_isTileOccupied(x, y), "Tile is already occupied");
        
        // Validate if terrain type matches with building's allowed terrain types
        require(Building(BuildingManager(_buildingManagerAddress).getCastleContract()).isAllowedTerrainType(tile.terrainType), "Invalid terrain type");

        // Burn gold for the castle
        Resource(ResourceManager(_resourceManagerAddress).getGoldContract()).burn(10000);
    }

    function placeBuilding(uint256 x, uint256 y, address buildingAddress) public{
        // Validate if tile exists
        Models.Tile memory tile = TileManager(_tileManagerAddress).get(x, y);
        require(Utils.isTileDefined(tile), "Tile not found");        
       
        // Validate if building exists
        Building building = BuildingManager(_buildingManagerAddress).get(buildingAddress);
        require(Utils.isBuildingDefined(building), "Invalid building");

        // Validate if terrain type matches with building's allowed terrain types
        require(building.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");
        
        // Eligible to place building. If owned buildings count is 0, then castle should be built first
        uint256[] memory ownedBuildings = _ownedBuildings[msg.sender];
        require(ownedBuildings.length != 0, "Build a castle first");
        
        // Verify if tile occupied or not
        require(!_isTileOccupied(x, y), "Tile is already occupied");

        // Validate if tile is free to place building on it and at least 1 building is owned by the caller in the tile's radius
        require(_hasAdjacentOwnedBuilding(x, y), "Tile is already occupied");

        // Burn building
        building.burn(1);
        
        // Register building ownership
        _ownedBuildings[msg.sender].push(Utils.encodeCoordinates(x, y));
    }

    function _isTileOccupied(uint256 x, uint256 y) private view returns (bool){
        return _placedBuildings[Utils.encodeCoordinates(x, y)] != address(0);
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