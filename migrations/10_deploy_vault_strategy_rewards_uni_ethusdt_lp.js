const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');
const StrategyUniLPStaking = artifacts.require('StrategyUniLPStaking');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852',
    Controller.address);
  await deployer.deploy(
    StrategyUniLPStaking,
    '0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852',
    '0x6c3e4cb2e96b01f4b866965a91ed4437839a121a',
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852',
    StrategyUniLPStaking.address);
  await contractInstance.setVault(
    '0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852',
    Vault.address);
  await deployer.deploy(
    PloutoRewards,
    Vault.address,
    PLU.address,
    Controller.address);
};
