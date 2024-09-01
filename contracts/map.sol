// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import './utils.sol';


contract Map is Ownable {
    using Utils for *;

    uint256[] private _tilesCoordinates;
    mapping(uint256 => Models.Tile) private _tiles;
    uint256 private _width;
    uint256 private _height;
    address private _owner;

    constructor() Ownable(msg.sender) {
        _owner = msg.sender;
    }

    function __initialize__(uint256 height, uint256 width, Models.Tile[] memory tiles) public onlyOwner {
        _height = height;
        _width = width;
        for (uint256 i = 0; i < tiles.length; i++) {
            Models.Tile memory tile = tiles[i];
            _tiles[Utils.encodeCoordinates(tile.x, tile.y)] = tile;
            _tilesCoordinates.push(Utils.encodeCoordinates(tile.x, tile.y));
        }
    }

    function getMap() public view returns (uint256 width,uint256 height, Models.Tile[] memory) {
        Models.Tile[] memory tiles = new Models.Tile[](_tilesCoordinates.length);

        for (uint256 i = 0; i < _tilesCoordinates.length; i++) {
            tiles[i] = _tiles[_tilesCoordinates[i]];
        }

        return (_width,_height,tiles);
    }

    function getTile(uint256 x, uint256 y) public view returns (Models.Tile memory tile) {
        return _tiles[Utils.encodeCoordinates(x,y)];
    }
}