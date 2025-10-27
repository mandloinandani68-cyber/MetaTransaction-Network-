const hre = require("hardhat");

async function main() {
  const Contract = await hre.ethers.getContractFactory("MetaTransactionNetwork");
  const instance = await Contract.deploy();
  await instance.deployed();

  console.log("MetaTransactionNetwork deployed to:", instance.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
