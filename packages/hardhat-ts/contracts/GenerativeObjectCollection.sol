pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "base64-sol/base64.sol";

import "./ERC721VoucherEmitter.sol";

contract GenerativeObjectCollection is ERC721VoucherEmitter {
  using SafeMath for uint256;

  uint256 public nextTokenId;
  uint256 public mintPrice;
  uint256 public mintStartTime;
  uint256 public mintEndTime;
  uint256 public maxTokens;
  mapping(uint256 => mapping(uint256 => string)) public layersURI;
  uint256 public nLayers;
  uint256 public optionsPerLayer;
  mapping(uint256 => uint256[]) public tokenLayers;
  mapping(bytes32 => bool) public combinationExists;
  uint256 public imageWidth;
  uint256 public imageHeight;

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
    require(mintStartTime_ > 0, "START_MUST_BE_NONZERO");
    require(mintEndTime_ > mintStartTime_, "END_MUST_BE_GT_START");
    mintPrice = mintPrice_;
    mintStartTime = mintStartTime_;
    mintEndTime = mintEndTime_;
    maxTokens = maxTokens_;
    emit MintParamsUpdated(mintPrice, mintStartTime, mintEndTime, maxTokens);
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
    _setDefaultRoyalty(receiver, feeNumerator);
  }

  function postLayers(
    string[][] calldata layers,
    uint256 width,
    uint256 height
  ) external onlyOwner {
    require(block.timestamp < mintStartTime, "TOO_LATE");
    imageWidth = width;
    imageHeight = height;
    nLayers = layers.length;
    optionsPerLayer = layers[0].length;
    for (uint256 i = 0; i < layers.length; i++) {
      require(layers[i].length == optionsPerLayer, "INVALID_LAYER");
      for (uint256 j = 0; j < layers[i].length; j++) {
        // URI for option j for layer i
        layersURI[i][j] = layers[i][j];
      }
    }
    emit GenerativeObjectLayersUpdated(layers);
  }

  // Adapted from the ZorbNFT contract
  function tokenURI(uint256 tokenId) public view virtual override(ERC721VoucherEmitter) returns (string memory) {
    require(_exists(tokenId), "No token");

    string memory idString = Strings.toString(tokenId);

    return
      _encodeMetadataJSON(
        abi.encodePacked(
          '{"name": "Wild Silks #',
          idString,
          '", "description": "Each Wild Silk represents a silk scarf design. Minting',
          " or buying a Wild Silks token on Zora over the minimum price within the allowed period",
          'produces a voucher token that can be used to claim a physical silk scarf.",',
          ' "image": "',
          imageForToken(tokenId),
          '"}'
        )
      );
  }

  // Adapted from ZorbNFT's zorbForAddress
  /// @param tokenId Token for which to get the image
  function imageForToken(uint256 tokenId) public view returns (string memory) {
    string memory layerImages;
    for (uint256 i = 0; i < nLayers; i++) {
      layerImages = string(
        abi.encodePacked(layerImages, '<image href="', layersURI[i][tokenLayers[tokenId][i]], '" width=', imageWidth, " height=", imageHeight, " />")
      );
    }
    string memory encoded = Base64.encode(
      abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ', imageWidth, " ", imageHeight, '">', layerImages, '</svg>"')
    );
    return string(abi.encodePacked("data:image/svg+xml;base64,", encoded));
  }

  function mint(address to) external payable returns (uint256) {
    require(mintStartTime > 0, "NOT_INITIALIZED");
    require(block.timestamp >= mintStartTime, "TOO_EARLY");
    require(block.timestamp < mintEndTime, "TOO_LATE");
    require(msg.value >= mintPrice || msg.sender == Ownable.owner(), "MOAR_MONEY");
    require(nextTokenId < maxTokens, "MINT_COMPLETE");

    uint256 tokenId = nextTokenId;
    nextTokenId += 1;

    uint256 offset = uint256(uint160(address(this))) * nextTokenId;
    uint256[] storage nextTokenLayers = tokenLayers[tokenId];
    uint256 attempts;
    bytes32 layersHash;
    do {
      for (uint256 i = 0; i < nLayers; i++) {
        offset += 1;
        uint256 index = _pseudoRandomNumber(offset) % optionsPerLayer;
        nextTokenLayers.push(index);
      }
      layersHash = keccak256(abi.encodePacked(nextTokenLayers));
    } while (combinationExists[layersHash] && attempts < 3);
    require(!combinationExists[layersHash], "WONT_CREATE_DUPLICATE");
    combinationExists[layersHash] = true;
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
  function _pseudoRandomNumber(uint256 offset) internal view returns (uint256) {
    return uint256(keccak256(bytes.concat(blockhash(block.number - 1), bytes32(offset))));
  }

  // Metadata logic adapted from https://github.com/ourzora/nft-editions/blob/main/contracts/SharedNFTLogic.sol
  /// Encodes the argument json bytes into base64-data uri format
  /// @param json Raw json to base64 and turn into a data-uri
  function _encodeMetadataJSON(bytes memory json) internal pure returns (string memory) {
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
  }
}
