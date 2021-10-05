const LOTT = artifacts.require("LOTTBEP20Token");
const PreSale = artifacts.require("PreSaleUnlocked");
const Web3 = require("web3");
const web3 = new Web3();

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(LOTT, web3.utils.toWei(`${100000000}`, 'ether'));
    let addressBUSD = "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee";
    if (network == 'live') {
        addressBUSD = "0xe9e7cea3dedca5984780bafc599bd69add087d56";
    }
    await deployer.deploy(PreSale, addressBUSD, LOTT.address);
}