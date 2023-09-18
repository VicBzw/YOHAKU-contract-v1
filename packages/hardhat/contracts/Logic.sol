// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFTFounder.sol";
import "./NFTMintPass.sol";

contract Logic is Ownable, Pausable {

    NFTFounder public founder;
    NFTMintPass public mintPass;
    address public withdrawAddress;
    uint public mintPassPrice;
    uint public mintPassLimit;


    constructor(address _withdrawAddress, uint _mintPassPrice, uint _limit){
        //        NFTFounder _founder = new NFTFounder();
        //        founder = _founder;
        //
        //        NFTMintPass _mintPass = new NFTMintPass();
        //        mintPass = _mintPass;

        withdrawAddress = _withdrawAddress;
        mintPassPrice = _mintPassPrice;
        mintPassLimit = _limit;
    }


    struct User {
        string accPwdHash;
        address softwareWallet;
        address hardwareWallet;
    }

    mapping(string => User) public users;

    event LogClaimMintPass(string, address, address);
    event LogClaimFreeMintPass(string, address, address);

    function mintPassFreeMint(string  memory accPwdHash, address to, string memory pattern)
    external
    whenNotPaused
    onlyOwner
    {
        //check mint pass claimed
        require(to != address(0), "Invalid to address");
        require(!compareStr(users[accPwdHash].accPwdHash, accPwdHash), "this account has claimed mint pass recently");
        require(mintPass.totalSupply() < mintPassLimit, "Mint pass total supply is limited");
        require(mintPass.owner() == address(this), "Mint pass contract owner is not current contract!");
        emit LogClaimFreeMintPass(accPwdHash, _msgSender(), to);
        users[accPwdHash] = User(accPwdHash, to, address(0));
        accPwdHashArray.push(accPwdHash);
        mintPass.safeMint(to, pattern);
    }

    string[] public accPwdHashArray;

    function mintPassMint(string  memory accPwdHash, string memory pattern)
    external
    whenNotPaused
    payable
    {
        require(mintPass.owner() == address(this), "Mint pass contract owner is not current contract!");
        require(msg.value >= mintPassPrice, "Price is wrong");
        require(_msgSender() != address(0), "Invalid sender address");
        require(mintPass.totalSupply() < mintPassLimit, "Mint pass total supply is limited");
        //check mint pass claimed
        require(!compareStr(users[accPwdHash].accPwdHash, accPwdHash), "This account has claimed mint pass recently");
        emit LogClaimMintPass(accPwdHash, _msgSender(), _msgSender());
        users[accPwdHash] = User(accPwdHash, _msgSender(), address(0));
        accPwdHashArray.push(accPwdHash);
        mintPass.safeMint(_msgSender(), pattern);
    }

    function compareStr(string  memory s1, string  memory s2)
    internal
    pure
    returns (bool)
    {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function burnMintPass(string memory accPwdHash)
    public
    onlyOwner
    {
        require(mintPass.owner() == address(this), "Mint pass contract owner is not current contract!");
        address mintPassAddress = users[accPwdHash].softwareWallet;
        uint balance = mintPass.balanceOf(mintPassAddress);
        require(balance > 0, "this account doesn't have mint pass");
        uint tokenId = mintPass.tokenOfOwnerByIndex(mintPassAddress, 0);
        mintPass.burn(tokenId);
    }

    event LogClaimFounder(string, address, address, string);

    function mintFounder(string memory accPwdHash, address hWallet, string memory pattern)
    public
    onlyOwner
    {
        require(founder.owner() == address(this), "Founder NFT contract owner is not current contract!");
        users[accPwdHash].hardwareWallet = hWallet;
        emit LogClaimFounder(accPwdHash, _msgSender(), hWallet, pattern);
        founder.safeMint(hWallet, pattern);
    }

    function mintingEvent(string memory accPwdHash, address hWallet, string memory pattern)
    external
    whenNotPaused
    onlyOwner
    {
        require(mintPass.owner() == address(this), "Mint pass contract owner is not current contract!");
        require(founder.owner() == address(this), "Founder NFT contract owner is not current contract!");
        //check mint pass claimed
        require(compareStr(users[accPwdHash].accPwdHash, accPwdHash), "this account doesn't have mint pass");
        //check membership claimed
        require(users[accPwdHash].hardwareWallet == address(0), "this account has claimed membership");
        burnMintPass(accPwdHash);
        mintFounder(accPwdHash, hWallet, pattern);
    }


    function transferMintPassContractOwner(address newOwner)
    external
    onlyOwner
    {
        require(mintPass.owner() == address(this), "Mint pass contract owner is not current contract!");
        mintPass.transferOwnership(newOwner);
    }

    function transferFounderContractOwner(address newOwner)
    external
    onlyOwner
    {
        require(founder.owner() == address(this), "Founder NFT contract owner is not current contract!");
        founder.transferOwnership(newOwner);
    }

    function hasMintPass(string memory accPwdHash)
    external
    view
    returns (bool)
    {
        return compareStr(users[accPwdHash].accPwdHash, accPwdHash);
    }

    function hasFounderNFT(string memory accPwdHash)
    external
    view
    returns (bool)
    {
        return users[accPwdHash].hardwareWallet != address(0);
    }

    function getMintPassTokenIds(string memory accPwdHash)
    external
    view
    returns (uint[] memory)
    {
        address owner = users[accPwdHash].softwareWallet;
        if (owner == address(0)) {
            return new uint[](0);
        }
        uint balance = mintPass.balanceOf(owner);
        uint[] memory tokenIds = new uint[](balance);
        for (uint i = 0; i < balance; i++) {
            tokenIds[i] = mintPass.tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function getFounderTokenIds(string memory accPwdHash)
    external
    view
    returns (uint[] memory)
    {
        address owner = users[accPwdHash].hardwareWallet;
        if (owner == address(0)) {
            return new uint[](0);
        }
        uint balance = founder.balanceOf(owner);
        uint[] memory tokenIds = new uint[](balance);
        for (uint i = 0; i < balance; i++) {
            tokenIds[i] = founder.tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function getBalance()
    public
    view
    returns (uint)
    {
        return address(this).balance;
    }

    event LogWithdraw(address, uint);

    function withdraw()
    external
    {
        require(address(this).balance > 0, "Withdraw amount must be greater than 0");
        require(_msgSender() != address(0), "Invalid sender address 0");
        require(withdrawAddress == _msgSender(), "You don't have permission to withdraw");
        emit LogWithdraw(_msgSender(), address(this).balance);
        payable(_msgSender()).transfer(address(this).balance);
    }

    event LogChangeWithdrawAddress(address, address);

    function changeWithdrawAddress(address _withdrawAddress)
    external
    whenNotPaused
    onlyOwner
    {
        emit LogChangeWithdrawAddress(withdrawAddress, _withdrawAddress);
        withdrawAddress = _withdrawAddress;
    }

    event LogChangeMintPassPrice(address, uint);

    function changeMintPassPrice(uint _price)
    external
    whenNotPaused
    onlyOwner
    {
        emit LogChangeMintPassPrice(_msgSender(), _price);
        mintPassPrice = _price;
    }

    event LogChangeMintPassLimit(uint, uint);

    function changeMintPassLimit(uint _limit)
    external
    whenNotPaused
    onlyOwner
    {
        emit LogChangeMintPassLimit(mintPassLimit, _limit);
        mintPassLimit = _limit;
    }

    function changeMintPassAddress(address _newContractAddress)
    external
    whenNotPaused
    onlyOwner
    {
        mintPass = NFTMintPass(_newContractAddress);
    }

    function changeFounderAddress(address _newContractAddress)
    external
    whenNotPaused
    onlyOwner
    {
        founder = NFTFounder(_newContractAddress);
    }

    function pushUserData(string  memory accPwdHash, address sWallet, address hWallet)
    public
    whenNotPaused
    onlyOwner
    {
        accPwdHashArray.push(accPwdHash);
        users[accPwdHash] = User(accPwdHash, sWallet, hWallet);
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

}
