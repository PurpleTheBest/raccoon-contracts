// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './models.sol';
import './building.sol';
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
        address building;
        address owner;
    }

    struct Cordinates{
        uint256 x;
        uint256 y;
    }

    enum buySell {Buy, Sell }

    struct ShopItem {
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

    Resource private _gold;
    Building private _castle;

    address[] private _buildingAddresses;
    address[] private _resourceAddresses;
    mapping (address => Building) private _buildings;
    mapping (address => Resource) private _resources;
    mapping(uint256 => Tile) private _tiles;
    uint256[] private _tilesCoordinates;
    mapping(address => Cordinates[]) private _ownedTiles;
    mapping(uint256 => ShopItem[]) _shopItems;

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
        emit contractDeployed("Gold contract deployed to address: ",address(_gold));

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
        emit contractDeployed("Castle contract deployed to address: ", address(_castle));
    }

    function __addTiles__(Tile[] memory tiles) public onlyOwner {
        for (uint256 i = 0; i < tiles.length; i++) {
            Tile memory tile = tiles[i];
            _tiles[_encodeCoordinates(tile.x, tile.y)] = tile;
            _tilesCoordinates.push(_encodeCoordinates(tile.x, tile.y));
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
        emit contractDeployed("Building contract deployed to address: ",address(building));
        _buildings[address(building)] = building;
        _buildingAddresses.push(address(building));
    }

    function __addResource__(string memory name, string memory symbol, string memory description) public onlyOwner {
        Resource resource = new Resource(name, symbol, description, address(this));
        emit contractDeployed(" Resource contract deployed to address: ",address(resource));
        _resources[address(resource)] = resource;
        _resourceAddresses.push(address(resource));
    }

    function __updateTile__(Tile memory tile) public onlyOwner {
         _tiles[_encodeCoordinates(tile.x, tile.y)] = tile;
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

    function getMap() public view returns (uint256 width,uint256 height,string memory name,Tile[] memory) {
        Tile[] memory tiles = new Tile[](_tilesCoordinates.length);

        for (uint256 i = 0; i < _tilesCoordinates.length; i++) {
            tiles[i] = _tiles[_tilesCoordinates[i]];
        }

        return (_mapWidth,_mapHeight,_mapName,tiles);
    }

    function getShopItems(uint256 x, uint256 y) public view returns(ShopItem[] memory){
        return _shopItems[_encodeCoordinates(x, y)];
    }

    function buyGold() public payable {
        _gold.mint(msg.sender, (msg.value * 100000) / 1e18);
    }

    function placeCastle(uint256 x, uint256 y) public{
        Cordinates[] memory ownedTiles = _ownedTiles[msg.sender];
        require(ownedTiles.length == 0, "Unable to build castle");

        Tile memory tile = _tiles[_encodeCoordinates(x, y)];
        require(_isTileDefined(tile), "Tile not found");
        require(tile.owner != _owner, "Tile is already occupied");
        require(_castle.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");

        _gold.burn(10000);
    }

    function placeBuilding(uint256 x, uint256 y, address buildingAddress) public{
         
        Building building = _buildings[buildingAddress];
        require(_isBuildingDefined(building), "Invalid building");

        uint256 encodedCoordinates = _encodeCoordinates(x, y);
        Tile storage tile = _tiles[encodedCoordinates];
        require(_isTileDefined(tile), "Tile not found");

        require(building.isAllowedTerrainType(tile.terrainType), "Invalid terrain type");

        Cordinates[] memory ownedTiles = _ownedTiles[msg.sender];
        require(ownedTiles.length != 0, "Build a castle first");
        require(_isTileFreeToOccupy(tile), "Tile is already occupied");
        
        building.burn(1);

        tile.owner = msg.sender;
        tile.building = buildingAddress;

        _ownedTiles[msg.sender].push(Cordinates({x:x, y:y}));
    }

    function _isTileDefined(Tile memory tile) private pure returns (bool){
        return tile.terrainType != Models.TerrainType.None;
    }

    function _isTileOccupied(Tile memory tile) private view returns (bool){
        return tile.owner != _owner && tile.building != address(0);
    }

    function _isBuildingDefined(Building building) private view returns (bool){
        return building.getBuildingDetails().buildingType != Models.BuildingType.None;
    }

    function _isTileFreeToOccupy(Tile memory tile) private view returns (bool){
        require(tile.owner != _owner,"You are not allowed");
        require(tile.building == address(0),"Already occupied");
        uint256 x = tile.x;
        uint256 y = tile.y;
        if(y % 2 == 0){
            return  _tiles[_encodeCoordinates(x+1, y)].owner != msg.sender 
                    && _tiles[_encodeCoordinates(x, y-1)].owner != msg.sender 
                    && _tiles[_encodeCoordinates(x-1, y-1)].owner != msg.sender 
                    && _tiles[_encodeCoordinates(x-1, y)].owner != msg.sender 
                    && _tiles[_encodeCoordinates(x-1, y+1)].owner != msg.sender 
                    && _tiles[_encodeCoordinates(x, y+1)].owner != msg.sender;
        }
        return  _tiles[_encodeCoordinates(x+1, y)].owner != msg.sender 
                && _tiles[_encodeCoordinates(x+1, y-1)].owner != msg.sender 
                && _tiles[_encodeCoordinates(x, y-1)].owner != msg.sender 
                && _tiles[_encodeCoordinates(x-1, y)].owner != msg.sender 
                && _tiles[_encodeCoordinates(x, y+1)].owner != msg.sender 
                && _tiles[_encodeCoordinates(x+1, y+1)].owner != msg.sender;
    }    

    // functions for encoding  (x,y,z) coordinates to uint256, and decoding 
    function _encodeCoordinates(uint256 x, uint256 y) private pure returns (uint256) {
        require(x < 2**128 && y < 2**128, "Coordinates out of bounds");
        return (x << 128) | y;
    }

    function _decodeCoordinates(uint256 encoded) private pure returns (uint256 x, uint256 y) {
        y = encoded & ((1 << 128) - 1);
        x = (encoded >> 128) & ((1 << 128) - 1);
    }
} 