const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');
const StrategyDummy = artifacts.require('StrategyDummy');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0xdf574c24545e5ffecb9a659c229253d4111d87e1',
    Controller.address);
  await deployer.deploy(
    StrategyDummy,
    '0xdf574c24545e5ffecb9a659c229253d4111d87e1',
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0xdf574c24545e5ffecb9a659c229253d4111d87e1',
    StrategyDummy.address);
  await contractInstance.setVault(
    '0xdf574c24545e5ffecb9a659c229253d4111d87e1',
    Vault.address);
  await deployer.deploy(
    PloutoRewards,
    Vault.address,
    PLU.address,
    Controller.address);
};
