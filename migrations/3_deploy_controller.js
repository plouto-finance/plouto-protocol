const Controller = artifacts.require('Controller');

module.exports = async function(deployer) {
  await deployer;
  const contractInstance = await deployer.deploy(Controller);
  await contractInstance.setRewards('0x025c1534f82996437Ad862FED39F02B973969362');
};
