// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import './models.sol';
import './utils.sol';
import './resource.sol';

contract ShopManager is Ownable {
    using Utils for *;

    uint256 private _shopItemId = 1;
    address private _goldContract;
    mapping(uint256 => Models.ShopItem) _shopItems;
    mapping(uint256 => uint256[]) _shops;

    constructor(address goldContract, address owner) Ownable(owner) {
        require(owner != address(0), "Invalid address");
        _goldContract = goldContract;
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

    function executeOrder(uint256 shopItemId) public {
        Models.ShopItem memory shopItem = _shopItems[shopItemId];
        require(shopItem.id != 0, "Shop item does not exist");

        IERC20 productToken = IERC20(shopItem.product);
        Resource goldToken = Resource(_goldContract);

        if (shopItem.buySell == Models.BuySell.Buy) {
            require(goldToken.transferFrom(msg.sender, shopItem.owner, shopItem.price), "Gold transfer failed");
            require(productToken.transfer(msg.sender, shopItem.quantity), "Product transfer failed");
        } else if (shopItem.buySell == Models.BuySell.Sell) {
            require(productToken.transferFrom(msg.sender, address(this), shopItem.quantity), "Product transfer failed");
            require(goldToken.transfer(msg.sender, shopItem.price), "Gold transfer failed");
        }

        emit Models.OrderExecuted(msg.sender, shopItemId, shopItem.quantity, shopItem.price, shopItem.buySell);
    }

}
