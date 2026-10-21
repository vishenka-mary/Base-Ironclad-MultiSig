const hre = require("hardhat");
async function main() {
  const MultiSigFactory = await hre.ethers.getContractFactory("IroncladMultiSig");
  // Deploying with initial owners and a 2-of-3 threshold
  const multisig = await MultiSigFactory.deploy(["0x...", "0x...", "0x..."], 2);
  await multisig.deployed();
  console.log("-> Ironclad MultiSig active at:", multisig.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
