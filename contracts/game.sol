// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Game {
    enum TerrainType { Forest, DeepWater, Water, Flat, Mountain }
    enum BiomeType { Normal, Desert, Snow }
    enum BuildingType { None, Castle, Shop, Tavern }

    struct Tile {
        string name;
        uint256 x;
        uint256 y;
        TerrainType terrainType;
        BiomeType biomeType;
        BuildingType buildingType;
        address blueprint;
        address owner;
    }

    struct Map {
        uint256 height;
        uint256 width;
        Tile[] tiles;
    }

    uint256 private _mapWidth;
    uint256 private _mapHeight;
    address private _nativeCurrency;
    address private _owner;
    string private _mapName;


    uint256 private _buildingIds = 0;

    mapping(uint256 => mapping(uint256 => Tile)) public map;

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
        _nativeCurrency = nativeCurrency;
    }

    function __initializeTiles(Tile[] memory tiles) public onlyOwner {
        for (uint256 i = 0; i < tiles.length; i++) {
            Tile memory tile = tiles[i];
            map[tile.x][tile.y] = tile;
        }
    }

    function __updateTile(Tile memory tile) public onlyOwner {
         map[tile.x][tile.y] = tile;
    }

    function getMap() public view returns (Map memory) {
        Tile[] memory tilesArray = new Tile[](_mapWidth * _mapHeight);
        uint256 index = 0;

        for (uint256 x = 0; x < _mapWidth; x++) {
            for (uint256 y = 0; y < _mapHeight; y++) {
                Tile storage tile = map[x][y];
                // Check if tile is initialized
                if (tile.x == x && tile.y == y) {
                    tilesArray[index] = tile;
                    index++;
                }
            }
        }

        // Resize the array to the actual number of initialized tiles
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
}