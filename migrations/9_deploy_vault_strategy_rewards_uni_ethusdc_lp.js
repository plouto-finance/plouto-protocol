const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');
const StrategyUniLPStaking = artifacts.require('StrategyUniLPStaking');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc',
    Controller.address);
  await deployer.deploy(
    StrategyUniLPStaking,
    '0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc',
    '0x7FBa4B8Dc5E7616e59622806932DBea72537A56b',
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc',
    StrategyUniLPStaking.address);
  await contractInstance.setVault(
    '0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc',
    Vault.address);
  await deployer.deploy(
    PloutoRewards,
    Vault.address,
    PLU.address,
    Controller.address);
};
