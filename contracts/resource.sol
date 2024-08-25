// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./models.sol";

contract Resource is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address private immutable _unlimitedAllowanceAddress;
    uint256 private _price;

    constructor(
        string memory name,
        string memory symbol,
        string memory description,
        address unlimitedAllowanceAddress
    ) ERC20(name, symbol) Ownable(_unlimitedAllowanceAddress) {
        require(_unlimitedAllowanceAddress != address(0), "Invalid address");
        unlimitedAllowanceAddress = _unlimitedAllowanceAddress;
        _approve(address(this), unlimitedAllowanceAddress, type(uint256).max);
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        require(msg.sender == _unlimitedAllowanceAddress, "Not allowed to burn");
        _burn(msg.sender, amount);
    }
}