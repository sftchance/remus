import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, waffle } from "hardhat";

const { deployContract } = waffle;

const LibColor = require("../../artifacts/contracts/lib/LibColorRGB.sol/LibColorRGB.json");

describe("LibColorRGB", function () {
    const deployLibraryFixture = async () => {
        const [owner, otherAccount] = await ethers.getSigners();

        const library = await deployContract(owner, LibColor);

        return { owner, otherAccount, library };
    };

    describe("RGB", function () {
        it("deploy", async () => {
            const { library } = await loadFixture(deployLibraryFixture);

            expect(library.address).to.be.properAddress;
        });

        it("pack(255,255,0)", async () => {
            const { library } = await loadFixture(deployLibraryFixture);

            expect(await library.pack(255, 255, 0)).to.equal(0xffff00);
        });

        it("r(0xffff00)", async () => {
            const { library } = await loadFixture(deployLibraryFixture);

            expect(await library.r(0xffff00)).to.equal(255);
        });

        it("g(0xffff00)", async () => {
            const { library } = await loadFixture(deployLibraryFixture);

            expect(await library.g(0xffff00)).to.equal(255);
        });

        it("b(0xffffff)", async () => {
            const { library } = await loadFixture(deployLibraryFixture);

            expect(await library.b(0xffffff)).to.equal(255);
        });

        it("rgb(0xffff00)", async () => {
            const { library } = await loadFixture(deployLibraryFixture);

            const { $r, $g, $b } = await library.rgb(0xffff00);

            expect($r).to.equal(255);
            expect($g).to.equal(255);
            expect($b).to.equal(0);
        });

        it("number(ffffff)", async () => {
            const { library } = await loadFixture(deployLibraryFixture);

            const bytes = ethers.utils.toUtf8Bytes("ffffff");

            expect(await library.number(bytes)).to.equal(0xffffff);

            const invalidBytes = ethers.utils.toUtf8Bytes("fffff");

            await expect(library.number(invalidBytes)).to.be.revertedWith(
                "LibColor::number: Invalid hexadecimal color string length"
            );

            const invalidBytes2 = ethers.utils.toUtf8Bytes("fffffg");

            await expect(library.number(invalidBytes2)).to.be.revertedWith(
                "LibColor::hexadecimalByte: Invalid hexadecimal character"
            );
        });

        it("hexadecimal(0xFFFF00`)", async () => {
            const { library } = await loadFixture(deployLibraryFixture);

            expect(await library.hexadecimal(0xffff00)).to.equal("FFFF00");
        });
    });
});
