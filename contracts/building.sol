// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./models.sol";
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
    mapping(uint8 => Models.TerrainType) private _allowedTerrainTypes;

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
            _allowedTerrainTypes[uint8(allowedTerrainTypes[i])] = allowedTerrainTypes[i];
        }
    }


    function isAllowedTerrainType(Models.TerrainType terrainType) public view returns (bool) {
        return _allowedTerrainTypes[uint8(terrainType)] == terrainType;
    }

     function getBuildingDetails() public view returns (BuildingDetails memory) {

        uint8 terrainCount = 0;
        for (uint8 i = 0; i < 256; i++) {
            if (_allowedTerrainTypes[i] != Models.TerrainType.None) {
                terrainCount++;
            }
        }

        Models.TerrainType[] memory allowedTerrainArray = new Models.TerrainType[](terrainCount);
        uint8 index = 0;
        for (uint8 i = 0; i < 256; i++) {
            if (_allowedTerrainTypes[i] != Models.TerrainType.None) {
                allowedTerrainArray[index] = _allowedTerrainTypes[i];
                index++;
            }
        }        
        
        return BuildingDetails({
            name: _name,
            description: _description,
            buildingType: _buildingType,
            inputResources: _inputResources,
            outputResources: _outputResources,
            allowedTerrainTypes: allowedTerrainArray
        });
    }
}
