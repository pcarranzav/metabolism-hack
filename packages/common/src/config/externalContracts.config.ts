import { NetworkID } from '@dethcrypto/eth-sdk/dist/abi-management/networks';
import { TExternalContractsAddressMap } from 'eth-hooks/models';

import zoraDeployMumbai from '@zoralabs/v3/dist/addresses/80001.json'
import zoraDeployPolygon from '@zoralabs/v3/dist/addresses/137.json'

/**
 * ⛳️⛳️⛳️⛳️⛳️⛳️⛳️⛳️⛳️⛳️⛳️⛳️⛳️⛳️
 * #### Instructions
 * - Add your contracts to the list here
 * - The format is described by {@link TExternalContractsAddressMap}
 *
 * ### Summary
 * The list of external contracts use by the app.
 * it is used to generate the type definitions for the external contracts by `yarn contracts:build`
 * provide the name and address of the external contract and the definition will be generated
 */
export const externalContractsAddressMap: TExternalContractsAddressMap = {
  // [NetworkID.POLYGON_MUMBAI]: zoraDeployMumbai,
  // [NetworkID.POLYGON]: zoraDeployPolygon,
  [NetworkID.MAINNET]: {
    DAI: '0x6b175474e89094c44da98b954eedeac495271d0f',
  },
};
