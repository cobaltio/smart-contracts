var MyNFT = artifacts.require("MyNFT");
var Transact = artifacts.require("SellNFT");
module.exports = function(deployer) {
    deployer.deploy(MyNFT).then(() => {
        return deployer.deploy(Transact, MyNFT.address)
    });
    // Additional contracts can be deployed here
};