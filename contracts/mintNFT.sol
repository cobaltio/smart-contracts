// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("MyNFT", "NFT") {}

    function mintNFT(
        address recipient,
        string memory tokenURI,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp < deadline, "Signed Transaction Expired");
        uint256 chainId = 1337;

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Desi-NFT")),
                keccak256(bytes("0.0.1")),
                chainId,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256(
                    "createNft(address recipient,string tokenURI,uint256 tokenId,uint256 deadline)"
                ),
                recipient,
                keccak256(bytes(tokenURI)),
                tokenId,
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );

        address signer = ecrecover(hash, v, r, s);

        require(signer == this.owner(), "Invalid Signature");
        require(signer != address(0));

        _mint(recipient, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }
}
