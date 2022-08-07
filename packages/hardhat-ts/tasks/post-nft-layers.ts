import { task } from 'hardhat/config';
import { NFTStorage } from 'nft.storage'
import { filesFromPath } from 'files-from-path'
import path from 'path'

const token = process.env.NFT_STORAGE_TOKEN ? process.env.NFT_STORAGE_TOKEN : ''

task('post-nft-layers', 'Sets the URLs for NFT layers on the GenerativeObjectCollection contract')
  .addPositionalParam('cid', 'IPFS CID for the folder containing the files (filenames should be "Layer N-K.png" where N is layer number and K the option)')
  .addPositionalParam('width', 'Image width in pixels')
  .addPositionalParam('height', 'Image height in pixels')
  .addPositionalParam('nLayers', 'Number of layers')
  .addPositionalParam('maxOptionsPerLayer', 'Number of options for each layer')
  .addPositionalParam('contractAddress', 'The address of the GenerativeObjectCollection contract')
  .setAction(async ({ cid, width, height, nLayers, maxOptionsPerLayer, contractAddress }, hre) => {

    const storage = new NFTStorage({ token })

    const status = await storage.status(cid)
    console.log(status)

    let layerUris: Array<Array<string>> = []
    for (let i = 0; i < parseInt(nLayers); i++) {
      layerUris.push([] as Array<string>)
      for (let j = 0; j < parseInt(maxOptionsPerLayer); j++) {
        layerUris[i].push(`ipfs://${cid}/Layer ${i}-${j}.png`)
      }
    }

    const collection = await hre.ethers.getContractAt('GenerativeObjectCollection', contractAddress, (await hre.ethers.getSigners())[0])

    console.log('Setting URIs on the contract...')
    await collection.postLayers(layerUris, width, height)
    console.log('Done.')
  })
