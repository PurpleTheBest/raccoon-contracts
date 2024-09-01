// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './models.sol';
import './utils.sol';


contract ResourceManager is Ownable{
    using Utils for *;
    
    address[] private _resourceAddresses;
    mapping (address => Resource) private _resources;
    address private _goldContract;
    address private _gameAddress;
    address private _owner;

    constructor(address gameAddress) Ownable(msg.sender) {
        require(gameAddress != address(0), "Invalid address");
        _gameAddress = gameAddress;
        _owner = msg.sender;
        _goldContract = address(new Resource("Gold", "GLD", "", _gameAddress));
        emit Models.ContractDeployed("Gold contract deployed", address(_goldContract));
    }

    function __add__(string memory name, string memory symbol, string memory description) public onlyOwner {
        Resource resource = new Resource(name, symbol, description, _gameAddress);
        _resources[address(resource)] = resource;
        _resourceAddresses.push(address(resource));
        emit Models.ContractDeployed("Building contract deployed", address(resource));
    }

    function getGoldContract() public view returns(address){
        return _goldContract;
    }

    function getAllContracts() public view returns(address[] memory){
        return _resourceAddresses;
    }
}