// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
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
    uint256 public constant maxSupply = 750;
    uint256 public maxMintAmount = 15;
    uint256 public maxMintAtOnce = 15;
    uint256 public publicCost = .02 ether;
    uint256 public whitelistCost = .016 ether;
    bool public paused = true;
    string public baseURI =
        "ipfs://bafybeibieultnbrehtdveu25xp2ymbjkzpkz2sn6qxcszlhell6o3rime4/";
    address public charityAddress;
    address public teamAddress;
    address public devAddress;
    address public marketingAddress;
    address public retAddress;
    address public royaltyAddress;
    uint96 public royaltyPercentage;

    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public tokensMinted;

    mapping(uint256 => uint256) private tokenRemap;
    uint256 private lastTokenId = 700;

    constructor(
        address initialOwner
    ) ERC721("DragonZ Limited Edition", "DragonZLE") Ownable(initialOwner) {
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

    function setWhitelistCost(uint256 _newWhitelistCost) external onlyOwner {
        whitelistCost = _newWhitelistCost;
    }

    function addToWhitelist(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = whitelistCost;
        }
    }

    function removeFromWhitelist(
        address[] memory _addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            delete whitelist[_addresses[i]];
        }
    }

    /**
     * @dev Updates the whitelist cost for specific addresses
     * @param _addresses Array of addresses to update
     * @param _cost The cost to set (if 0, uses the current whitelistCost)
     */
    function updateWhitelistCost(address[] memory _addresses, uint256 _cost) external onlyOwner {
        uint256 costToUse = _cost > 0 ? _cost : whitelistCost;
        
        for (uint256 i = 0; i < _addresses.length; i++) {
            // Only update if address is already whitelisted
            if (whitelist[_addresses[i]] > 0) {
                whitelist[_addresses[i]] = costToUse;
            }
        }
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
        require(totalSupply() > 49, "Finish marketing minting first");

        uint256 mintPrice = whitelist[msg.sender] > 0
            ? whitelist[msg.sender]
            : publicCost;
        require(msg.value >= mintPrice * numTokens, "Invalid amount sent");

        for (uint256 i = 0; i < numTokens; i++) {
            require(lastTokenId > 0, "No more tokens available");
            uint256 randomIndex = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, lastTokenId)
                )
            ) % lastTokenId;
            uint256 tokenId = tokenRemap[randomIndex] == 0
                ? randomIndex + 1
                : tokenRemap[randomIndex];

            tokenRemap[randomIndex] = tokenRemap[lastTokenId - 1] == 0
                ? lastTokenId
                : tokenRemap[lastTokenId - 1];
            lastTokenId--;

            _safeMint(msg.sender, tokenId);
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

    function devMint(address recipient, uint256 numTokens) external onlyOwner {
        require(
            totalSupply() + numTokens <= maxSupply,
            "Total supply exceeded"
        );
        require(totalSupply() > 49, "Finish marketing minting first");
        require(recipient != address(0), "Invalid recipient address");
        require(lastTokenId > 0, "No more tokens available");

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 randomIndex = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, lastTokenId)
                )
            ) % lastTokenId;
            uint256 tokenId = tokenRemap[randomIndex] == 0
                ? randomIndex + 1
                : tokenRemap[randomIndex];

            tokenRemap[randomIndex] = tokenRemap[lastTokenId - 1] == 0
                ? lastTokenId
                : tokenRemap[lastTokenId - 1];
            lastTokenId--;

            _safeMint(recipient, tokenId);
        }
    }

    uint256 public mintingCounter = 0;
    uint256 public lastMintedTokenId;

    function marketingMint() external onlyOwner {
        uint256 currentTotalSupply = totalSupply();
        require(
            currentTotalSupply < maxSupply,
            "Contract has reached maximum supply"
        );

        uint256 numToMint = 25;
        uint256 start;
        uint256 end;

        require(mintingCounter < 2, "Marketing mint limit reached");

        start = lastMintedTokenId == 0 ? maxSupply - 49 : lastMintedTokenId + 1;
        end = start + numToMint;

        for (uint256 i = start; i < end; i++) {
            _safeMint(marketingAddress, i);
        }

        mintingCounter++;
        lastMintedTokenId = end - 1;
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
        uint256 devWithdraw = (balanceToWithdraw * 55) / 100;
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

    /**
     * @dev Allows the owner to rescue ERC20 tokens sent to this contract by mistake
     * @param tokenAddress The address of the ERC20 token contract
     * @param to The address to send the rescued tokens to
     * @param amount The amount of tokens to rescue
     */
    function rescueERC20(address tokenAddress, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Cannot send to zero address");
        
        // Create an interface to the ERC20 contract
        IERC20 token = IERC20(tokenAddress);
        
        // Transfer the tokens to the specified address
        token.transfer(to, amount);
    }

    /**
     * @dev Allows the owner to rescue ERC721 tokens sent to this contract by mistake
     * @param tokenAddress The address of the ERC721 token contract
     * @param tokenId The ID of the token to rescue
     * @param to The address to send the rescued token to
     */
    function rescueERC721(address tokenAddress, uint256 tokenId, address to) external onlyOwner {
        require(to != address(0), "Cannot send to zero address");
        
        // Create an interface to the ERC721 contract
        IERC721 token = IERC721(tokenAddress);
        
        // If rescuing tokens from this contract, use the internal transfer function
        if (tokenAddress == address(this)) {
            // Ensure the contract owns the token
            require(_ownerOf(tokenId) == address(this), "Contract does not own this token");
            _update(to, tokenId, address(this));
        } else {
            // For external contracts, use safeTransferFrom
            token.safeTransferFrom(address(this), to, tokenId);
        }
    }
}
