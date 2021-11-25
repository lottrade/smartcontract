// SPDX-License-Identifier: MIT
// NIFTSY protocol for NFT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//v0.0.2
contract ERC721Distribution is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;

    string startNftUrl = 'https://ipfs.io/ipfs/QmaSYZg9up7mzNuCk4iUCSPSqWqn3BWuXbBKfHiytN4Mue';
    string proNftUrl = 'https://ipfs.io/ipfs/QmYw2pxEbKHVu8yQhu3e6HFCdgudzCVmnk3BL8DXfKN8qV';
    string expertNftUrl = 'https://ipfs.io/ipfs/QmYtRxDCkZBwAmKmG8YiVpXWXfgfe9e9JJV4ioLeYwBmzc';
    string partnerNftUrl = 'https://ipfs.io/ipfs/QmVBSLXVmMPfxVw4KDzxZP1dr3NxB7hmNEVTUf2zbWEbD3';

    uint64 startNftCouner = 0;
    uint64 proNftCouner = 0;
    uint64 expertNftCouner = 0;
    uint64 partnerNftCouner = 0;

    uint64 startNftEmission = 4500;
    uint64 proNftEmission = 1500;
    uint64 expertNftEmission = 500;
    uint64 partnerNftEmission = 100;

    mapping(address => bool) public trustedMinter;

    mapping(address => uint256[]) public ovnerStartNft;
    mapping(address => uint256[]) public ovnerProNft;
    mapping(address => uint256[]) public ovnerExpertNft;
    mapping(address => uint256[]) public ovnerPartnerNft;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_)  {
        trustedMinter[msg.sender] = true;
        tokenCounter = 0;
    }

     modifier checktrustedMinter() {
        require(trustedMinter[msg.sender], "Trusted address only");
        _;
    }

    modifier checkNftType(string memory nftType) {
        require(
            keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("start"))) ||
            keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("pro"))) || 
            keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("expert"))) || 
            keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("partner"))),
            "ERC721Distribution:: Unavailable nft type for mint"
        );
        _;
    }

    modifier chectNftEmission(string memory nftType) {
        if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("start")))) {
            require(startNftCouner < startNftEmission, "ERC721Distribution:: Over-emission for start nft");
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("pro")))) {
            require(proNftCouner < proNftEmission, "ERC721Distribution:: Over-emission for pro nft");
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("expert")))) {
            require(expertNftCouner < expertNftEmission, "ERC721Distribution:: Over-emission for expert nft");
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("partner")))) {
            require(partnerNftCouner < partnerNftEmission, "ERC721Distribution:: Over-emission for partner nft");
        }
        _;
    }

    function updateNftEmission(string memory nftType, uint64 newEmission) external checkNftType(nftType) onlyOwner {
        if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("start")))) {
            startNftEmission = newEmission;
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("pro")))) {
            proNftEmission = newEmission;
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("expert")))) {
            expertNftEmission = newEmission;
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("partner")))) {
            partnerNftEmission = newEmission;
        }
    }

    function updateNftUrl(string memory nftType, string memory newNftUrl) external checkNftType(nftType) onlyOwner {
        if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("start")))) {
            startNftUrl = newNftUrl;
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("pro")))) {
            proNftUrl = newNftUrl;
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("expert")))) {
            expertNftUrl = newNftUrl;
        }
        else if (keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(("partner")))) {
            partnerNftUrl = newNftUrl;
        }
    }

    function mint(address to, string memory nftType) external checktrustedMinter() checkNftType(nftType) chectNftEmission(nftType) returns (uint256) {
        uint256 newItemId = tokenCounter;
        string memory nftUrl = _getUrlForMintNft(nftType);

        _safeMint(to, newItemId);
        _setTokenURI(newItemId, nftUrl);
        tokenCounter = tokenCounter + 1;

        _incrementNftCounterAndAddOwner(nftType, newItemId);

        return newItemId;
    }

    function setMinterStatus(address _minter, bool _isTrusted) external onlyOwner {
        trustedMinter[_minter] = _isTrusted;
    }

    function _getUrlForMintNft(string memory _nftType) internal view returns(string memory) {
        string memory nftUrl;
        if (keccak256(abi.encodePacked((_nftType))) == keccak256(abi.encodePacked(("start")))) nftUrl = startNftUrl;
        else if (keccak256(abi.encodePacked((_nftType))) == keccak256(abi.encodePacked(("pro")))) nftUrl = proNftUrl;
        else if (keccak256(abi.encodePacked((_nftType))) == keccak256(abi.encodePacked(("expert")))) nftUrl = expertNftUrl;
        else if (keccak256(abi.encodePacked((_nftType))) == keccak256(abi.encodePacked(("partner")))) nftUrl = partnerNftUrl;

        return nftUrl;
    }

    function _incrementNftCounterAndAddOwner(string memory _nftType, uint256 itemId) internal {
        if (keccak256(abi.encodePacked((_nftType))) == keccak256(abi.encodePacked(("start")))) {
            startNftCouner += 1;
            ovnerStartNft[msg.sender].push(itemId);
        } else if (keccak256(abi.encodePacked((_nftType))) == keccak256(abi.encodePacked(("pro")))) {
            proNftCouner += 1;
            ovnerProNft[msg.sender].push(itemId);
        } else if (keccak256(abi.encodePacked((_nftType))) == keccak256(abi.encodePacked(("expert")))) {
            expertNftCouner += 1;
            ovnerExpertNft[msg.sender].push(itemId);
        } else if (keccak256(abi.encodePacked((_nftType))) == keccak256(abi.encodePacked(("partner")))) {
            partnerNftCouner += 1;
            ovnerPartnerNft[msg.sender].push(itemId);
        }
    }
}