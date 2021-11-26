// SPDX-License-Identifier: MIT
// NIFTSY protocol for NFT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//v0.0.3
contract ERC721Distribution is ERC721URIStorage, Ownable {
    string startNftIpfsHash = "QmaSYZg9up7mzNuCk4iUCSPSqWqn3BWuXbBKfHiytN4Mue";
    string proNftIpfsHash = "QmYw2pxEbKHVu8yQhu3e6HFCdgudzCVmnk3BL8DXfKN8qV";
    string expertNftIpfsHash = "QmYtRxDCkZBwAmKmG8YiVpXWXfgfe9e9JJV4ioLeYwBmzc";
    string partnerNftIpfsHash = "QmVBSLXVmMPfxVw4KDzxZP1dr3NxB7hmNEVTUf2zbWEbD3";

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
        require(_tokenId >= 0 && _tokenId <= 6599, "ERC721Distribution: unavailable itemId");
        string memory nftIpfsHash;

        if (_tokenId >= 0 && _tokenId <= 4499) nftIpfsHash = startNftIpfsHash;
        else if (_tokenId > 4499 && _tokenId <= 5999) nftIpfsHash = proNftIpfsHash;
        else if (_tokenId > 5999 && _tokenId <= 6499) nftIpfsHash = expertNftIpfsHash;
        else if (_tokenId > 6499 && _tokenId <= 6599) nftIpfsHash = partnerNftIpfsHash;

        return nftIpfsHash;
    }

    function _baseURI() internal view override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function baseURI() external view  returns (string memory) {
        return _baseURI();
    }
}