const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');
const StrategyUniLPStaking = artifacts.require('StrategyUniLPStaking');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0xbb2b8038a1640196fbe3e38816f3e67cba72d940',
    Controller.address);
  await deployer.deploy(
    StrategyUniLPStaking,
    '0xbb2b8038a1640196fbe3e38816f3e67cba72d940',
    '0xCA35e32e7926b96A9988f61d510E038108d8068e',
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0xbb2b8038a1640196fbe3e38816f3e67cba72d940',
    StrategyUniLPStaking.address);
  await contractInstance.setVault(
    '0xbb2b8038a1640196fbe3e38816f3e67cba72d940',
    Vault.address);
  await deployer.deploy(
    PloutoRewards,
    Vault.address,
    PLU.address,
    Controller.address);
};
