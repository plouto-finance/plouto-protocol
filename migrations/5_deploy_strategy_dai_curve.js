const Controller = artifacts.require('Controller');
const StrategyDAICurve = artifacts.require('StrategyDAICurve');

module.exports = async function(deployer) {
  await deployer;
  await deployer.deploy(StrategyDAICurve, Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0x6b175474e89094c44da98b954eedeac495271d0f',
    StrategyDAICurve.address);
};
