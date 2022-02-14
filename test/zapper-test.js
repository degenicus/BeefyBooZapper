const { expect } = require("chai");
const { ethers } = require("hardhat");

const eth = (amount) => ethers.utils.parseEther(amount);

let vault;
let zapper;
let depositor;
let boo;
let router;
const booHolder = "0xb18bd5be9508882b3ea934838671da7fe5aa11ca";
const reaperVault = "0xFC550BAD3c14160CBA7bc05ee263b3F060149AFF";
const uniRouter = "0xF491e7B69E4244ad4002BC14e878a34207E38c29";
const booAddress = "0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE";
const wftm = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";

beforeEach(async function () {
  await network.provider.request({
    method: "hardhat_reset",
    params: [
      {
        forking: {
          jsonRpcUrl: "https://rpc.ftm.tools/",
          blockNumber: 30935820,
        },
      },
    ],
  });

  const Zapper = await ethers.getContractFactory("BeefyBooZapper");
  zapper = await Zapper.deploy(uniRouter, wftm);
  await zapper.deployed();

  const Vault = await ethers.getContractFactory("ReaperVaultv1_3");
  vault = Vault.attach(reaperVault);

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [booHolder],
  });
  depositor = ethers.provider.getSigner(booHolder);

  const Boo = await ethers.getContractFactory("SpookyToken");
  boo = Boo.attach(booAddress);

  const Router = await ethers.getContractFactory("UniswapV2Router02");
  router = Router.attach(uniRouter);
});

describe("Zapper", function () {
  it("Should be able to deposit FTM", async function () {
    const vaultBalanceBefore = await vault.balanceOf(booHolder);
    const ftmDeposit = eth("1");
    await zapper.connect(depositor).beefInETH(reaperVault, eth("0"), {
      value: ftmDeposit,
    });
    const vaultBalanceAfter = await vault.balanceOf(booHolder);
    console.log(`vaultBalanceBefore: ${vaultBalanceBefore}`);
    console.log(`vaultBalanceAfter: ${vaultBalanceAfter}`);
    const rfTokenBalance = await vault.balanceOf(booHolder);
    const price = await vault.getPricePerFullShare();
    const booAmount = rfTokenBalance.mul(price).div(eth("1"));
    console.log(rfTokenBalance);
    console.log(price);
    console.log(booAmount);

    const amountsOut = await router.getAmountsOut(booAmount, [
      booAddress,
      wftm,
    ]);
    console.log(amountsOut);
    const wftmValueOfDeposit = amountsOut[1];
    expect(wftmValueOfDeposit).to.be.closeTo(ftmDeposit, eth("0.01"));
  });
});
