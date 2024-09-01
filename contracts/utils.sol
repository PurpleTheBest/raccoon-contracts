// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import './building.sol';

library Utils {
    function encodeCoordinates(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x < 2**128 && y < 2**128, "Coordinates out of bounds");
        return (x << 128) | y;
    }

    function decodeCoordinates(uint256 encoded) internal pure returns (uint256 x, uint256 y) {
        y = encoded & ((1 << 128) - 1);
        x = (encoded >> 128) & ((1 << 128) - 1);
    }

    function getAdjacentTileCordinates(uint256 x, uint256 y)internal pure returns (uint256[6] memory){ 
        uint256[6] memory adjacentTiles;

        if (y % 2 == 0) {
            adjacentTiles[0] = Utils.encodeCoordinates(x + 1, y);
            adjacentTiles[1] = Utils.encodeCoordinates(x, y - 1);
            adjacentTiles[2] = Utils.encodeCoordinates(x - 1, y - 1);
            adjacentTiles[3] = Utils.encodeCoordinates(x - 1, y);
            adjacentTiles[4] = Utils.encodeCoordinates(x - 1, y + 1);
            adjacentTiles[5] = Utils.encodeCoordinates(x, y + 1);
        } else {
            adjacentTiles[0] = Utils.encodeCoordinates(x + 1, y);
            adjacentTiles[1] = Utils.encodeCoordinates(x + 1, y - 1);
            adjacentTiles[2] = Utils.encodeCoordinates(x, y - 1);
            adjacentTiles[3] = Utils.encodeCoordinates(x - 1, y);
            adjacentTiles[4] = Utils.encodeCoordinates(x, y + 1);
            adjacentTiles[5] = Utils.encodeCoordinates(x + 1, y + 1);
        }

        return adjacentTiles;
    }

    function isTileDefined(Models.Tile memory tile) internal pure returns (bool){
        return tile.terrainType != Models.TerrainType.None;
    }    

    function isBuildingDefined(Building building) internal view returns (bool){
        return building.getBuildingDetails().buildingType != Models.BuildingType.None;
    }
}
