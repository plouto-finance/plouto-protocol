const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');
const StrategyDummy = artifacts.require('StrategyDummy');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0x28Da24ed20906CDE186D8B4f83412C3AE37a6269',
    Controller.address);
  await deployer.deploy(
    StrategyDummy,
    '0x28Da24ed20906CDE186D8B4f83412C3AE37a6269',
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0x28Da24ed20906CDE186D8B4f83412C3AE37a6269',
    StrategyDummy.address);
  await contractInstance.setVault(
    '0x28Da24ed20906CDE186D8B4f83412C3AE37a6269',
    Vault.address);
  await deployer.deploy(
    PloutoRewards,
    Vault.address,
    PLU.address,
    Controller.address);
};
