// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import './models.sol';
import './utils.sol';
import './resource.sol';

contract ShopManager is Ownable {
    using Utils for *;

    address private _owner;
    uint256 private _shopItemId = 1;

    // ShopItemId => ShopItem
    mapping(uint256 => Models.ShopItem) _shopItems;

    // ShopCordinates => ShopItemIds
    mapping(uint256 => uint256[]) _shops;

    constructor() Ownable(msg.sender) {
        _owner = msg.sender;
    }

    function __add__(uint256 x, uint256 y, Models.ShopItem[] memory shopItems) public onlyOwner {
        uint256 encodedKey = Utils.encodeCoordinates(x, y);
        for (uint256 i = 0; i < shopItems.length; i++) {
            shopItems[i].id = _shopItemId;
            _shopItems[_shopItemId] = shopItems[i];
            _shops[encodedKey].push(_shopItemId);
            _shopItemId++;
        }    
    }

    function getShopItems(uint256 x, uint256 y) public view returns(Models.ShopItem[] memory){
        uint256[] memory shopItemIds = _shops[Utils.encodeCoordinates(x, y)];
        Models.ShopItem[] memory shopItems;

        for (uint256 i = 0; i < shopItemIds.length; i++) {
        
            shopItems[i] = _shopItems[shopItemIds[i]];
        }

        return shopItems;
    }

    function getShopItem(uint256 id) public view returns(Models.ShopItem memory){
        return _shopItems[id];
    }
}
