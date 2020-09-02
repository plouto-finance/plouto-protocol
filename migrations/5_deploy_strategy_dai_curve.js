const Controller = artifacts.require('Controller');
const StrategyDAICurve = artifacts.require('StrategyDAICurve');

module.exports = async function(deployer, network) {
  await deployer;
  await deployer.deploy(StrategyDAICurve, Controller.address);
  if (network.includes('ropsten')) {
    const contractInstance = await deployer.deploy(Controller, { overwrite: false });
    await contractInstance.setStrategy(
      '0xADeD4B66783099E174a17b74E698aeFA0fd8f19d',
      StrategyDAICurve.address);
    return;
  } else if (network.includes('kovan')) {
    const contractInstance = await deployer.deploy(Controller, { overwrite: false });
    await contractInstance.setStrategy(
      '0x5075a70f5c86a4132e57fcea857c0c1d87e43093',
      StrategyDAICurve.address);
    return;
  }
  const contractInstance = await deployer.deploy(Controller, { overwrite: false });
  await contractInstance.setStrategy(
    '0x6b175474e89094c44da98b954eedeac495271d0f',
    StrategyDAICurve.address);
};
