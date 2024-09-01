// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import './models.sol';
import './building.sol';
import './utils.sol';


contract BuildingManager is Ownable {
    using Utils for *;

    address[] private _buildingAddresses;
    mapping (address => Building) private _buildings;
    address private _castleContract;
    address private _gameAddress;
    address private _owner;


    constructor(address gameAddress) Ownable(msg.sender) {
        require(gameAddress != address(0), "Invalid address");

        _gameAddress = gameAddress;
        _owner = msg.sender;

        Models.TerrainType[] memory castleAllowedTerrainTypes = new Models.TerrainType[](2);
        castleAllowedTerrainTypes[0] = Models.TerrainType.Flat;
        castleAllowedTerrainTypes[1] = Models.TerrainType.Forest;

        _castleContract = address(new Building(
            "Castle",
            "CSTL",
            "",
            _gameAddress,
            new Building.ResourceAmount[](0), 
            new Building.ResourceAmount[](0), 
            castleAllowedTerrainTypes,
            Models.BuildingType.Castle
        ));

        emit Models.ContractDeployed("Castle contract deployed", _castleContract);
    }

    function __add__(
            string memory name,
            string memory symbol,
            string memory description,
            Building.ResourceAmount[] memory inputResources,
            Building.ResourceAmount[] memory outputResources,
            Models.TerrainType[] memory terrainTypes,
            Models.BuildingType buildingType) public onlyOwner {
        
        Building building = new Building(name, symbol, description, address(this), inputResources, outputResources, terrainTypes, buildingType);
        _buildings[address(building)] = building;
        _buildingAddresses.push(address(building));
        emit Models.ContractDeployed("Building contract deployed", address(building));
    }

    function getCastleContract() public view returns(address){
        return _castleContract;
    }

    function getAllContracts() public view returns(address[] memory){
        return _buildingAddresses;
    }

    function get(address buildingAddress) public view returns (Building building) {
        return _buildings[buildingAddress];
    }
}