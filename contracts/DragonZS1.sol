// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Contract is
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ReentrancyGuard,
    ERC721Royalty
{
    using Strings for uint256;
    uint256 public constant maxSupply = 1122;
    uint256 public maxMintAmount = 50;
    uint256 public maxMintAtOnce = 50;
    uint256 public publicCost = .02 ether;
    bool public paused = true;
    string public baseURI =
        "ipfs://QmVHMW4pSJ1ZMA5fg74wMP6UC2BtzNVDPHEQZ734hjZUmS/";
    address public charityAddress;
    address public teamAddress;
    address public devAddress;
    address public marketingAddress;
    address public retAddress;
    address public royaltyAddress;
    uint96 public royaltyPercentage;

    mapping(address => uint256) public tokensMinted;

    uint256 private nextTokenId = 1;

    constructor(
        address initialOwner
    ) ERC721("DragonZ Series 1", "DragonZ") Ownable(initialOwner) {
        royaltyAddress = msg.sender;
        royaltyPercentage = 500;
        _setDefaultRoyalty(royaltyAddress, royaltyPercentage);
    }

    function updateRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        require(_royaltyAddress != address(0), "Invalid: Zero address");
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyPercentage);
    }

    function updateRoyaltyPercentage(
        uint96 _royaltyPercentage
    ) external onlyOwner {
        require(
            _royaltyPercentage <= 1000,
            "Royalty percentage cannot exceed 10%"
        );
        royaltyPercentage = _royaltyPercentage;
        _setDefaultRoyalty(royaltyAddress, royaltyPercentage);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 numTokens) public payable nonReentrant {
        require(!paused, "Minting is paused");
        require(
            totalSupply() + numTokens <= maxSupply,
            "Total supply exceeded"
        );
        require(numTokens <= maxMintAtOnce, "Exceeds max mint per transaction");
        require(
            tokensMinted[msg.sender] + numTokens <= maxMintAmount,
            "Max mints per wallet exceeded"
        );
        require(
            nextTokenId + numTokens - 1 <= maxSupply,
            "Not enough tokens available"
        );

        require(msg.value >= publicCost * numTokens, "Invalid amount sent");

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, nextTokenId);
            nextTokenId++;
            tokensMinted[msg.sender]++;
        }
    }

    // The following functions are overrides required by Solidity.
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Enumerable, ERC721Royalty, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        string memory baseTokenURI = super.tokenURI(tokenId);
        return string(abi.encodePacked(baseTokenURI, ".json"));
    }

    function pause(bool val) external onlyOwner {
        paused = val;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function updateAllAddresses(
        address _charityAddress,
        address _teamAddress,
        address _devAddress,
        address _marketingAddress,
        address _retAddress,
        address _royaltyAddress
    ) external onlyOwner {
        require(_charityAddress != address(0), "Invalid: Zero address");
        require(_teamAddress != address(0), "Invalid: Zero address");
        require(_devAddress != address(0), "Invalid: Zero address");
        require(_marketingAddress != address(0), "Invalid: Zero address");
        require(_retAddress != address(0), "Invalid: Zero address");
        require(_royaltyAddress != address(0), "Invalid: Zero address");

        charityAddress = _charityAddress;
        teamAddress = _teamAddress;
        devAddress = _devAddress;
        marketingAddress = _marketingAddress;
        retAddress = _retAddress;
        royaltyAddress = _royaltyAddress;
    }

    function updateCharityAddress(address _charityAddress) external onlyOwner {
        require(_charityAddress != address(0), "Invalid: Zero address");
        charityAddress = _charityAddress;
    }

    function updateTeamAddress(address _teamAddress) external onlyOwner {
        require(_teamAddress != address(0), "Invalid: Zero address");
        teamAddress = _teamAddress;
    }

    function updateDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "Invalid: Zero address");
        devAddress = _devAddress;
    }

    function updateMarketingAddress(
        address _marketingAddress
    ) external onlyOwner {
        require(_marketingAddress != address(0), "Invalid: Zero address");
        marketingAddress = _marketingAddress;
    }

    function updateRetAddress(address _retAddress) external onlyOwner {
        require(_retAddress != address(0), "Invalid: Zero address");
        retAddress = _retAddress;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setMaxMintAtOnce(uint256 _newMaxMintAtOnce) external onlyOwner {
        maxMintAtOnce = _newMaxMintAtOnce;
    }

    function setPublicCost(uint256 _newPublicCost) external onlyOwner {
        publicCost = _newPublicCost;
    }

    function deployerMint() external onlyOwner {
        require(marketingAddress != address(0), "Marketing address not set");
        require(nextTokenId <= maxSupply, "All tokens already minted");

        uint256 batchSize = 100;
        uint256 remainingTokens = maxSupply - nextTokenId + 1;
        uint256 tokensToMint = remainingTokens > batchSize
            ? batchSize
            : remainingTokens;

        for (uint256 i = 0; i < tokensToMint; i++) {
            _safeMint(marketingAddress, nextTokenId);
            nextTokenId++;
        }
    }

    function withdraw() external onlyOwner {
        require(charityAddress != address(0), "Charity address not set");
        require(teamAddress != address(0), "Team address not set");
        require(devAddress != address(0), "Dev address not set");
        require(marketingAddress != address(0), "Marketing address not set");
        require(retAddress != address(0), "Ret address not set");
        uint256 balanceToWithdraw = address(this).balance;
        uint256 charityWithdraw = (balanceToWithdraw * 10) / 100;
        uint256 teamWithdraw = (balanceToWithdraw * 20) / 100;
        uint256 devWithdraw = (balanceToWithdraw * 30) / 100;
        uint256 marketingWithdraw = (balanceToWithdraw * 15) / 100;
        uint256 retWithdraw = balanceToWithdraw -
            charityWithdraw -
            teamWithdraw -
            devWithdraw -
            marketingWithdraw;
        payable(charityAddress).transfer(charityWithdraw);
        payable(teamAddress).transfer(teamWithdraw);
        payable(devAddress).transfer(devWithdraw);
        payable(marketingAddress).transfer(marketingWithdraw);
        payable(retAddress).transfer(retWithdraw);
    }

    function rescueERC20(
        address tokenAddress,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "Cannot send to zero address");

        IERC20 token = IERC20(tokenAddress);

        token.transfer(to, amount);
    }

    function rescueERC721(
        address tokenAddress,
        uint256 tokenId,
        address to
    ) external onlyOwner {
        require(to != address(0), "Cannot send to zero address");

        IERC721 token = IERC721(tokenAddress);

        if (tokenAddress == address(this)) {
            require(
                _ownerOf(tokenId) == address(this),
                "Contract does not own this token"
            );
            _update(to, tokenId, address(this));
        } else {
            token.safeTransferFrom(address(this), to, tokenId);
        }
    }
}