// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "./resource.sol";

contract Building is Resource {
   
    struct ResourceAmount {
        address resourceContractAddr;
        uint256 amount;
    }

    struct BuildingDetails {
        string name;
        string description;
        Models.BuildingType buildingType;
        ResourceAmount[] inputResources;
        ResourceAmount[] outputResources;
        Models.TerrainType[] allowedTerrainTypes;
    }

    Models.BuildingType private _buildingType;
    ResourceAmount[] private _inputResources;
    ResourceAmount[] private _outputResources;
    Models.TerrainType[] private _allowedTerrainTypes;
    mapping(uint8 => Models.TerrainType) private _allowedTerrainTypesMap;
    BuildingDetails private _buildingDetails;


    constructor(
        string memory name,
        string memory symbol,
        string memory description,
        address owner,
        ResourceAmount[] memory inputResources,
        ResourceAmount[] memory outputResources,
        Models.TerrainType[] memory allowedTerrainTypes,
        Models.BuildingType buildingType) Resource(name,symbol,description,owner) {
        
        _approve(address(this), owner, type(uint256).max);
        _buildingType = buildingType;

        for (uint256 i = 0; i < inputResources.length; i++) {
            _inputResources.push(inputResources[i]);
        }
        for (uint256 i = 0; i < outputResources.length; i++) {
            _outputResources.push(outputResources[i]);
        }
        for (uint256 i = 0; i < allowedTerrainTypes.length; i++) {
            _allowedTerrainTypesMap[uint8(allowedTerrainTypes[i])] = allowedTerrainTypes[i];
            _allowedTerrainTypes.push(allowedTerrainTypes[i]);
        }
    }


    function isAllowedTerrainType(Models.TerrainType terrainType) public view returns (bool) {
        return _allowedTerrainTypesMap[uint8(terrainType)] == terrainType;
    }

    function getBuildingType() public view returns (Models.BuildingType){
        return _buildingType;
    }

     function getBuildingDetails() public view returns (
        string memory, 
        string memory, 
        Models.BuildingType, 
        ResourceAmount[] memory, 
        ResourceAmount[] memory, 
        Models.TerrainType[] memory){
        return (
            _name,
            _description,
            _buildingType,
            _inputResources,
            _outputResources,
            _allowedTerrainTypes
        );
    }
}
