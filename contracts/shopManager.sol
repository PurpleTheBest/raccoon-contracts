// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import './models.sol';
import './utils.sol';


contract ShopManager is Ownable {
    using Utils for *;

    mapping(uint256 => Models.ShopItem[]) _shopItems;

    constructor(address owner) Ownable(owner) {
        require(owner != address(0), "Invalid address");
    }

    function __add__(uint256 x, uint256 y, Models.ShopItem[] memory shopItems) public onlyOwner {
        uint256 encodedKey = Utils.encodeCoordinates(x, y);
        delete _shopItems[encodedKey];
        for (uint256 i = 0; i < shopItems.length; i++) {
            _shopItems[encodedKey].push(shopItems[i]);
        }    
    }

    function getShopItems(uint256 x, uint256 y) public view returns(Models.ShopItem[] memory){
        return _shopItems[Utils.encodeCoordinates(x, y)];
    }
}