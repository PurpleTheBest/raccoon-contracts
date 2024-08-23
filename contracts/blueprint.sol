// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./models.sol";

contract Blueprint is ERC20, Ownable {
   
    struct ResourceAmount {
        address resourceContractAddr;
        uint256 amount;
    }

    address private _unlimitedAllowanceAddress;
    string public  Name;
    string public Description;
    Models.Levels public Level;
    Models.BuildingType public BuildingType;
    ResourceAmount[] public InputResources;
    ResourceAmount[] public OutputResources;
    mapping(uint8 => Models.TerrainType) public AllowedTerrainTypes;

    constructor(
        string memory name,
        string memory symbol,
        string memory description,
        address unlimitedAllowanceAddress,
        address initialOwner,
        ResourceAmount[] memory inputResources,
        ResourceAmount[] memory outputResources,
        Models.TerrainType[] memory allowedTerrainTypes,
        Models.Levels level,
        Models.BuildingType buildingType) ERC20(name, symbol) Ownable(initialOwner) {
        
        _unlimitedAllowanceAddress = unlimitedAllowanceAddress;
        _approve(unlimitedAllowanceAddress, initialOwner, type(uint256).max);
        Level = level;
        BuildingType = buildingType;
        Description = description;
        Name = name;

        for (uint256 i = 0; i < inputResources.length; i++) {
            InputResources.push(inputResources[i]);
        }
        for (uint256 i = 0; i < outputResources.length; i++) {
            OutputResources.push(outputResources[i]);
        }
        for (uint256 i = 0; i < allowedTerrainTypes.length; i++) {
            AllowedTerrainTypes[uint8(allowedTerrainTypes[i])] = allowedTerrainTypes[i];
        }
    }

    function __setLevel__(Models.Levels level)public {
        require(msg.sender == _unlimitedAllowanceAddress, "Not allowed to set level");
        Level = level;
    }

    // Mint new tokens - only the unlimitedAllowanceAddress can mint
    function mint(address to, uint256 amount) public {
        require(msg.sender == _unlimitedAllowanceAddress, "Not allowed to mint");
        _mint(to, amount);
    }

    // Burn tokens - only the unlimitedAllowanceAddress can burn
    function burn(uint256 amount) public {
        require(msg.sender == _unlimitedAllowanceAddress, "Not allowed to burn");
        _burn(msg.sender, amount);
    }

    function getAllowedTerrainType(Models.TerrainType terrainType) public view returns (Models.TerrainType) {
        return AllowedTerrainTypes[uint8(terrainType)];
    }
}
