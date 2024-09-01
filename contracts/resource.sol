// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./models.sol";

contract Resource is ERC20, Ownable {

    string public _name;
    string public _description;

    constructor(
        string memory name,
        string memory symbol,
        string memory description,
        address owner
    ) ERC20(name, symbol) Ownable(owner) {
        require(owner != address(0), "Invalid address");

        _name = name;
        _description = description;
        _approve(address(this), owner, type(uint256).max);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address burnAddress, uint256 amount) public onlyOwner {
        _burn(burnAddress, amount);
    }
}