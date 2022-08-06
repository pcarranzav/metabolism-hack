pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./IERC721Voucher.sol";

contract ERC721Voucher is ERC721Enumerable, IERC721Voucher {
  address public voucherEmitter;

  constructor(
    address voucherEmitter_,
    string memory name_,
    string memory symbol_
  ) ERC721(name_, symbol_) {
    voucherEmitter = voucherEmitter_;
  }
}
