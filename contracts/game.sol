// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './models.sol';
import './blueprint.sol';
import './resource.sol';

contract Game {
    
     struct Tile {
        string name;
        uint256 x;
        uint256 y;
        uint256 z;
        uint256 elevation;
        Models.TerrainType terrainType;
        Models.BiomeType biomeType;
        address blueprint;
        address owner;
    }

    struct Map {
        uint256 height;
        uint256 width;
        uint256 length;
        Tile[] tiles;
    }

    struct Cordinates{
        uint256 x;
        uint256 y;
        uint256 z;
    }

    uint256 private _mapWidth;
    uint256 private _mapHeight;
    uint256 private _mapLength;    
    address private _owner;
    string private _mapName;

    Resource private _nativeResource;
    Blueprint private _castleBlueprint;

    mapping (address => Blueprint) private _blueprints;
    mapping (address => Resource) private _resources;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Tile))) private _tiles;
    mapping(address => Cordinates[]) private _ownedTiles;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not allowed");
        _;
    }

     modifier ensureAllowedTerrainType() {
        require(msg.sender == _owner, "Not allowed");
        _;
    }

    constructor(uint256 mapWidth, uint256 mapHeight, uint256 mapLength, string memory mapName) {
        _mapWidth= mapWidth;
        _mapHeight = mapHeight;
        _mapLength = mapLength;
        _mapName = mapName;
        _owner = msg.sender;
    }

    function __setNativeResource__(address nativeResourceAddress) public onlyOwner {
        _nativeResource = Resource(nativeResourceAddress);
    }

    function __setCastleBlueprint__(address castleBlueprintAddress) public onlyOwner {
        _castleBlueprint = Blueprint(castleBlueprintAddress);
    }

    function __initializeTiles__(Tile[] memory tiles) public onlyOwner {
        for (uint256 i = 0; i < tiles.length; i++) {
            Tile memory tile = tiles[i];
            _tiles[tile.x][tile.y][tile.z] = tile;
        }
    }

    function __setBlueprints__(address[] memory blueprints) public onlyOwner {
        for(uint256 i =0; i< blueprints.length; i++){
            _blueprints[blueprints[i]] = Blueprint(blueprints[i]);
        }
    }

    function __setResources__(address[] memory resources) public onlyOwner {
        for(uint256 i =0; i< resources.length; i++){
            _resources[resources[i]] = Resource(resources[i]);
        }
    }

    function __updateTile__(Tile memory tile) public onlyOwner {
         _tiles[tile.x][tile.y][tile.z] = tile;
    }

    function getMap() public view returns (Map memory) {
        Tile[] memory tilesArray = new Tile[](_mapWidth * _mapHeight);
        uint256 index = 0;

        for (uint256 x = 0; x < _mapWidth; x++) {
            for (uint256 y = 0; y < _mapHeight; y++) {
                for (uint256 z = 0; y < _mapLength; z++) {
                    Tile storage tile = _tiles[x][y][z];
                    if (tile.x == x && tile.y == y && tile.z == z) {
                        tilesArray[index] = tile;
                        index++;
                    }
                }
            }
        }

        Tile[] memory resultArray = new Tile[](index);
        for (uint256 i = 0; i < index; i++) {
            resultArray[i] = tilesArray[i];
        }

        Map memory currentMap = Map({
            height: _mapHeight,
            width: _mapWidth,
            length: _mapLength,
            tiles: resultArray
        });

        return currentMap;
    }

    function buyGold() public payable {
        _nativeResource.mint(msg.sender, (msg.value * 100000) / 1e18);
    }

    function setCastle(uint256 x, uint256 y, uint256 z) public{
        Tile memory tile = _tiles[x][y][z];
        require(tile.terrainType != Models.TerrainType.None, "Tile not found");
        require(tile.owner != _owner, "Tile is already occupied");

        require(_castleBlueprint.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");

        Cordinates[] memory ownedTiles = _ownedTiles[msg.sender];

        require(ownedTiles.length == 0, "Unable to build castle");

        _nativeResource.burn(_castleBlueprint.getPrice());
    }

    function occupyTile(uint256 x, uint256 y, uint256 z, address blueprintAddress) public{
         
        Blueprint blueprint = _blueprints[blueprintAddress];
        require(_isBlueprintDefined(blueprint), "Invalid blueprint");

        Tile memory tile = _tiles[x][y][z];
        require(_isTileDefined(tile), "Tile not found");

        require(blueprint.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");

        Cordinates[] memory ownedTiles = _ownedTiles[msg.sender];
        require(ownedTiles.length != 0, "Build a castle first");
        require(_isTileFreeToOccupy(tile), "Tile is already occupied");
        
        blueprint.burn(1);

        tile.owner = msg.sender;
        tile.blueprint = blueprintAddress;

        _ownedTiles[msg.sender].push(Cordinates({x:x, y:y, z:z}));
    }

    function _isTileDefined(Tile memory tile) private pure returns (bool){
        return tile.terrainType != Models.TerrainType.None;
    }

    function _isBlueprintDefined(Blueprint blueprint) private view returns (bool){
        return blueprint.getBlueprintDetails().buildingType != Models.BuildingType.None;
    }

    function _isTileFreeToOccupy(Tile memory tile) private view returns (bool){
        return  tile.owner != _owner 
            && tile.blueprint == address(0)
            && _tiles[tile.x+1][tile.y+1][tile.z].owner != msg.sender 
            && _tiles[tile.x][tile.y+1][tile.z].owner != msg.sender 
            && _tiles[tile.x-1][tile.y+1][tile.z].owner != msg.sender 
            && _tiles[tile.x-1][tile.y][tile.z].owner != msg.sender 
            && _tiles[tile.x][tile.y-1][tile.z].owner != msg.sender 
            && _tiles[tile.x+1][tile.y][tile.z].owner != msg.sender;
    }
} 