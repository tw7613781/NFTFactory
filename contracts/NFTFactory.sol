// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * @dev 本合约使用block.timestamp来判断锁仓情况,具有block timestamp manipulation的潜在风险,请参考
 * https://www.bookstack.cn/read/ethereumbook-en/spilt.14.c2a6b48ca6e1e33c.md
 * 但是考虑到目前并没有利益驱动,为了合约的简单性和时间的准确性,还是采用block.timestamp,而不是block.number,请悉知
 */
contract NFTFactory is ERC721, ReentrancyGuard, Ownable {
  uint256 public constant ONE_DAY = 86400;
  uint256 public constant TOTAL_RESERVE_NFTS = 150;
  uint256 public constant TOTAL_USERS_NFTS = 849;
  uint256 public constant DAILY_RELEASE = 333;
  uint256 public constant START_TIME = 1639062000; //1639062000
  uint256 private counter;
  uint256 private mintByOwner;
  uint256 private mintByUser;
  mapping(address => uint256) private lockedAddress;

  constructor() ERC721("Interstellar Maze", "IM") {
    counter = 0;
    mintByOwner = 0;
    mintByUser = 0;
  }

  /**
    * @dev mint logic
    * 1: 一共999个，开发小组保留15%,共150个,其余任何人都可以mint,每人每天24小时只能mint 1个，总数最多3个。
    * 2: 三天释放,每24小时释放333个NFT，3天全部释放完毕。
    * 3: 北京时间2021年12月12日上午10点开始 - 1639274400
    */
  function mint() public nonReentrant {
    require(
      counter < releasedNum(),
      "Mint more than released"
    );
    if (_msgSender() == owner()) {
      require(
        mintByOwner < TOTAL_RESERVE_NFTS,
        "Mint more than reserved for owner"
      );
      _safeMint(owner(), counter);
      counter += 1;
      mintByOwner += 1;
    } else {
      require(
        mintByUser < TOTAL_USERS_NFTS,
        "Mint more than public released"
      );
      require(
        balanceOf(_msgSender()) < 3,
        "One address can only mint 3 NFTs"
      );
      require(
        block.timestamp > lockedAddress[_msgSender()],
        "The address has minted today"
      );
      _safeMint(_msgSender(), counter);
      counter += 1;
      mintByUser += 1;
      lockedAddress[_msgSender()] = ((block.timestamp - START_TIME) / ONE_DAY + 1) * ONE_DAY + START_TIME;
    }
  }

  function releasedNum() public view returns (uint256) {
    require(
      block.timestamp > START_TIME,
      "The minting is not started yet"
    );
    uint256 _totalRelease = ((block.timestamp - START_TIME) / ONE_DAY + 1) * DAILY_RELEASE;
    return _totalRelease > DAILY_RELEASE * 3 ? DAILY_RELEASE * 3 : _totalRelease;
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://www.btcart.cn/api/nft/";
  }
}
