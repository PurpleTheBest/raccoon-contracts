// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './models.sol';
import './blueprint.sol';
import './resource.sol';

contract Game {
    event contractDeployed(string message,address addr);

    struct Tile {
        string name;
        uint256 x;
        uint256 y;
        uint256 elevation;
        Models.TerrainType terrainType;
        Models.BiomeType biomeType;
        address blueprint;
        address owner;
    }

    struct Cordinates{
        uint256 x;
        uint256 y;
    }

    enum buySell {Buy, Sell }

    struct shopItem {
        buySell buySell;
        address product;
        address owner;
        uint256 quantity;
        uint256 price;
    }

    uint256 private _mapWidth;
    uint256 private _mapHeight;
    address private _owner;
    string private _mapName;
    address private _gold;

    Resource private _nativeResource;
    Blueprint private _castleBlueprint;

    mapping (address => Blueprint) private _blueprints;
    mapping (address => Resource) private _resources;
    mapping(uint256 => Tile) private _tiles;
    uint256[] private _tilesCoordinates;
    mapping(address => Cordinates[]) private _ownedTiles;
    mapping(uint256 => shopItem[]) _shopItems;

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

   function __setNativeResource__() public onlyOwner {
    _nativeResource = new Resource("Gold", "GLD", "it is native currency", address(this));
    emit contractDeployed("Native currency contract deployed to address: ",address(_nativeResource));

    Models.TerrainType[] memory castleAllowedTerrainTypes = new Models.TerrainType[](2);
    castleAllowedTerrainTypes[0] = Models.TerrainType.Flat;
    castleAllowedTerrainTypes[1] = Models.TerrainType.Forest;

    _castleBlueprint = new Blueprint(
        "Castle",
        "CSTL",
        "Start",
        address(this),
        new Blueprint.ResourceAmount[](0), 
        new Blueprint.ResourceAmount[](0), 
        castleAllowedTerrainTypes,
        Models.BuildingType.Castle
    );
    emit contractDeployed("Castle contract deployed to address: ", address(_castleBlueprint));
}

    function __initializeTiles__(Tile[] memory tiles) public onlyOwner {
        for (uint256 i = 0; i < tiles.length; i++) {
            Tile memory tile = tiles[i];
            _tiles[__encodeCoordinates__(tile.x, tile.y)] = tile;
            _tilesCoordinates.push(__encodeCoordinates__(tile.x, tile.y));
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
         _tiles[__encodeCoordinates__(tile.x, tile.y)] = tile;
    }

    function getResourceContracts() public pure returns(address[] memory){

    }

    function getMap() public view returns (uint256 width,uint256 height,string memory name,Tile[] memory) {
        Tile[] memory tiles = new Tile[](_tilesCoordinates.length);

        for (uint256 i = 0; i < _tilesCoordinates.length; i++) {
            tiles[i] = _tiles[_tilesCoordinates[i]];
        }

        return (_mapWidth,_mapHeight,_mapName,tiles);
    }

    function buyGold() public payable {
        _nativeResource.mint(msg.sender, (msg.value * 100000) / 1e18);
    }

    function setCastle(uint256 x, uint256 y) public{
        Tile memory tile = _tiles[__encodeCoordinates__(x, y)];
        require(_isTileDefined(tile), "Tile not found");
        require(tile.owner != _owner, "Tile is already occupied");

        require(_castleBlueprint.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");

        Cordinates[] memory ownedTiles = _ownedTiles[msg.sender];

        require(ownedTiles.length == 0, "Unable to build castle");

        _nativeResource.burn(10000);
    }

    function occupyTile(uint256 x, uint256 y, address blueprintAddress) public{
         
        Blueprint blueprint = _blueprints[blueprintAddress];
        require(_isBlueprintDefined(blueprint), "Invalid blueprint");

        uint256 encodedCoordinates = __encodeCoordinates__(x, y);
        Tile storage tile = _tiles[encodedCoordinates];
        require(_isTileDefined(tile), "Tile not found");

        require(blueprint.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");

        Cordinates[] memory ownedTiles = _ownedTiles[msg.sender];
        require(ownedTiles.length != 0, "Build a castle first");
        require(_isTileFreeToOccupy(tile), "Tile is already occupied");
        
        blueprint.burn(1);

        tile.owner = msg.sender;
        tile.blueprint = blueprintAddress;

        _ownedTiles[msg.sender].push(Cordinates({x:x, y:y}));
    }

    function _isTileDefined(Tile memory tile) private pure returns (bool){
        return tile.terrainType != Models.TerrainType.None;
    }

    function _isBlueprintDefined(Blueprint blueprint) private view returns (bool){
        return blueprint.getBlueprintDetails().buildingType != Models.BuildingType.None;
    }

    function _isTileFreeToOccupy(Tile memory tile) private view returns (bool){
        require(tile.owner != _owner,"You are not allowed");
        require(tile.blueprint == address(0),"Already occupied");
        uint256 x = tile.x;
        uint256 y = tile.y;
        if(y % 2 == 0){
            return  _tiles[__encodeCoordinates__(x+1, y)].owner != msg.sender 
                    && _tiles[__encodeCoordinates__(x, y-1)].owner != msg.sender 
                    && _tiles[__encodeCoordinates__(x-1, y-1)].owner != msg.sender 
                    && _tiles[__encodeCoordinates__(x-1, y)].owner != msg.sender 
                    && _tiles[__encodeCoordinates__(x-1, y+1)].owner != msg.sender 
                    && _tiles[__encodeCoordinates__(x, y+1)].owner != msg.sender;
        }
        return  _tiles[__encodeCoordinates__(x+1, y)].owner != msg.sender 
                && _tiles[__encodeCoordinates__(x+1, y-1)].owner != msg.sender 
                && _tiles[__encodeCoordinates__(x, y-1)].owner != msg.sender 
                && _tiles[__encodeCoordinates__(x-1, y)].owner != msg.sender 
                && _tiles[__encodeCoordinates__(x, y+1)].owner != msg.sender 
                && _tiles[__encodeCoordinates__(x+1, y+1)].owner != msg.sender;
    }

    function getShopItems(uint256 x, uint256 y) public view returns(shopItem[] memory){
        return _shopItems[__encodeCoordinates__(x, y)];
    }

    // functions for encoding  (x,y,z) coordinates to uint256, and decoding 
    function __encodeCoordinates__(uint256 x, uint256 y) private pure returns (uint256) {
        require(x < 2**128 && y < 2**128, "Coordinates out of bounds");
        return (x << 128) | y;
    }

    function __decodeCoordinates__(uint256 encoded) private pure returns (uint256 x, uint256 y) {
        y = encoded & ((1 << 128) - 1);
        x = (encoded >> 128) & ((1 << 128) - 1);
    }


} 