const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    PloutoRewards,
    '0x752a5b5bb4751d6c59674f6ef056d3d383a36e61',
    PLU.address,
    Controller.address);
};
