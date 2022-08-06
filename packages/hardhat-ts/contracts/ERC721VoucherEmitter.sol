pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

import "./IERC721Voucher.sol";
import "./ERC721Voucher.sol";

contract ERC721VoucherEmitter is ERC721Enumerable, ERC721Royalty {
  IERC721Voucher public voucher;

  event VoucherCreated(address owner, uint256 tokenId, uint256 voucherId);

  constructor(
    string memory name_,
    string memory symbol_,
    string memory voucherName_,
    string memory voucherSymbol_
  ) ERC721(name_, symbol_) {
    voucher = new ERC721Voucher(address(this), voucherName_, voucherSymbol_);
  }

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
    // TODO mint an ERC721Voucher token and assign it to `to`
    emit VoucherCreated(to, tokenId, 0);
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
    ERC721Royalty._burn(tokenId);
  }
}
