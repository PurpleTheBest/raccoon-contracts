// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./models.sol";
import "./resource.sol";

contract Blueprint is Resource {
   
    struct ResourceAmount {
        address resourceContractAddr;
        uint256 amount;
    }

     struct BlueprintDetails {
        string name;
        string description;
        Models.BuildingType buildingType;
        ResourceAmount[] inputResources;
        ResourceAmount[] outputResources;
        Models.TerrainType[] allowedTerrainTypes;
    }

    address private _unlimitedAllowanceAddress;
    string private _name;
    string private _description;
    Models.BuildingType private _buildingType;
    ResourceAmount[] private _inputResources;
    ResourceAmount[] private _outputResources;
    mapping(uint8 => Models.TerrainType) private _allowedTerrainTypes;

    constructor(
        string memory name,
        string memory symbol,
        string memory description,
        address unlimitedAllowanceAddress,
        ResourceAmount[] memory inputResources,
        ResourceAmount[] memory outputResources,
        Models.TerrainType[] memory allowedTerrainTypes,
        Models.BuildingType buildingType) Resource(name,symbol,description,unlimitedAllowanceAddress) {
        _unlimitedAllowanceAddress = unlimitedAllowanceAddress;
        _approve(unlimitedAllowanceAddress, unlimitedAllowanceAddress, type(uint256).max);
        _buildingType = buildingType;
        _description = description;
        _name = name;

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

     function getBlueprintDetails() public view returns (BlueprintDetails memory) {

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
        
        return BlueprintDetails({
            name: _name,
            description: _description,
            buildingType: _buildingType,
            inputResources: _inputResources,
            outputResources: _outputResources,
            allowedTerrainTypes: allowedTerrainArray
        });
    }
}
