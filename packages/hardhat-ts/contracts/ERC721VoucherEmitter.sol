pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@zoralabs/v3/dist/contracts/modules/Asks/Core/ETH/AsksCoreEth.sol";

import "./IERC721Voucher.sol";
import "./ERC721Voucher.sol";

contract ERC721VoucherEmitter is ERC721Enumerable, ERC721Royalty {
  // Voucher NFT contract, created by this contract
  IERC721Voucher public voucher;
  // ERC721TransferHelper from Zora, that will be the only contract allowed to execute transfers that produce vouchers
  address public transferHelper;
  // AsksCoreEth contract from zora, that will be queried to validate if a transfer meets the minimum price requirement to produce a voucher
  AsksCoreEth public asksCore;
  // Minimum price for a resale to generate a new voucher
  uint256 minVoucherPrice;

  event VoucherCreated(address owner, uint256 tokenId, uint256 voucherId);

  constructor(
    string memory name_,
    string memory symbol_,
    string memory voucherName_,
    string memory voucherSymbol_,
    address asksCore_,
    address transferHelper_,
    uint256 minVoucherPrice_
  ) ERC721(name_, symbol_) {
    voucher = new ERC721Voucher(address(this), voucherName_, voucherSymbol_);
    asksCore = AsksCoreEth(asksCore_);
    transferHelper = transferHelper_;
    minVoucherPrice = minVoucherPrice_;
  }

  // Should be overridden by individual NFT contracts
  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {}

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC721Royalty) returns (bool) {
    return ERC721Enumerable.supportsInterface(interfaceId) || ERC721Royalty.supportsInterface(interfaceId);
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
    // ?
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721) {
    super._afterTokenTransfer(from, to, tokenId);
    if (msg.sender == transferHelper) {
      (address seller, uint256 price) = asksCore.askForNFT(address(this), tokenId);
      if (seller == from && price >= minVoucherPrice) {
        _mintVoucher(to, tokenId);
      }
    } else if (from == address(0)) {
      _mintVoucher(to, tokenId);
    }
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
    ERC721Royalty._burn(tokenId);
  }

  function _mintVoucher(address to, uint256 tokenId) internal {
    uint256 voucherId = voucher.mint(to, tokenId);
    emit VoucherCreated(to, tokenId, voucherId);
  }
}
