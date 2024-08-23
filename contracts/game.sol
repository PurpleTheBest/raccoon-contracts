// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Game {
    enum TerrainType { Forest, DeepWater, Water, Flat, Mountain }
    enum BiomeType { Normal, Desert, Snow }
    enum BuildingType { Castle, Shop, Tavern }

    struct Building {
        uint256 id;
        BuildingType buildingType;
        string name;
        address owner;
    }

    struct Tile {
        uint256 x;
        uint256 y;
        TerrainType terrainType;
        BiomeType biomeType;
        Building building;
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

    function __setBuilding__(uint256 x, uint256 y, Building memory building) public onlyOwner {
        Tile storage tile = map[x][y];

        require(tile.x == x && tile.y == y, "Tile does not exist");

        tile.building = building;
    }
}