import { GenerativeObjectCollection__factory, GenerativeObjectCollection } from 'generated/contract-types';
import { task } from 'hardhat/config';
import { NFTStorage } from 'nft.storage'
import { filesFromPath } from 'files-from-path'
import path from 'path'

const token = process.env.NFT_STORAGE_TOKEN ? process.env.NFT_STORAGE_TOKEN : ''

task('upload-nft-layers', 'Uploads the layers for an NFT to NFT.storage and reports the CID')
  .addPositionalParam('folderPath', 'Path to the folder containing the files (must be PNG)')
  .setAction(async ({ folderPath }) => {
    const files = filesFromPath(folderPath, {
      pathPrefix: path.resolve(folderPath), // see the note about pathPrefix below
    })

    const storage = new NFTStorage({ token })

    console.log(`storing file(s) from ${folderPath}`)
    const cid = await storage.storeDirectory(files)
    console.log({ cid })

    const status = await storage.status(cid)
    console.log(status)
  })
