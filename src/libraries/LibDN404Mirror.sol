// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/// @title LibDN404Mirror
/// @author Shiva (shiva.shanmuganathan@laguna.games)
/// @notice Adapted from https://github.com/Vectorized/dn404
/// @custom:storage-location uint72(bytes9(keccak256("DN404_MIRROR_STORAGE")))
import {LibContractOwner} from '../../lib/laguna-diamond-foundry/src/libraries/LibContractOwner.sol';

library LibDN404Mirror {
    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                           EVENTS                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Emitted when token `id` is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /// @dev Emitted when `owner` enables `account` to manage the `id` token.
    event Approval(address indexed owner, address indexed account, uint256 indexed id);

    /// @dev Emitted when `owner` enables or disables `operator` to manage all of their tokens.
    event ApprovalForAll(address indexed owner, address indexed operator, bool isApproved);

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This is for marketplace signaling purposes. This contract has a `pullOwner()`
    /// function that will sync the owner from the base contract.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /// @dev `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
    uint256 private constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE =
        0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                        CUSTOM ERRORS                       */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Thrown when a call for an NFT function did not originate
    /// from the base DN404 contract.
    error SenderNotBase();

    /// @dev Thrown when a call for an NFT function did not originate from the deployer.
    error SenderNotDeployer();

    /// @dev Thrown when transferring an NFT to a contract address that
    /// does not implement ERC721Receiver.
    error TransferToNonERC721ReceiverImplementer();

    /// @dev Thrown when a linkMirrorContract call is received and the
    /// NFT mirror contract has already been linked to a DN404 base contract.
    error AlreadyLinked();

    /// @dev Thrown when retrieving the base DN404 address when a link has not
    /// been established.
    error NotLinked();

    /// @dev The function selector is not recognized.
    error FnSelectorNotRecognized();

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                          STORAGE                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Struct contain the NFT mirror contract storage.
    struct DN404NFTStorage {
        // Address of the ERC20 base contract.
        address baseERC20;
    }

    /// @dev Returns a storage pointer for DN404NFTStorage.
    function _getDN404NFTStorage() internal pure returns (DN404NFTStorage storage $) {
        /// @solidity memory-safe-assembly
        assembly {
            // `uint72(bytes9(keccak256("DN404_MIRROR_STORAGE")))`.
            $.slot := 0x3602298b8c10b01230 // Truncate to 9 bytes to reduce bytecode size.
        }
    }

    /// @dev Sets `spender` as the approved account to manage token `id` in
    /// the base DN404 contract.
    ///
    /// Requirements:
    /// - Token `id` must exist.
    /// - The caller must be the owner of the token,
    ///   or an approved operator for the token owner.
    ///
    /// Emits an {Approval} event.
    function approve(address spender, uint256 id) internal {
        address base = baseERC20();
        /// @solidity memory-safe-assembly
        assembly {
            spender := shr(96, shl(96, spender))
            let m := mload(0x40)
            mstore(0x00, 0xd10b6e0c) // `approveNFT(address,uint256,address)`.
            mstore(0x20, spender)
            mstore(0x40, id)
            mstore(0x60, caller())
            if iszero(
                and(
                    // Arguments of `and` are evaluated last to first.
                    gt(returndatasize(), 0x1f), // The call must return at least 32 bytes.
                    call(gas(), base, callvalue(), 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
            // Emit the {Approval} event.
            log4(codesize(), 0x00, _APPROVAL_EVENT_SIGNATURE, shr(96, mload(0x0c)), spender, id)
        }
    }

    /// @dev Sets whether `operator` is approved to manage the tokens of the caller in
    /// the base DN404 contract.
    ///
    /// Emits an {ApprovalForAll} event.
    function setApprovalForAll(address operator, bool approved) internal {
        address base = baseERC20();
        /// @solidity memory-safe-assembly
        assembly {
            operator := shr(96, shl(96, operator))
            let m := mload(0x40)
            mstore(0x00, 0xf6916ddd) // `setApprovalForAllNFT(address,bool,address)`.
            mstore(0x20, operator)
            mstore(0x40, iszero(iszero(approved)))
            mstore(0x60, caller())
            if iszero(
                and(
                    // Arguments of `and` are evaluated last to first.
                    eq(mload(0x00), 1), // The call must return 1.
                    call(gas(), base, callvalue(), 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
            // Emit the {ApprovalForAll} event.
            // The `approved` value is already at 0x40.
            log3(0x40, 0x20, _APPROVAL_FOR_ALL_EVENT_SIGNATURE, caller(), operator)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Transfers token `id` from `from` to `to`.
    ///
    /// Requirements:
    ///
    /// - Token `id` must exist.
    /// - `from` must be the owner of the token.
    /// - `to` cannot be the zero address.
    /// - The caller must be the owner of the token, or be approved to manage the token.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 id) internal {
        address base = baseERC20();
        /// @solidity memory-safe-assembly
        assembly {
            from := shr(96, shl(96, from))
            to := shr(96, shl(96, to))
            let m := mload(0x40)
            mstore(m, 0xe5eb36c8) // `transferFromNFT(address,address,uint256,address)`.
            mstore(add(m, 0x20), from)
            mstore(add(m, 0x40), to)
            mstore(add(m, 0x60), id)
            mstore(add(m, 0x80), caller())
            if iszero(
                and(
                    // Arguments of `and` are evaluated last to first.
                    eq(mload(m), 1), // The call must return 1.
                    call(gas(), base, callvalue(), add(m, 0x1c), 0x84, m, 0x20)
                )
            ) {
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
            // Emit the {Transfer} event.
            log4(codesize(), 0x00, _TRANSFER_EVENT_SIGNATURE, from, to, id)
        }
    }

    /// @dev Permissionless function to pull the owner from the base DN404 contract
    /// if it implements ownable, for marketplace signaling purposes.
    function pullOwner() internal returns (bool) {
        address newOwner;
        address base = baseERC20();
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x8da5cb5b) // `owner()`.
            let success := staticcall(gas(), base, 0x1c, 0x04, 0x00, 0x20)
            newOwner := mul(shr(96, mload(0x0c)), and(gt(returndatasize(), 0x1f), success))
        }
        // DN404NFTStorage storage $ = _getDN404NFTStorage();
        address oldOwner = LibContractOwner.contractOwner();
        if (oldOwner != newOwner) {
            LibContractOwner.setContractOwner(newOwner);
        }
        return true;
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                     MIRROR OPERATIONS                      */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns the address of the base DN404 contract.
    function baseERC20() internal view returns (address base) {
        base = _getDN404NFTStorage().baseERC20;
        if (base == address(0)) revert NotLinked();
    }

    function logDirectTransfer(address from, address to, uint256[] calldata ids) internal returns (bool) {
        DN404NFTStorage storage $ = _getDN404NFTStorage();
        if ($.baseERC20 != msg.sender) revert SenderNotBase();
        /// @solidity memory-safe-assembly
        assembly {
            let o := add(0x24, calldataload(0x44)) // Direct logs offset.
            let end := add(o, shl(5, calldataload(sub(o, 0x20))))
            for {

            } iszero(eq(o, end)) {
                o := add(0x20, o)
            } {
                log4(codesize(), 0x00, _TRANSFER_EVENT_SIGNATURE, from, to, calldataload(o))
            }
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    function linkMirrorContract(address base) internal returns (bool) {
        DN404NFTStorage storage $ = _getDN404NFTStorage();
        if ($.baseERC20 != address(0)) revert AlreadyLinked();
        $.baseERC20 = msg.sender;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    function logTransfer(uint256[] calldata ids) internal returns (bool) {
        DN404NFTStorage storage $ = _getDN404NFTStorage();
        if ($.baseERC20 != msg.sender) revert SenderNotBase();

        /// @solidity memory-safe-assembly
        assembly {
            let o := add(0x24, calldataload(0x04)) // Packed logs offset.
            let end := add(o, shl(5, calldataload(sub(o, 0x20))))
            for {

            } iszero(eq(o, end)) {
                o := add(0x20, o)
            } {
                let d := calldataload(o) // Entry in the packed logs.
                let a := shr(96, d) // The address.
                let b := and(1, d) // Whether it is a burn.
                log4(
                    codesize(),
                    0x00,
                    _TRANSFER_EVENT_SIGNATURE,
                    mul(a, b), // `from`.
                    mul(a, iszero(b)), // `to`.
                    shr(168, shl(160, d)) // `id`.
                )
            }
            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
    }

    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*                      PRIVATE HELPERS                       */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Helper to read a string from the base DN404 contract.
    function _readString(uint256 fnSelector, uint256 arg0) internal view returns (string memory result) {
        address base = baseERC20();
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(0x00, fnSelector)
            mstore(0x20, arg0)
            if iszero(staticcall(gas(), base, 0x1c, 0x24, 0x00, 0x00)) {
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            returndatacopy(0x00, 0x00, 0x20) // Copy the offset of the string in returndata.
            returndatacopy(result, mload(0x00), 0x20) // Copy the length of the string.
            returndatacopy(add(result, 0x20), add(mload(0x00), 0x20), mload(result)) // Copy the string.
            let end := add(add(result, 0x20), mload(result))
            mstore(end, 0) // Zeroize the word after the string.
            mstore(0x40, add(end, 0x20)) // Allocate memory.
        }
    }

    /// @dev Helper to read a word from the base DN404 contract.
    function _readWord(uint256 fnSelector, uint256 arg0, uint256 arg1) internal view returns (uint256 result) {
        address base = baseERC20();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(0x00, fnSelector)
            mstore(0x20, arg0)
            mstore(0x40, arg1)
            if iszero(
                and(
                    // Arguments of `and` are evaluated last to first.
                    gt(returndatasize(), 0x1f), // The call must return at least 32 bytes.
                    staticcall(gas(), base, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
            mstore(0x40, m) // Restore the free memory pointer.
            result := mload(0x00)
        }
    }

    /// @dev Helper to read a uint256[] array from the base DN404 contract with three arguments.
    function _readArray(
        uint256 fnSelector,
        uint256 arg0,
        uint256 arg1,
        uint256 arg2
    ) internal view returns (uint256[] memory) {
        address base = baseERC20();
        bool success;
        bytes memory data;

        // Make a single call to get the full array
        (success, data) = base.staticcall(abi.encodeWithSelector(bytes4(uint32(fnSelector)), arg0, arg1, arg2));

        if (!success) {
            revert();
        }

        // Decode the array directly from the returned data
        return abi.decode(data, (uint256[]));
    }

    /// @dev Returns the calldata value at `offset`.
    function _calldataload(uint256 offset) internal pure returns (uint256 value) {
        /// @solidity memory-safe-assembly
        assembly {
            value := calldataload(offset)
        }
    }

    /// @dev Returns if `a` has bytecode of non-zero length.
    function _hasCode(address a) internal view returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := extcodesize(a) // Can handle dirty upper bits.
        }
    }

    /// @dev Perform a call to invoke {IERC721Receiver-onERC721Received} on `to`.
    /// Reverts if the target does not support the function correctly.
    function _checkOnERC721Received(address from, address to, uint256 id, bytes memory data) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the calldata.
            let m := mload(0x40)
            let onERC721ReceivedSelector := 0x150b7a02
            mstore(m, onERC721ReceivedSelector)
            mstore(add(m, 0x20), caller()) // The `operator`, which is always `msg.sender`.
            mstore(add(m, 0x40), shr(96, shl(96, from)))
            mstore(add(m, 0x60), id)
            mstore(add(m, 0x80), 0x80)
            let n := mload(data)
            mstore(add(m, 0xa0), n)
            if n {
                pop(staticcall(gas(), 4, add(data, 0x20), n, add(m, 0xc0), n))
            }
            // Revert if the call reverts.
            if iszero(call(gas(), to, 0, add(m, 0x1c), add(n, 0xa4), m, 0x20)) {
                if returndatasize() {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(m, 0x00, returndatasize())
                    revert(m, returndatasize())
                }
            }
            // Load the returndata and compare it.
            if iszero(eq(mload(m), shl(224, onERC721ReceivedSelector))) {
                mstore(0x00, 0xd1a57ed6) // `TransferToNonERC721ReceiverImplementer()`.
                revert(0x1c, 0x04)
            }
        }
    }
}
