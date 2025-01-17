// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title DN404MetadataFacet
/// @notice Provides metadata functions for the DN404 contract.
/// @author Shiva (shiva.shanmuganathan@laguna.games)

import {LibTokenURI} from '../libraries/LibTokenURI.sol';
import {LibDN404} from '../libraries/LibDN404.sol';

contract DN404MetadataFacet {
    /*«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-«-*/
    /*               METADATA FUNCTIONS                           */
    /*-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»-»*/

    /// @dev Returns the name of the token.
    function name() public view returns (string memory) {
        return LibDN404._getDN404Storage().name;
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view returns (string memory) {
        return LibDN404._getDN404Storage().symbol;
    }

    /// @dev Returns the decimals places of the token. Defaults to 18.
    function decimals() public pure returns (uint8) {
        return LibDN404._decimals();
    }

    /// @notice Returns the tokenURI of the token.
    /// @param id The ID of the token.
    /// @return The tokenURI of the token.
    /// @dev Note:
    /// - The tokenURI is generated using the token ID.
    /// - This function is invoked by `tokenURI` in the Mirror contract.
    function tokenURINFT(uint256 id) public view returns (string memory) {
        return LibTokenURI.generateTokenURI(uint32(id));
    }
}
