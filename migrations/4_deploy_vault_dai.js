const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');

module.exports = async function(deployer) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0x6b175474e89094c44da98b954eedeac495271d0f',
    Controller.address,
    150);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setVault(
    '0x6b175474e89094c44da98b954eedeac495271d0f',
    Vault.address);
};
