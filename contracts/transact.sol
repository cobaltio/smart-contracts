// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SellNFT is Ownable, Pausable {
    // event Sent(address indexed payee, uint256 amount, uint256 balance);
    // event Received(
    //     address indexed payer,
    //     uint256 indexed tokenId,
    //     uint256 amount,
    //     uint256 balance
    // );
    event Sold(
        address indexed to,
        address indexed from,
        uint256 indexed tokenId,
        uint256 amount
    );

    ERC721 public nftAddress;

    constructor(address _nftAddress) {
        require(_nftAddress != address(0) && _nftAddress != address(this));
        nftAddress = ERC721(_nftAddress);
    }

    function _sendNft(
        address from,
        address to,
        uint256 _tokenId
    ) private {
        require(to != address(0) && to != address(this));
        nftAddress.safeTransferFrom(from, to, _tokenId);
        // emit Received(sendTo, _tokenId, msg.value, address(this).balance);
    }

    function _sendPayment(address to, uint256 _amount) private {
        require(to != address(0) && to != address(this));
        require(_amount > 0 && _amount <= address(this).balance);
        payable(to).transfer(_amount);
        // emit Sent(_payee, _amount, address(this).balance);
    }

    function deductFees(uint256 amount)
        public
        pure
        returns (uint256 amount_after_fees)
    {
        amount_after_fees = (amount * 98) / 100;
    }

    function sellNft(
        uint256 _amount,
        uint256 _tokenId,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable {
        require(block.timestamp < _deadline, "Signed Transaction Expired");
        address buyer = msg.sender;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

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
                    "sellNft(address sender,uint256 amount,uint256 tokenId,uint256 deadline)"
                ),
                buyer,
                _amount,
                _tokenId,
                _deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct)
        );

        address signer = ecrecover(hash, v, r, s);
        require(signer == this.owner(), "Invalid Signature");
        require(signer != address(0));

        address tokenOwner = nftAddress.ownerOf(_tokenId);

        _sendNft(tokenOwner, buyer, _tokenId);
        uint256 amount_after_fees = deductFees(_amount);
        _sendPayment(tokenOwner, amount_after_fees);

        emit Sold(buyer, tokenOwner, _tokenId, _amount);
    }
}
