const Controller = artifacts.require('Controller');
const Vault = artifacts.require('Vault');

module.exports = async function(deployer, network) {
  await deployer;
  if (network.includes('ropsten')) {
    await deployer.deploy(
      Vault,
      '0x05b954633faf5ceeecdf945c13ad825faabbf66f',
      Controller.address,
      150);
    return;
  } else if (network.includes('kovan')) {
    await deployer.deploy(
      Vault,
      '0xc707fd5a456eec2609463f7fea79756356f0a754',
      Controller.address,
      150);
    return;
  }
  await deployer.deploy(
    Vault,
    '0x6b175474e89094c44da98b954eedeac495271d0f',
    Controller.address,
    150);
};
