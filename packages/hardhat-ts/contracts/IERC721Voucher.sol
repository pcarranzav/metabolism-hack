pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721Voucher is IERC721Enumerable {
  /**
   * @notice mints a voucher associated with a parent token
   * @dev the returned token ID will be an NFT that represents
   * a voucher linked to the parent token ID.
   * @param to Owner of the new voucher token
   * @param parentTokenId Parent token to which this voucher is linked
   * @return tokenId for the new voucher token
   */
  function mint(address to, uint256 parentTokenId) external returns (uint256);

  /**
   * @notice claim a voucher
   * @param tokenId voucher token to claim
   * @param extraData additional (potentially encrypted) data related to the voucher claim, e.g. an encrypted key and an encrypted address
   */
  function claim(uint256 tokenId, bytes calldata extraData) external;
}
