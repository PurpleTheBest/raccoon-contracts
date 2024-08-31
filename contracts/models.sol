// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract Models{
    event ContractDeployed(string message,address addr);

    struct Tile {
        string name;
        uint256 x;
        uint256 y;
        uint256 elevation;
        Models.TerrainType terrainType;
        Models.BiomeType biomeType;
    }

    struct Cordinates{
        uint256 x;
        uint256 y;
    }

    enum BuySell {Buy, Sell }

    struct ShopItem {
        BuySell buySell;
        address product;
        address owner;
        uint256 quantity;
        uint256 price;
    }
    enum TerrainType { None, Forest, DeepWater, Water, Flat, Mountain }
    enum BiomeType {  None, Normal, Desert, Snow }
    enum BuildingType { None, Castle, Shop, Tavern }   
}