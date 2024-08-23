// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Resource is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address public immutable unlimitedAllowanceAddress;
    enum Levels {Level1,Level2,Level3,Level4,Level5}
    Levels level;

    constructor(
        string memory name,
        string memory symbol,
        address _unlimitedAllowanceAddress,
        Levels level_
    ) ERC20(name, symbol) Ownable(_unlimitedAllowanceAddress) {
        require(_unlimitedAllowanceAddress != address(0), "Invalid address");
        unlimitedAllowanceAddress = _unlimitedAllowanceAddress;
        _approve(address(this), unlimitedAllowanceAddress, type(uint256).max);
        level = level_;
    }

    function isFirstLevel() public view returns (bool){
        return  level == Levels.Level1;
    }

    function setLevel(Levels level_)public {
        require(msg.sender == unlimitedAllowanceAddress, "Not allowed to set level");
        level = level_;
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(msg.sender == unlimitedAllowanceAddress, "Not allowed to burn");
        _burn(from, amount);
    }
}