const Controller = artifacts.require('Controller');

module.exports = async function(deployer) {
  await deployer;
  const contractInstance = await deployer.deploy(Controller);
  await contractInstance.setRewards('0x416835EFFE1f89D65eEE00734d0438dACbE7C9F7');
};
