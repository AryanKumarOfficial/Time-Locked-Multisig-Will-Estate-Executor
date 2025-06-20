// scripts/deploy.js
const hre = require("hardhat");
require("dotenv").config();

async function main() {
  // Get contract factory
  const Will = await hre.ethers.getContractFactory("TimeLockedMultisigWill");

  // Example parameters – replace with real executor addresses and interval
  const executors = [
    "0xExecutorAddress1...",
    "0xExecutorAddress2..."
  ];
  const intervalSeconds = 60 * 60 * 24 * 365; // 1 year

  console.log("Deploying TimeLockedMultisigWill...");
  const will = await Will.deploy(executors, intervalSeconds);
  await will.deployed();

  console.log("TimeLockedMultisigWill deployed to:", will.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
Learn more about New+ by visiting https://aka.ms/PowerToysOverview_NewPlus