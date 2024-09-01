// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import './utils.sol';

contract ResourceFactory is Ownable{
    using Utils for *;
    
    mapping (address => address[]) _gameResources;
    mapping (address => address) _gameGold;

    address private _owner;

    constructor() Ownable(msg.sender) {
        _owner = msg.sender;
    }

    function __initialize__(address gameAddress) public{
        address goldAddress = address(new Resource("Gold", "GLD", "", gameAddress));
        _gameGold[gameAddress] = goldAddress;
        emit Models.ContractDeployed("Gold contract deployed", address(goldAddress));
    }

    function __addResource__(
        string memory name,
        string memory symbol,
        string memory description,
        address gameAddress) public onlyOwner {

        Resource resource = new Resource(name, symbol, description, gameAddress);
        _gameResources[gameAddress].push(address(resource));
        emit Models.ContractDeployed("Building contract deployed", address(resource));
    }

    function getGold(address gameAddress) public view returns(address){
        return _gameGold[gameAddress];
    }

    function getResources(address gameAddress) public view returns(address[] memory){
        return _gameResources[gameAddress];
    }
}