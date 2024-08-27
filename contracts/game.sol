// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './models.sol';
import './building.sol';
import './resource.sol';
import './utils.sol';


contract Game {
    using Utils for *;
    uint256 private _mapWidth;
    uint256 private _mapHeight;
    address private _owner;
    string private _mapName;

    Resource private _gold;
    Building private _castle;

    address[] private _buildingAddresses;
    address[] private _resourceAddresses;
    mapping (address => Building) private _buildings;
    mapping (address => Resource) private _resources;
    mapping(uint256 => Models.Tile) private _tiles;
    uint256[] private _tilesCoordinates;
    mapping(address => Models.Cordinates[]) private _ownedTiles;
    mapping(uint256 => Models.ShopItem[]) _shopItems;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not allowed");
        _;
    }

     modifier ensureAllowedTerrainType() {
        require(msg.sender == _owner, "Not allowed");
        _;
    }

    constructor(uint256 mapWidth, uint256 mapHeight, string memory mapName) {
        _mapWidth= mapWidth;
        _mapHeight = mapHeight;
        _mapName = mapName;
        _owner = msg.sender;
    }

   function __initialize__() public onlyOwner {
        _gold = new Resource("Gold", "GLD", "it is native currency", address(this));

        Models.TerrainType[] memory castleAllowedTerrainTypes = new Models.TerrainType[](2);
        castleAllowedTerrainTypes[0] = Models.TerrainType.Flat;
        castleAllowedTerrainTypes[1] = Models.TerrainType.Forest;

        _castle = new Building(
            "Castle",
            "CSTL",
            "Start",
            address(this),
            new Building.ResourceAmount[](0), 
            new Building.ResourceAmount[](0), 
            castleAllowedTerrainTypes,
            Models.BuildingType.Castle
        );
    }

    function __addTiles__(Models.Tile[] memory tiles) public onlyOwner {
        for (uint256 i = 0; i < tiles.length; i++) {
            Models.Tile memory tile = tiles[i];
            _tiles[Utils.encodeCoordinates(tile.x, tile.y)] = tile;
            _tilesCoordinates.push(Utils.encodeCoordinates(tile.x, tile.y));
        }
    }

    function __addBuilding__(
            string memory name,
            string memory symbol,
            string memory description,
            Building.ResourceAmount[] memory inputResources,
            Building.ResourceAmount[] memory outputResources,
            Models.TerrainType[] memory terrainTypes,
            Models.BuildingType buildingType) public onlyOwner {
        
        Building building = new Building(name, symbol, description, address(this), inputResources, outputResources, terrainTypes, buildingType);
        _buildings[address(building)] = building;
        _buildingAddresses.push(address(building));
    }

    function __addResource__(string memory name, string memory symbol, string memory description) public onlyOwner {
        Resource resource = new Resource(name, symbol, description, address(this));
        _resources[address(resource)] = resource;
        _resourceAddresses.push(address(resource));
    }

    function __updateTile__(Models.Tile memory tile) public onlyOwner {
         _tiles[Utils.encodeCoordinates(tile.x, tile.y)] = tile;
    }

    function getCastleContract() public view returns(address){
        return address(_castle);
    }

    function getGoldContract() public view returns(address){
        return address(_gold);
    }

    function getResourceContracts() public view returns(address[] memory){
        return _resourceAddresses;
    }

     function getBuildingsContracts() public view returns(address[] memory){
        return _buildingAddresses;
    }

    function getMap() public view returns (uint256 width,uint256 height,string memory name, Models.Tile[] memory) {
        Models.Tile[] memory tiles = new Models.Tile[](_tilesCoordinates.length);

        for (uint256 i = 0; i < _tilesCoordinates.length; i++) {
            tiles[i] = _tiles[_tilesCoordinates[i]];
        }

        return (_mapWidth,_mapHeight,_mapName,tiles);
    }

    function getShopItems(uint256 x, uint256 y) public view returns(Models.ShopItem[] memory){
        return _shopItems[Utils.encodeCoordinates(x, y)];
    }

    function buyGold() public payable {
        _gold.mint(msg.sender, (msg.value * 100000) / 1e18);
    }

    function placeCastle(uint256 x, uint256 y) public{
        Models.Cordinates[] memory ownedTiles = _ownedTiles[msg.sender];
        require(ownedTiles.length == 0, "Unable to build castle");

        Models.Tile memory tile = _tiles[Utils.encodeCoordinates(x, y)];
        require(Utils.isTileDefined(tile), "Tile not found");
        require(!Utils.isTileOccupied(tile), "Tile is already occupied");
        require(_castle.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");

        _gold.burn(10000);
    }

    function placeBuilding(uint256 x, uint256 y, address buildingAddress) public{
        Models.Cordinates[] memory ownedTiles = _ownedTiles[msg.sender];
        require(ownedTiles.length != 0, "Build a castle first");

        Building building = _buildings[buildingAddress];
        require(Utils.isBuildingDefined(building), "Invalid building");

        uint256 encodedCoordinates = Utils.encodeCoordinates(x, y);
        Models.Tile storage tile = _tiles[encodedCoordinates];
        require(Utils.isTileDefined(tile), "Tile not found");
        require(_isTileFreeToOccupy(tile), "Tile is already occupied");
        require(building.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");
        
        building.burn(1);

        tile.owner = msg.sender;
        tile.building = buildingAddress;

        _ownedTiles[msg.sender].push(Models.Cordinates({x:x, y:y}));
    }

   
    function _isTileFreeToOccupy(Models.Tile memory tile) private view returns (bool){
        require(!Utils.isTileOccupied(tile), "Tile is already occupied");
        
        uint256 x = tile.x;
        uint256 y = tile.y;
        if(y % 2 == 0){
            return  _tiles[Utils.encodeCoordinates(x+1, y)].owner != msg.sender 
                    && _tiles[Utils.encodeCoordinates(x, y-1)].owner != msg.sender 
                    && _tiles[Utils.encodeCoordinates(x-1, y-1)].owner != msg.sender 
                    && _tiles[Utils.encodeCoordinates(x-1, y)].owner != msg.sender 
                    && _tiles[Utils.encodeCoordinates(x-1, y+1)].owner != msg.sender 
                    && _tiles[Utils.encodeCoordinates(x, y+1)].owner != msg.sender;
        }
        return  _tiles[Utils.encodeCoordinates(x+1, y)].owner != msg.sender 
                && _tiles[Utils.encodeCoordinates(x+1, y-1)].owner != msg.sender 
                && _tiles[Utils.encodeCoordinates(x, y-1)].owner != msg.sender 
                && _tiles[Utils.encodeCoordinates(x-1, y)].owner != msg.sender 
                && _tiles[Utils.encodeCoordinates(x, y+1)].owner != msg.sender 
                && _tiles[Utils.encodeCoordinates(x+1, y+1)].owner != msg.sender;
    }    
} 