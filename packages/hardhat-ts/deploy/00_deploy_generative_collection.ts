import { DeployFunction } from 'hardhat-deploy/types'
import { THardhatRuntimeEnvironmentExtended } from 'helpers/types/THardhatRuntimeEnvironmentExtended'

import zoraDeployMumbai from '@zoralabs/v3/dist/addresses/80001.json'
import zoraDeployPolygon from '@zoralabs/v3/dist/addresses/137.json'

const func: DeployFunction = async (hre: THardhatRuntimeEnvironmentExtended) => {
  const { getNamedAccounts, deployments, ethers } = hre
  const BigNumber = ethers.BigNumber

  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()
  const chainId: string = await hre.getChainId()
  let zoraDeploy: Record<string, string>
  if (chainId == '137') {
    zoraDeploy = zoraDeployPolygon
  } else {
    zoraDeploy = zoraDeployMumbai
  }
  const now = Math.round(Date.now() / 1000)
  const deployed = await deploy('GenerativeObjectCollection', {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [
      deployer,
      "Wild Silks",
      "WSLK",
      "Wild Silks Voucher",
      "WSLKV",
      zoraDeploy['AsksV1_1'],
      zoraDeploy['ERC721TransferHelper'],
      ethers.utils.parseEther('6'), // in MATIC
      BigNumber.from(now + (3 * 30 * 24 * 3600)), // 3 months-ish from now
      BigNumber.from(now + (4 * 30 * 24 * 3600)), // 4 months-ish from now
    ],
    log: true,
  })

  // Getting a previously deployed contract
  const GenerativeObjectCollection = await ethers.getContractAt(deployed.abi, deployed.address, await ethers.getSigner(deployer))
  console.log('Setting mint parameters...')
  await GenerativeObjectCollection.setMintParams(
    ethers.utils.parseEther('3'), // in MATIC
    BigNumber.from(1), //now + (1 * 24 * 3600)), // Tomorrow
    BigNumber.from(now + (3 * 30 * 24 * 3600)), // Same as voucherDeadline
    BigNumber.from('500')
  )

  console.log('Setting royalties...')
  await GenerativeObjectCollection.setDefaultRoyalty(deployer, BigNumber.from('3000')) // 30%.
}
export default func
func.tags = ['GenerativeObjectCollection']

/*
Tenderly verification
let verification = await tenderly.verify({
  name: contractName,
  address: contractAddress,
  network: targetNetwork,
})
*/
