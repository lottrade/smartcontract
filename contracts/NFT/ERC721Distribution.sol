// SPDX-License-Identifier: MIT
// NIFTSY protocol for NFT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ERC721Distribution is ERC721URIStorage, Ownable {
    string startNftIpfsHash = "QmWTnzkr4wysmwxpt6wVmzj9F6N5kfV6bcDA3oQLqcD61F";
    string proNftIpfsHash = "QmbppBJVsFFgvXv9GkTaHoGrBR1yofnVdFUxWu9sykAJW1";
    string expertNftIpfsHash = "QmSgFFQBZb1DvynB6cJFsP54FAhMy6g2ES1UFcGiibWyjj";
    string partnerNftIpfsHash = "QmZmg712oJUF5qqEDdgvF9TM5VgBtQ353vCqUkzytqdeTr";

    mapping(address => bool) public trustedMinter;

    mapping(address => uint256[]) public ovnerNft;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_)  {
        trustedMinter[msg.sender] = true;
    }

    modifier checkTrustedMinter() {
        require(trustedMinter[msg.sender], "Trusted address only");
        _;
    }

    function updateNftUrl(string memory nftType, string memory newNftUrl) external onlyOwner {
        if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("start")))) {
            startNftIpfsHash = newNftUrl;
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("pro")))) {
            proNftIpfsHash = newNftUrl;
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("expert")))) {
            expertNftIpfsHash = newNftUrl;
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("partner")))) {
            partnerNftIpfsHash = newNftUrl;
        }
    }

    function mint(address _to, uint256 _tokenId) external checkTrustedMinter() returns (uint256) {
        string memory nftIpfsHash = _getUrlForMintNft(_tokenId);
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, nftIpfsHash);

        ovnerNft[_to].push(_tokenId);
        return _tokenId;
    }

    function setMinterStatus(address _minter, bool _isTrusted) external onlyOwner {
        trustedMinter[_minter] = _isTrusted;
    }

    function getOvnerNfts(address _ovner) external view returns(address, uint256[] memory) {
        uint256[] memory ovnerNfts = ovnerNft[_ovner];
        uint256[] memory nfts = new uint[](ovnerNfts.length);

        for (uint i = 0; i < ovnerNfts.length; i++) {
            nfts[i] = ovnerNfts[i];
        }

        return (_ovner, nfts);
    }

    function _getUrlForMintNft(uint256 _tokenId) internal view returns(string memory) {
        require(_tokenId >= 1 && _tokenId <= 6600, "ERC721Distribution: unavailable itemId");
        string memory nftIpfsHash;

        if (_tokenId >= 1 && _tokenId <= 4500) nftIpfsHash = startNftIpfsHash;
        else if (_tokenId > 4500 && _tokenId <= 6000) nftIpfsHash = proNftIpfsHash;
        else if (_tokenId > 6000 && _tokenId <= 6500) nftIpfsHash = expertNftIpfsHash;
        else if (_tokenId > 6500 && _tokenId <= 6600) nftIpfsHash = partnerNftIpfsHash;

        return nftIpfsHash;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function baseURI() external pure returns (string memory) {
        return _baseURI();
    }
}