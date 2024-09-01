// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import './building.sol';
import './utils.sol';


contract BuildingFactory is Ownable {
    using Utils for *;

    mapping (address => bool) _buildings;
    mapping (address => address[]) _gameBuildings;
    mapping (address => address) _gameCastle;
    address private _owner;

    constructor() Ownable(msg.sender) {
        _owner = msg.sender;       
    }

    function __initialize__(address gameAddress) public onlyOwner{
         Models.TerrainType[] memory castleAllowedTerrainTypes = new Models.TerrainType[](2);
        castleAllowedTerrainTypes[0] = Models.TerrainType.Flat;
        castleAllowedTerrainTypes[1] = Models.TerrainType.Forest;

        Building building = new Building(
            "Castle",
            "CSTL",
            "",
            gameAddress,
            new Building.ResourceAmount[](0), 
            new Building.ResourceAmount[](0), 
            castleAllowedTerrainTypes,
            Models.BuildingType.Castle
        );
        address castleAddress = address(building);
        _gameCastle[gameAddress] = castleAddress;
        _buildings[castleAddress] = true;
        emit Models.ContractDeployed("Castle contract deployed", castleAddress);
    }

    function __addBuilding__(
            string memory name,
            string memory symbol,
            string memory description,
            address owner,
            Models.TerrainType[] memory terrainTypes,
            Models.BuildingType buildingType,
            Building.ResourceAmount[] memory inputResources,
            Building.ResourceAmount[] memory outputResources
            ) public onlyOwner {
        
        Building building = new Building(name, symbol, description, owner, inputResources, outputResources, terrainTypes, buildingType);
        _gameBuildings[owner].push(address(building));
        _buildings[address(building)] = true;

        emit Models.ContractDeployed("Building contract deployed", address(building));
    }

    function getCastle(address gameAddress) public view returns(address){
        return _gameCastle[gameAddress];
    }

    function getBuildings(address gameAddress) public view returns(address[] memory){
        return _gameBuildings[gameAddress];
    }

    function isDefined(address buildingAddress) public view returns (bool){
        return _buildings[buildingAddress];
    }
}