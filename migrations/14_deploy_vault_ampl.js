const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');

module.exports = async function(deployer, network) {
  await deployer;
  if (network.includes('ropsten')) {
    await deployer.deploy(
      Vault,
      '0xADeD4B66783099E174a17b74E698aeFA0fd8f19d',
      Controller.address);
    const contractInstance = await deployer.deploy(Controller, { overwrite: false });
    await contractInstance.setVault(
      '0xADeD4B66783099E174a17b74E698aeFA0fd8f19d',
      Vault.address);
    return;
  } else if (network.includes('kovan')) {
    await deployer.deploy(
      Vault,
      '0x5075a70f5c86a4132e57fcea857c0c1d87e43093',
      Controller.address);
    const contractInstance = await deployer.deploy(Controller, { overwrite: false });
    await contractInstance.setVault(
      '0x5075a70f5c86a4132e57fcea857c0c1d87e43093',
      Vault.address);
    return;
  }
  await deployer.deploy(
    Vault,
    '0xd46ba6d942050d489dbd938a2c909a5d5039a161',
    Controller.address);
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setVault(
    '0xd46ba6d942050d489dbd938a2c909a5d5039a161',
    Vault.address);
};