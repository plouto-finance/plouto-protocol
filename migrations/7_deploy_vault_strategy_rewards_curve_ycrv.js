const PLU = artifacts.require('PLU');
const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');
const StrategyCurveYCRVVoter = artifacts.require('StrategyCurveYCRVVoter');
const PloutoRewards = artifacts.require('PloutoRewards');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(
    Vault,
    '0xdf5e0e81dff6faf3a7e52ba697820c5e32d806a8',
    Controller.address);
  await deployer.deploy(
    StrategyCurveYCRVVoter,
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0xdf5e0e81dff6faf3a7e52ba697820c5e32d806a8',
    StrategyCurveYCRVVoter.address);
  await contractInstance.setVault(
    '0xdf5e0e81dff6faf3a7e52ba697820c5e32d806a8',
    Vault.address);
  await deployer.deploy(
    PloutoRewards,
    Vault.address,
    PLU.address,
    Controller.address);
};
