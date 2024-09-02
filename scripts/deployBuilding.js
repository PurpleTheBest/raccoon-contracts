const hre = require('hardhat');
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  const name = "Castle";
  const symbol = "CSTL";
  const description = "";
  const owner = "0xC3a99178Ea1Ca514De13225Ccb907287667417FA";  // Ensure this address is correctly formatted
  const inputResources = [];  // Empty array as shown in the image
  const outputResources = [];  // Empty array as shown in the image
  const allowedTerrainTypes = [1, 4];  // Provided in the image
  const buildingType = 1;

  const Building = await hre.ethers.deployContract("Building", [
    name,
    symbol,
    description,
    owner,
    inputResources,
    outputResources,
    allowedTerrainTypes,
    buildingType
  ]);

  await Building.waitForDeployment();

  const buildingAddress = await Building.getAddress();

  console.log(`Building contract deployed to: ${buildingAddress}`);

  await sleep(30000);

  await hre.run('verify:verify', {
    address: buildingAddress,
    constructorArguments: [
      name,
      symbol,
      description,
      owner,
      inputResources,
      outputResources,
      allowedTerrainTypes,
      buildingType
    ],
    contract: 'contracts/building.sol:Building', 
  });
}

// Handle errors
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
