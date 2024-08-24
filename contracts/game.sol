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
        Models.TerrainType terrainType;
        Models.BiomeType biomeType;
        address blueprint;
        address owner;
        uint256 price;
    }

    struct Map {
        uint256 height;
        uint256 width;
        Tile[] tiles;
    }

    struct Cordinates{
        uint256 x;
        uint256 y;
    }

    uint256 private _mapWidth;
    uint256 private _mapHeight;
    Resource private _nativeCurrency;
    address private _owner;
    string private _mapName;

    mapping (address => Blueprint) private _blueprints;
    mapping (address => Resource) private _resources;
    mapping(uint256 => mapping(uint256 => Tile)) private _tiles;
    mapping(address => Cordinates[]) private _ownedTiles;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not allowed");
        _;
    }

    constructor(uint256 mapWidth, uint256 mapHeight, string memory mapName) {
        _mapWidth= mapWidth;
        _mapHeight = mapHeight;
        _mapName = mapName;
        _owner = msg.sender;
    }

    function __setNativeCurrency__(address nativeCurrency) public onlyOwner {
        _nativeCurrency = Resource(nativeCurrency);
    }

    function __initializeTiles__(Tile[] memory tiles) public onlyOwner {
        for (uint256 i = 0; i < tiles.length; i++) {
            Tile memory tile = tiles[i];
            _tiles[tile.x][tile.y] = tile;
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
         _tiles[tile.x][tile.y] = tile;
    }

    function getMap() public view returns (Map memory) {
        Tile[] memory tilesArray = new Tile[](_mapWidth * _mapHeight);
        uint256 index = 0;

        for (uint256 x = 0; x < _mapWidth; x++) {
            for (uint256 y = 0; y < _mapHeight; y++) {
                Tile storage tile = _tiles[x][y];
                if (tile.x == x && tile.y == y) {
                    tilesArray[index] = tile;
                    index++;
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
            tiles: resultArray
        });

        return currentMap;
    }

     function buyGold() public payable {
         Resource token = Resource(_nativeCurrency);
         token.mint(msg.sender, (msg.value * 100000) / 1e18);
     }

    function buyTile(uint256 x, uint256 y, address blueprintAddress) public{
         
        require(_blueprints[blueprintAddress].getBlueprintDetails().buildingType != Models.BuildingType.None, "Invalid blueprint");

        Tile memory tile = _tiles[x][y];
        require(tile.terrainType != Models.TerrainType.None, "Tile not found");
        require(tile.owner != _owner, "Tile is already occupied");

        _nativeCurrency.burn(tile.price);

        Blueprint blueprint = Blueprint(blueprintAddress);
        require(blueprint.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");

        Cordinates[] memory ownedTiles = _ownedTiles[msg.sender];

        if(
            ownedTiles.length != 0
            && _tiles[x+1][y+1].owner != msg.sender 
            && _tiles[x][y+1].owner != msg.sender 
            && _tiles[x-1][y+1].owner != msg.sender 
            && _tiles[x-1][y].owner != msg.sender 
            && _tiles[x][y-1].owner != msg.sender 
            && _tiles[x+1][y].owner != msg.sender){
                revert("Unable to buy");
        }

        blueprint.burn(1);

        tile.owner = msg.sender;
        tile.blueprint = blueprintAddress;

        _ownedTiles[msg.sender].push(Cordinates({x:x, y:y}));
    }
} 