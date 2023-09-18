// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @custom:security-contact workbzw@outlook.com
contract NFTFounder is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    mapping(uint => string) public pattern;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("YOHAKU Founder", "YF") {}

    function _baseURI()
    internal
    pure
    override
    returns (string memory)
    {
        return "https://yohaku.club/api/nft/metadata/founder/";
    }

    function pause()
    public
    onlyOwner
    {
        _pause();
    }

    function unpause()
    public
    onlyOwner
    {
        _unpause();
    }

    function safeMint(address to, string memory patternVid)
    public
    onlyOwner
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        pattern[tokenId] = patternVid;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    // override transferFrom
    function transferFrom(address from, address to, uint256 tokenId)
    public
    override(ERC721, IERC721)
    onlyOwner
    {
        //super.transferFrom(from, to, tokenId);
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    virtual
    override(ERC721, IERC721)
    onlyOwner
    {
        //super.safeTransferFrom(from, to, tokenId, data);
        _safeTransfer(from, to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
    public
    virtual
    override(ERC721, IERC721)
    onlyOwner
    {
        //super.safeTransferFrom(from, to, tokenId, data);
        _safeTransfer(from, to, tokenId,"");
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, pattern[tokenId])) : "";
    }

    function burn(uint256 tokenId)
    public
    virtual
    override(ERC721Burnable)
    onlyOwner
    {
        //solhint-disable-next-line max-line-length
        //require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function approve(address, uint256)
    public
    virtual
    override(ERC721, IERC721)
    {
        revert("Approval function is disabled");
    }

    function setApprovalForAll(address, bool)
    public
    virtual
    override(ERC721, IERC721)
    {
        revert("SetApprovalForAll function is disabled");
    }
}
