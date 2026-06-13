const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RightRegistry", function () {
  async function deployFixture() {
    const [admin, recipient] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("RightRegistry");
    const registry = await Factory.deploy(admin.address);
    await registry.deployed();
    return { registry, admin, recipient };
  }

  it("grants bootstrap roles to the constructor admin", async function () {
    const { registry, admin } = await deployFixture();
    const DEFAULT_ADMIN_ROLE = await registry.DEFAULT_ADMIN_ROLE();
    const ISSUER_ROLE = await registry.ISSUER_ROLE();

    expect(await registry.hasRole(DEFAULT_ADMIN_ROLE, admin.address)).to.equal(true);
    expect(await registry.hasRole(ISSUER_ROLE, admin.address)).to.equal(true);
  });

  it("issues a right and stores the expected accounting state", async function () {
    const { registry, recipient } = await deployFixture();
    const now = Math.floor(Date.now() / 1000);

    const tx = await registry.issueRight({
      issuerId: 1,
      to: recipient.address,
      controller: recipient.address,
      resourceUnit: 1,
      maxAmount: 1000,
      initialRemainingAmount: 1000,
      windowStart: now,
      windowEnd: now + 3600,
      metadataHash: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("right-1")),
      metadataURI: "ipfs://right-1",
      parentRightId: 0,
      lineageFlags: 0,
      activateImmediately: true
    });

    await tx.wait();

    expect(await registry.ownerOf(1)).to.equal(recipient.address);
    const right = await registry.getRight(1);
    expect(right.issuerId.toString()).to.equal("1");
    expect(right.maxAmount.toString()).to.equal("1000");
    expect(right.remainingAmount.toString()).to.equal("1000");
    expect(right.lifecycleStatus.toString()).to.equal("1");
  });
});
