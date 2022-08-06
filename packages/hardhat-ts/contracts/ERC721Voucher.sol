pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IERC721Voucher.sol";

contract ERC721Voucher is Ownable, ERC721Enumerable, IERC721Voucher {
  using SafeMath for uint256;

  address public voucherEmitter;
  uint256 public nextTokenId;
  mapping(uint256 => uint256) public parentTokenIds;
  mapping(uint256 => bool) public claimed;

  event VoucherClaimed(address voucherEmitter, uint256 parentTokenId, address owner, uint256 tokenId, bytes extraData);

  constructor(
    address owner_,
    address voucherEmitter_,
    string memory name_,
    string memory symbol_
  ) ERC721(name_, symbol_) {
    voucherEmitter = voucherEmitter_;
    _transferOwnership(owner_);
  }

  /**
   * @notice mints a voucher associated with a parent token
   * @dev the returned token ID will be an NFT that represents
   * a voucher linked to the parent token ID.
   * @param to Owner of the new voucher token
   * @param parentTokenId Parent token to which this voucher is linked
   * @return tokenId for the new voucher token
   */
  function mint(address to, uint256 parentTokenId) external virtual returns (uint256) {
    require(msg.sender == voucherEmitter, "NOT_VOUCHER_EMITTER");
    uint256 tokenId = nextTokenId;
    nextTokenId = nextTokenId.add(1);
    parentTokenIds[tokenId] = parentTokenId;
    _mint(to, tokenId);
    return tokenId;
  }

  /**
   * @notice claim a voucher
   * @param tokenId voucher token to claim
   * @param extraData additional (potentially encrypted) data related to the voucher claim, e.g. an encrypted key and an encrypted address
   */
  function claim(uint256 tokenId, bytes calldata extraData) external {
    require(!claimed[tokenId], "ALREADY_CLAIMED");
    require(msg.sender == ownerOf(tokenId), "ONLY_OWNER_CAN_CALL");
    claimed[tokenId] = true;
    // Emit the extraData in an event so that a subgraph or API can pick it up
    emit VoucherClaimed(voucherEmitter, parentTokenIds[tokenId], msg.sender, tokenId, extraData);
  }

  // TODO generate metadata that references the parent token
  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
    return super.tokenURI(tokenId);
  }
}
