const hre = require("hardhat");

async function main() {
  console.log("Deploying GonanaEscrow to BNB Chain Testnet...");

  const GonanaEscrow = await hre.ethers.getContractFactory("GonanaEscrow");
  const escrow = await GonanaEscrow.deploy();

  await escrow.waitForDeployment();
  
  const contractAddress = await escrow.getAddress();
  console.log("✅ GonanaEscrow deployed to:", contractAddress);
  console.log("\nContract details:");
  console.log("- Platform Fee:", await escrow.platformFee(), "basis points (2.5%)");
  console.log("- Owner:", await escrow.owner());
  console.log("\nView on BscScan:");
  console.log(`https://testnet.bscscan.com/address/${contractAddress}`);
  console.log("\nTo verify contract, run:");
  console.log(`npx hardhat verify --network bscTestnet ${contractAddress}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
