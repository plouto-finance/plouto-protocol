const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');
const StrategyDummy = artifacts.require('StrategyDummy');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0x6f259637dcd74c767781e37bc6133cd6a68aa161',
    Controller.address);
  await deployer.deploy(
    StrategyDummy,
    '0x6f259637dcd74c767781e37bc6133cd6a68aa161',
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0x6f259637dcd74c767781e37bc6133cd6a68aa161',
    StrategyDummy.address);
  await contractInstance.setVault(
    '0x6f259637dcd74c767781e37bc6133cd6a68aa161',
    Vault.address);
  await deployer.deploy(
    PloutoRewards,
    Vault.address,
    PLU.address,
    Controller.address);
};
