// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import './models.sol';
import './building.sol';
import './resource.sol';

library Utils {
    function encodeCoordinates(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x < 2**128 && y < 2**128, "Coordinates out of bounds");
        return (x << 128) | y;
    }

    function decodeCoordinates(uint256 encoded) internal pure returns (uint256 x, uint256 y) {
        y = encoded & ((1 << 128) - 1);
        x = (encoded >> 128) & ((1 << 128) - 1);
    }

    function isTileDefined(Models.Tile memory tile) internal pure returns (bool){
        return tile.terrainType != Models.TerrainType.None;
    }

    function isTileOccupied(Models.Tile memory tile) internal pure returns (bool){
        return tile.building != address(0);
    }

    function isBuildingDefined(Building building) internal view returns (bool){
        return building.getBuildingDetails().buildingType != Models.BuildingType.None;
    }
}
