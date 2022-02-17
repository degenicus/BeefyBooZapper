const hre = require("hardhat");

async function main() {
  const BeefyBooZapper = await hre.ethers.getContractFactory("BeefyBooZapper");
  const uniRouter = "0xF491e7B69E4244ad4002BC14e878a34207E38c29";
  const wftm = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";
  const beefyBooZapper = await BeefyBooZapper.deploy(uniRouter, wftm);

  await beefyBooZapper.deployed();

  console.log("BeefyBooZapper deployed to:", beefyBooZapper.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
