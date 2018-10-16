var Migrations = artifacts.require("./Migrations.sol");
var BlindAuction = artifacts.require("./BlindAuction.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(BlindAuction,1200000,1200000, '0x7a261075c737163ae2525f271717f3dbf5450b8c');
};
