const PulotoGovernance = artifacts.require('PulotoGovernance');

module.exports = async function(deployer, network) {
  await deployer;
  const contractInstance = await deployer.deploy(PulotoGovernance);
  await contractInstance.initialize(0);
};
