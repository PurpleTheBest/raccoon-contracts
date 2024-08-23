// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Recipe is ERC20, Ownable {

    enum TerrainType {Mountains,Forest,Water,DeepWater,Sand,Grass}
    enum Levels {Level1,Level2,Level3,Level4,Level5}

    struct ResourceAmount {
        address resourceContractAddr;
        uint256 amount;
    }

    using SafeERC20 for IERC20;

    address public unlimitedAllowanceAddress;
    Levels public level;
    ResourceAmount[] public inputResources;
    ResourceAmount[] public outputResources;

    constructor(
        string memory name,
        string memory symbol,
        address _unlimitedAllowanceAddress,
        address initialOwner,
        ResourceAmount[] memory _inputResources,
        ResourceAmount[] memory _outputResources,
        Levels level_
    ) ERC20(name, symbol) Ownable(initialOwner) {
        // Set unlimited allowance for the specified address
        unlimitedAllowanceAddress = _unlimitedAllowanceAddress;
        _approve(unlimitedAllowanceAddress, initialOwner, type(uint256).max);
        level = level_;
        
        // Store the input and output resources
        for (uint256 i = 0; i < _inputResources.length; i++) {
            inputResources.push(_inputResources[i]);
        }
        for (uint256 i = 0; i < _outputResources.length; i++) {
            outputResources.push(_outputResources[i]);
        }
    }

    function isFirstLevel() public view returns (bool){
        return  level == Levels.Level1;
    }

    function setLevel(Levels level_)public {
        require(msg.sender == unlimitedAllowanceAddress, "Not allowed to set level");
        level = level_;
    }

    // Mint new tokens - only the unlimitedAllowanceAddress can mint
    function mint(address to, uint256 amount) public {
        require(msg.sender == unlimitedAllowanceAddress, "Not allowed to mint");
        _mint(to, amount);
    }

    // Burn tokens - only the unlimitedAllowanceAddress can burn
    function burn(uint256 amount) public {
        require(msg.sender == unlimitedAllowanceAddress, "Not allowed to burn");
        _burn(msg.sender, amount);
    }

    // Transfer tokens - using the inherited ERC20 transfer function
    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, amount);
    }

    // Check balance - using the inherited ERC20 balanceOf function
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }

    // Getter for input resources
    function getInputResources() public view returns (ResourceAmount[] memory) {
        return inputResources;
    }

    // Getter for output resources
    function getOutputResources() public view returns (ResourceAmount[] memory) {
        return outputResources;
    }
}
