const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');
const StrategySwerveUSD = artifacts.require('StrategySwerveUSD');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    Controller.address);
  await deployer.deploy(
    StrategySwerveUSD,
    2,
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    StrategySwerveUSD.address);
  await contractInstance.setVault(
    '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    Vault.address);
  await deployer.deploy(
    PloutoRewards,
    Vault.address,
    PLU.address,
    Controller.address);
};
