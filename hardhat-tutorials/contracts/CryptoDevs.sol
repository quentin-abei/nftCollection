// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {

    // concatenation of baseURI and tokenId
    string _baseTokenURI;
    //price of one CD token
    uint256 public _price = 0.01 ether;
    //in cas eof emergency we will pause the contract
    bool public _paused;
    //maximum number of CD
    uint256 public maxTokenIds = 20;
    //track the numbers of CD minted
    uint256 public tokenIds;
    //Whitelist contract instance
    IWhitelist whitelist;
    //presale started or not ?
    bool public presaleStarted;
    //when will presale end ?
    uint256 presaleEnded;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    constructor (string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }
    
    function startPresale() public onlyOwner {
        presaleStarted = true;
        //define the time when presale will end as
        //current timestamp + x minutes
        presaleEnded = block.timestamp + 5 minutes;
    }

    function presaleMint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp < presaleEnded, "Presale is not running at the moment");
        require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
        require(tokenIds < maxTokenIds, "Exceeded maximum Crypto Devs Supply");
        require(msg.value >= _price, "Fees are not correct");
        _safeMint(msg.sender, tokenIds);
        //after each mint we increase the tracking variable by 1
        tokenIds +=1;
        
    }

    //after the presale has ended , allow an user to mint 1 NFT
    function mint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp >= presaleEnded, "Presale has not ended yet");
        require(tokenIds < maxTokenIds, "Exceed maximum Crypto Devs Supply");
        require(msg.value >= _price, "Fees are not correct");
        _safeMint(msg.sender, tokenIds);
        tokenIds +=1;
    }

    // i will override the default Openzeppelin ERC721
    // implementation which returns an empty string by default

    function _baseURI() internal view virtual override returns(string memory) {
         return _baseTokenURI;
    }

    // contract paused or not ?
    // paused when val is true unpaused if it's false
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    // this contract will receive fees
    // from each nft mint
    // this function allow the owner to withdarw
    // ETH from the contract straigh to his wallet
    function withdraw() public onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "Failed to sent eth");
    }
    
    //msg.data must be empty
    receive() external payable{}
    //msg.data is not empty
    fallback() external payable{}



} 
