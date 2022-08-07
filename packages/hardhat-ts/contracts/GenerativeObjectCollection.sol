pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC721VoucherEmitter.sol";

contract GenerativeObjectCollection is ERC721VoucherEmitter {
  using SafeMath for uint256;

  uint256 public nextTokenId;
  uint256 public mintPrice;
  uint256 public mintStartTime;
  uint256 public mintEndTime;
  uint256 public maxTokens;
  string[][] public layersURI;
  mapping(uint256 => uint256[]) tokenLayers;
  mapping(bytes32 => bool) combinationExists;

  event GenerativeObjectCollectionCreated(address addr_, address owner_);
  event GenerativeObjectLayersUpdated(string[][] layers);
  event MintParamsUpdated(uint256 mintPrice, uint256 mintStartTime, uint256 mintEndTime, uint256 maxTokens);

  constructor(
    address owner_,
    string memory name_,
    string memory symbol_,
    string memory voucherName_,
    string memory voucherSymbol_,
    address asksCore_,
    address transferHelper_,
    uint256 minVoucherPrice_,
    uint256 voucherDeadline_,
    uint256 claimDeadline_
  ) ERC721VoucherEmitter(owner_, name_, symbol_, voucherName_, voucherSymbol_, asksCore_, transferHelper_, minVoucherPrice_, voucherDeadline_, claimDeadline_) {
    emit GenerativeObjectCollectionCreated(address(this), owner_);
  }

  function setMintParams(
    uint256 mintPrice_,
    uint256 mintStartTime_,
    uint256 mintEndTime_,
    uint256 maxTokens_
  ) external onlyOwner {
    require(mintStartTime > block.timestamp, "START_MUST_BE_FUTURE");
    require(mintEndTime > mintStartTime, "END_MUST_BE_GT_START");
    mintPrice = mintPrice_;
    mintStartTime = mintStartTime_;
    mintEndTime = mintEndTime_;
    maxTokens = maxTokens_;
    emit MintParamsUpdated(mintPrice, mintStartTime, mintEndTime, maxTokens);
  }

  function postLayers(string[][] calldata layers) external onlyOwner {
    require(block.timestamp < mintStartTime, "TOO_LATE");
    for (uint256 i = 0; i < layers.length; i++) {
      require(layers[i].length > 0, "EMPTY_LAYERS_NOT_ALLOWED");
      for (uint256 j = 0; j < layers[i].length; i++) {
        // URI for option j for layer i
        layersURI[i][j] = layers[i][j];
      }
    }
    emit GenerativeObjectLayersUpdated(layers);
  }

  function tokenURI(uint256 tokenId) public view virtual override(ERC721VoucherEmitter) returns (string memory) {
    // TODO create dynamic metadata with an embedded svg image
  }

  function mint(address to) external payable returns (uint256) {
    require(mintStartTime > 0, "NOT_INITIALIZED");
    require(block.timestamp >= mintStartTime, "TOO_EARLY");
    require(block.timestamp < mintEndTime, "TOO_LATE");
    require(msg.value >= mintPrice, "MOAR_MONEY");
    require(nextTokenId < maxTokens, "MINT_COMPLETE");

    uint256 tokenId = nextTokenId;
    nextTokenId += 1;

    uint256 offset = uint256(uint160(address(this))) * nextTokenId;
    uint256[] storage nextTokenLayers = tokenLayers[tokenId];
    do {
      for (uint256 i = 0; i < layersURI.length; i++) {
        offset += 1;
        uint256 index = _randomNumber(offset) % layersURI[i].length;
        nextTokenLayers[i] = index;
      }
    } while (combinationExists[keccak256(abi.encodePacked(nextTokenLayers))]);
    combinationExists[keccak256(abi.encodePacked(nextTokenLayers))] = true;
    _mint(to, tokenId);
    return tokenId;
  }

  function withdraw() external onlyOwner {
    uint256 funds = address(this).balance;
    (bool success, ) = payable(msg.sender).call{ value: funds }("");
    require(success, "WITHDRAW_FAILED");
  }

  // Randomness provided by this is predictable. Use with care!
  // Copied from https://fravoll.github.io/solidity-patterns/randomness.html
  // Then added the offset - this is still predictable but now we can have
  // an arbitrary number of random numbers per block
  function _randomNumber(uint256 offset) internal view returns (uint256) {
    return uint256(keccak256(bytes.concat(blockhash(block.number - 1), bytes32(offset))));
  }
}
