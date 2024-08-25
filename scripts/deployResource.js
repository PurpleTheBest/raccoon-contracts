const hre = require('hardhat');
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function main() {
  const mapWidth = 10;
  const mapHeight = 10;
  const mapLength = 10;
  const mapName = "FantasyLand";

  const Game = await hre.ethers.deployContract("Game", [
    mapWidth,
    mapHeight,
    mapLength,
    mapName
  ]);

  await Game.waitForDeployment();

  const gameAddress = await Game.getAddress();

  console.log(`Game contract deployed to: ${gameAddress}`);

  await sleep(30000);

  await hre.run('verify:verify', {
    address: gameAddress,
    constructorArguments: [
      mapWidth,
      mapHeight,
      mapLength,
      mapName
    ],
    contract: 'contracts/resource.sol:Resource', 
  });
}

// Handle errors
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
