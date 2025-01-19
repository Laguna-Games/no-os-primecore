// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title LibDN404
/// @author Shiva (shiva.shanmuganathan@laguna.games)
/// @notice Adapted from https://github.com/Vectorized/dn404
/// @custom:storage-location uint72(bytes9(keccak256("DN404_STORAGE")))

import {LibRNG} from './LibRNG.sol';
import {Strings} from '../../lib/openzeppelin-contracts/contracts/utils/Strings.sol';
import {IERC20} from '../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
// Uniswap V3 Core and Periphery
import {FullMath} from '../../lib/v3-core/contracts/libraries/FullMath.sol';
import {ISwapRouter} from '../../lib/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import {IQuoter} from '../../lib/v3-periphery/contracts/interfaces/IQuoter.sol';

// WETH Interface
/// @title Interface for WETH
interface IWETH is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

library LibDN404 {
    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                           EVENTS                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev Emitted when `owner` sets their skipNFT flag to `status`.
    event SkipNFTSet(address indexed owner, bool status);

    /// @dev Emitted when treasury fee is paid
    event TreasuryFeePaid(address indexed treasuryAddress, uint256 amount);

    /// @dev Emitted when excess ETH is refunded to the owner
    event ExcessETHRefunded(address indexed owner, uint256 amount);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /// @dev `keccak256(bytes("SkipNFTSet(address,bool)"))`.
    uint256 private constant _SKIP_NFT_SET_EVENT_SIGNATURE =
        0xb5a1de456fff688115a4f75380060c23c8532d14ff85f687cc871456d6420393;

    // Constants for different attribute generations
    uint256 private constant SALT_1 = 1;
    uint256 private constant SALT_2 = 2;
    uint256 private constant SALT_3 = 3;
    uint256 private constant SALT_4 = 4;
    uint256 private constant SALT_5 = 5;
    uint256 private constant SALT_6 = 6;
    uint256 private constant SALT_7 = 7;

    uint256 private constant MAX_SUPPLY = 7777000000000000000000;

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                        CUSTOM ERRORS                       */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Thrown when attempting to double-initialize the contract.
    error DNAlreadyInitialized();

    /// @dev The function can only be called after the contract has been initialized.
    error DNNotInitialized();

    /// @dev Thrown when attempting to transfer or burn more tokens than sender's balance.
    error InsufficientBalance();

    /// @dev Thrown when a spender attempts to transfer tokens with an insufficient allowance.
    error InsufficientAllowance();

    /// @dev Thrown when minting an amount of tokens that would overflow the max tokens.
    error TotalSupplyOverflow();

    /// @dev The unit must be greater than zero and less than `2**96`.
    error InvalidUnit();

    /// @dev Thrown when the caller for a fallback NFT function is not the mirror contract.
    error SenderNotMirror();

    /// @dev Thrown when attempting to transfer tokens to the zero address.
    error TransferToZeroAddress();

    /// @dev Thrown when the mirror address provided for initialization is the zero address.
    error MirrorAddressIsZero();

    /// @dev Thrown when the link call to the mirror contract reverts.
    error LinkMirrorContractFailed();

    /// @dev Thrown when setting an NFT token approval
    /// and the caller is not the owner or an approved operator.
    error ApprovalCallerNotOwnerNorApproved();

    /// @dev Thrown when transferring an NFT
    /// and the caller is not the owner or an approved operator.
    error TransferCallerNotOwnerNorApproved();

    /// @dev Thrown when transferring an NFT and the from address is not the current owner.
    error TransferFromIncorrectOwner();

    /// @dev Thrown when checking the owner or approved address for a non-existent NFT.
    error TokenDoesNotExist();

    /// @dev The function selector is not recognized.
    error FnSelectorNotRecognized();

    /// @dev Thrown when minting more tokens than the maximum supply.
    error MaxSupplyExceeded();

    /// @dev Custom error for insufficient ETH
    error InsufficientETH();

    /// @dev Custom error for insufficient output amount
    error InsufficientOutputAmount();

    /// @dev Custom error for not being the token owner
    error NotTokenOwner();

    /// @dev Custom error for not being an EOA
    error NotEOA();

    /// @dev Custom error for swap failure
    error SwapFailed();

    /// @dev Custom error for invalid treasury address
    error InvalidTreasuryAddress();

    /// @dev Custom error for invalid fee percentage
    error InvalidFeePercentage();

    /// @dev Custom error for pool not found
    error PoolNotFound();

    /// @dev Custom error for invalid slippage
    error InvalidSlippage();

    /// @dev Custom error for slippage exceeding available ETH
    error SlippageExceedsAvailableETH();

    /// @dev Thrown when attempting to re-enter the `_reroll` function
    error ReentrancyGuard();

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                         CONSTANTS                          */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev The flag to denote that the skip NFT flag is initialized.
    uint8 internal constant _ADDRESS_DATA_SKIP_NFT_INITIALIZED_FLAG = 1 << 0;

    /// @dev The flag to denote that the address should skip NFTs.
    uint8 internal constant _ADDRESS_DATA_SKIP_NFT_FLAG = 1 << 1;

    /// @dev The flag to denote that the address has overridden the default Permit2 allowance.
    uint8 internal constant _ADDRESS_DATA_OVERRIDE_PERMIT2_FLAG = 1 << 2;

    /// @dev The address of WETH
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @dev The address of the Uniswap V3 Factory
    address internal constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    /// @dev The address of the Uniswap V3 Swap Router
    address internal constant UNISWAP_V3_SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    /// @dev The address of the Uniswap V3 Quoter
    address constant UNISWAP_V3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

    /// @dev The address of the Uniswap V3 Non-Fungible Position Manager
    address constant UNISWAP_V3_NON_FUNGIBLE_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    /// @dev The canonical Permit2 address.
    /// For signature-based allowance granting for single transaction ERC20 `transferFrom`.
    /// To enable, override `_givePermit2DefaultInfiniteAllowance()`.
    /// [Github](https://github.com/Uniswap/permit2)
    /// [Etherscan](https://etherscan.io/address/0x000000000022D473030F116dDEE9F6B43aC78BA3)
    address internal constant _PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    //  Goal number of common NFTs to be minted
    uint16 internal constant TARGET_COMMON_COUNT = 4000;

    //  Goal number of uncommon NFTs to be minted
    uint16 internal constant TARGET_UNCOMMON_COUNT = 2500;

    //  Goal number of rare NFTs to be minted
    uint16 internal constant TARGET_RARE_COUNT = 1000;

    //  Goal number of legendary NFTs to be minted
    uint16 internal constant TARGET_LEGENDARY_COUNT = 200;

    //  Goal number of mythic NFTs to be minted
    uint16 internal constant TARGET_MYTHIC_COUNT = 77;

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                          STORAGE                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Struct containing an address's token data and settings.
    struct AddressData {
        // Auxiliary data.
        uint88 aux;
        // Flags for `initialized` and `skipNFT`.
        uint8 flags;
        // The alias for the address. Zero means absence of an alias.
        uint32 addressAlias;
        // The number of NFT tokens.
        uint32 ownedLength;
        // The token balance in wei.
        uint96 balance;
    }

    /// @dev A uint32 map in storage.
    struct Uint32Map {
        uint256 spacer;
    }

    /// @dev A bitmap in storage.
    struct Bitmap {
        uint256 spacer;
    }

    /// @dev A struct to wrap a uint256 in storage.
    struct Uint256Ref {
        uint256 value;
    }

    /// @dev A mapping of an address pair to a Uint256Ref.
    struct AddressPairToUint256RefMap {
        uint256 spacer;
    }

    /// @dev Struct containing the base token contract storage.
    struct DN404Storage {
        // Current number of address aliases assigned.
        uint32 numAliases;
        // Next NFT ID to assign for a mint.
        uint32 nextTokenId;
        // The head of the burned pool.
        uint32 burnedPoolHead;
        // The tail of the burned pool.
        uint32 burnedPoolTail;
        // Total number of NFTs in existence.
        uint32 totalNFTSupply;
        // Total supply of tokens.
        uint96 totalSupply;
        // Name of the token.
        string name;
        // Symbol of the token.
        string symbol;
        // Address of the NFT mirror contract.
        address mirrorERC721;
        // Address of the presale contract.
        address presaleContract;
        // Mapping of a user alias number to their address.
        mapping(uint32 => address) aliasToAddress;
        // Mapping of user operator approvals for NFTs.
        AddressPairToUint256RefMap operatorApprovals;
        // Mapping of NFT approvals to approved operators.
        mapping(uint256 => address) nftApprovals;
        // Bitmap of whether an non-zero NFT approval may exist.
        Bitmap mayHaveNFTApproval;
        // Bitmap of whether a NFT ID exists. Ignored if `_useExistsLookup()` returns false.
        Bitmap exists;
        // Mapping of user allowances for ERC20 spenders.
        AddressPairToUint256RefMap allowance;
        // Mapping of NFT IDs owned by an address.
        mapping(address => Uint32Map) owned;
        // The pool of burned NFT IDs.
        Uint32Map burnedPool;
        // Even indices: owner aliases. Odd indices: owned indices.
        Uint32Map oo;
        // Mapping of user account AddressData.
        mapping(address => AddressData) addressData;
        // Uniswap V3 Router
        address UniswapRouter;
        // Array to track all whitelisted addresses
        address[] whitelistedAddressList;
        // Mapping from address to index position in whitelistedAddressList (+1 to handle 0 index)
        mapping(address => uint256) whitelistedAddressIndex;
        // Base URI for token metadata
        string baseURI;
        // Minimum amount of tokens required for reroll
        uint256 rerollThreshold;
        // Mapping of rarity by tier to total prime cores minted
        mapping(uint8 rarityTier => uint16 totalPrimecoresMinted) rarityTotalsByTier;
        // Mapping of token ID to primecore data
        mapping(uint256 tokenId => PrimecoreData primecoreData) tokenIdToPCData;
        uint256 treasuryFeePercentage; // Treasury fee percentage (1% = 100)
        address treasuryAddress; // Address to receive treasury fees
        uint24 poolFeeTier; // Fee tier for the pool
        address poolAddress; // Address of the pool
        bool rerollLocked; // Reroll reentrancy guard lock
    }

    /// @dev Struct to store primecore data
    struct PrimecoreData {
        RarityTier rarityTier;
        uint16 luck;
        ProductionType prodType;
        ElementType elementSlot1;
        ElementType elementSlot2;
        ElementType elementSlot3;
        uint8 firstNameIdx;
        uint8 middleNameIdx;
        uint8 lastNameIdx;
    }

    /// @dev Enum to store production type
    enum ProductionType {
        NONE,
        HYDROSTEEL,
        TERRAGLASS,
        FIRESTONE,
        KRONOSITE,
        CELESTIUM
    }

    /// @dev Enum to store element type
    enum ElementType {
        NONE,
        FIRE,
        WATER,
        EARTH
    }

    /// @dev Enum to store rarity tier
    enum RarityTier {
        NONE,
        COMMON,
        UNCOMMON,
        EPIC,
        LEGENDARY,
        MYTHIC
    }

    /// @dev Returns a storage pointer for DN404Storage.
    function _getDN404Storage() internal pure returns (DN404Storage storage $) {
        /// @solidity memory-safe-assembly
        assembly {
            // `uint72(bytes9(keccak256("DN404_STORAGE")))`.
            $.slot := 0xa20d6e21d0e5255308 // Truncate to 9 bytes to reduce bytecode size.
        }
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                         INITIALIZER                        */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Initializes the DN404 contract with an
    /// `initialTokenSupply`, `initialTokenOwner` and `mirror` NFT contract address.
    ///
    /// Note: The `initialSupplyOwner` will have their skip NFT status set to true.
    function _initializeDN404(uint256 initialTokenSupply, address initialSupplyOwner, address mirror) internal {
        DN404Storage storage $ = _getDN404Storage();

        unchecked {
            if (_unit() - 1 >= 2 ** 96 - 1) revert InvalidUnit();
        }
        if ($.mirrorERC721 != address(0)) revert DNAlreadyInitialized();
        if (mirror == address(0)) revert MirrorAddressIsZero();

        /// @solidity memory-safe-assembly
        assembly {
            // Make the call to link the mirror contract.
            mstore(0x00, 0x0f4599e5) // `linkMirrorContract(address)`.
            mstore(0x20, caller())
            if iszero(and(eq(mload(0x00), 1), call(gas(), mirror, 0, 0x1c, 0x24, 0x00, 0x20))) {
                mstore(0x00, 0xd125259c) // `LinkMirrorContractFailed()`.
                revert(0x1c, 0x04)
            }
        }

        $.nextTokenId = uint32(_toUint(_useOneIndexed()));
        $.mirrorERC721 = mirror;

        if (initialTokenSupply != 0) {
            if (initialSupplyOwner == address(0)) revert TransferToZeroAddress();
            if (_totalSupplyOverflows(initialTokenSupply)) revert TotalSupplyOverflow();

            $.totalSupply = uint96(initialTokenSupply);
            AddressData storage initialOwnerAddressData = $.addressData[initialSupplyOwner];
            initialOwnerAddressData.balance = uint96(initialTokenSupply);

            /// @solidity memory-safe-assembly
            assembly {
                // Emit the {Transfer} event.
                mstore(0x00, initialTokenSupply)
                log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, shl(96, initialSupplyOwner)))
            }

            _setSkipNFT(initialSupplyOwner, true);
        }

        // add msg.sender (owner) and this address to whitelist
        _addToWhitelist(msg.sender);
        _addToWhitelist(address(this));
    }

    function _setPresaleContract(address presaleContract) internal {
        DN404Storage storage $ = _getDN404Storage();
        $.presaleContract = presaleContract;
    }

    function _getPresaleContract() internal view returns (address) {
        return _getDN404Storage().presaleContract;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*               BASE UNIT FUNCTION TO OVERRIDE               */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Amount of token balance that is equal to one NFT.
    ///
    /// Note: The return value MUST be kept constant after `_initializeDN404` is called.
    function _unit() internal pure returns (uint256) {
        return 10 ** 18;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                       CONFIGURABLES                        */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns whether the tokens IDs are from `[1..n]` instead of `[0..n-1]`.
    function _useOneIndexed() internal pure returns (bool) {
        return true;
    }

    /// @dev Returns if direct NFT transfers should be used during ERC20 transfers
    /// whenever possible, instead of burning and re-minting.
    function _useDirectTransfersIfPossible() internal pure returns (bool) {
        return true;
    }

    /// @dev Returns if burns should be added to the burn pool.
    /// This returns false by default, which means the NFT IDs are re-minted in a cycle.
    function _addToBurnedPool(
        uint256 totalNFTSupplyAfterBurn,
        uint256 totalSupplyAfterBurn
    ) internal pure returns (bool) {
        // Silence unused variable compiler warning.
        totalSupplyAfterBurn = totalNFTSupplyAfterBurn;
        return false;
    }

    /// @dev Returns whether to use the exists bitmap for more efficient
    /// scanning of an empty token ID slot.
    /// Recommended for collections that do not use the burn pool,
    /// and are expected to have nearly all possible NFTs materialized.
    ///
    /// Note: The returned value must be constant after initialization.
    function _useExistsLookup() internal pure returns (bool) {
        return true;
    }

    /// @dev Returns the decimals places of the token. Defaults to 18.
    /// Does not affect DN404's internal calculations.
    /// Will only affect the frontend UI on most protocols.
    function _decimals() internal pure returns (uint8) {
        return 18;
    }

    /// @dev Hook that is called after a batch of NFT transfers.
    /// The lengths of `from`, `to`, and `ids` are guaranteed to be the same.
    function _afterNFTTransfers(address[] memory from, address[] memory to, uint256[] memory ids) internal {
        (to); // noop
        DN404Storage storage $ = _getDN404Storage();

        for (uint256 i = 0; i < ids.length; i++) {
            if (from[i] == address(0) || (_isWhitelisted(from[i]))) {
                // obtain runtime RNG
                uint256 randomness = LibRNG.getRuntimeRNG();
                // Roll for rarity using scaling buckets
                uint8 rarityTier = _rollRarityTier(randomness);
                // Set rarity and increment counter
                $.tokenIdToPCData[ids[i]].rarityTier = RarityTier(rarityTier);
                $.rarityTotalsByTier[rarityTier]++;
                // Roll for attributes
                $.tokenIdToPCData[ids[i]].luck = uint16(LibRNG.expand(10000, randomness, SALT_2) + 1);
                $.tokenIdToPCData[ids[i]].prodType = ProductionType(uint8(LibRNG.expand(5, randomness, SALT_3) + 1));

                // Roll for element slots based on rarity
                uint8 elementSlot1 = uint8(LibRNG.expand(3, randomness, SALT_4) + 1);
                uint8 elementSlot2 = uint8(LibRNG.expand(3, randomness, SALT_5) + 1);
                uint8 elementSlot3 = uint8(LibRNG.expand(3, randomness, SALT_6) + 1);
                bool isEven = (uint8(LibRNG.expand(2, randomness, SALT_7) + 1) & 1) == 0;

                // Assign element slots based on rarity tier
                if (rarityTier == 1) {
                    $.tokenIdToPCData[ids[i]].elementSlot1 = ElementType(elementSlot1);
                } else if (rarityTier == 2) {
                    $.tokenIdToPCData[ids[i]].elementSlot1 = ElementType(elementSlot1);
                    if (isEven) {
                        $.tokenIdToPCData[ids[i]].elementSlot2 = ElementType(elementSlot2);
                    }
                } else if (rarityTier == 3) {
                    $.tokenIdToPCData[ids[i]].elementSlot1 = ElementType(elementSlot1);
                    $.tokenIdToPCData[ids[i]].elementSlot2 = ElementType(elementSlot2);
                } else if (rarityTier == 4) {
                    $.tokenIdToPCData[ids[i]].elementSlot1 = ElementType(elementSlot1);
                    $.tokenIdToPCData[ids[i]].elementSlot2 = ElementType(elementSlot2);
                    if (isEven) {
                        $.tokenIdToPCData[ids[i]].elementSlot3 = ElementType(elementSlot3);
                    }
                } else if (rarityTier == 5) {
                    $.tokenIdToPCData[ids[i]].elementSlot1 = ElementType(elementSlot1);
                    $.tokenIdToPCData[ids[i]].elementSlot2 = ElementType(elementSlot2);
                    $.tokenIdToPCData[ids[i]].elementSlot3 = ElementType(elementSlot3);
                }
            }
        }
    }

    /// @dev Override this function to return true if `_afterNFTTransfers` is used.
    /// This is to help the compiler avoid producing dead bytecode.
    function _useAfterNFTTransfers() internal pure returns (bool) {
        return true;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                          PERMIT2                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Whether Permit2 has infinite allowances by default for all owners.
    /// For signature-based allowance granting for single transaction ERC20 `transferFrom`.
    /// To enable, override this function to return true.
    ///
    /// Note: The returned value SHOULD be kept constant.
    /// If the returned value changes from false to true,
    /// it can override the user customized allowances for Permit2 to infinity.
    function _givePermit2DefaultInfiniteAllowance() internal pure returns (bool) {
        return false;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-��-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    ///
    /// Will mint NFTs to `to` if the recipient's new balance supports
    /// additional NFTs ***AND*** the `to` address's skipNFT flag is set to false.
    ///
    /// Note:
    /// - May mint more NFTs than `amount / _unit()`.
    ///   The number of NFTs minted is what is needed to make `to`'s NFT balance whole.
    /// - Token IDs wraps back to `_toUint(_useOneIndexed())` upon exceeding the upper limit.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 amount) internal {
        if (to == address(0)) revert TransferToZeroAddress();

        DN404Storage storage $ = _getDN404Storage();
        if ($.mirrorERC721 == address(0)) revert DNNotInitialized();

        // Check max supply
        if (uint256($.totalSupply) + amount > MAX_SUPPLY) revert MaxSupplyExceeded();

        AddressData storage toAddressData = $.addressData[to];

        _DNMintTemps memory t;
        unchecked {
            {
                uint256 toBalance = uint256(toAddressData.balance) + amount;
                toAddressData.balance = uint96(toBalance);
                t.toEnd = toBalance / _unit();
            }
            uint256 idLimit;
            {
                uint256 newTotalSupply = uint256($.totalSupply) + amount;
                $.totalSupply = uint96(newTotalSupply);
                uint256 overflows = _toUint(_totalSupplyOverflows(newTotalSupply));
                if (overflows | _toUint(newTotalSupply < amount) != 0) revert TotalSupplyOverflow();
                idLimit = newTotalSupply / _unit();
            }
            while (!getSkipNFT(to)) {
                Uint32Map storage toOwned = $.owned[to];
                Uint32Map storage oo = $.oo;
                uint256 toIndex = toAddressData.ownedLength;
                if ((t.numNFTMints = _zeroFloorSub(t.toEnd, toIndex)) == uint256(0)) break;

                t.packedLogs = _packedLogsMalloc(t.numNFTMints);
                _packedLogsSet(t.packedLogs, to, 0);
                $.totalNFTSupply += uint32(t.numNFTMints);
                toAddressData.ownedLength = uint32(t.toEnd);
                t.toAlias = _registerAndResolveAlias(toAddressData, to);
                uint32 burnedPoolHead = $.burnedPoolHead;
                t.burnedPoolTail = $.burnedPoolTail;
                t.nextTokenId = _wrapNFTId($.nextTokenId, idLimit);
                // Mint loop.
                do {
                    uint256 id;
                    if (burnedPoolHead != t.burnedPoolTail) {
                        id = _get($.burnedPool, burnedPoolHead++);
                    } else {
                        id = t.nextTokenId;
                        while (_get(oo, _ownershipIndex(id)) != 0) {
                            id = _useExistsLookup()
                                ? _wrapNFTId(_findFirstUnset($.exists, id + 1, idLimit), idLimit)
                                : _wrapNFTId(id + 1, idLimit);
                        }
                        t.nextTokenId = _wrapNFTId(id + 1, idLimit);
                    }
                    if (_useExistsLookup()) _set($.exists, id, true);
                    _set(toOwned, toIndex, uint32(id));
                    _setOwnerAliasAndOwnedIndex(oo, id, t.toAlias, uint32(toIndex++));
                    _packedLogsAppend(t.packedLogs, id);
                } while (toIndex != t.toEnd);

                $.nextTokenId = uint32(t.nextTokenId);
                $.burnedPoolHead = burnedPoolHead;
                _packedLogsSend(t.packedLogs, $);
                break;
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, shl(96, to)))
        }
        if (_useAfterNFTTransfers()) {
            _afterNFTTransfers(_zeroAddresses(t.numNFTMints), _filled(t.numNFTMints, to), _packedLogsIds(t.packedLogs));
        }
    }

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    /// This variant mints NFT tokens starting from ID
    /// `preTotalSupply / _unit() + _toUint(_useOneIndexed())`.
    /// The `nextTokenId` will not be changed.
    /// If any NFTs are minted, the burned pool will be invalidated (emptied).
    ///
    /// Will mint NFTs to `to` if the recipient's new balance supports
    /// additional NFTs ***AND*** the `to` address's skipNFT flag is set to false.
    ///
    /// Note:
    /// - May mint more NFTs than `amount / _unit()`.
    ///   The number of NFTs minted is what is needed to make `to`'s NFT balance whole.
    /// - Token IDs wraps back to `_toUint(_useOneIndexed())` upon exceeding the upper limit.
    ///
    /// Emits a {Transfer} event.
    function _mintNext(address to, uint256 amount) internal {
        if (to == address(0)) revert TransferToZeroAddress();

        DN404Storage storage $ = _getDN404Storage();
        if ($.mirrorERC721 == address(0)) revert DNNotInitialized();

        // Check max supply
        if (uint256($.totalSupply) + amount > MAX_SUPPLY) revert MaxSupplyExceeded();

        AddressData storage toAddressData = $.addressData[to];

        _DNMintTemps memory t;
        unchecked {
            {
                uint256 toBalance = uint256(toAddressData.balance) + amount;
                toAddressData.balance = uint96(toBalance);
                t.toEnd = toBalance / _unit();
            }
            uint256 id;
            uint256 idLimit;
            {
                uint256 preTotalSupply = uint256($.totalSupply);
                uint256 newTotalSupply = uint256(preTotalSupply) + amount;
                $.totalSupply = uint96(newTotalSupply);
                uint256 overflows = _toUint(_totalSupplyOverflows(newTotalSupply));
                if (overflows | _toUint(newTotalSupply < amount) != 0) revert TotalSupplyOverflow();
                idLimit = newTotalSupply / _unit();
                id = _wrapNFTId(preTotalSupply / _unit() + _toUint(_useOneIndexed()), idLimit);
            }
            while (!getSkipNFT(to)) {
                Uint32Map storage toOwned = $.owned[to];
                Uint32Map storage oo = $.oo;
                uint256 toIndex = toAddressData.ownedLength;
                if ((t.numNFTMints = _zeroFloorSub(t.toEnd, toIndex)) == uint256(0)) break;

                t.packedLogs = _packedLogsMalloc(t.numNFTMints);
                // Invalidate (empty) the burned pool.
                $.burnedPoolHead = 0;
                $.burnedPoolTail = 0;
                _packedLogsSet(t.packedLogs, to, 0);
                $.totalNFTSupply += uint32(t.numNFTMints);
                toAddressData.ownedLength = uint32(t.toEnd);
                t.toAlias = _registerAndResolveAlias(toAddressData, to);
                // Mint loop.
                do {
                    while (_get(oo, _ownershipIndex(id)) != 0) {
                        id = _useExistsLookup()
                            ? _wrapNFTId(_findFirstUnset($.exists, id + 1, idLimit), idLimit)
                            : _wrapNFTId(id + 1, idLimit);
                    }
                    if (_useExistsLookup()) _set($.exists, id, true);
                    _set(toOwned, toIndex, uint32(id));
                    _setOwnerAliasAndOwnedIndex(oo, id, t.toAlias, uint32(toIndex++));
                    _packedLogsAppend(t.packedLogs, id);
                    id = _wrapNFTId(id + 1, idLimit);
                } while (toIndex != t.toEnd);

                _packedLogsSend(t.packedLogs, $);
                break;
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, shl(96, to)))
        }
        if (_useAfterNFTTransfers()) {
            _afterNFTTransfers(_zeroAddresses(t.numNFTMints), _filled(t.numNFTMints, to), _packedLogsIds(t.packedLogs));
        }
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Burns `amount` tokens from `from`, reducing the total supply.
    ///
    /// Will burn sender NFTs if balance after transfer is less than
    /// the amount required to support the current NFT balance.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 amount) internal {
        DN404Storage storage $ = _getDN404Storage();
        if ($.mirrorERC721 == address(0)) revert DNNotInitialized();

        AddressData storage fromAddressData = $.addressData[from];
        _DNBurnTemps memory t;

        unchecked {
            t.fromBalance = fromAddressData.balance;
            if (amount > t.fromBalance) revert InsufficientBalance();

            fromAddressData.balance = uint96(t.fromBalance -= amount);
            t.totalSupply = uint256($.totalSupply) - amount;
            $.totalSupply = uint96(t.totalSupply);

            Uint32Map storage fromOwned = $.owned[from];
            uint256 fromIndex = fromAddressData.ownedLength;
            t.numNFTBurns = _zeroFloorSub(fromIndex, t.fromBalance / _unit());

            if (t.numNFTBurns != 0) {
                t.packedLogs = _packedLogsMalloc(t.numNFTBurns);
                _packedLogsSet(t.packedLogs, from, 1);
                bool addToBurnedPool;
                {
                    uint256 totalNFTSupply = uint256($.totalNFTSupply) - t.numNFTBurns;
                    $.totalNFTSupply = uint32(totalNFTSupply);
                    addToBurnedPool = _addToBurnedPool(totalNFTSupply, t.totalSupply);
                }

                Uint32Map storage oo = $.oo;
                uint256 fromEnd = fromIndex - t.numNFTBurns;
                fromAddressData.ownedLength = uint32(fromEnd);
                uint32 burnedPoolTail = $.burnedPoolTail;
                // Burn loop.
                do {
                    uint256 id = _get(fromOwned, --fromIndex);
                    _setOwnerAliasAndOwnedIndex(oo, id, 0, 0);
                    _packedLogsAppend(t.packedLogs, id);
                    if (_useExistsLookup()) _set($.exists, id, false);
                    if (addToBurnedPool) _set($.burnedPool, burnedPoolTail++, uint32(id));
                    if (_get($.mayHaveNFTApproval, id)) {
                        _set($.mayHaveNFTApproval, id, false);
                        delete $.nftApprovals[id];
                    }
                    // Add this code to decrease the rarity count when burning
                    RarityTier rarityTier = $.tokenIdToPCData[id].rarityTier;

                    if (rarityTier > RarityTier.NONE && $.rarityTotalsByTier[uint8(rarityTier)] > 0) {
                        $.rarityTotalsByTier[uint8(rarityTier)]--;
                        delete $.tokenIdToPCData[id];
                    }
                } while (fromIndex != fromEnd);

                if (addToBurnedPool) $.burnedPoolTail = burnedPoolTail;
                _packedLogsSend(t.packedLogs, $);
            }
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0)
        }
        if (_useAfterNFTTransfers()) {
            _afterNFTTransfers(
                _filled(t.numNFTBurns, from),
                _zeroAddresses(t.numNFTBurns),
                _packedLogsIds(t.packedLogs)
            );
        }
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                INTERNAL TRANSFER FUNCTIONS                 */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Moves `amount` of tokens from `from` to `to`.
    ///
    /// Will burn sender NFTs if balance after transfer is less than
    /// the amount required to support the current NFT balance.
    ///
    /// Will mint NFTs to `to` if the recipient's new balance supports
    /// additional NFTs ***AND*** the `to` address's skipNFT flag is
    /// set to false.
    ///
    /// Emits a {Transfer} event.
    function _transfer(address from, address to, uint256 amount) internal {
        if (to == address(0)) revert TransferToZeroAddress();

        DN404Storage storage $ = _getDN404Storage();
        AddressData storage fromAddressData = $.addressData[from];
        AddressData storage toAddressData = $.addressData[to];
        if ($.mirrorERC721 == address(0)) revert DNNotInitialized();

        _DNTransferTemps memory t;
        t.fromOwnedLength = fromAddressData.ownedLength;
        t.toOwnedLength = toAddressData.ownedLength;

        unchecked {
            {
                uint256 fromBalance = fromAddressData.balance;
                if (amount > fromBalance) revert InsufficientBalance();
                fromAddressData.balance = uint96(fromBalance -= amount);

                uint256 toBalance = uint256(toAddressData.balance) + amount;
                toAddressData.balance = uint96(toBalance);
                t.numNFTBurns = _zeroFloorSub(t.fromOwnedLength, fromBalance / _unit());

                if (!getSkipNFT(to)) {
                    if (from == to) t.toOwnedLength = t.fromOwnedLength - t.numNFTBurns;
                    t.numNFTMints = _zeroFloorSub(toBalance / _unit(), t.toOwnedLength);
                }
            }

            while (_useDirectTransfersIfPossible()) {
                uint256 n = _min(t.fromOwnedLength, _min(t.numNFTBurns, t.numNFTMints));
                if (n == uint256(0)) break;
                t.numNFTBurns -= n;
                t.numNFTMints -= n;
                if (from == to) {
                    t.toOwnedLength += n;
                    break;
                }
                t.directLogs = _directLogsMalloc(n, from, to);
                Uint32Map storage fromOwned = $.owned[from];
                Uint32Map storage toOwned = $.owned[to];
                t.toAlias = _registerAndResolveAlias(toAddressData, to);
                uint256 toIndex = t.toOwnedLength;
                n = toIndex + n;
                // Direct transfer loop.
                do {
                    uint256 id = _get(fromOwned, --t.fromOwnedLength);
                    _set(toOwned, toIndex, uint32(id));
                    _setOwnerAliasAndOwnedIndex($.oo, id, t.toAlias, uint32(toIndex));
                    _directLogsAppend(t.directLogs, id);
                    if (_get($.mayHaveNFTApproval, id)) {
                        _set($.mayHaveNFTApproval, id, false);
                        delete $.nftApprovals[id];
                    }
                } while (++toIndex != n);

                toAddressData.ownedLength = uint32(t.toOwnedLength = toIndex);
                fromAddressData.ownedLength = uint32(t.fromOwnedLength);
                break;
            }

            t.totalNFTSupply = uint256($.totalNFTSupply) + t.numNFTMints - t.numNFTBurns;
            $.totalNFTSupply = uint32(t.totalNFTSupply);

            Uint32Map storage oo = $.oo;
            t.packedLogs = _packedLogsMalloc(t.numNFTBurns + t.numNFTMints);

            t.burnedPoolTail = $.burnedPoolTail;
            if (t.numNFTBurns != 0) {
                _packedLogsSet(t.packedLogs, from, 1);
                bool addToBurnedPool = _addToBurnedPool(t.totalNFTSupply, $.totalSupply);
                Uint32Map storage fromOwned = $.owned[from];
                uint256 fromIndex = t.fromOwnedLength;
                fromAddressData.ownedLength = uint32(t.fromEnd = fromIndex - t.numNFTBurns);
                uint32 burnedPoolTail = t.burnedPoolTail;
                // Burn loop.
                do {
                    uint256 id = _get(fromOwned, --fromIndex);
                    _setOwnerAliasAndOwnedIndex(oo, id, 0, 0);
                    _packedLogsAppend(t.packedLogs, id);
                    if (_useExistsLookup()) _set($.exists, id, false);
                    if (addToBurnedPool) _set($.burnedPool, burnedPoolTail++, uint32(id));
                    if (_get($.mayHaveNFTApproval, id)) {
                        _set($.mayHaveNFTApproval, id, false);
                        delete $.nftApprovals[id];
                    }

                    RarityTier rarityTier = $.tokenIdToPCData[id].rarityTier;
                    if (rarityTier > RarityTier.NONE && $.rarityTotalsByTier[uint8(rarityTier)] > 0) {
                        $.rarityTotalsByTier[uint8(rarityTier)]--;
                        delete $.tokenIdToPCData[id];
                    }
                } while (fromIndex != t.fromEnd);

                if (addToBurnedPool) $.burnedPoolTail = (t.burnedPoolTail = burnedPoolTail);
            }

            if (t.numNFTMints != 0) {
                _packedLogsSet(t.packedLogs, to, 0);
                Uint32Map storage toOwned = $.owned[to];
                t.toAlias = _registerAndResolveAlias(toAddressData, to);
                uint256 idLimit = $.totalSupply / _unit();
                t.nextTokenId = _wrapNFTId($.nextTokenId, idLimit);
                uint256 toIndex = t.toOwnedLength;
                toAddressData.ownedLength = uint32(t.toEnd = toIndex + t.numNFTMints);
                uint32 burnedPoolHead = $.burnedPoolHead;
                // Mint loop.
                do {
                    uint256 id;
                    if (burnedPoolHead != t.burnedPoolTail) {
                        id = _get($.burnedPool, burnedPoolHead++);
                    } else {
                        id = t.nextTokenId;
                        while (_get(oo, _ownershipIndex(id)) != 0) {
                            id = _useExistsLookup()
                                ? _wrapNFTId(_findFirstUnset($.exists, id + 1, idLimit), idLimit)
                                : _wrapNFTId(id + 1, idLimit);
                        }
                        t.nextTokenId = _wrapNFTId(id + 1, idLimit);
                    }
                    if (_useExistsLookup()) _set($.exists, id, true);
                    _set(toOwned, toIndex, uint32(id));
                    _setOwnerAliasAndOwnedIndex(oo, id, t.toAlias, uint32(toIndex++));
                    _packedLogsAppend(t.packedLogs, id);
                } while (toIndex != t.toEnd);

                $.burnedPoolHead = burnedPoolHead;
                $.nextTokenId = uint32(t.nextTokenId);
            }

            if (t.directLogs != bytes32(0)) _directLogsSend(t.directLogs, $);
            if (t.packedLogs != bytes32(0)) _packedLogsSend(t.packedLogs, $);
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            // forgefmt: disable-next-item
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), shr(96, shl(96, to)))
        }
        if (_useAfterNFTTransfers()) {
            uint256[] memory ids = _directLogsIds(t.directLogs);
            unchecked {
                _afterNFTTransfers(
                    _concat(_filled(ids.length + t.numNFTBurns, from), _filled(t.numNFTMints, from)),
                    _concat(
                        _concat(_filled(ids.length, to), _zeroAddresses(t.numNFTBurns)),
                        _filled(t.numNFTMints, to)
                    ),
                    _concat(ids, _packedLogsIds(t.packedLogs))
                );
            }
        }
    }

    /// @dev Transfers token `id` from `from` to `to`.
    /// Also emits an ERC721 {Transfer} event on the `mirrorERC721`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - `msgSender` must be the owner of the token, or be approved to manage the token.
    ///
    /// Emits a {Transfer} event.
    function _initiateTransferFromNFT(address from, address to, uint256 id, address msgSender) internal {
        // Emit ERC721 {Transfer} event.
        // We do this before the `_transferFromNFT`, as `_transferFromNFT` may use
        // the `_afterNFTTransfers` hook, which may trigger more transfers.
        // This helps keeps the sequence of emitted events consistent.
        // Since `mirrorERC721` is a trusted contract, we can do this.
        bytes32 directLogs = _directLogsMalloc(1, from, to);
        _directLogsAppend(directLogs, id);
        _directLogsSend(directLogs, _getDN404Storage());

        _transferFromNFT(from, to, id, msgSender);
    }

    /// @dev Transfers token `id` from `from` to `to`.
    ///
    /// This function will be called when a ERC721 transfer is made on the mirror contract.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - `msgSender` must be the owner of the token, or be approved to manage the token.
    ///
    /// Emits a {Transfer} event.
    function _transferFromNFT(address from, address to, uint256 id, address msgSender) internal {
        if (to == address(0)) revert TransferToZeroAddress();

        DN404Storage storage $ = _getDN404Storage();
        if ($.mirrorERC721 == address(0)) revert DNNotInitialized();

        Uint32Map storage oo = $.oo;

        if (from != $.aliasToAddress[_get(oo, _ownershipIndex(_restrictNFTId(id)))]) {
            revert TransferFromIncorrectOwner();
        }

        if (msgSender != from) {
            if (!_isApprovedForAll(from, msgSender)) {
                if (_getApproved(id) != msgSender) {
                    revert TransferCallerNotOwnerNorApproved();
                }
            }
        }

        AddressData storage fromAddressData = $.addressData[from];
        AddressData storage toAddressData = $.addressData[to];

        uint256 unit = _unit();
        mapping(address => Uint32Map) storage owned = $.owned;

        unchecked {
            uint256 fromBalance = fromAddressData.balance;
            if (unit > fromBalance) revert InsufficientBalance();
            fromAddressData.balance = uint96(fromBalance - unit);
            toAddressData.balance += uint96(unit);
        }
        if (_get($.mayHaveNFTApproval, id)) {
            _set($.mayHaveNFTApproval, id, false);
            delete $.nftApprovals[id];
        }
        unchecked {
            Uint32Map storage fromOwned = owned[from];
            uint32 updatedId = _get(fromOwned, --fromAddressData.ownedLength);
            uint32 i = _get(oo, _ownedIndex(id));
            _set(fromOwned, i, updatedId);
            _set(oo, _ownedIndex(updatedId), i);
        }
        unchecked {
            uint32 n = toAddressData.ownedLength++;
            _set(owned[to], n, uint32(id));
            _setOwnerAliasAndOwnedIndex(oo, id, _registerAndResolveAlias(toAddressData, to), n);
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Transfer} event.
            mstore(0x00, unit)
            // forgefmt: disable-next-item
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), shr(96, shl(96, to)))
        }
        if (_useAfterNFTTransfers()) {
            _afterNFTTransfers(_filled(1, from), _filled(1, to), _filled(1, id));
        }
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                 INTERNAL APPROVE FUNCTIONS                 */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Sets `amount` as the allowance of `spender` over the tokens of `owner`.
    ///
    /// Emits a {Approval} event.
    function _approve(address owner, address spender, uint256 amount) internal {
        if (_givePermit2DefaultInfiniteAllowance() && spender == _PERMIT2) {
            _getDN404Storage().addressData[owner].flags |= _ADDRESS_DATA_OVERRIDE_PERMIT2_FLAG;
        }
        _ref(_getDN404Storage().allowance, owner, spender).value = amount;
        /// @solidity memory-safe-assembly
        assembly {
            // Emit the {Approval} event.
            mstore(0x00, amount)
            // forgefmt: disable-next-item
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, shl(96, owner)), shr(96, shl(96, spender)))
        }
    }

    /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
    function _allowance(address owner, address spender) internal view returns (uint256) {
        if (_givePermit2DefaultInfiniteAllowance() && spender == _PERMIT2) {
            uint8 flags = _getDN404Storage().addressData[owner].flags;
            if ((flags & _ADDRESS_DATA_OVERRIDE_PERMIT2_FLAG) == uint256(0)) {
                return type(uint256).max;
            }
        }
        return _ref(_getDN404Storage().allowance, owner, spender).value;
    }

    /// @dev Transfers `amount` tokens from `from` to `to`.
    ///
    /// Note: Does not update the allowance if it is the maximum uint256 value.
    ///
    /// Will burn sender NFTs if balance after transfer is less than
    /// the amount required to support the current NFT balance.
    ///
    /// Will mint NFTs to `to` if the recipient's new balance supports
    /// additional NFTs ***AND*** the `to` address's skipNFT flag is
    /// set to false.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
    ///
    /// Emits a {Transfer} event.
    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        Uint256Ref storage a = _ref(_getDN404Storage().allowance, from, msg.sender);

        uint256 allowed = _givePermit2DefaultInfiniteAllowance() &&
            msg.sender == _PERMIT2 &&
            (_getDN404Storage().addressData[from].flags & _ADDRESS_DATA_OVERRIDE_PERMIT2_FLAG) == uint256(0)
            ? type(uint256).max
            : a.value;

        if (allowed != type(uint256).max) {
            if (amount > allowed) revert InsufficientAllowance();
            unchecked {
                a.value = allowed - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                 DATA HITCHHIKING FUNCTIONS                 */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns the auxiliary data for `owner`.
    /// Minting, transferring, burning the tokens of `owner` will not change the auxiliary data.
    /// Auxiliary data can be set for any address, even if it does not have any tokens.
    function _getAux(address owner) internal view returns (uint88) {
        return _getDN404Storage().addressData[owner].aux;
    }

    /// @dev Set the auxiliary data for `owner` to `value`.
    /// Minting, transferring, burning the tokens of `owner` will not change the auxiliary data.
    /// Auxiliary data can be set for any address, even if it does not have any tokens.
    function _setAux(address owner, uint88 value) internal {
        _getDN404Storage().addressData[owner].aux = value;
    }

    /// @dev Moves token `tokenId` to the last index in the owner's token array.
    /// @param owner The owner of the token.
    /// @param tokenId The ID of the token to move.
    /// @return True
    function _moveTokenToLastIndex(address owner, uint256 tokenId) internal returns (bool) {
        DN404Storage storage $ = _getDN404Storage();
        AddressData storage ownerData = $.addressData[owner];
        Uint32Map storage owned = $.owned[owner];

        // Get the current index of the token in owner's array
        uint256 currentIndex = _get($.oo, _ownedIndex(tokenId));
        uint256 lastIndex = ownerData.ownedLength - 1;

        // If token is not already at the last position
        if (currentIndex != lastIndex) {
            // Get the token at the last position
            uint32 lastTokenId = _get(owned, lastIndex);

            // Swap positions
            _set(owned, currentIndex, lastTokenId);
            _set(owned, lastIndex, uint32(tokenId));

            // Update the ownership indices
            _setOwnerAliasAndOwnedIndex($.oo, lastTokenId, ownerData.addressAlias, uint32(currentIndex));
            _setOwnerAliasAndOwnedIndex($.oo, tokenId, ownerData.addressAlias, uint32(lastIndex));
        }

        return true;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                     SKIP NFT FUNCTIONS                     */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns true if minting and transferring ERC20s to `owner` will skip minting NFTs.
    /// Returns false otherwise.
    function getSkipNFT(address owner) internal view returns (bool result) {
        uint8 flags = _getDN404Storage().addressData[owner].flags;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(iszero(and(flags, _ADDRESS_DATA_SKIP_NFT_FLAG)))
        }
    }

    /// @dev Internal function to set account `owner` skipNFT flag to `state`
    ///
    /// Initializes account `owner` AddressData if it is not currently initialized.
    ///
    /// Emits a {SkipNFTSet} event.
    function _setSkipNFT(address owner, bool state) internal {
        AddressData storage d = _getDN404Storage().addressData[owner];
        uint8 flags = d.flags;
        /// @solidity memory-safe-assembly
        assembly {
            let s := xor(iszero(and(flags, _ADDRESS_DATA_SKIP_NFT_FLAG)), iszero(state))
            flags := xor(mul(_ADDRESS_DATA_SKIP_NFT_FLAG, s), flags)
            flags := or(_ADDRESS_DATA_SKIP_NFT_INITIALIZED_FLAG, flags)
            mstore(0x00, iszero(iszero(state)))
            log2(0x00, 0x20, _SKIP_NFT_SET_EVENT_SIGNATURE, shr(96, shl(96, owner)))
        }
        d.flags = flags;
    }

    /// @dev Returns the `addressAlias` of account `to`.
    ///
    /// Assigns and registers the next alias if `to` alias was not previously registered.
    function _registerAndResolveAlias(
        AddressData storage toAddressData,
        address to
    ) internal returns (uint32 addressAlias) {
        DN404Storage storage $ = _getDN404Storage();
        addressAlias = toAddressData.addressAlias;
        if (addressAlias == uint256(0)) {
            unchecked {
                addressAlias = ++$.numAliases;
            }
            toAddressData.addressAlias = addressAlias;
            $.aliasToAddress[addressAlias] = to;
            if (addressAlias == uint256(0)) revert(); // Overflow.
        }
    }

    /// @dev Returns the total NFT supply.
    function _totalNFTSupply() internal view returns (uint256) {
        return _getDN404Storage().totalNFTSupply;
    }

    /// @dev Returns `owner` NFT balance.
    function _balanceOfNFT(address owner) internal view returns (uint256) {
        return _getDN404Storage().addressData[owner].ownedLength;
    }

    /// @dev Returns `owner` balance.
    function _balanceOf(address owner) internal view returns (uint256) {
        return _getDN404Storage().addressData[owner].balance;
    }

    /// @dev Returns the owner of token `id`.
    /// Returns the zero address instead of reverting if the token does not exist.
    function _ownerAt(uint256 id) internal view returns (address) {
        DN404Storage storage $ = _getDN404Storage();
        return $.aliasToAddress[_get($.oo, _ownershipIndex(_restrictNFTId(id)))];
    }

    /// @dev Returns the owner of token `id`.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    function _ownerOf(uint256 id) internal view returns (address) {
        if (!_exists(id)) revert TokenDoesNotExist();
        return _ownerAt(id);
    }

    /// @dev Returns whether `operator` is approved to manage the NFT tokens of `owner`.
    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return _ref(_getDN404Storage().operatorApprovals, owner, operator).value != 0;
    }

    /// @dev Returns if token `id` exists.
    function _exists(uint256 id) internal view returns (bool) {
        return _ownerAt(id) != address(0);
    }

    /// @dev Returns the account approved to manage token `id`.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    function _getApproved(uint256 id) internal view returns (address) {
        if (!_exists(id)) revert TokenDoesNotExist();
        return _getDN404Storage().nftApprovals[id];
    }

    /// @dev Sets `spender` as the approved account to manage token `id`, using `msgSender`.
    ///
    /// Requirements:
    /// - `msgSender` must be the owner or an approved operator for the token owner.
    function _approveNFT(address spender, uint256 id, address msgSender) internal returns (address owner) {
        DN404Storage storage $ = _getDN404Storage();

        owner = $.aliasToAddress[_get($.oo, _ownershipIndex(_restrictNFTId(id)))];

        if (msgSender != owner) {
            if (!_isApprovedForAll(owner, msgSender)) {
                revert ApprovalCallerNotOwnerNorApproved();
            }
        }

        $.nftApprovals[id] = spender;
        _set($.mayHaveNFTApproval, id, spender != address(0));
    }

    /// @dev Approve or remove the `operator` as an operator for `msgSender`,
    /// without authorization checks.
    function _setApprovalForAll(address operator, bool approved, address msgSender) internal {
        // For efficiency, we won't check if `operator` isn't `address(0)` (practically a no-op).
        _ref(_getDN404Storage().operatorApprovals, msgSender, operator).value = _toUint(approved);
    }

    /// @dev Returns the NFT IDs of `owner` in the range `[begin..end)` (exclusive of `end`).
    /// `begin` and `end` are indices in the owner's token ID array, not the entire token range.
    /// Optimized for smaller bytecode size, as this function is intended for off-chain calling.
    function _ownedIds(address owner, uint256 begin, uint256 end) internal view returns (uint256[] memory ids) {
        DN404Storage storage $ = _getDN404Storage();
        Uint32Map storage owned = $.owned[owner];
        end = _min($.addressData[owner].ownedLength, end);
        /// @solidity memory-safe-assembly
        assembly {
            ids := mload(0x40)
            let i := begin
            for {

            } lt(i, end) {
                i := add(i, 1)
            } {
                let s := add(shl(96, owned.slot), shr(3, i)) // Storage slot.
                let id := and(0xffffffff, shr(shl(5, and(i, 7)), sload(s)))
                mstore(add(add(ids, 0x20), shl(5, sub(i, begin))), id) // Append to.
            }
            mstore(ids, sub(i, begin)) // Store the length.
            mstore(0x40, add(add(ids, 0x20), shl(5, sub(i, begin)))) // Allocate memory.
        }
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                 INTERNAL / PRIVATE HELPERS                 */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns `(i - _toUint(_useOneIndexed())) << 1`.
    function _ownershipIndex(uint256 i) internal pure returns (uint256) {
        unchecked {
            return (i - _toUint(_useOneIndexed())) << 1;
        }
    }

    /// @dev Returns `((i - _toUint(_useOneIndexed())) << 1) + 1`.
    function _ownedIndex(uint256 i) internal pure returns (uint256) {
        unchecked {
            return ((i - _toUint(_useOneIndexed())) << 1) + 1;
        }
    }

    /// @dev Returns the uint32 value at `index` in `map`.
    function _get(Uint32Map storage map, uint256 index) internal view returns (uint32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := add(shl(96, map.slot), shr(3, index)) // Storage slot.
            result := and(0xffffffff, shr(shl(5, and(index, 7)), sload(s)))
        }
    }

    /// @dev Updates the uint32 value at `index` in `map`.
    function _set(Uint32Map storage map, uint256 index, uint32 value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let s := add(shl(96, map.slot), shr(3, index)) // Storage slot.
            let o := shl(5, and(index, 7)) // Storage slot offset (bits).
            let v := sload(s) // Storage slot value.
            sstore(s, xor(v, shl(o, and(0xffffffff, xor(value, shr(o, v))))))
        }
    }

    /// @dev Sets the owner alias and the owned index together.
    function _setOwnerAliasAndOwnedIndex(
        Uint32Map storage map,
        uint256 id,
        uint32 ownership,
        uint32 ownedIndex
    ) internal {
        uint256 t = _toUint(_useOneIndexed());
        /// @solidity memory-safe-assembly
        assembly {
            let i := sub(id, t) // Index of the uint64 combined value.
            let s := add(shl(96, map.slot), shr(2, i)) // Storage slot.
            let v := sload(s) // Storage slot value.
            let o := shl(6, and(i, 3)) // Storage slot offset (bits).
            let combined := or(shl(32, ownedIndex), and(0xffffffff, ownership))
            sstore(s, xor(v, shl(o, and(0xffffffffffffffff, xor(shr(o, v), combined)))))
        }
    }

    /// @dev Returns the boolean value of the bit at `index` in `bitmap`.
    function _get(Bitmap storage bitmap, uint256 index) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := add(shl(96, bitmap.slot), shr(8, index)) // Storage slot.
            result := and(1, shr(and(0xff, index), sload(s)))
        }
    }

    /// @dev Updates the bit at `index` in `bitmap` to `value`.
    function _set(Bitmap storage bitmap, uint256 index, bool value) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let s := add(shl(96, bitmap.slot), shr(8, index)) // Storage slot.
            let o := and(0xff, index) // Storage slot offset (bits).
            sstore(s, or(and(sload(s), not(shl(o, 1))), shl(o, iszero(iszero(value)))))
        }
    }

    /// @dev Returns the index of the least significant unset bit in `[begin..upTo]`.
    /// If no unset bit is found, returns `type(uint256).max`.
    function _findFirstUnset(
        Bitmap storage bitmap,
        uint256 begin,
        uint256 upTo
    ) internal view returns (uint256 unsetBitIndex) {
        /// @solidity memory-safe-assembly
        assembly {
            unsetBitIndex := not(0) // Initialize to `type(uint256).max`.
            let s := shl(96, bitmap.slot) // Storage offset of the bitmap.
            let bucket := add(s, shr(8, begin))
            let negBits := shl(and(0xff, begin), shr(and(0xff, begin), not(sload(bucket))))
            if iszero(negBits) {
                let lastBucket := add(s, shr(8, upTo))
                for {

                } 1 {

                } {
                    bucket := add(bucket, 1)
                    negBits := not(sload(bucket))
                    if or(negBits, gt(bucket, lastBucket)) {
                        break
                    }
                }
                if gt(bucket, lastBucket) {
                    negBits := shr(and(0xff, not(upTo)), shl(and(0xff, not(upTo)), negBits))
                }
            }
            if negBits {
                // Find-first-set routine.
                // From: https://github.com/vectorized/solady/blob/main/src/utils/LibBit.sol
                let b := and(negBits, add(not(negBits), 1)) // Isolate the least significant bit.
                // For the upper 3 bits of the result, use a De Bruijn-like lookup.
                // Credit to adhusson: https://blog.adhusson.com/cheap-find-first-set-evm/
                // forgefmt: disable-next-item
                let r := shl(
                    5,
                    shr(
                        252,
                        shl(
                            shl(2, shr(250, mul(b, 0x2aaaaaaaba69a69a6db6db6db2cb2cb2ce739ce73def7bdeffffffff))),
                            0x1412563212c14164235266736f7425221143267a45243675267677
                        )
                    )
                )
                // For the lower 5 bits of the result, use a De Bruijn lookup.
                // forgefmt: disable-next-item
                r := or(
                    r,
                    byte(
                        and(div(0xd76453e0, shr(r, b)), 0x1f),
                        0x001f0d1e100c1d070f090b19131c1706010e11080a1a141802121b1503160405
                    )
                )
                r := or(shl(8, sub(bucket, s)), r)
                unsetBitIndex := or(r, sub(0, or(gt(r, upTo), lt(r, begin))))
            }
        }
    }

    /// @dev Returns a storage reference to the value at (`a0`, `a1`) in `map`.
    function _ref(
        AddressPairToUint256RefMap storage map,
        address a0,
        address a1
    ) internal pure returns (Uint256Ref storage ref) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x28, a1)
            mstore(0x14, a0)
            mstore(0x00, map.slot)
            ref.slot := keccak256(0x00, 0x48)
            // Clear the part of the free memory pointer that was overwritten.
            mstore(0x28, 0x00)
        }
    }

    /// @dev Wraps the NFT ID.
    function _wrapNFTId(uint256 id, uint256 idLimit) internal pure returns (uint256 result) {
        result = _toUint(_useOneIndexed());
        /// @solidity memory-safe-assembly
        assembly {
            result := or(
                mul(or(mul(iszero(gt(id, idLimit)), id), gt(id, idLimit)), result),
                mul(mul(lt(id, idLimit), id), iszero(result))
            )
        }
    }

    /// @dev Returns `id > type(uint32).max ? 0 : id`.
    function _restrictNFTId(uint256 id) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mul(id, lt(id, 0x100000000))
        }
    }

    /// @dev Returns whether `amount` is an invalid `totalSupply`.
    function _totalSupplyOverflows(uint256 amount) internal pure returns (bool result) {
        uint256 unit = _unit();
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(iszero(or(shr(96, amount), lt(0xfffffffe, div(amount, unit)))))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function _zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns `x < y ? x : y`.
    function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns `b ? 1 : 0`.
    function _toUint(bool b) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(iszero(b))
        }
    }

    /// @dev Initiates memory allocation for direct logs with `n` log items.
    function _directLogsMalloc(uint256 n, address from, address to) private pure returns (bytes32 p) {
        /// @solidity memory-safe-assembly
        assembly {
            // `p`'s layout:
            //    uint256 offset;
            //    uint256[] logs;
            p := mload(0x40)
            let m := add(p, 0x40)
            mstore(m, 0x144027d3) // `logDirectTransfer(address,address,uint256[])`.
            mstore(add(m, 0x20), shr(96, shl(96, from)))
            mstore(add(m, 0x40), shr(96, shl(96, to)))
            mstore(add(m, 0x60), 0x60) // Offset of `logs` in the calldata to send.
            // Skip 4 words: `fnSelector`, `from`, `to`, `calldataLogsOffset`.
            let logs := add(0x80, m)
            mstore(logs, n) // Store the length.
            let offset := add(0x20, logs) // Skip the word for `p.logs.length`.
            mstore(0x40, add(offset, shl(5, n))) // Allocate memory.
            mstore(add(0x20, p), logs) // Set `p.logs`.
            mstore(p, offset) // Set `p.offset`.
        }
    }

    /// @dev Adds a direct log item to `p` with token `id`.
    function _directLogsAppend(bytes32 p, uint256 id) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(p)
            mstore(offset, id)
            mstore(p, add(offset, 0x20))
        }
    }

    /// @dev Calls the `mirror` NFT contract to emit {Transfer} events for packed logs `p`.
    function _directLogsSend(bytes32 p, DN404Storage storage $) private {
        address mirror = $.mirrorERC721;
        /// @solidity memory-safe-assembly
        assembly {
            let logs := mload(add(p, 0x20))
            let n := add(0x84, shl(5, mload(logs))) // Length of calldata to send.
            let o := sub(logs, 0x80) // Start of calldata to send.
            if iszero(and(eq(mload(o), 1), call(gas(), mirror, 0, add(o, 0x1c), n, o, 0x20))) {
                revert(o, 0x00)
            }
        }
    }

    /// @dev Returns the token IDs of the direct logs.
    function _directLogsIds(bytes32 p) private pure returns (uint256[] memory ids) {
        /// @solidity memory-safe-assembly
        assembly {
            if p {
                ids := mload(add(p, 0x20))
            }
        }
    }

    /// @dev Initiates memory allocation for packed logs with `n` log items.
    function _packedLogsMalloc(uint256 n) private pure returns (bytes32 p) {
        /// @solidity memory-safe-assembly
        assembly {
            // `p`'s layout:
            //     uint256 offset;
            //     uint256 addressAndBit;
            //     uint256[] logs;
            p := mload(0x40)
            let logs := add(p, 0xa0)
            mstore(logs, n) // Store the length.
            let offset := add(0x20, logs) // Skip the word for `p.logs.length`.
            mstore(0x40, add(offset, shl(5, n))) // Allocate memory.
            mstore(add(0x40, p), logs) // Set `p.logs`.
            mstore(p, offset) // Set `p.offset`.
        }
    }

    /// @dev Set the current address and the burn bit.
    function _packedLogsSet(bytes32 p, address a, uint256 burnBit) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(add(p, 0x20), or(shl(96, a), burnBit)) // Set `p.addressAndBit`.
        }
    }

    /// @dev Adds a packed log item to `p` with token `id`.
    function _packedLogsAppend(bytes32 p, uint256 id) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            let offset := mload(p)
            mstore(offset, or(mload(add(p, 0x20)), shl(8, id))) // `p.addressAndBit | (id << 8)`.
            mstore(p, add(offset, 0x20))
        }
    }

    /// @dev Calls the `mirror` NFT contract to emit {Transfer} events for packed logs `p`.
    function _packedLogsSend(bytes32 p, DN404Storage storage $) private {
        address mirror = $.mirrorERC721;
        /// @solidity memory-safe-assembly
        assembly {
            let logs := mload(add(p, 0x40))
            let o := sub(logs, 0x40) // Start of calldata to send.
            mstore(o, 0x263c69d6) // `logTransfer(uint256[])`.
            mstore(add(o, 0x20), 0x20) // Offset of `logs` in the calldata to send.
            let n := add(0x44, shl(5, mload(logs))) // Length of calldata to send.
            if iszero(and(eq(mload(o), 1), call(gas(), mirror, 0, add(o, 0x1c), n, o, 0x20))) {
                revert(o, 0x00)
            }
        }
    }

    /// @dev Returns the token IDs of the packed logs (destructively).
    function _packedLogsIds(bytes32 p) private pure returns (uint256[] memory ids) {
        /// @solidity memory-safe-assembly
        assembly {
            if p {
                ids := mload(add(p, 0x40))
                let o := add(ids, 0x20)
                let end := add(o, shl(5, mload(ids)))
                for {

                } iszero(eq(o, end)) {
                    o := add(o, 0x20)
                } {
                    mstore(o, shr(168, shl(160, mload(o))))
                }
            }
        }
    }

    /// @dev Returns an array of zero addresses.
    function _zeroAddresses(uint256 n) private pure returns (address[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x40, add(add(result, 0x20), shl(5, n)))
            mstore(result, n)
            codecopy(add(result, 0x20), codesize(), shl(5, n))
        }
    }

    /// @dev Returns an array each set to `value`.
    function _filled(uint256 n, uint256 value) private pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let o := add(result, 0x20)
            let end := add(o, shl(5, n))
            mstore(0x40, end)
            mstore(result, n)
            for {

            } iszero(eq(o, end)) {
                o := add(o, 0x20)
            } {
                mstore(o, value)
            }
        }
    }

    /// @dev Returns an array each set to `value`.
    function _filled(uint256 n, address value) private pure returns (address[] memory result) {
        result = _toAddresses(_filled(n, uint160(value)));
    }

    /// @dev Concatenates the arrays.
    function _concat(uint256[] memory a, uint256[] memory b) private view returns (uint256[] memory result) {
        uint256 aN = a.length;
        uint256 bN = b.length;
        if (aN == uint256(0)) return b;
        if (bN == uint256(0)) return a;
        /// @solidity memory-safe-assembly
        assembly {
            let n := add(aN, bN)
            if n {
                result := mload(0x40)
                mstore(result, n)
                let o := add(result, 0x20)
                mstore(0x40, add(o, shl(5, n)))
                let aL := shl(5, aN)
                pop(staticcall(gas(), 4, add(a, 0x20), aL, o, aL))
                pop(staticcall(gas(), 4, add(b, 0x20), shl(5, bN), add(o, aL), shl(5, bN)))
            }
        }
    }

    /// @dev Concatenates the arrays.
    function _concat(address[] memory a, address[] memory b) private view returns (address[] memory result) {
        result = _toAddresses(_concat(_toUints(a), _toUints(b)));
    }

    /// @dev Reinterpret cast to an uint array.
    function _toUints(address[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an address array.
    function _toAddresses(uint256[] memory a) private pure returns (address[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Struct of temporary variables for transfers.
    struct _DNTransferTemps {
        uint256 numNFTBurns;
        uint256 numNFTMints;
        uint256 fromOwnedLength;
        uint256 toOwnedLength;
        uint256 totalNFTSupply;
        uint256 fromEnd;
        uint256 toEnd;
        uint32 toAlias;
        uint256 nextTokenId;
        uint32 burnedPoolTail;
        bytes32 directLogs;
        bytes32 packedLogs;
    }

    /// @dev Struct of temporary variables for mints.
    struct _DNMintTemps {
        uint256 nextTokenId;
        uint32 burnedPoolTail;
        uint256 toEnd;
        uint32 toAlias;
        uint256 numNFTMints;
        bytes32 packedLogs;
    }

    /// @dev Struct of temporary variables for burns.
    struct _DNBurnTemps {
        uint256 fromBalance;
        uint256 totalSupply;
        uint256 numNFTBurns;
        bytes32 packedLogs;
    }

    /// @dev Returns the calldata value at `offset`.
    function _calldataload(uint256 offset) private pure returns (uint256 value) {
        /// @solidity memory-safe-assembly
        assembly {
            value := calldataload(offset)
        }
    }

    /// @dev Executes a return opcode to return `x` and end the current call frame.
    function _return(uint256 x) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, x)
            return(0x00, 0x20)
        }
    }

    /// @notice Returns the token IDs owned by `owner`.
    /// @param owner The owner of the tokens.
    /// @param begin The starting index of the batch.
    /// @param batchSize The size of the batch.
    /// @return The token IDs owned by `owner`.
    function getUserNFTsBatch(
        address owner,
        uint256 begin,
        uint256 batchSize
    ) internal view returns (uint256[] memory) {
        uint256 balance = _balanceOfNFT(owner);
        uint256 end = begin + batchSize;
        if (end > balance) {
            end = balance;
        }
        return _ownedIds(owner, begin, end);
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                 DN404 METADATA GETTER FUNCTIONS            */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @notice Returns the primecore data for a token.
    /// @param tokenId The ID of the token.
    /// @return rarityTier The rarity tier of the token.
    /// @return luck The luck of the token.
    /// @return prodType The production type of the token.
    /// @return elementSlot1 The first element slot of the token.
    /// @return elementSlot2 The second element slot of the token.
    /// @return elementSlot3 The third element slot of the token.
    function getPrimecoreData(
        uint256 tokenId
    )
        internal
        view
        returns (
            uint8 rarityTier,
            uint16 luck,
            uint8 prodType,
            uint8 elementSlot1,
            uint8 elementSlot2,
            uint8 elementSlot3
        )
    {
        DN404Storage storage $ = _getDN404Storage();
        rarityTier = uint8($.tokenIdToPCData[tokenId].rarityTier);
        luck = $.tokenIdToPCData[tokenId].luck;
        prodType = uint8($.tokenIdToPCData[tokenId].prodType);
        elementSlot1 = uint8($.tokenIdToPCData[tokenId].elementSlot1);
        elementSlot2 = uint8($.tokenIdToPCData[tokenId].elementSlot2);
        elementSlot3 = uint8($.tokenIdToPCData[tokenId].elementSlot3);
    }

    /// @notice Adds an address to the whitelist
    /// @param account The address to add to the whitelist.
    function _addToWhitelist(address account) internal {
        DN404Storage storage $ = _getDN404Storage();
        if ($.whitelistedAddressIndex[account] == 0) {
            $.whitelistedAddressList.push(account);
            // Store index + 1 (so 0 means not in list)
            $.whitelistedAddressIndex[account] = $.whitelistedAddressList.length;
        }
    }

    /// @notice Removes an address from the whitelist
    /// @param account The address to remove from the whitelist.
    function _removeFromWhitelist(address account) internal {
        DN404Storage storage $ = _getDN404Storage();
        uint256 index = $.whitelistedAddressIndex[account];
        require(index > 0, 'account not in whitelist');
        // Move the last address to the removed position
        $.whitelistedAddressList[index - 1] = $.whitelistedAddressList[$.whitelistedAddressList.length - 1];
        // Update the index for the moved address
        $.whitelistedAddressIndex[$.whitelistedAddressList[$.whitelistedAddressList.length - 1]] = index;
        // Remove the last element
        $.whitelistedAddressList.pop();
        delete $.whitelistedAddressIndex[account];
    }

    /// @notice Checks if an address is whitelisted
    /// @param account The address to check.
    /// @return True if the address is whitelisted, false otherwise.
    function _isWhitelisted(address account) internal view returns (bool) {
        return _getDN404Storage().whitelistedAddressIndex[account] != 0;
    }

    /// @notice Returns all whitelisted addresses
    /// @return The whitelisted addresses.
    function _getWhitelistedAddresses() internal view returns (address[] memory) {
        return _getDN404Storage().whitelistedAddressList;
    }

    /// @notice Returns the number of whitelisted addresses
    /// @return The number of whitelisted addresses.
    function _getWhitelistedAddressCount() internal view returns (uint256) {
        return _getDN404Storage().whitelistedAddressList.length;
    }

    /// @notice Sets the Uniswap Router address and adds it to whitelist
    /// @param router The address of the Uniswap Router.
    function _setUniswapRouter(address router) internal {
        DN404Storage storage $ = _getDN404Storage();
        $.UniswapRouter = router;
    }

    /// @notice Returns the Uniswap Router address
    /// @return The Uniswap Router address.
    function _getUniswapRouter() internal view returns (address) {
        return _getDN404Storage().UniswapRouter;
    }

    /// @notice Sets the base URI for token metadata
    /// @param baseURI The base URI for token metadata.
    function _setBaseURI(string memory baseURI) internal {
        _getDN404Storage().baseURI = baseURI;
    }

    /// @notice Gets the base URI for token metadata
    /// @return The base URI for token metadata.
    function _getBaseURI() internal view returns (string memory) {
        return _getDN404Storage().baseURI;
    }

    /// @notice Gets the complete image URI for a token based on its attributes
    /// @param tokenId The ID of the token.
    /// @return The complete image URI for the token.
    function _getImageURI(uint256 tokenId) internal view returns (string memory) {
        DN404Storage storage $ = _getDN404Storage();

        // Get the token's attributes
        (
            uint8 rarityTier,
            uint16 luck,
            uint8 prodType,
            uint8 elementSlot1,
            uint8 elementSlot2,
            uint8 elementSlot3
        ) = getPrimecoreData(tokenId);

        // Build the image path based on attributes
        string memory imagePath;
        {
            // Convert attributes to strings
            string memory rarityStr = Strings.toString(rarityTier);
            string memory luckStr = Strings.toString(luck);
            string memory prodTypeStr = Strings.toString(prodType);

            // Build elements string
            string memory elementsStr = string(
                abi.encodePacked(
                    Strings.toString(elementSlot1),
                    elementSlot2 > 0 ? string(abi.encodePacked('_elementSlot2_', Strings.toString(elementSlot2))) : '',
                    elementSlot3 > 0 ? string(abi.encodePacked('_elementSlot3_', Strings.toString(elementSlot3))) : ''
                )
            );

            // Combine into final path
            imagePath = string(
                abi.encodePacked(
                    'rarity_',
                    rarityStr,
                    '_luck_',
                    luckStr,
                    '_production_',
                    prodTypeStr,
                    '_elementSlot1_',
                    elementsStr,
                    '.png'
                )
            );
        }

        // Combine base URI with image path
        return string(abi.encodePacked($.baseURI, imagePath));
    }

    /// @notice Checks if the caller is an EOA
    /// @return True if the caller is an EOA, false otherwise.
    function _isEOA() internal view returns (bool) {
        return msg.sender == tx.origin;
    }

    /// @dev Sets the minimum amount of tokens that need to be transferred from LP to trigger a reroll
    /// @param threshold The new threshold amount in wei (18 decimals)
    function _setRerollThreshold(uint256 threshold) internal {
        _getDN404Storage().rerollThreshold = threshold;
    }

    /// @dev Gets the current threshold amount for triggering rerolls
    /// @return The current threshold amount in wei (18 decimals)
    function _getRerollThreshold() internal view returns (uint256) {
        return _getDN404Storage().rerollThreshold;
    }

    /// @notice Roll for rarity tier with scaling buckets to maintain target distribution
    /// @param randomness The randomness value for the roll.
    /// @return The rarity tier (1-5).
    function _rollRarityTier(uint256 randomness) internal view returns (uint8) {
        DN404Storage storage $ = _getDN404Storage();

        uint256 commonBucket;
        uint256 uncommonBucket;
        uint256 rareBucket;
        uint256 legendaryBucket;
        uint256 mythicBucket;

        ///  NOTE:
        ///  We use "weighted probability buckets" to roll rarity.
        ///  Ideally, the chances are [4000, 2500, 1000, 200, 77]
        ///  so commons are 4000/7777 = 51% chance and mythics are 77/7777 = 1%.
        ///
        ///  The code below grows or shrinks those buckets based on how many
        ///  NFTs of each rarity are currently minted in circulation.
        ///  If only 38 mythics are in circulation, the mythic bucket doubles.
        ///  If less than 10% of a tier is minted, the scale is capped at 10x.

        if ($.rarityTotalsByTier[1] <= TARGET_COMMON_COUNT / 10) {
            commonBucket = TARGET_COMMON_COUNT * 10; //  cap the scalar at 10x for super low inventory
        } else {
            uint256 commonScalar = (TARGET_COMMON_COUNT * 100) / $.rarityTotalsByTier[1];
            commonBucket = (TARGET_COMMON_COUNT * commonScalar) / 100;
        }

        if ($.rarityTotalsByTier[2] <= TARGET_UNCOMMON_COUNT / 10) {
            uncommonBucket = TARGET_UNCOMMON_COUNT * 10; //  cap the scalar at 10x for super low inventory
        } else {
            uint256 uncommonScalar = (TARGET_UNCOMMON_COUNT * 100) / $.rarityTotalsByTier[2];
            uncommonBucket = (TARGET_UNCOMMON_COUNT * uncommonScalar) / 100;
        }

        if ($.rarityTotalsByTier[3] <= TARGET_RARE_COUNT / 10) {
            rareBucket = TARGET_RARE_COUNT * 10; //  cap the scalar at 10x for super low inventory
        } else {
            uint256 rareScalar = (TARGET_RARE_COUNT * 100) / $.rarityTotalsByTier[3];
            rareBucket = (TARGET_RARE_COUNT * rareScalar) / 100;
        }

        if ($.rarityTotalsByTier[4] <= TARGET_LEGENDARY_COUNT / 10) {
            legendaryBucket = TARGET_LEGENDARY_COUNT * 10; //  cap the scalar at 10x for super low inventory
        } else {
            uint256 legendaryScalar = (TARGET_LEGENDARY_COUNT * 100) / $.rarityTotalsByTier[4];
            legendaryBucket = (TARGET_LEGENDARY_COUNT * legendaryScalar) / 100;
        }

        if ($.rarityTotalsByTier[5] <= TARGET_MYTHIC_COUNT / 10) {
            mythicBucket = TARGET_MYTHIC_COUNT * 10; //  cap the scalar at 10x for super low inventory
        } else {
            uint256 mythicScalar = (TARGET_MYTHIC_COUNT * 100) / $.rarityTotalsByTier[5];
            mythicBucket = (TARGET_MYTHIC_COUNT * mythicScalar) / 100;
        }

        uint256 roll = LibRNG.expand(
            commonBucket + uncommonBucket + rareBucket + legendaryBucket + mythicBucket,
            randomness,
            SALT_1
        );

        if (roll < commonBucket) {
            return 1; //  common
        } else if (roll < commonBucket + uncommonBucket) {
            return 2; //  uncommon
        } else if (roll < commonBucket + uncommonBucket + rareBucket) {
            return 3; //  rare
        } else if (roll < commonBucket + uncommonBucket + rareBucket + legendaryBucket) {
            return 4; //  legendary
        } else {
            return 5; //  mythic
        }
    }

    /// @dev Performs a reroll operation for the specified token ID
    /// @param tokenId The ID of the NFT to reroll
    /// @param slippageBps Slippage tolerance in basis points (e.g., 100 = 1%)
    function _reroll(uint256 tokenId, uint16 slippageBps) internal {
        DN404Storage storage $ = _getDN404Storage();

        // Initial validations
        _validateRerollPreconditions(tokenId, slippageBps, $.rerollThreshold);
        $.rerollLocked = true;

        // Cache owner and important values
        address owner = _ownerOf(tokenId);
        uint256 rerollThreshold = $.rerollThreshold;
        address treasury = $.treasuryAddress;
        uint256 userETH = msg.value;

        // Prepare for reroll
        bool isPartialBalanceLessThanThreshold = (_balanceOf(owner) % _unit()) < rerollThreshold;
        _moveTokenToLastIndex(owner, tokenId);

        // Execute swaps and collect fees
        (, /*uint256 ethReceived*/ uint256 treasuryFee, uint256 excess) = _executeRerollSwaps(
            owner,
            rerollThreshold,
            slippageBps,
            userETH
        );

        // Handle token transfers and burning/minting
        _handleTokenOperations(owner, rerollThreshold, isPartialBalanceLessThanThreshold);

        // Handle ETH transfers
        _handleETHTransfers(treasury, owner, treasuryFee, excess);

        // Release the reentrancy lock
        $.rerollLocked = false;
    }

    /// @dev Validates all preconditions for reroll operation
    function _validateRerollPreconditions(uint256 tokenId, uint16 slippageBps, uint256 rerollThreshold) internal {
        DN404Storage storage $ = _getDN404Storage();
        // Reentrancy check
        if ($.rerollLocked) revert ReentrancyGuard();

        // Validate slippage range (0.1% to 10%)
        if (slippageBps < 10 || slippageBps > 1000) revert InvalidSlippage();

        // Validate caller is EOA
        if (!_isEOA()) revert NotEOA();

        // Validate token ownership
        if (_ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

        // Validate balance and allowance
        if (_balanceOf(msg.sender) < _unit()) revert InsufficientBalance();
        if (_allowance(msg.sender, address(this)) < rerollThreshold) revert InsufficientAllowance();

        // Check if user has sufficient ETH for the swap
        uint256 requiredETH = _getRequiredETHForSwap(rerollThreshold);
        if (msg.value < (requiredETH / 5)) revert InsufficientETH(); // 20% slippage
    }

    /// @dev Executes the swap operations for reroll
    function _executeRerollSwaps(
        address owner,
        uint256 rerollThreshold,
        uint16 slippageBps,
        uint256 userETH
    ) private returns (uint256 ethReceived, uint256 treasuryFee, uint256 excess) {
        DN404Storage storage $ = _getDN404Storage();
        // Transfer tokens from user to contract
        _transfer(owner, address(this), rerollThreshold);

        // Execute PC to ETH swap
        ethReceived = _swapPCForETH(rerollThreshold, slippageBps);

        // Calculate treasury fee
        treasuryFee = (ethReceived * $.treasuryFeePercentage) / 10000;

        // Execute ETH to PC swap
        uint256 ethForBuyback = ethReceived + userETH - treasuryFee;
        excess = _swapETHForPC(ethForBuyback, rerollThreshold, slippageBps);

        return (ethReceived, treasuryFee, excess);
    }

    /// @dev Handles token operations after swaps
    function _handleTokenOperations(
        address owner,
        uint256 rerollThreshold,
        bool isPartialBalanceLessThanThreshold
    ) private {
        // Transfer tokens back to owner
        _transfer(address(this), owner, rerollThreshold);

        // Handle burn and mint if necessary
        if (!isPartialBalanceLessThanThreshold) {
            _burn(owner, _unit());
            _mint(owner, _unit());
        }
    }

    /// @dev Handles ETH transfers after swaps
    function _handleETHTransfers(address treasury, address owner, uint256 treasuryFee, uint256 excess) private {
        // Transfer treasury fee
        (bool treasurySuccess, ) = treasury.call{value: treasuryFee}('');
        require(treasurySuccess, 'Treasury transfer failed');
        emit TreasuryFeePaid(treasury, treasuryFee);

        // Return excess ETH to user
        (bool refundSuccess, ) = owner.call{value: excess}('');
        require(refundSuccess, 'Excess ETH transfer failed');
        emit ExcessETHRefunded(owner, excess);
    }

    /// @dev Gets required ETH amount for swap
    function _getRequiredETHForSwap(uint256 rerollThreshold) internal returns (uint256) {
        return
            IQuoter(UNISWAP_V3_QUOTER).quoteExactOutputSingle(
                WETH,
                address(this),
                _getPoolFeeTier(),
                rerollThreshold,
                0
            );
    }

    /// @dev Swaps PC tokens for ETH via Uniswap
    /// @param pcAmount The amount of PC tokens to swap
    /// @param slippageBps Slippage tolerance in basis points
    /// @return ethReceived The amount of ETH received from the swap
    function _swapPCForETH(uint256 pcAmount, uint16 slippageBps) internal returns (uint256 ethReceived) {
        address router = _getUniswapRouter();

        // Get expected output and calculate minimum acceptable amount
        uint256 expectedOutput = _getExpectedOutput(pcAmount);
        uint256 minOutput = (expectedOutput * (10000 - slippageBps)) / 10000;

        // Prepare and execute swap
        _approve(address(this), router, pcAmount);
        ethReceived = _executeSwap(router, pcAmount, minOutput);

        // Convert WETH to ETH
        IWETH(WETH).withdraw(ethReceived);
        return ethReceived;
    }

    /// @dev Gets expected output for PC to ETH swap
    function _getExpectedOutput(uint256 pcAmount) internal returns (uint256) {
        return IQuoter(UNISWAP_V3_QUOTER).quoteExactInputSingle(address(this), WETH, _getPoolFeeTier(), pcAmount, 0);
    }

    /// @dev Executes the swap through Uniswap
    function _executeSwap(address router, uint256 pcAmount, uint256 minOutput) private returns (uint256) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(this),
            tokenOut: WETH,
            fee: _getPoolFeeTier(),
            recipient: address(this),
            deadline: block.timestamp + 60,
            amountIn: pcAmount,
            amountOutMinimum: minOutput,
            sqrtPriceLimitX96: 0
        });

        uint256 ethReceived = ISwapRouter(router).exactInputSingle(params);
        if (ethReceived < minOutput) revert InsufficientOutputAmount();
        return ethReceived;
    }

    /// @dev Swaps ETH for PC tokens via Uniswap
    /// @param ethAmount The amount of ETH to swap
    /// @param pcAmount The amount of PC tokens to receive from the swap
    /// @param slippageBps Slippage tolerance in basis points
    function _swapETHForPC(uint256 ethAmount, uint256 pcAmount, uint16 slippageBps) internal returns (uint256) {
        address router = _getUniswapRouter();

        // Calculate maximum input based on quote and slippage
        uint256 expectedInput = IQuoter(UNISWAP_V3_QUOTER).quoteExactOutputSingle(
            WETH,
            address(this),
            _getPoolFeeTier(),
            pcAmount,
            0
        );

        uint256 maxInput = (expectedInput * (10000 + slippageBps)) / 10000;
        if (maxInput > ethAmount) revert SlippageExceedsAvailableETH();

        // Set up the swap parameters with maxInput
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: WETH,
            tokenOut: address(this),
            fee: _getPoolFeeTier(),
            recipient: address(this),
            deadline: block.timestamp + 60,
            amountOut: pcAmount,
            amountInMaximum: maxInput,
            sqrtPriceLimitX96: 0
        });

        // Wrap ETH to WETH before the swap
        IWETH(WETH).deposit{value: ethAmount}();

        // Approve router to spend our WETH
        IWETH(WETH).approve(router, ethAmount);

        // Execute the swap
        uint256 amountIn = ISwapRouter(router).exactOutputSingle(params);
        uint256 excess = ethAmount - amountIn;
        IWETH(WETH).withdraw(excess);
        return excess;
    }

    /// @notice Sets the treasury address
    /// @param treasury The address of the treasury.
    function _setTreasuryAddress(address treasury) internal {
        _getDN404Storage().treasuryAddress = treasury;
    }

    /// @notice Gets the treasury address
    /// @return The address of the treasury.
    function _getTreasuryAddress() internal view returns (address) {
        return _getDN404Storage().treasuryAddress;
    }

    /// @notice Sets the treasury fee percentage
    /// @param treasuryFeePercentage The percentage of the treasury fee.
    function _setTreasuryFeePercentage(uint256 treasuryFeePercentage) internal {
        _getDN404Storage().treasuryFeePercentage = treasuryFeePercentage;
    }

    /// @notice Gets the treasury fee percentage
    /// @return The percentage of the treasury fee.
    function _getTreasuryFeePercentage() internal view returns (uint256) {
        return _getDN404Storage().treasuryFeePercentage;
    }

    /// @notice Sets the pool fee tier
    /// @param feeTier The fee tier.
    function _setPoolFeeTier(uint24 feeTier) internal {
        _getDN404Storage().poolFeeTier = feeTier;
    }

    /// @notice Gets the pool fee tier
    /// @return The fee tier.
    function _getPoolFeeTier() internal view returns (uint24) {
        return _getDN404Storage().poolFeeTier;
    }

    /// @notice Sets the pool address
    /// @param poolAddress The address of the pool.
    function _setPoolAddress(address poolAddress) internal {
        _getDN404Storage().poolAddress = poolAddress;
        _setSkipNFT(poolAddress, true);
    }

    /// @notice Gets the pool address
    /// @return The address of the pool.
    function _getPoolAddress() internal view returns (address) {
        return _getDN404Storage().poolAddress;
    }
}
