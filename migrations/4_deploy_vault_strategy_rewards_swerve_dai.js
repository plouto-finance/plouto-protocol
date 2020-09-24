const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');
const StrategySwerveUSD = artifacts.require('StrategySwerveUSD');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0x6B175474E89094C44Da98b954EedeAC495271d0F',
    Controller.address);
  await deployer.deploy(
    StrategySwerveUSD,
    0,
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setVault(
    '0x6B175474E89094C44Da98b954EedeAC495271d0F',
    Vault.address);
  await contractInstance.setStrategy(
    '0x6B175474E89094C44Da98b954EedeAC495271d0F',
    StrategySwerveUSD.address);
  await deployer.deploy(
    PloutoRewards,
    Vault.address,
    PLU.address,
    Controller.address);
};
