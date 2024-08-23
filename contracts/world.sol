// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './recipe.sol';
import './resource.sol';

contract World {
    using SafeERC20 for IERC20;
    bool private nativeCurrencySet = false;
    address public islandAddr;
    address public gold;
    uint256 private column;
    uint256 private row;
    string public worldName;
    error CantBuy();
    error IncorrectPayment();
    error NotAllowed();

    enum TerrainType {Mountains,Forest,Water,DeepWater,Sand,Grass}
    enum BuildingType {VendorShop, RecipeShop, Tavern, Brothel, Residential}
    
    struct Building {
        BuildingType buildingType;
        string name;
        uint256 x;
        uint256 y;
    }

    mapping(uint256 => Building) private buildings;

    struct Landfield {
        address owner;
        uint256 price;
        uint256 sellPrice;
        TerrainType terrainType;
        address recipe;
        uint256 lastClaim;
        uint256 x;
        uint256 y;
    }

    mapping(uint256 => Landfield) private landfields;
    address[] resources;
    address[] receipes;
    uint256 private landfieldNonce = 0;
    uint256 private buildingNonce = 0;

    constructor(string memory worldName_) {
        islandAddr = msg.sender;
        worldName = worldName_;
    }

    function buyGold() public payable {
        Resource token = Resource(gold);
        token.mint(msg.sender, (msg.value * 100000) / 1e18);
    }

    function getLandfields()public view returns(Landfield[] memory){
            Landfield[] memory result = new Landfield[](landfieldNonce);

            for (uint256 i = 0; i < landfieldNonce; i++) {
                result[i] = landfields[i];
            }
            return result;
    }

    function __createLandfields__(TerrainType[] memory terrainType,uint256[]memory price,uint256[] memory x,uint256[] memory y,uint256 row_,uint256 column_)public  {
        for (uint256 i = 0; i < price.length; i++) {
                landfields[landfieldNonce] = Landfield({
                    owner: address(0),        
                    price: price[i],             
                    sellPrice: 0,             
                    terrainType: terrainType[i], 
                    recipe: address(0),       
                    lastClaim: 0,             
                    x: x[i],                     
                    y: y[i]                      
                });

        landfieldNonce++;
        }
        row = row_;
        column = column_;
    }

    function getDimensions()public view returns(uint256,uint256){
        return (row,column);
    }
    
    function __setNativeCurrency__(address goldAddr) public {
        require(msg.sender == islandAddr, "Not allowed");
        require(!nativeCurrencySet, "Native currency already set");

        gold = goldAddr;
        nativeCurrencySet = true;
    }


    function buyLandfield(uint256 id) public  {
        Resource token = Resource(gold);
        if (landfields[id].owner == address(0)) {
            token.burn(msg.sender,landfields[id].price);
            landfields[id].owner = msg.sender;
        } else if (landfields[id].owner != address(0)) {
            bool result = token.transfer(landfields[id].owner,landfields[id].sellPrice); 
            if(result) landfields[id].owner = msg.sender;
        } else {
            revert CantBuy();
        }
    }

    function setSellPrice(uint256 sellPrice, uint256 landfieldId) public {
        if (landfields[landfieldId].owner == msg.sender) {
            landfields[landfieldId].sellPrice = sellPrice;
        } else {
            revert NotAllowed();
        }
    }

    function __destroyAll__() public {
        require(islandAddr == msg.sender,"Not allowed");
        for (uint256 i = 0; i < landfieldNonce; i++) {
            delete landfields[i];
        }
        landfieldNonce = 0;

        for (uint256 i = 0; i < buildingNonce; i++) {
            delete buildings[i];
        }
        buildingNonce = 0;
    }

    function getOwnership(uint256 landfieldId) public view returns (address) {
        return landfields[landfieldId].owner;
    }

function setRecipe(uint256 landfieldId, address recipe) public {
    Recipe recipeContract = Recipe(recipe);
    if (recipeContract.isFirstLevel()) {
        landfields[landfieldId].recipe = recipe;
        landfields[landfieldId].lastClaim = block.number;
    } else if (landfields[landfieldId].owner == msg.sender) {
        recipeContract.transferFrom(msg.sender, address(this), 1);
        landfields[landfieldId].recipe = recipe;
        landfields[landfieldId].lastClaim = block.number;
    } else {
        revert NotAllowed();
    }
}

    function claimResource(uint256 landfieldId) public {
        require(landfields[landfieldId].owner == msg.sender,"Not owner");
        require(landfields[landfieldId].recipe != address(0), "Recipe is not set");

        Recipe recipeContract = Recipe(landfields[landfieldId].recipe);

        Recipe.ResourceAmount[] memory inputResources = recipeContract.getInputResources();
        Recipe.ResourceAmount[] memory outputResources = recipeContract.getOutputResources();

        uint256 maxTroughPut  = 0;
        for (uint256 i = 0; i < inputResources.length; i++) {
            Resource currentResourceContract = Resource(inputResources[i].resourceContractAddr);
            maxTroughPut = (maxTroughPut < currentResourceContract.balanceOf(msg.sender)/inputResources[i].amount) ? maxTroughPut : currentResourceContract.balanceOf(msg.sender)/inputResources[i].amount;
        }
        uint256 cycleCount = (block.number - landfields[landfieldId].lastClaim)/10;

        uint256 transferCycleCount = (maxTroughPut < cycleCount) ? maxTroughPut : cycleCount;

        for (uint256 i = 0; i < inputResources.length; i++) {
            Resource currentResourceContract = Resource(inputResources[i].resourceContractAddr);
            currentResourceContract.burn(msg.sender,transferCycleCount * inputResources[i].amount);
        }

        for (uint256 i = 0; i < outputResources.length; i++) {
            Resource currentResourceContract = Resource(outputResources[i].resourceContractAddr);
            currentResourceContract.mint(msg.sender, (transferCycleCount * outputResources[i].amount));
        }

    }

function getLandfieldProduction(uint256 landfieldId) public view returns (uint256[] memory) {
    require(landfields[landfieldId].owner == msg.sender, "Not owner");
    require(landfields[landfieldId].recipe != address(0), "Recipe is not set");

    Recipe recipeContract = Recipe(landfields[landfieldId].recipe);

    Recipe.ResourceAmount[] memory inputResources = recipeContract.getInputResources();
    Recipe.ResourceAmount[] memory outputResources = recipeContract.getOutputResources();

    uint256 maxTroughPut = type(uint256).max; 
    for (uint256 i = 0; i < inputResources.length; i++) {
        Resource currentResourceContract = Resource(inputResources[i].resourceContractAddr);
        uint256 availableAmount = currentResourceContract.balanceOf(msg.sender) / inputResources[i].amount;
        if (availableAmount < maxTroughPut) {
            maxTroughPut = availableAmount;
        }
    }

    uint256 cycleCount = (block.number - landfields[landfieldId].lastClaim) / 10;

    uint256 transferCycleCount = maxTroughPut < cycleCount ? maxTroughPut : cycleCount;

    uint256[] memory result = new uint256[](outputResources.length); 
    for (uint256 i = 0; i < outputResources.length; i++) {
        result[i] = transferCycleCount * outputResources[i].amount;
    }

    return result;
}

    function __setResources__(address[] memory resources_)public{
        require(msg.sender == islandAddr,"Not allowed");
        for (uint256 i = 0; i < resources_.length; i++) {
            resources[i] = resources_[i];
        }
    }

    function __setReceipes__(address[] memory receipes_)public{
        require(msg.sender == islandAddr,"Not allowed");
        for (uint256 i = 0; i < receipes_.length; i++) {
            receipes[i] = receipes_[i];
        }
    }

    function __getResources__()public view returns(address[] memory resources_){
        for (uint256 i = 0; i < resources.length; i++) {
            resources_[i] = resources[i];
        }
        return resources_;
    }

    function __getReceipes__()public view returns(address[] memory receipes_){
        for (uint256 i = 0; i < receipes.length; i++) {
            receipes_[i] = receipes[i];
        }
        return receipes_;
    }

    function getLandfieldPrice(uint256 id) public view returns(uint256){
        if(landfields[id].owner ==  address(0)){
            return landfields[id].price;
        }
        return landfields[id].sellPrice;
    }

    function getBuildings()public view returns(Building[] memory){
            Building[] memory result = new Building[](buildingNonce);

            for (uint256 i = 0; i < buildingNonce; i++) {
                result[i] = buildings[i];
            }
            return result;
    }

  function __createBuildings__(BuildingType[] memory buildingType,string[] memory name,uint256[] memory x,uint256[] memory y)public  {
        require(msg.sender == islandAddr,"Not allowed");

        for (uint256 i = 0; i < buildingType.length; i++) {
                buildings[buildingNonce] = Building({                           
                    buildingType: buildingType[i], 
                    name: name[i],       
                    x: x[i],                     
                    y: y[i]                      
                });

        buildingNonce++;
        }
    }

}
